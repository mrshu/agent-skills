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

- `Skill review-anvil` — run with all defaults against auto-detected target
- `Skill review-anvil "5 rounds, 2 codex + 1 claude, focus: async correctness, target: PR #42"` — fully specified
- `Skill review-anvil "1 round, only: security, target: src/auth/"` — narrow focus, single pass

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
