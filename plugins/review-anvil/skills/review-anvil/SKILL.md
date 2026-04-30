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

(context + task blocks — Task 5)

## Output Format

(final report + per-round status — Task 6)

## Edge Cases

(failure handling, target detection, parse fallback — Task 6)
