---
name: review-anvil-pr
description: Read-only multi-agent review of a GitHub Pull Request, with the synthesized report posted back as a PR comment so the author is notified. Use when the user wants to review a GitHub PR (github.com or GitHub Enterprise) and post a structured review back to the PR conversation. Requires `gh` on PATH. Activates the `review-anvil` engine in read-only mode and orchestrates the shell helper for posting.
---

# review-anvil-pr

Preset that reviews a GitHub PR with the multi-agent loop and posts the result back as a top-level PR comment. The skill orchestrates three steps:

1. `scripts/pr-helper.sh init <locator>` — locator parsing, `gh` preflight (auth + PR reachability), marker UUID + report path setup
2. The [`review-anvil`](../review-anvil/SKILL.md) engine in read-only mode (`commit_mode=none`)
3. `scripts/pr-helper.sh post <host> <owner> <repo> <n> <marker> <report_path>` — marker injection, `gh pr comment`, race-free URL recovery

## Inputs

The user provides a PR locator as the first argument:

- **Full GitHub URL** — `https://<host>/<owner>/<repo>/pull/<N>` for github.com or GitHub Enterprise
- **Slug** — `<owner>/<repo>#<N>` (host defaults to github.com)

**Bare integers are rejected** by the helper script to prevent wrong-repo misdirection. The user must pass a URL or slug.

## How to invoke

### 1. Resolve the helper script

The script lives at `./scripts/pr-helper.sh` relative to this SKILL.md. Depending on how the skill was installed, the absolute path is one of:

- `${CLAUDE_PLUGIN_ROOT}/skills/review-anvil-pr/scripts/pr-helper.sh` — Claude Code via `/plugin install`
- `~/.claude/skills/review-anvil-pr/scripts/pr-helper.sh` — Claude Code via `npx skills add` (global)
- `~/.codex/skills/review-anvil-pr/scripts/pr-helper.sh` — Codex CLI via `npx skills add`
- `<project>/.<agent>/skills/review-anvil-pr/scripts/pr-helper.sh` — project-scoped install in other agents

Find the file by trying these paths in order, or by locating the SKILL.md the agent loaded and resolving `./scripts/pr-helper.sh` relative to it.

### 2. Init

```bash
bash <helper-path> init "<locator>"
```

On success, the script prints these KEY=VALUE lines on stdout:

```
HOST=github.com
OWNER=acme
REPO=widgets
N=137
MARKER=<uuidv4>
REPORT_PATH=.review-anvil/final-report-<uuidv4>.md
TITLE=<PR title>
```

Capture all values. Echo to the user: `review target: $HOST/$OWNER/$REPO#$N — $TITLE`.

On non-zero exit, surface the script's stderr verbatim and stop. Do not dispatch reviewers.

### 3. Activate the engine

Activate the `review-anvil` skill with this argument string (extra user args go between the pinned params and the rounds default):

```
commit_mode: none, target: <locator>, report_path: <REPORT_PATH>, <extra-user-args>, rounds: 2
```

The user may override `rounds:` in their args (it's a default, not a pin). They should not override `commit_mode`, `target`, or `report_path` — these are pinned for safety. The engine's own validation will catch the cross-parameter cases.

The engine runs the review loop, writes the final report to `<REPORT_PATH>`, and prints that path on its last output line.

### 4. Post

```bash
bash <helper-path> post "$HOST" "$OWNER" "$REPO" "$N" "$MARKER" "$REPORT_PATH"
```

The script atomically prepends the marker UUID to the report, posts via `gh pr comment`, then recovers the comment URL via paginated marker lookup (with one retry after ~2s to absorb GitHub's read-after-write lag). On success it prints the URL; on URL-recovery failure it prints `posted (URL unavailable)`.

### 5. Report back

Surface the URL (or fallback string) to the user. If the helper script exited non-zero from `post`, surface its stderr; the report still exists on disk at `<REPORT_PATH>` for manual posting.

## Constraints

- Requires `gh` on `PATH` and `uuidgen`. The script aborts with a clear error if either is missing.
- Read-only by design — the PR's branch may not be checked out locally, and pushing fix commits to a PR you don't own is rarely the intent. If you want fix-and-commit on a PR you have locally, activate `review-anvil` directly with `commit_mode=per_fix` (the engine's cross-parameter validation will require the local checkout to match).
- Supports github.com and GitHub Enterprise — the script extracts the host from the URL and sets `GH_HOST` internally for all `gh` invocations.
- Bare-integer PR locators are rejected — pass a URL or `<owner>/<repo>#<N>` slug to be unambiguous about repo identity.

## Pairing

This preset depends on the `review-anvil` engine being available in the same agent. Both skills ship in the same plugin and should be installed together (`npx skills add mrshu/agent-skills --skill review-anvil --skill review-anvil-pr`, or just `--all`).
