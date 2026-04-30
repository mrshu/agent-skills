---
name: review-anvil
description: Iteratively refine code via N rounds of parallel subagent review and orchestrator-applied fixes. Use when the user says "let's do three rounds", "fix/review loop", "back-and-forth review", "iterative review", or asks to harden a change with multiple rounds of codex/claude review. Configurable rounds, agent count/mix, focus, and target.
---

# review-anvil — Iterative Multi-Agent Fix/Review Loop

Wrap a code change in **N rounds of parallel reviewer subagents + orchestrator-applied fixes**. Each round = (parallel review by M agents) → (you synthesize findings) → (you apply fixes, commit) → next round.

## How to Use

The user invokes the skill with a free-form args string. Parse it to extract these parameters:

| Param | Default | Plain-English forms |
|---|---|---|
| `rounds` | `3` | "5 rounds", "three rounds", "do 4 passes" |
| `agents` | `3` | "3 agents", "2 reviewers", or a mix like `"2 codex + 1 claude"`, `"three claude reviewers and one codex"` |
| `focus` | the four pillars (correctness, maintainability, simplicity, production blast-radius) | "focus on async correctness", "only: security" (the `only:` prefix replaces defaults instead of appending) |
| `target` | auto-detect | "PR #42", "branch", "uncommitted", "src/auth/", "last 3 commits" |

### Parsing rules

- `agents` may be a single number (use the default mix policy below) **or** a plain-English mix. If a mix is given, honor it exactly. The mix may name `codex`/`codex-exec` or `claude`/`claude-exec`.
- `focus` defaults are *appended* to user input. If the user prefixes their focus with `only:`, replace defaults with their list.
- `target` auto-detection precedence (when not specified):
  1. Currently checked-out PR (run `gh pr view --json number,headRefName 2>/dev/null`); if a PR is found, use its diff.
  2. Else, if the current branch differs from `main`, use the branch-vs-main diff (`git diff main...HEAD`).
  3. Else, use uncommitted changes (`git diff` and `git diff --cached`).
- If the args string is missing or empty, use all defaults.

### Example invocations

- `Skill review-anvil` → 3 rounds, default mix (2 codex + 1 claude), default four-pillar focus, auto-detected target.
- `Skill review-anvil "5 rounds, 2 codex + 1 claude, focus: async correctness, target: PR #42"`
- `Skill review-anvil "1 round, only: security, target: src/auth/"`
- `Skill review-anvil "three rounds, three claude reviewers"` → 3 rounds × 3 claude-exec.

## Default Mix Policy

When the user gives a count but no mix, pick the mix from this table:

| `agents` | Mix |
|---|---|
| 1 | 1 codex-exec |
| 2 | 1 codex-exec + 1 claude-exec |
| 3 | 2 codex-exec + 1 claude-exec |
| 4 | 2 codex-exec + 2 claude-exec |
| 5 | 3 codex-exec + 2 claude-exec |
| N | ~60/40 codex/claude split, codex gets the odd one |

Rationale: codex-exec tends to surface more issues per call in our usage, so it gets the larger share. When `agents=1` we use codex-exec for the same reason.

## Loop Mechanics

Run the loop **once per round** for `rounds` total. Within a round:

### 1. Snapshot the target

Capture the current state of the diff/branch/PR at the start of the round so all reviewers see the same input. Concretely:

- Run the appropriate `git diff …` command(s) to materialize the diff as text.
- Note the commit SHA at round start (`git rev-parse HEAD`) so the round summary can reference the exact baseline.

### 2. Dispatch reviewers in parallel

Send a **single message containing M `Agent` tool calls**, one per reviewer in the mix. For each:

- For codex-exec reviewers: `subagent_type: "general-purpose"`, with a prompt that opens with "Use the codex-exec skill to perform this review." The prompt body is the **Reviewer Prompt Template** below, filled in.
- For claude-exec reviewers: `subagent_type: "general-purpose"`, with a prompt that opens with "Use the claude-exec skill to perform this review." Same template body.

Always dispatch in parallel. Never serialize reviewers within a round.

### 3. Synthesize

When all reviewers return, merge their findings:

- **Dedup** overlapping issues (same area + same root cause). Keep the highest-severity instance and note which reviewers raised it.
- **Group** by severity (`critical` → `nit`), then by topic within severity.
- **Drop** any item already addressed in this round's earlier fixes (defensive — shouldn't normally happen in v1 since fixes happen after synthesis).

If a reviewer's output is unparseable, label its findings "unstructured" and pass through the prose into a separate section of the synthesis. Do not retry.

### 4. Apply fixes

Make the edits as the orchestrator. Group fixes by topic and **commit one logical fix-group per commit**, conventional-commit style:

- `fix(area): <what>` — for bug/correctness fixes
- `refactor(area): <what>` — for maintainability/simplicity changes
- `test(area): <what>` — when adding tests
- `chore(area): <what>` — for production-readiness tweaks (logging, error handling, config)

Items judged noise (e.g., reviewer disagreement with house style, false positives) are **deferred**, not silently dropped. Record each deferred item with a one-line reason.

### 5. Round summary

Append a short markdown block to running output:

```
### Round N — <convergence flag>
- Reviewers: <list of agents dispatched>
- Findings: C critical, H high, M medium, L low, X nit
- Fixes applied: K commits (<sha1>..<shaN>)
- Deferred: D items (see below)
```

The convergence flag is one of:
- `clean` — no findings at all
- `nits_only` — no findings above `low` severity
- `material_findings` — at least one `medium` or higher

### 6. Continue or finish

If the round number is less than `rounds`, start the next round (back to step 1). Round N+1 reviews the new state — its prior-round summary input includes the commits from round N.

After the final round, emit the **Final Report** described under "Output Format."

### Failure handling

- If a reviewer agent fails or times out, log it in the round summary as `<agent>: failed (<reason>)` and proceed with the others. No retries.
- If **all** reviewers in a round fail, abort the loop and report what happened. Do not "carry on" with zero findings — that produces a misleading clean signal.
- If `git commit` fails (pre-commit hook, conflicts), surface the error and stop the loop. Do not bypass hooks.

### Concurrency

- Within a round: parallel (single multi-tool-call message).
- Between rounds: strictly sequential (round N+1 needs round N's commits to exist).

## Reviewer Prompt Template

Each reviewer subagent receives a self-contained prompt assembled from a **context block** and a **task block**.

### Context block (orchestrator fills in)

```
You are a strict code reviewer for round {N} of {ROUNDS}.

TARGET
{Description of the target — e.g. "PR #42 (12 files, +340/-89) on branch
feature/auth-rewrite"; or "diff between `main` and `feature/x` (`git diff
main...HEAD`)"; or "uncommitted changes in src/auth/ (`git diff` +
`git diff --cached`)". Include the actual diff text or instructions to
fetch it.}

PRIOR ROUNDS
{One line per prior round, e.g.:
  Round 1: 4 critical / 6 high / 3 medium / 5 nit; 7 fixes applied
  (commits a1b2c3d..7e8f9a0); 2 deferred.
If this is round 1, write "None — this is round 1."}

FOCUS
- Correctness
- Maintainability
- Simplicity
- Production blast-radius (what could blow up in production?)
{plus any user-supplied additions, or only the user-supplied list when
they prefixed it with `only:`}
```

### Task block (fixed boilerplate, identical for every reviewer)

````
TASK
Review the target above. Be very critical. Surface issues across the
focus areas. IMPORTANT: research only — do not edit any files.

Severity guide:
- critical: data loss, security breach, production crash
- high: correctness bug or major maintainability problem
- medium: should fix but not blocking
- low: style or minor
- nit: preference

Do not repeat issues already addressed in prior rounds (see PRIOR
ROUNDS).

For each issue, return a structured finding with these keys:
- severity: one of critical|high|medium|low|nit
- area: short topic tag (e.g. "auth", "db-migration", "error-handling")
- what: one-sentence description of the problem
- why: one-to-three-sentence explanation of why it matters
- suggested_fix: PROSE description of how to fix (no patches, no code
  blocks unless quoting a single short line for clarity)

Output format: a markdown report. End the report with a fenced
```findings block containing one YAML list item per finding, like:

  ```findings
  - severity: high
    area: auth
    what: ...
    why: ...
    suggested_fix: ...
  ```

If you find nothing worth raising, return an empty findings block:

  ```findings
  []
  ```
````

### Filling in the template

- The orchestrator constructs the full prompt by concatenating the context block (with placeholders filled) and the task block verbatim.
- The reviewer subagent is invoked with a sentence like "Use the {codex-exec|claude-exec} skill to perform this review." prepended to the assembled prompt.
- Reviewers must return **prose findings only**. The skill rejects (or simply ignores) any embedded patches.
- The PRIOR ROUNDS lines are constructed directly from each prior round's summary (Loop Mechanics §5) — include all five severity counts in the form `Round N: C critical / H high / M medium / L low / X nit; K fixes applied (<sha1>..<shaN>); D deferred.`

## Output Format

### During execution

Print a one-line status before each round:

```
Round 2/3: dispatching 2 codex-exec + 1 claude-exec on PR #42 …
```

Append the round summary block (defined under Loop Mechanics, step 5) after each round completes.

### Final report

After the last round completes, emit a fresh top-level report below the running output. The report is a new document — not a replacement for the per-round blocks already printed during execution.

`Findings addressed` in the Total section equals the post-dedup count of unique findings surfaced across all rounds, minus the count of deferred items. Use this structure:

```
# review-anvil report

**Target:** <description, e.g. "PR #42 (feature/auth-rewrite, 12 files, +340/-89)">
**Rounds:** <N>
**Mix per round:** <e.g. "2 codex-exec + 1 claude-exec">
**Focus:** <comma-separated focus list actually used>

## Round 1 — <convergence flag>
- Findings: C critical, H high, M medium, L low, X nit
- Fixes applied: K commits (<sha1>..<shaK>)
- Deferred: D items

## Round 2 — <convergence flag>
…

## Total
- Total commits: T
- Findings addressed: A
- Findings deferred: D
- Tuning suggestion: <one line, e.g. "round 3 was clean — `rounds=2`
  likely sufficient next time"; omit if no clean rounds occurred>

## Deferred items
For each deferred item across all rounds:
- **[severity] area** — what (deferred because: reason)
```

### Tuning suggestion rule

Look at the convergence flags across rounds:

- If the **last** round was `clean` or `nits_only` and any earlier round was `material_findings`, suggest `rounds = N - 1` (or further if the last two rounds were both clean/nits).
- If **every** round was `material_findings`, suggest `rounds = N + 1` next time (the loop hadn't converged).
- Otherwise omit the suggestion.

## Edge Cases

### Missing reviewer dependency

`review-anvil` dispatches `codex-exec` and `claude-exec` subagents — both must be installed for the skill to function. If `Skill codex-exec` or `Skill claude-exec` fails to resolve, the dispatched reviewer will error out. Before round 1, confirm both are available; if either is missing, abort with: "review-anvil requires codex-exec and claude-exec; install them via `/plugin install codex-exec` and `/plugin install claude-exec`."

### Empty or trivial target

If the auto-detected target has no diff (e.g., user is on `main` with no uncommitted changes), abort early and report: "No target detected — nothing to review." Do not invent work to do.

### Target spanning a binary file or huge diff

If the diff exceeds ~5000 lines, warn in the per-round status and continue — but include in the reviewer prompt a note: "This is a large diff; you may focus on the most impactful slice if a thorough whole-diff review is impractical."

### `agents` requested exceeds reasonable limits

Reject `agents > 8` with an explanatory error before round 1. Eight parallel reviewers per round is already aggressive; higher counts produce more dedup work than signal.

### `rounds = 0`

Reject before starting. Zero rounds is a no-op and almost certainly a typo.

### A reviewer returns an unparseable findings block

Use the prose body as a free-form findings list. Do not retry. Note in the round summary: "<agent>: unstructured findings (parse failed)."

### A reviewer fails outright

Note in the round summary: "<agent>: failed (<reason>)." Continue with remaining reviewers. If **all** reviewers fail, abort and report.

### A `git commit` fails inside a round

Stop the loop, print the git error, leave any partial fixes in the working tree (or staged) for the user to resolve. Do not bypass hooks (`--no-verify`) and do not amend earlier commits.

### Conflicting findings across reviewers

If two reviewers contradict each other (one says "wrap in a try/except," another says "don't swallow this exception"), surface both under the same area in the synthesis with their reviewers tagged, and pick the orchestrator's judgment when applying fixes. Mention the disagreement in the round summary.

### Re-runs

This skill is **not idempotent**. Re-running it will start fresh review rounds against the latest state (including this run's own commits). That is usually what the user wants. If the prior run left deferred items, surface them at the top of the new run's final report under "Deferred from previous runs (still present)" — the orchestrator can detect this by inspecting recent commit messages for `fix(…)`/`refactor(…)` etc. associated with prior rounds.
