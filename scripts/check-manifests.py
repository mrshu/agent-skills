#!/usr/bin/env python3
"""Validate plugin manifests against the marketplace registry.

Run from the repo root (or anywhere — paths are resolved relative to this
file). Fails with a non-zero exit and a list of problems if:

  * any plugin.json or marketplace.json is invalid JSON;
  * a plugins/<dir>/ has a plugin.json not listed in marketplace.json,
    or a marketplace entry has no matching plugin directory;
  * a marketplace entry's `source` does not point at an existing dir;
  * the name/version in a plugin.json disagree with its marketplace entry.

This guards the drift that let gh-pr-image ship uninstallable.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLUGINS = ROOT / "plugins"
MARKETPLACE = ROOT / ".claude-plugin" / "marketplace.json"


def load_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return exc


def main():
    errors = []

    market = load_json(MARKETPLACE)
    if isinstance(market, Exception):
        print(f"error: {MARKETPLACE.relative_to(ROOT)}: {market}", file=sys.stderr)
        return 1

    entries = {}
    for entry in market.get("plugins", []):
        name = entry.get("name")
        if not name:
            errors.append(f"marketplace entry missing 'name': {entry!r}")
            continue
        if name in entries:
            errors.append(f"duplicate marketplace entry: {name}")
        entries[name] = entry

    # Every plugin directory with a manifest must be registered and consistent.
    dirs = {}
    for pj_path in sorted(PLUGINS.glob("*/.claude-plugin/plugin.json")):
        d = pj_path.parent.parent.name
        pj = load_json(pj_path)
        if isinstance(pj, Exception):
            errors.append(f"{pj_path.relative_to(ROOT)}: invalid JSON: {pj}")
            continue
        dirs[d] = pj
        name = pj.get("name")
        if name != d:
            errors.append(f"{d}: plugin.json name '{name}' != directory name")
        entry = entries.get(name)
        if entry is None:
            errors.append(f"{d}: not registered in marketplace.json")
            continue
        if entry.get("version") != pj.get("version"):
            errors.append(
                f"{name}: version mismatch — plugin.json {pj.get('version')!r} "
                f"vs marketplace {entry.get('version')!r}"
            )

    # Every marketplace entry must point at an existing plugin directory.
    for name, entry in entries.items():
        src = entry.get("source", "")
        src_dir = (ROOT / src).resolve() if src else None
        if not src or not src_dir.is_dir():
            errors.append(f"{name}: source '{src}' is not an existing directory")
        if name not in dirs:
            errors.append(f"{name}: marketplace entry has no plugins/{name}/ manifest")

    if errors:
        print("manifest check FAILED:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print(f"manifest check OK: {len(dirs)} plugins registered and consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
