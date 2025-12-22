---
name: wshot
description: Take screenshots of windows on Wayland/GNOME. Use when asked to capture, screenshot, or photograph a window, app, or screen. Supports selection by app name, PID, title, or window ID.
---

# Screenshot Tool for Wayland/GNOME

Take screenshots of specific windows by app name, PID, title, or window ID.

## Usage

```bash
# List all windows (returns JSON)
uv run .claude/skills/wshot/wshot.py list

# Capture by app name
uv run .claude/skills/wshot/wshot.py capture firefox -o /tmp/shot.png

# Capture by PID
uv run .claude/skills/wshot/wshot.py capture --pid 1234 -o /tmp/shot.png

# Capture by title substring
uv run .claude/skills/wshot/wshot.py capture --title "GitHub" -o /tmp/shot.png

# Capture by window ID
uv run .claude/skills/wshot/wshot.py capture --id 2889387148 -o /tmp/shot.png
```

## Workflow

1. First run `list` to see available windows and their properties
2. Pick the target window by app name, PID, title, or ID
3. Run `capture` with the appropriate selector and output path
4. The output path is printed on success

## Output Format

The `list` command returns JSON:
```json
[
  {
    "id": 2889387148,
    "app": "Alacritty",
    "title": "Terminal",
    "pid": 12711,
    "x": 0, "y": 29,
    "w": 1920, "h": 1051,
    "focused": true
  }
]
```

## Requirements

- GNOME with Wayland
- `window-calls` extension (script will prompt to install if missing)
- If GNOME blocks the screenshot, a dialog appears - user clicks "Share"

## When to Use

Use this skill when the user asks to:
- Take a screenshot of a window or application
- Capture what's on screen
- Get an image of a running app
- Screenshot something by name or PID
