#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
Wayland screenshot tool for GNOME.

Requirements:
  - window-calls extension: https://extensions.gnome.org/extension/4724/window-calls/
  - GNOME may block screenshots from terminals (security feature)
    If blocked, a dialog will appear - click 'Share' to confirm

Usage:
    uv run wshot.py list                     # List windows (JSON)
    uv run wshot.py capture firefox          # By app name
    uv run wshot.py capture --pid 1234       # By PID
    uv run wshot.py capture --title "foo"    # By title
    uv run wshot.py capture -o out.png app   # Custom output path
"""

import json, subprocess, sys, shutil, time
from pathlib import Path

EXT_URL = "https://extensions.gnome.org/extension/4724/window-calls/"


def gdbus(dest: str, path: str, method: str, *args) -> str:
    r = subprocess.run(
        ["gdbus", "call", "--session", "--dest", dest, "--object-path", path, "--method", method, *map(str, args)],
        capture_output=True, text=True, timeout=10
    )
    return r.stdout if r.returncode == 0 else ""


def parse_json(s: str):
    start = s.find("[") if "[" in s else s.find("{")
    end = (s.rfind("]") if "[" in s else s.rfind("}")) + 1
    return json.loads(s[start:end]) if start >= 0 and end > 0 else None


def list_windows():
    data = parse_json(gdbus("org.gnome.Shell", "/org/gnome/Shell/Extensions/Windows",
                            "org.gnome.Shell.Extensions.Windows.List"))
    if not data: return []

    windows = []
    for w in data:
        rect = parse_json(gdbus("org.gnome.Shell", "/org/gnome/Shell/Extensions/Windows",
                                "org.gnome.Shell.Extensions.Windows.GetFrameRect", w["id"])) or {}
        windows.append({
            "id": w["id"], "app": w.get("wm_class", ""), "title": w.get("title", ""),
            "pid": w.get("pid"), "x": rect.get("x", 0), "y": rect.get("y", 0),
            "w": rect.get("width", 0), "h": rect.get("height", 0), "focused": w.get("focus", False)
        })
    return windows


def screenshot(x: int, y: int, w: int, h: int, path: str) -> bool:
    # Try direct D-Bus
    if "(true," in gdbus("org.gnome.Shell", "/org/gnome/Shell/Screenshot",
                         "org.gnome.Shell.Screenshot.ScreenshotArea", x, y, w, h, "false", path):
        return True

    # Fallback: portal (user must click Share)
    print("Click 'Share' in the GNOME dialog...", file=sys.stderr)
    gdbus("org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop",
          "org.freedesktop.portal.Screenshot.Screenshot", "", "{}")
    time.sleep(2)

    pics = sorted(Path.home().glob("Pictures/Screenshot*.png"), key=lambda p: p.stat().st_mtime, reverse=True)
    if pics:
        # Try to crop with ImageMagick
        if subprocess.run(["which", "convert"], capture_output=True).returncode == 0:
            subprocess.run(["convert", pics[0], "-crop", f"{w}x{h}+{x}+{y}", "+repage", path], capture_output=True)
            pics[0].unlink()
        else:
            shutil.move(pics[0], path)
        return Path(path).exists()
    return False


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__); return

    # Check extension
    if not gdbus("org.gnome.Shell", "/org/gnome/Shell/Extensions/Windows", "org.gnome.Shell.Extensions.Windows.List"):
        print(f"Extension required: {EXT_URL}", file=sys.stderr)
        if sys.stdin.isatty():
            subprocess.run(["xdg-open", EXT_URL], capture_output=True)
        sys.exit(1)

    if args[0] == "list":
        print(json.dumps(list_windows(), indent=2)); return

    if args[0] == "capture":
        windows = list_windows()
        if not windows: print("No windows", file=sys.stderr); sys.exit(1)

        # Parse args
        path, target, match = "/tmp/screenshot.png", None, "app"
        i = 1
        while i < len(args):
            if args[i] == "-o": path = args[i+1]; i += 2
            elif args[i] == "--pid": match, target = "pid", int(args[i+1]); i += 2
            elif args[i] == "--title": match, target = "title", args[i+1]; i += 2
            elif args[i] == "--id": match, target = "id", int(args[i+1]); i += 2
            elif not args[i].startswith("-"): target = args[i]; i += 1
            else: i += 1

        # Find window
        win = next((w for w in windows if (
            (match == "pid" and w["pid"] == target) or
            (match == "id" and w["id"] == target) or
            (match == "title" and target.lower() in w["title"].lower()) or
            (match == "app" and target.lower() in w["app"].lower())
        )), None)

        if not win:
            print(f"No match for '{target}'. Available:", file=sys.stderr)
            for w in windows: print(f"  {w['app']}: {w['title'][:50]}", file=sys.stderr)
            sys.exit(1)

        if screenshot(win["x"], win["y"], win["w"], win["h"], path):
            print(path)
        else:
            print("Screenshot failed", file=sys.stderr); sys.exit(1)
    else:
        print(f"Unknown: {args[0]}", file=sys.stderr); sys.exit(1)


if __name__ == "__main__":
    main()
