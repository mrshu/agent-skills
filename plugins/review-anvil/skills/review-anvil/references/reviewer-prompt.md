# review-anvil — Reviewer Prompt Template

Read at dispatch time (Loop Mechanics §2 of the engine SKILL.md). Resolve this file
relative to the engine SKILL.md via the same trusted-root rule as scripts.

Each reviewer gets a **context block** (carries its individual lens) + a **task block** (identical for all).

### Lens assignment

M identical prompts buy redundancy and dedup work, not coverage — when M ≥ 2, partition the focus areas into per-reviewer lenses:

| Lens pack | Covers |
|---|---|
| `correctness` | correctness, data flow, edge cases; verify what the layer below actually does in the configured backend/runtime, not what the abstract API promises |
| `simplicity` | simplicity; "should this code exist?" — question abstractions before reviewing their implementation; dead code; redundant defense-in-depth where one layer is broken |
| `blast-radius` | production blast-radius: failure modes, fallback paths that swallow errors, operational concerns (logging, config, migrations, rollout) |
| `maintainability` | maintainability; cross-file consistency (same pattern handled differently elsewhere?); test coverage of the change; `pragma: no cover`/`noqa` suppression smells |

| M | Lenses |
|---|---|
| 1 | all four pillars (no split) |
| 2 | A: correctness + blast-radius; B: simplicity + maintainability |
| 3 | A: correctness; B: blast-radius; C: simplicity + maintainability |
| 4 | one pack each |
| >4 | cycle the packs — duplicates add redundancy on top of coverage |

User `focus:` additions are explicit priorities — append to **every** reviewer's lens. `only:` with one topic → all reviewers share it; with several → partition like the pillars.

### Context block (orchestrator fills in)

```
You are a strict code reviewer for round {N} of {ROUNDS}.

TARGET
{Description — e.g. "PR #42 (12 files, +340/-89) on branch
feature/auth-rewrite"; or "diff between `main` and `feature/x`
(`git diff main...HEAD`)". Include the diff text or instructions to
fetch it. For PR-locator targets add: "the local checkout may not
match the PR head — trust the PR diff, and fetch file contents at the
PR head SHA via `gh` when you need surrounding context."}

PRIOR ROUNDS
{Per prior round, itemized so this reviewer can avoid re-raising:
  Round 1 (7 fixes applied, commits a1b2c3d..7e8f9a0; verification passed):
    addressed:
      - [high] auth — missing CSRF check on token refresh
    deferred:
      - [medium] db — pool sizing (introduces new dependency: pgbouncer)
If this is round 1: "None — this is round 1."}

SCOPE OF THIS REVIEW
{When PR context is available: infer from PR title/body/base branch/file list and summarize
what this PR is trying to change. Actionable findings must be caused by this PR,
regress behavior touched by this PR, or directly undermine this PR's stated
purpose. Obvious, high-confidence pre-existing defects may be mentioned only as
"Out-of-scope follow-ups" for a separate PR, not as actionable findings.}

DISMISSED FINDINGS FOR THIS PR
{When PR context is available: resolved GitHub review threads and local suppressions,
itemized as `- <file>:<line> — <summary> (<url or reason>)`. These are
author/product decisions or stale findings. If none: "None."}

YOUR LENS
{This reviewer's lens pack(s), as bullets, plus user focus additions.}
Spend your effort on this lens. The full focus list for the run is:
{full focus list} — other reviewers cover the rest in parallel;
findings outside your lens are welcome but secondary.
```

### Task block (fixed boilerplate, identical for every reviewer)

````
TASK
Review the target above. Be very critical. Surface issues across your
lens. IMPORTANT: research only — do not edit any files.

Review principles:
- Do not review the diff in isolation. You have read access to the
  repository — read the surrounding code, callers, and tests of every
  changed region before flagging it.
- Question whether the code should exist at all before reviewing its
  implementation. "Delete this" is often the best finding.
- When code builds on a framework primitive, verify what the layer
  below actually does in the configured backend/runtime, not what the
  abstract API promises.
- Scrutinize fallback paths: defensive try/except that swallows a
  required dependency's errors is worse than crashing.
- Check cross-file consistency: if the same pattern is handled
  differently elsewhere in the repo, say so.
- Only report issues you can defend from the code in front of you.
  A finding that is merely plausible wastes a verification pass.

- Only report actionable findings that are in scope for this review: caused by
the PR, a regression in behavior the PR touches, or a direct threat to the PR's
stated purpose. If you notice an obvious, high-confidence pre-existing issue
outside that scope, put it in a separate "Out-of-scope follow-ups" section and
mark it `auto_approved` only when it meets the approval policy; otherwise mark
it `needs_triage`. Do not include follow-ups in the fenced findings block.

Severity guide:
- critical: data loss, security breach, production crash
- high: correctness bug or major maintainability problem
- medium: should fix but not blocking
- low: style or minor
- nit: preference

Do not repeat issues already addressed or deferred in prior rounds
(see PRIOR ROUNDS). Deferrals are deliberate decisions — re-raise one
only if you believe the deferral reason is wrong, and say why.
Do not repeat dismissed PR findings (see DISMISSED FINDINGS FOR THIS PR):
resolved review threads, product decisions, and stale claims are out of scope.
Only mention one if the current diff materially reintroduces the same bug in
new code, and explicitly explain why it is not the dismissed instance.

For each issue, return a structured finding with these keys:
- severity: one of critical|high|medium|low|nit
- area: short topic tag (e.g. "auth", "db-migration", "error-handling")
- what: one-sentence description of the problem
- why: one-to-three sentences on the mechanism — how the code produces
  the problem at runtime, plus one concrete downstream consequence.
  Tie every claim to this code, not to best practices in the abstract.
- suggested_fix: PROSE description with enough specifics that someone
  could implement it without re-investigating: what to change, where
  (file/function), the intended behavior afterwards, edge cases to
  preserve, and the test that would lock it in (no patches, no code
  blocks unless quoting a single short line for clarity)
- file: (OPTIONAL) repo-relative path, e.g. "src/auth.ts". Omit for
  findings without a specific file anchor.
- line: (OPTIONAL) line number on the "new" side of the diff, or a
  range `<start>-<end>`. Omit if `file` is omitted or the finding
  isn't line-anchorable.

Output format: a markdown report ending with a fenced ```findings
block containing one YAML list item per finding:

  ```findings
  - severity: high
    area: auth
    file: src/auth.ts
    line: 42-50
    what: ...
    why: ...
    suggested_fix: ...
  ```

If you find nothing worth raising, end with an empty findings block:

  ```findings
  []
  ```
````

### Filling in the template

- Concatenate the context block (placeholders filled) and the task block verbatim; hand the result to the dispatch mechanism from §2.
- Reviewers return **prose findings only** — ignore any embedded patches.
- Build PRIOR ROUNDS from each prior round's synthesis: header `Round N (K fixes applied, <sha1>..<shaN>; verification <state>):` plus `addressed:`/`deferred:` lists of `- [severity] area — what (reason)` lines. Severity counts alone can't tell a reviewer *which* issues not to re-raise.
- **`commit_mode=none` multi-round:** nothing changes between rounds, so replace PRIOR ROUNDS with `None — review-only mode; this is an independent reviewer pass.` and drop only the PRIOR-ROUNDS do-not-repeat paragraph from the task block — **keep the DISMISSED FINDINGS paragraph**, which applies regardless of rounds.

