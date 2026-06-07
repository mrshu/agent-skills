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
- `claude -p --permission-mode plan '<prompt>'` — read-only safe review mode

### review-anvil

Iterative multi-agent review-and-fix loop. Wraps the *"let's do three rounds of fix/review"* pattern: dispatch parallel `codex-exec` and `claude-exec` reviewers, synthesize their findings, apply fixes with logically-separated commits, and repeat. Defaults to 3 rounds × 3 reviewers (2 codex + 1 claude). Configurable rounds, agent count/mix, focus, and target.

The plugin ships **four cross-agent skills** under `plugins/review-anvil/skills/`:

- **`review-anvil`** — the engine. The actual review loop with the full parameter surface (`rounds`, `agents`, `focus`, `target`, `min_fix_severity`, `allow_new_deps`, `commit_mode`, `report_path`). The default mode is fix-and-commit (`commit_mode=per_fix`).
- **`review-anvil-readonly`** — preset. Read-only review pass: activates the engine with `commit_mode=none` and a default of `rounds=1`. No edits, no commits.
- **`review-anvil-pr`** — preset. **Read-only** review of a GitHub PR (github.com or GitHub Enterprise) with **hybrid posting**: findings with a `file`+`line` anchor become inline review comments threaded next to the code; findings without anchors (architectural / overview) roll into a top-level summary body. The whole thing submits as one PR review (one timeline event). Falls back to a top-level comment if no findings are anchored or if GitHub rejects the inline payload (e.g. reviewer-supplied line numbers outside the diff). Pairs the engine in read-only mode with `scripts/pr-helper.sh` for locator parsing, `gh` preflight, and posting. Auto-detects the PR from the current branch when no locator is passed. Requires `gh` and `jq` on PATH.
- **`review-anvil-improve-pr`** — preset. **Productive** PR loop with a "narrate then update" UX: (1) post a top-level "starting" PR comment cc'ing the original author (notifying them what's about to happen), (2) review + apply fix commits across N rounds, (3) `git push` back to the PR, (4) PATCH-edit the starting comment in-place with the synthesized report (success) or a failure summary (any failure). One comment in the PR timeline, two states, one notification. Reuses `pr-helper.sh` with `verify-checkout` / `post-start` / `post-update` subcommands. Targets the local branch directly (`<base>...HEAD`) to bypass the engine's "PR-target / per_fix incompatibility" rule. Auto-detects PR from current branch when no locator is passed. Requires `gh` on PATH; you must be on the PR's branch with a clean worktree.

Four skills (not four slash commands) because skills are the cross-agent abstraction — anything that supports `Skill <name>` (Claude Code, Codex CLI, Cursor, OpenCode, Continue, Cline, Gemini CLI, …) can activate any of these by description match. The `npx skills add mrshu/agent-skills --all` install carries all four SKILL.mds and the shared helper script under `review-anvil-pr/scripts/`. Multi-forge support (GitLab MR, Gitea PR, …) is a v2 concern.

In Claude Code, you can also invoke directly as `Skill review-anvil "<free-form args>"` — see `skills/review-anvil/SKILL.md` for the full parameter surface.

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
