#!/usr/bin/env python3
"""Validate the YAML frontmatter used to discover and install plugin skills.

Requires PyYAML. Run from any directory; paths are relative to this file.
"""

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent


def validate_frontmatter(path):
    lines = path.read_text().splitlines()
    if not lines or lines[0] != "---":
        return ["missing YAML frontmatter"]
    try:
        end = lines.index("---", 1)
    except ValueError:
        return ["missing closing frontmatter delimiter"]

    try:
        metadata = yaml.safe_load("\n".join(lines[1:end]))
    except yaml.YAMLError as exc:
        return [f"invalid YAML frontmatter: {exc}"]

    if not isinstance(metadata, dict):
        return ["frontmatter must be a mapping"]
    return [
        f"{key} must be a nonempty string"
        for key in ("name", "description")
        if not isinstance(metadata.get(key), str) or not metadata[key].strip()
    ]


def main():
    skills = sorted((ROOT / "plugins").glob("*/skills/*/SKILL.md"))
    errors = [
        f"{path.relative_to(ROOT)}: {error}"
        for path in skills
        for error in validate_frontmatter(path)
    ]
    if errors:
        print("skill check FAILED:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"skill check OK: {len(skills)} skills have valid frontmatter")
    return 0


if __name__ == "__main__":
    sys.exit(main())
