---
name: overleaf-comment
description: Bulk-post Overleaf comments from a JSON plan. Use when asked to add many Overleaf comments at once (e.g. thesis review, paper feedback, multi-line annotations). Drives an existing logged-in browser tab via the chrome-cdp skill.
---

# Overleaf bulk comment poster

Post N Overleaf comments from a JSON plan, one CDP eval per item. Uses the user's already-logged-in browser session via the [`chrome-cdp`](../../chrome-cdp) skill.

Break-even is around 5 comments — for fewer, type them directly in Overleaf.

## Prerequisites

1. **`chrome-cdp` skill** installed; the wrapper auto-discovers `cdp.mjs` (or set `$CDP_BIN`).
2. **Brave / Chrome** running with `--remote-debugging-port=9222`.
3. **Overleaf project tab open** in that browser, **logged in**, with **commenting permission**.

## Usage

```bash
# 1. find the project tab
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-comment/overleaf-comment --list

# 2. post a plan (target prefix from `cdp list`)
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-comment/overleaf-comment 6172EEAA plan.json

# or supply the project URL — the wrapper picks the matching tab
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-comment/overleaf-comment --url https://www.overleaf.com/project/<id> plan.json
```

For self-hosted Overleaf set `OVERLEAF_HOSTS="overleaf.example.com"` (space-separated for multiple).

## Plan format

A JSON array of `{file, line, text}`:

```json
[
  {"file": "main.tex",                 "line": 8,   "text": "linespread should be 1.5"},
  {"file": "parts/200-discussion.tex", "line": 108, "text": "ungrammatical"}
]
```

- `file` matches Overleaf's file tree by **basename** (or path-suffix when the plan supplies `/`).
- `line` is **1-indexed**. Blank lines cannot be commented on.
- `text` is the comment body; multi-line is fine via `\n` in the JSON string.

## Output

Per-item results stream to stdout:

```
[main.tex] OK: main.tex (155 lines)
  L8: OK: line 8
  L109: FAIL: line 109 is blank — Overleaf cannot anchor a comment
```

A summary, identity preflight, and any FAIL diagnostics go to stderr.

**Exit codes:** `0` = all OK · `1` = at least one FAIL/SKIP · `2` = usage / validation · `75` = `EX_TEMPFAIL` (background tab, "Out of sync" modal — re-run after fixing).

**Residual plan:** if any items failed or were skipped, the wrapper writes `<plan>.residual.json` containing just those items. Retry with `overleaf-comment <target> <plan>.residual.json`.

## Limitations

- One top-level thread per entry — no replies / threading.
- Single-line anchor only (no multi-line range).
- English UI required; non-English locales surface a warning at preflight.
- Pegged to Overleaf's current React UI; selectors and strings are gathered at the top of `page-helpers.js` for easy re-targeting on a redesign.
- Posts under whichever account the tab is logged in as; the wrapper prints `posting as Overleaf account: <email>` before running so you can verify.
- Don't type or click in the Overleaf editor while a run is in progress.
