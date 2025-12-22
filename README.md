# agent-skills

A Claude Code plugin with useful skills for AI agents.

## Installation

```bash
/plugin install mrshu/agent-skills
```

Or via CLI:
```bash
claude plugin install mrshu/agent-skills
```

## Skills

### wshot

Screenshot tool for Wayland/GNOME. Capture windows by app name, PID, title, or window ID.

**Requirements:**
- GNOME with Wayland
- `window-calls` extension (auto-prompted if missing)

Claude will automatically use this skill when you ask to take screenshots of windows or applications.

## License

MIT
