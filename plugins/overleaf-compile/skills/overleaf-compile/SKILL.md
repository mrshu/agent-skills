---
name: overleaf-compile
description: Recompile an Overleaf project and extract its build logs, errors and warnings in a standardized format. Use when asked to compile/recompile an Overleaf paper, debug why a PDF build fails, see what's broken after pushing changes, or pull LaTeX/biber errors and warnings out of an Overleaf project. Drives an already-logged-in browser tab via the chrome-cdp skill.
---

# Overleaf compile + log extractor

Recompile an Overleaf project and pull its build diagnostics out in a
standardized format, closing a publish → compile → debug loop. Uses the user's
already-logged-in browser session via the [`chrome-cdp`](../../chrome-cdp)
skill.

Mechanism is **API-first**: the page helper calls Overleaf's internal
`POST /project/:id/compile` from inside the tab (which holds the session
cookie + `ol-csrfToken`), then fetches the build's raw `output.log` /
`output.blg`. The rendered logs pane is scraped only as a `--no-recompile`
fallback.

## Prerequisites

1. **`chrome-cdp` skill** installed; the wrapper auto-discovers `cdp.mjs` (or set `$CDP_BIN`).
2. **Chrome / Brave** running with `--remote-debugging-port=9222`.
3. **Overleaf project tab open** in that browser, **logged in**.
4. `python3` on PATH (used for log parsing).

## Usage

```bash
# find the project tab
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-compile/overleaf-compile --list

# recompile + standardized JSON logs (target prefix from `cdp list`)
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-compile/overleaf-compile 60D065AD

# or address the tab by project URL
${CLAUDE_PLUGIN_ROOT}/skills/overleaf-compile/overleaf-compile --url https://www.overleaf.com/project/<id>

# fast triage: just the errors, human-readable
overleaf-compile 60D065AD --errors-only --format compiler

# recompile from scratch and keep the raw artifacts
overleaf-compile 60D065AD --clear-cache --out-dir ./build-logs
```

Run `overleaf-compile --help` for the full flag list (`--format`,
`--errors-only`, `--info`, `--no-dedup`, `--raw-tail N`, `--clear-cache`,
`--draft`, `--stop-on-first-error`, `--no-recompile`, `--out-dir`,
`--timeout`). For self-hosted Overleaf set `OVERLEAF_HOSTS="overleaf.example.com"`.

## Output

Default is JSON: a `compile` summary plus normalized `entries`.

```json
{
  "compile": {"status": "success", "pages": 24, "errors": 30, "warnings": 6,
              "typesetting": 156, "info": 0, "bib": 2, "buildId": "…"},
  "entries": [
    {"level": "error", "file": "acl_latex.tex", "line": 835,
     "message": "Undefined control sequence (\\blacktriangle)",
     "source": "output.log", "count": 1}
  ]
}
```

- `level` ∈ `error | warning | typesetting | info | bib-error | bib-warning`.
- Identical entries are collapsed with a `count` (`--no-dedup` to keep all).
- `Package…/Font…Info:` chatter is dropped unless `--info`.
- `--format compiler` renders `file:line: level: message [xN]` lines + a summary.

**`status` is not a verdict.** Overleaf returns `status: "success"` whenever a
PDF was produced — *including* runs with dozens of `Undefined control
sequence` errors. Read the parsed `errors` count, not `status`. The wrapper's
**exit code** reflects this: `0` = no errors, `1` = ≥1 error (LaTeX or bib),
`2` = usage, `75` = `EX_TEMPFAIL` (compile timed out / transport issue).

## Limitations

- Pegged to Overleaf's current SaaS compile API + React UI; the internal
  endpoint shape and DOM selectors are gathered at the top of `page-helpers.js`
  for easy re-targeting if Overleaf changes them.
- The LaTeX log parser is conservative: line numbers are exact; `file`
  attribution is best-effort (it falls back to the compile root when pdfTeX's
  paren nesting drains on stray content parens).
- `--no-recompile` reads the on-screen logs pane (no compile) — lossy
  (Overleaf truncates messages, only the last UI compile is present). Prefer a
  real compile for full-fidelity logs.
- English UI assumed for the `--no-recompile` DOM path.
- Compiles under whichever account the tab is logged in as.

## Publishing / sync assumption

This compiles whatever source **Overleaf currently holds**. If you publish by
pushing to Overleaf's own git remote, the project is already up to date and no
sync step is needed — push, then run this. GitHub-mirror projects that need a
manual *pull* inside Overleaf are out of scope (sync is not triggered here).
