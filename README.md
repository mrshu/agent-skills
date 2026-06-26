# agent-skills

A Claude Code plugin marketplace with useful skills for AI agents.

## Installation

First, add the marketplace:
```bash
/plugin marketplace add mrshu/agent-skills
```

Then install plugins:
```bash
/plugin install scholar-search
/plugin install wshot
/plugin install paper-siphon
/plugin install codex-exec
/plugin install claude-exec
/plugin install review-anvil
/plugin install overleaf-comment
/plugin install overleaf-compile
/plugin install gdocs-comment
```

## Plugins

### scholar-search

Find academic papers, explore citations, and export BibTeX. Uses four tools under the hood:

- **s2cli** (Semantic Scholar) — paper recommendations, citation/reference networks, arXiv/DOI lookups
- **openalexcli** (OpenAlex) — broadest coverage (260M+ works), institution/journal queries, aggregation
- **arxivy** (arXiv) — direct arXiv search, paper lookup by ID, browse recent submissions by category
- **dblpcli** (DBLP) — high-quality, curated BibTeX export

All tools run via `uvx` — no installation needed.

### paper-siphon

Convert academic PDFs to clean Markdown. Supports local files and remote URLs (e.g. arXiv). Three extraction modes:

- **Default** — fast Docling-based extraction, handles most papers
- **VLM** (`--vlm`) — vision-language model for complex layouts and scans
- **Formula enrichment** (`--enrich-formula`) — better LaTeX fidelity for math-heavy papers

Runs via `uvx` — no installation needed.

### codex-exec

Delegate code review, plan review, and deep exploration tasks to **Codex CLI** from Claude Code. Use it as a pre-push quality gate, plan counter-review, or deep-dig exploration tool. Key commands:

- `codex review --base main` — review current branch against main
- `codex review --uncommitted` — review work-in-progress changes
- `codex exec '<prompt>'` — custom prompted review, plan critique, or codebase exploration

### claude-exec

Delegate code review, plan review, and deep exploration tasks to **Claude Code CLI** from Codex or other agents. The mirror of codex-exec — lets non-Claude agents get an independent second opinion. Key commands:

- `claude -p '<prompt>'` — non-interactive review or exploration
- `claude -p --permission-mode dontAsk --tools "Bash,Read,Glob,Grep" ...`
  — scripted review with an explicit built-in tool set
- See `plugins/claude-exec/skills/claude-exec/SKILL.md` for the full
  fallback recipe, including `--allowedTools`, stdin prompts, and watchdog use.

### review-anvil

`review-anvil` turns a code review into a repeatable loop: `codex-exec`
and `claude-exec` reviewers inspect the same snapshot, their findings are
merged into one report, uncertain claims are checked against the code, and the
loop either reports, commits fixes, or updates a PR.

It is built for the messy middle after a first implementation, when you want
several independent review passes, fewer bogus findings, and fixes that are
checked before they land.

| I want to... | Use | Edits code | Commits | Pushes | Posts to PR | Can approve |
|---|---|---:|---:|---:|---:|---:|
| Harden local changes with fix commits | `review-anvil` | Yes | Yes | No | No | No |
| Review without touching files | `review-anvil-readonly` | No | No | No | No | No |
| Review a PR and post findings | `review-anvil-pr` | No | No | No | Yes | Yes, unless disabled |
| Improve a checked-out PR branch | `review-anvil-improve-pr` | Yes | Yes | Yes | Yes | No |

What makes it useful:

- **Parallel review:** Codex and Claude reviewers inspect the same snapshot with
  different lenses, then the workflow merges overlapping findings.
- **Claim checking:** single-reviewer material findings, risky deletions, and
  uncertain claims are checked before they become comments or fix commits.
- **Verified fixes:** fixing runs use the project's test/build command when
  available and should not leave the branch newly red.
- **Adaptive rounds:** fixing runs can stop early when the review converges,
  or continue up to 6 total rounds when useful fixes are still surfacing. Use
  "exactly 3 rounds" or `max_rounds: 3` when you want a hard stop.
- **PR-native output:** anchored findings become inline review comments; broader
  findings stay in one compact summary.
- **PR repair flow:** `review-anvil-improve-pr` can announce a run, commit and
  push verified fixes to a checked-out PR branch, then update the same PR comment
  with the result.
- **Approval control:** `review-anvil-pr` can submit a real GitHub approval when
  review-only checks pass. Use `approve: never` or "comment only" when
  approval should stay human.
- **Simplicity lens:** the default focus includes a minimization ladder (need it
  at all? → stdlib → native feature → existing dependency → one line → the
  minimum that works), adapted from [ponytail](https://github.com/DietrichGebert/ponytail).

The plugin ships four cross-agent skills under `plugins/review-anvil/skills/`.
Anything that supports `Skill <name>` (Claude Code, Codex CLI, Cursor, OpenCode,
Continue, Cline, Gemini CLI, …) can activate them by description match. In
Claude Code, you can also invoke directly as `Skill review-anvil "<free-form
args>"`; see `skills/review-anvil/SKILL.md` for the full behavior and advanced
controls (`rounds`, `max_rounds`, `agents`, `focus`, `target`, `verify_cmd`,
`reproduction`, `adversarial`, `approve`, `report_path`, and more).

### overleaf-comment

Bulk-post Overleaf comments from a JSON plan. Drives the user's already-logged-in browser tab via Chrome DevTools Protocol, so no API keys / no test accounts. Break-even is around 5 comments — under that, type them by hand.

- `overleaf-comment --list` — show open Overleaf project tabs
- `overleaf-comment <target> plan.json` — post the plan against a tab prefix from `--list`
- `overleaf-comment --url https://www.overleaf.com/project/<id> plan.json` — auto-resolve the tab from the project URL

Plan items are `{file, line, text}`. Failed/skipped items are written to `<plan>.residual.json` so a retry is one command.

**Requirements:**
- A `chrome-cdp` skill installation (auto-discovered or via `$CDP_BIN`)
- Brave / Chrome / Chromium running with `--remote-debugging-port=9222`
- The Overleaf project tab open and logged in, with commenting permission

### overleaf-compile

Recompile an Overleaf project and extract its build logs/errors/warnings in a standardized format — closing a push → compile → debug loop. API-first: calls Overleaf's internal compile endpoint from inside the logged-in tab and fetches the raw `output.log` / `output.blg`, so the diagnostics are complete (not the truncated logs pane).

- `overleaf-compile --list` — show open Overleaf project tabs
- `overleaf-compile <target>` — recompile and emit standardized JSON logs
- `overleaf-compile --url https://www.overleaf.com/project/<id>` — auto-resolve the tab
- `overleaf-compile <target> --errors-only --format compiler` — fast human-readable triage

Entries are `{level, file, line, message, source, count}` with `level ∈ error|warning|typesetting|info|bib-*`. Note that Overleaf's `status: "success"` only means *a PDF was produced* — the exit code (and parsed `errors` count) is the real verdict. `--clear-cache` recompiles from scratch; `--out-dir` saves the raw artifacts; `--no-recompile` reads the on-screen logs pane without compiling.

**Requirements:**
- A `chrome-cdp` skill installation (auto-discovered or via `$CDP_BIN`)
- Brave / Chrome / Chromium running with `--remote-debugging-port=9222`
- The Overleaf project tab open and logged in
- `python3` on PATH (log parsing)

### gdocs-comment

Bulk-post anchored Google Docs comments (with `@-mentions`) from a JSON plan. Drives the user's already-logged-in browser tab via Chrome DevTools Protocol — no Drive API keys, no OAuth dance. Break-even is around 5 comments — under that, type them by hand.

- `gdocs-comment --list` — show open Google Docs tabs
- `gdocs-comment <target> plan.json` — post the plan against a tab prefix from `--list`
- `gdocs-comment --url https://docs.google.com/document/d/<id>/edit plan.json` — auto-resolve the tab from the document URL
- `gdocs-comment --dry-run plan.json` — validate the plan without posting

Plan items are `{anchor, text, mentions?}` — `anchor` is a substring of the doc body, and the comment is anchored to the first match. Failed items are written to `<plan>.residual.json` for one-command retry.

**Requirements:**
- A `chrome-cdp` skill installation (auto-discovered or via `$CDP_BIN`)
- Chrome / Brave / Edge with remote debugging enabled
- The Google Doc tab open and logged in, with comment permission
- Node.js 22+

### wshot

Screenshot tool for Wayland/GNOME. Capture windows by app name, PID, title, or window ID.

**Requirements:**
- GNOME with Wayland
- `window-calls` extension (auto-prompted if missing)

## License

MIT
