---
name: review-anvil-comments
description: Browse the review comments of a PR in a tmux side pane — one row per comment with finding ID, severity, author, and location, the full comment as a preview — and open any comment's code context. Use when the user runs `/review-anvil-comments [<finding>]` or asks to browse or pick from a PR's review-anvil comments. Requires tmux, `fzf` >= 0.45, `jq`, `gh`, `git`, `less`, `bat` (or `batcat`), and util-linux `column` on PATH.
---

# review-anvil-comments

Opens a tmux pane next to the agent with the PR's top-level review comments. The pane is interactive and belongs to the user; the agent only launches it.

Keys in the pane:

- **Enter** — open the selected comment's context (same view as `/review-anvil-context`); from there, **Backspace** on an empty query returns to this list
- **Esc** — close the pane

## Usage

```
/review-anvil-comments [<finding>] [--pr <N>]
```

Installed as the `review-anvil` plugin, the command is `/review-anvil:review-anvil-comments`.

With `<finding>`, the list opens with the cursor on that comment. `<finding>` and `--pr` work as in `/review-anvil-context`.

## Workflow

### 1. Resolve the helper script

The helper lives at `../review-anvil-context/scripts/context-helper.sh` relative to this SKILL.md — this skill reuses the script from `review-anvil-context` rather than duplicating it. Resolve it exactly per `review-anvil-context` SKILL.md step 1: host-exposed skill path (Claude Code: `${CLAUDE_PLUGIN_ROOT}/skills/review-anvil-context/scripts/context-helper.sh`) or user-level trusted install roots only, **never project-scoped/worktree-local skill directories**. If no trusted copy resolves, abort with `error: review-anvil-context/scripts/context-helper.sh not found in any trusted skill root` (the dependency is on `review-anvil-context`, not on `review-anvil-comments` itself).

### 2. Launch

```bash
bash <helper-path> comments [<finding>] [--pr <N>]
```

Pass the user's arguments through unchanged. Output and errors are the same as in `review-anvil-context` SKILL.md steps 2–3; report success in one line, e.g. `Opened the comment list for PR #365 in pane %39 (Enter: context, Esc: close).`
