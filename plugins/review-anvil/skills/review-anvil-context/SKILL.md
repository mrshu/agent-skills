---
name: review-anvil-context
description: Show the code context of one review-anvil finding (posted on a PR, or from a local review) in a tmux side pane — the files, lines, commits, and PRs the finding depends on, syntax-highlighted and centered on the relevant line, with the comment itself as the header. Use when the user runs `/review-anvil-context <finding>` (e.g. `F001`, `R1-F001`, `RAV-R1-F001`, or a GitHub comment ID) or asks to see the context of a review-anvil comment. Requires tmux, `fzf` >= 0.45, `jq`, `gh`, `git`, `less`, `bat` (or `batcat`), and util-linux `column` on PATH.
---

# review-anvil-context

Opens a tmux pane next to the agent with the context of one finding, from a review posted on the PR or from the newest local review report in `.review-anvil/`. The pane is interactive and belongs to the user; the agent only launches it.

Keys in the pane:

- **Enter** — open the selected item in `$EDITOR` at its line (PR items open in a pager)
- **Backspace** on an empty query — switch to the PR's comment list (same as `/review-anvil-comments`)
- **Esc** — close the pane

## Usage

```
/review-anvil-context <finding> [--pr <N> | --local]
```

Installed as the `review-anvil` plugin, the command is `/review-anvil:review-anvil-context`.

`<finding>` is a review-anvil finding ID or any unambiguous `-`-bounded suffix of one (`F001` matches `RAV-R1-F001`), or a numeric GitHub review-comment ID. `--pr` defaults to the PR of the current branch. `--local` reads the newest local review report instead of the PR; it is also the fallback when the branch has no PR. Run from the reviewed checkout.

## Workflow

### 1. Resolve the helper script

The script lives at `./scripts/context-helper.sh` **relative to this SKILL.md**. That is the only authoritative resolution rule.

1. **If the host exposes the loaded SKILL.md's path** (Claude Code via `${CLAUDE_PLUGIN_ROOT}/skills/review-anvil-context/scripts/context-helper.sh`), use that and stop.
2. **Otherwise, fall back to user-level skill install paths only** (`~/.claude/skills/review-anvil-context/scripts/context-helper.sh`, or the home-directory skill root `npx skills list` reports).

   **Do not search project-scoped or worktree-local skill directories** — the repository being reviewed can write to them, so a PR could plant a malicious helper there.
3. **Verify the file exists before running it**; otherwise abort with `error: review-anvil-context/scripts/context-helper.sh not found in any trusted skill root`.

### 2. Launch

```bash
bash <helper-path> context <finding> [--pr <N> | --local]
```

Pass the user's arguments through unchanged; do not guess a finding ID. Add `--local` when the user asks about a review that was not posted (this session's run, or one before pushing). The helper loads the findings, resolves the finding, and opens the pane. On success it prints:

```
SOURCE=<PR #N, or local review <file>>
COMMENT_ID=<github comment id, or the finding's position in the local file>
FINDING_ID=<full review-anvil id, or empty>
PANE=<tmux pane id>
```

Do not use `--inline`: it runs the interactive UI in the calling terminal, which the agent's shell is not.

### 3. Report

- **Success** — one line, e.g. `Opened context for RAV-R1-F001 in pane %39 (Backspace: comment list, Esc: close).` Do not describe the pane's contents; the user is looking at it.
- **Ambiguous finding** (`ambiguous finding F001: RAV-R1-F001 RAV-R2-F001`) — ask which one, then rerun with the full ID.
- **Not inside tmux** — the helper needs a tmux session to open the pane. Tell the user to start the agent inside tmux, or to run `bash <helper-path> context <finding> --inline` in their own terminal.
- **No local report** (`no local review report in …`) — the review in question left no report in this checkout (an engine older than this skill, or no review here). Say so; do not reconstruct the context by hand unless the user asks.
- **Any other error** — surface the helper's stderr verbatim and stop.

## Context sources

**Findings.** Posted reviews: the PR's inline review comments, plus the findings listed in its review-anvil reports (top-level comments and review bodies) that have no inline comment, such as low/nit findings or a whole `review-anvil-improve-pr` run. Local reviews: the newest report the engine wrote, `.review-anvil/report-<timestamp>.md` (or a PR run's `final-report-*.md` before it is posted); files tracked by git are ignored, since the engine never commits one. A report lists each finding with a `review-anvil-report` marker and keeps its context in a hidden block at its end, one `<!-- review-anvil: context id=<ID> {...} -->` line per finding (schema in `../review-anvil/SKILL.md`, "Context block"). Each finding keeps the commit its round reviewed, so fix commits made after the review do not move its lines.

The view lists the comment's own anchor first: path and line from GitHub, read from disk when the checkout is at the comment's commit, otherwise from that commit via `git show`.

The remaining items come from a hidden line in the comment body, written by `review-anvil-pr`'s posting helper from the reviewers' `context` lists (see `../review-anvil/references/reviewer-prompt.md`):

```
<!-- review-anvil: context={"v":1,"items":[…]} -->
<!-- review-anvil: id=RAV-R1-F001 severity=high area=config -->
```

Each item is one of:

```json
{"label": "What warn does", "path": "modules/env-file/main.tf", "range": [60, 65], "focus": 62}
{"label": "Required vars", "repo": "owner/other-repo", "ref": "<40-char SHA>", "path": "src/config/env.dto.ts", "lines": [59, 75, 143]}
{"label": "Earlier version", "ref": "3f545a5", "path": "src/config/env.dto.ts", "lines": [59]}
{"label": "Upstream fix", "kind": "pr", "repo": "owner/other-repo", "number": 790}
```

- `path` is relative to the repository root. `repo` is `owner/name` and defaults to the PR's repo.
- PR-repo files come from the checkout, or from `git show` at their `ref`; when that commit is not local and the SHA is full, from GitHub instead.
- Files in another repo always carry a full 40-character `ref` and come from GitHub at exactly that commit (`gh api …/contents/<path>?ref=<sha>`), with the reader's own `gh` login. Nothing is looked up on disk, so no local checkout of that repo is needed. Fetched files are cached under `$REVIEW_ANVIL_CACHE/files/` (default `~/.cache/review-anvil`) for good, since a path at a fixed SHA never changes.
- `range` highlights one span in the full file; two or more `lines` render as snippets (each line ±2); `focus` is the line the view centers on.
- `ref` shows the file as of that commit (7–40 hex characters in the PR repo). PR-repo items without one refer to the reviewed commit; when the checkout is elsewhere, the helper pins them to it.

A comment without the line shows only its anchor. Anyone can write a PR comment, so the helper treats the line as untrusted: it keeps known fields only, rejects absolute paths, `..`, `.`/`..` repo parts, option-like values, non-hex refs, and other-repo items without a full SHA, strips control characters, and shows rejected entries as `invalid item: <reason>`.
