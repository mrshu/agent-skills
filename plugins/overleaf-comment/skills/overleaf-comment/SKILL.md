---
name: overleaf-comment
description: Bulk-post Overleaf comments from a JSON plan. Use when asked to add many Overleaf comments at once (e.g. thesis review, paper feedback, multi-line annotations). Drives an existing logged-in browser tab via the chrome-cdp skill.
---

# Overleaf bulk comment poster

Post N Overleaf comments from a JSON plan in one shot. Works with the user's already-logged-in browser session — no API keys, no scraping, no test-account setup. Uses the [`chrome-cdp`](../../chrome-cdp) skill to drive Brave/Chrome via the DevTools Protocol.

## When to use

- A reviewer wants to leave many comments at specific lines across multiple project files (thesis review, paper feedback, code review on a `.tex` artefact).
- An agent has produced a structured review and wants to land each finding as a native Overleaf comment, not as `\todo{}` markers in the source.

**Don't use this** for one-off comments — typing in Overleaf directly is faster. The break-even is around ~5 comments.

## Prerequisites

1. **`chrome-cdp` skill** installed and working (the script auto-discovers `cdp.mjs` in `~/.claude/skills/`, `~/.claude/plugins/*/skills/`, sibling-skill paths, or via `$CDP_BIN`).
2. **Brave / Chrome / Chromium** running with `--remote-debugging-port=9222` (see chrome-cdp's prerequisites).
3. **Overleaf project tab open** in that browser, **already logged in**, with **comment-add permissions** (paid plan or shared-as-reviewer).

## Usage

```bash
# 1. find the project tab
overleaf-comment --list

# 2. post a plan (target prefix from `cdp list`)
overleaf-comment 6172EEAA plan.json

# or supply the project URL — script picks the matching tab
overleaf-comment --url https://www.overleaf.com/project/6822076bb010d50556f6917d plan.json
```

## Plan format

A JSON array of `{file, line, text}` objects. The script groups by `file`, opens each file once, then posts all of that file's comments before moving on:

```json
[
  {"file": "main.tex",                      "line": 8,   "text": "linespread should be 1.5 per FMFI template"},
  {"file": "main.tex",                      "line": 55,  "text": "delete the \\mfkonzultant placeholder"},
  {"file": "parts/200-discussion.tex",      "line": 108, "text": "ungrammatical — 'too limited to internalize'"},
  {"file": "parts/200-discussion.tex",      "line": 109, "text": "'augumentaion' typo"}
]
```

- `file` matches by **basename** in Overleaf's file tree (so `parts/foo.tex` and `foo.tex` both work).
- `line` is **1-indexed**, matching Overleaf's editor.
- `text` is the comment body. Multi-line is fine (use `\n` in the JSON string).
- **Blank lines cannot be commented on** — Overleaf needs a non-empty selection. The script skips them with a `FAIL` log.

## Output

One log line per item, e.g.:

```
[main.tex] OK: main.tex (155 lines)
  L8: OK: line 8
  L55: OK: line 55
[parts/200-discussion.tex] OK: parts/200-discussion.tex (110 lines)
  L108: OK: line 108
  L109: FAIL: line 109 is blank — Overleaf cannot anchor a comment
```

## Failure handling

The script auto-recovers from common races:
- **"Submit disabled"** (textarea-state lag) → cancel + retry once.
- **"Out of sync" modal** before a run starts → click `Reload editor`, re-inject helpers.
- **"Out of sync" modal mid-run** → script aborts cleanly with a message; re-run with the remaining items.

If `cdp eval` itself errors (browser closed, Allow-prompt timed out, etc.) the chrome-cdp error surfaces directly.

## Throughput

~1 comment / 1.5–2 seconds after warmup. 38 comments in ~5 min including one modal recovery in our reference run.

## Implementation notes (for the curious)

- All page logic lives in `page-helpers.js` and is injected on each invocation. The bash wrapper is just a CLI parser + plan loader.
- Comments use Overleaf's standard "Add comment" affordance: the script selects the line in the underlying CodeMirror 6 view (`view.dispatch({selection: ...})`), clicks `button[aria-label="Add comment"]`, fills `textarea.review-panel-add-comment-textarea` via the native value setter, and clicks the "Comment" submit button.
- Files are opened by clicking `[role="treeitem"]` whose text ends with the requested basename. Folders are auto-expanded.
- `chrome-cdp`'s daemon caches the per-tab CDP session, so the `cdp eval` call is fast after the first request.

## Limitations

- **Replies / threading**: not supported — every entry creates a new top-level comment thread.
- **Attaching to a range** (multi-line selection): not supported — selection is always the entire line.
- **Tracking which comments succeeded across reloads**: if Overleaf forces a mid-run reload, the script aborts; you must re-run with the remaining items. (A future version could checkpoint to disk.)
- **Free-tier Overleaf**: comments may be disabled. If `add-comment button unavailable` recurs immediately, check the project's permission/plan.
- **One browser, one user**: posts under whichever account the browser is logged in as.
