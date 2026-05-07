---
name: overleaf-comment
description: Bulk-post Overleaf comments from a JSON plan. Use when asked to add many Overleaf comments at once (e.g. thesis review, paper feedback, multi-line annotations). Drives an existing logged-in browser tab via the chrome-cdp skill.
---

# Overleaf bulk comment poster

Post N Overleaf comments from a JSON plan, one CDP eval per item, streaming results as they happen. Uses the user's already-logged-in browser session — no API keys, no scraping. Built on the [`chrome-cdp`](../../chrome-cdp) skill.

## When to use

- A reviewer wants to leave many comments at specific lines across multiple project files (thesis review, paper feedback, code review on a `.tex` artefact).
- An agent has produced a structured review and wants to land each finding as a native Overleaf comment, not as `\todo{}` markers in the source.

**Don't use this** for one-off comments — typing in Overleaf directly is faster. The break-even is around 5 comments.

## Prerequisites

1. **`chrome-cdp` skill** installed and working. The wrapper auto-discovers `cdp.mjs` in `~/.claude/skills/`, `~/.claude/plugins/*/skills/`, sibling-skill paths, or via `$CDP_BIN`.
2. **Brave / Chrome / Chromium** running with `--remote-debugging-port=9222` (see chrome-cdp's prerequisites).
3. **Overleaf project tab open** in that browser, **already logged in**, with **comment-add permissions** (paid plan or shared-as-reviewer).

## Usage

```bash
# 1. find the project tab
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-comment/overleaf-comment --list

# 2. post a plan (target prefix from `cdp list`)
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-comment/overleaf-comment 6172EEAA plan.json

# or supply the project URL — script picks the matching tab
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-comment/overleaf-comment --url https://www.overleaf.com/project/6822076bb010d50556f6917d plan.json
```

(`${CLAUDE_PLUGIN_ROOT}` is set by Claude when the skill is loaded as a plugin. If you've installed the skill personally and put `overleaf-comment` on `$PATH`, the bare name works too.)

## Plan format

A JSON array of `{file, line, text}` objects. The wrapper groups by `file`, opens each file once, then posts all of that file's comments before moving on:

```json
[
  {"file": "main.tex",                  "line": 8,   "text": "linespread should be 1.5 per FMFI template"},
  {"file": "main.tex",                  "line": 55,  "text": "delete the \\mfkonzultant placeholder"},
  {"file": "parts/200-discussion.tex",  "line": 108, "text": "ungrammatical — 'too limited to internalize'"}
]
```

- `file` is matched **strictly** in Overleaf's file tree — exact basename first, then path-suffix only when the plan supplies a path with `/` or `\` AND exactly one tree item matches. `intro.tex` will NOT match `myintro.tex`. Ambiguous matches surface as `FAIL: ambiguous match`.
- `line` is **1-indexed**, matching Overleaf's editor.
- `text` is the comment body. Multi-line is fine (use `\n` in the JSON string). Empty / whitespace-only `text` is rejected by the validator.
- **Blank lines cannot be commented on** — Overleaf needs a non-empty selection. The wrapper skips them with a `FAIL` log.

## Output

Per-item results stream to stdout as they happen:

```
[main.tex] OK: main.tex (155 lines)
  L8: OK: line 8
  L55: OK: line 55
[parts/200-discussion.tex] OK: parts/200-discussion.tex (110 lines)
  L108: OK: line 108
  L109: FAIL: line 109 is blank — Overleaf cannot anchor a comment
```

A summary line and the active Overleaf account go to stderr:

```
overleaf-comment: posting as Overleaf account: marek@example.com
plan: 5 items
summary: 3 ok / 1 fail / 1 skip (5 total)
overleaf-comment: residual plan written to plan.residual.json (1 failed + 1 skipped)
```

**Exit codes:**

- `0` — all items succeeded
- `1` — at least one item failed or was skipped
- `2` — usage / validation error (missing arg, invalid plan JSON, missing dependency)
- `75` — `EX_TEMPFAIL`: an "Out of sync" or background-tab condition was detected; re-run after the editor / focus settles

**Residual plan** — when any item failed or was skipped, the wrapper writes `<plan>.residual.json` next to the original plan, containing only those items. To retry just the failures: `overleaf-comment <target> plan.residual.json`.

## Failure handling

- **Pre-flight "Out of sync" modal**: wrapper clicks **Reload editor** and exits 75 before posting anything. Re-run after the page settles.
- **Background-tab throttling**: Chrome aggressively throttles `setTimeout` on hidden tabs, which would cause every poll to time out. The wrapper calls `Page.bringToFront` and exits 75 if the tab still reports `document.hidden=true`.
- **Identity preflight**: the wrapper prints the active Overleaf account on stderr before posting (best effort — Overleaf may not expose it in any of the known signals, in which case `<unknown>` is printed). Verify before letting a long plan run.
- **Per-item polling**: each `post()` polls for the Add-comment button to be enabled, the textarea to appear, and the Submit button to enable. Each `cdp eval` runs comfortably under chrome-cdp's 15 s ceiling.
- **Mid-run "Out of sync"**: each `post()` checks for the modal at entry and returns `RELOADED:` if it had to click **Reload editor**. The wrapper then aborts with exit 75 and writes a residual plan covering everything that didn't post.
- **Stale comment dialog**: if a post fails before submit, the wrapper clicks Cancel (scoped to the review panel) so the next iteration starts clean. After submit, Cancel is **not** clicked — the comment may have landed server-side; the FAIL message says so.
- **Stale file view**: `openFile()` snapshots the current document and only returns OK once the document content has actually changed AND the tree item is marked active.
- **Add-comment unavailable diagnosis**: when the button can't be found, the helper distinguishes between (a) comments not exposed at all on this project — likely free-tier / viewer-only / archived; (b) button present but disabled — selection cleared or non-comment-capable mode; (c) UI in a non-English locale. The exact cause is named in the FAIL string.

## Throughput

Each post takes ~2.5–4 s in the browser (Add-comment button enable, textarea appear, submit, textarea remove). Each `cdp eval` adds another ~0.5 s of round-trip overhead. Plan on **~3–5 s per comment** for a typical run.

A 38-comment plan completes in ~3 minutes; a single mid-run reload costs ~10 s plus the re-run trim time.

## Architecture

- The wrapper injects `page-helpers.js` once, then iterates plan items in bash, doing **one `cdp eval` per item**. Each eval finishes well under chrome-cdp's 15 s `Runtime.evaluate` ceiling, and per-item results stream to stdout as they happen.
- Comments use Overleaf's standard "Add comment" affordance: select the line in the underlying CodeMirror 6 view (`view.dispatch({selection: ...})`), click `button[aria-label="Add comment"]`, fill `textarea.review-panel-add-comment-textarea` via the native value setter, and click Submit.
- File-tree clicking matches `[role="treeitem"]` whose inner `.item-name` equals the requested basename (or path-suffix-with-separator-boundary when the plan supplies a path).

## Limitations

- **Replies / threading**: not supported — every entry creates a new top-level comment thread.
- **Multi-line range selection**: the comment is always anchored to the entire single line.
- **One browser, one user**: posts under whichever account the tab is logged in as. The wrapper prints the active account on stderr before posting; if it shows `<unknown>` (Overleaf didn't expose it in any of the known signals), verify the tab manually before running.
- **English UI required**: the helpers match the strings "Add comment", "Comment", "Cancel", "Reload editor". The wrapper warns when the UI language is anything else.
- **Don't interact during a run**: clicking or typing in the editor while the wrapper is active will be overwritten by the next selection dispatch and may insert text that Overleaf autosaves before the wrapper notices.
- **Multi-tab matches**: if `--url` resolves to more than one tab of the same project (duplicates are common), the wrapper fails with the list of prefixes and asks you to pass one explicitly.
- **Self-hosted Overleaf**: set `OVERLEAF_HOSTS=overleaf.example.com` (space-separated for multiple hosts) so `--list` recognises it. `--url` is host-agnostic and works without the env var.
- **Forced reload mid-run**: when detected, the wrapper aborts with exit 75 and writes a residual plan; re-run with `<plan>.residual.json`.
- **Selectors**: pegged to Overleaf's current React UI (review panel, file tree, CodeMirror 6). UI redesigns may break the helpers; the failure mode is `FAIL: ...` per item with no false-positive OKs.
