# agent-skills

A collection of useful skills for AI agents (Claude Code, etc.)

## Skills

### wshot

Screenshot tool for Wayland/GNOME. Capture windows by app name, PID, title, or window ID.

```bash
uv run .claude/skills/wshot/wshot.py list              # List windows (JSON)
uv run .claude/skills/wshot/wshot.py capture firefox   # Screenshot by app
```

## Installation

Copy the `.claude/skills/` directory to your project or to `~/.claude/skills/` for global availability.

## Requirements

- [uv](https://github.com/astral-sh/uv) for running Python scripts
- Skill-specific requirements listed in each skill's SKILL.md
