# review-anvil — Design

**Date:** 2026-04-30
**Status:** Approved (brainstorm)
**Next step:** writing-plans

## Goal

Wrap a recurring user pattern — *"let's do three rounds of fix/review with
codex-exec and claude-exec"* — into a reusable skill. The pattern is an
**iterative review-driven refinement loop**: parallel subagent reviewers find
issues, the orchestrator synthesizes their findings and applies fixes (with
logically-separated commits), then the next round reviews the new state.

The skill exposes this as a single configurable invocation with sensible
defaults, so it can be triggered with phrases like "let's do three rounds" or
explicitly with parameters.

## Pattern observed

Reconstructed from ~15 instances across the user's transcripts:

- **Loop shape:** round = (parallel review by N subagents) → (orchestrator
  synthesizes findings) → (orchestrator makes fixes, commits) → next round.
- **Reviewers:** mix of `codex-exec` and `claude-exec`. Counts in transcripts
  vary ("2 codex + 2 claude", "3 rounds with codex", "two codex-exec subagents").
- **Focus areas:** every prompt names the same four — *correctness,
  maintainability, simplicity, things that could blow up in production*. Often
  plus "refactor right away."
- **Output discipline:** "logically separated commits" — fixes per round get
  their own commits.
- **Stance:** "be very critical."

## Design decisions

| # | Question | Decision |
|---|---|---|
| 1 | What does `agents` mean? | Single number, single tool by default, plain-English overrides parsed by the skill (e.g. `"2 codex + 1 claude"`). |
| 2 | What's the review target? | Auto-detect with override (PR if checked out → branch-vs-main diff → uncommitted changes; explicit `target=` overrides). |
| 3 | Who applies fixes? | Orchestrator (main session) only. Subagents are read-only critics. |
| 4 | Stop criteria? | Run requested `rounds`, stop early on productive-loop convergence, and allow bounded adaptive continuation up to `max_rounds` (default 6 for `per_fix`) when material findings keep appearing. |
| 5 | `focus` semantics? | User-supplied focus is *appended* to the four-pillar default. `only:` prefix replaces. |
| 6 | Two-phase (design + code)? | Out of scope for v1. Single-phase fix/review only. The `focus` parameter is flexible enough to retarget the loop at non-code artifacts (e.g., a design doc) when the user wants. |
| 7 | Commit cadence? | One commit per logical fix-group within a round. No knob in v1. |
| 8 | Default agent mix? | Mixed by default. See policy below. |
| 9 | Reviewers propose patches? | No — prose findings only with `suggested_fix` descriptions. Orchestrator does all editing. |

## Skill identity

- **Name:** `review-anvil`
- **Plugin location:** `plugins/review-anvil/skills/review-anvil/SKILL.md`
- **Invocation:**
  - **Auto-trigger** when the user says phrases like "let's do three rounds",
    "fix/review loop", "back-and-forth review", "iterative review", "rounds of
    review with codex/claude".
  - **Explicit:** `Skill review-anvil` with a free-form args string parsed in
    plain English.

The skill is prose-only — no scripts/binaries. It instructs the orchestrating
Claude session how to dispatch subagents, synthesize findings, apply fixes,
and report.

## Parameters

| Param | Default | Notes |
|---|---|---|
| `rounds` | `3` | Integer ≥1. Requested round count; productive loops may stop early on convergence or continue adaptively up to `max_rounds`. |
| `max_rounds` | `6` for productive loops | Hard cap for adaptive continuation; exact/no-extra phrasing collapses it to `rounds`. |
| `agents` | `3` | Total reviewers per round. Plain-English mix override (`"2 codex + 1 claude"`, `"three claude reviewers"`). |
| `focus` | the four pillars (correctness, maintainability, simplicity, production blast-radius) | User input is appended. `only:` prefix replaces. |
| `target` | auto-detect | PR if checked out → branch-vs-main diff → uncommitted changes. Override: `pr:123`, `branch`, `uncommitted`, `path:src/foo.py`, `commits:HEAD~3..HEAD`. |
| `commit_style` | per-logical-fix | Hardcoded in v1. |

### Default mix policy

When the user doesn't specify a mix, the skill picks based on `agents`:

| `agents` | Mix |
|---|---|
| 1 | 1 codex-exec |
| 2 | 1 codex + 1 claude |
| 3 | 2 codex + 1 claude |
| 4 | 2 codex + 2 claude |
| N | ~60/40 codex/claude split, codex gets the odd one |

### Example invocations

- `Skill review-anvil` → 3 rounds, default mix (2 codex + 1 claude), default
  focus, auto-detected target.
- `Skill review-anvil "5 rounds, 2 codex + 1 claude, focus: async correctness, target: PR #42"`
- `Skill review-anvil "1 round, only: security, target: src/auth/"`

## Loop mechanics

Each round runs this sequence:

1. **Snapshot target.** Capture the current diff/branch/PR state at round
   start so all reviewers see the same thing.

2. **Dispatch reviewers in parallel.** Single message with M `Agent` calls
   (one per reviewer in the mix), invoking the relevant skill (`codex-exec`
   or `claude-exec`). Each gets the context+task prompt below.

3. **Synthesize.** Merge findings:
   - Dedup overlapping issues across reviewers.
   - Group by severity, then by topic.
   - Drop items already addressed in this round's earlier fixes (defensive).

4. **Apply fixes.** Orchestrator makes edits. **One commit per logical
   fix-group**, conventional-commit style. Items judged noise are skipped
   and reported as "deferred" with a reason.

5. **Round summary.** Short markdown block: agents dispatched, findings
   count by severity, fixes applied (with commit SHAs), deferred items
   with reasons, **convergence flag** (`clean`, `nits_only`,
   `material_findings`).

6. **Continue** until requested `rounds` are reached, convergence stops the
   productive loop, or adaptive continuation reaches `max_rounds`. Final report
   includes per-round summaries and a top-level digest.

**Failure handling:** if a reviewer fails or returns malformed output, log
in the round summary and continue with the others. No retries — a failed
agent in round N just means round N has fewer reviewers.

**Concurrency:** parallel within a round (single multi-tool-call message),
strictly sequential between rounds (round N+1 needs round N's commits).

## Reviewer prompt template

Each subagent receives a self-contained prompt with:

**Context block** (orchestrator fills in):
- Target description (e.g. "PR #42", "diff between `main` and
  `feature/auth-rewrite`", "uncommitted changes in `src/auth/`").
- Round number ("round 2 of 3").
- Prior-round summary (1 line per prior round listing issues addressed,
  commits, deferred items). Lets the reviewer skip already-addressed
  issues.
- Focus list (default four pillars + user additions, or `only:` override).

**Task block** (fixed boilerplate):
- "Review the target. Be very critical. Surface issues across the focus
  areas."
- Severity guide:
  - `critical` — data loss, security, production crash.
  - `high` — correctness or major maintainability.
  - `medium` — should fix but not blocking.
  - `low` — style / minor.
  - `nit` — preference.
- "Don't repeat issues already addressed in prior rounds (see summary)."
- Output schema: structured findings, each with
  `{severity, area, what, why, suggested_fix}`. **Prose only** for
  `suggested_fix` — do not include patches.

**Output format:** markdown report ending with a parseable findings block
(fenced ` ```findings ` YAML or one item per heading with bold severity
tag). If parse fails, orchestrator falls back to using the prose as-is and
labels the agent's output "unstructured findings."

## Final output

Single markdown report at end of run:

```
# ⚒️ review-anvil report

**Target:** PR #42 (feature/auth-rewrite, 12 files, +340/-89)
**Rounds:** 3
**Mix per round:** 2 codex-exec + 1 claude-exec
**Focus:** correctness, maintainability, simplicity, prod blast-radius

## Round 1 — material_findings (4 critical, 6 high, 3 medium, 5 nit)
- Fixes applied: 7 commits (a1b2c3d..7e8f9a0)
- Deferred: 2 items (see below)

## Round 2 — material_findings (1 high, 4 medium, 2 nit)
- Fixes applied: 3 commits

## Round 3 — nits_only ✓
- No critical/high/medium findings
- 2 nit-level items not addressed (style preferences)

## Total
- 10 commits across rounds
- 19 findings addressed, 4 deferred (with reasons below)
- Suggestion: round 3 was clean — `rounds=2` likely sufficient next time

## Deferred items
…
```

During execution: one-line status per round (`Round 2/3: dispatching 3
reviewers...`).

## File layout

```
plugins/review-anvil/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── review-anvil/
        └── SKILL.md
```

`SKILL.md` sections:
- YAML frontmatter (name, description with trigger phrases).
- **How to use** — parameters table, plain-English parsing rules.
- **Default mix policy.**
- **Loop mechanics** — the 6-step round procedure.
- **Reviewer prompt template** — context + task blocks.
- **Output format** — final-report shape and per-round status format.
- **Edge cases** — failure handling, target detection rules.

## Out of scope (v1)

- **Two-phase variant** (design-critique + fix/review). The `focus` and
  `target` parameters can retarget the loop at non-code artifacts when
  needed; a separate phase is not required.
- **Reviewer-applied patches.** Reviewers stay read-only.
- **Early stopping / adaptive continuation.** Included in the current engine:
  productive loops stop on convergence and may continue up to `max_rounds`.
- **Per-fix vs per-round commit knob.** Hardcoded to per-logical-fix.
- **A "judge" / synthesis subagent.** The orchestrator synthesizes directly.

These can be revisited if usage warrants.
