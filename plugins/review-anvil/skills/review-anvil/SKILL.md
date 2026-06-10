---
name: review-anvil
description: Iteratively refine code via N rounds of parallel subagent review and orchestrator-applied fixes. Use when the user says "let's do three rounds", "fix/review loop", "back-and-forth review", "iterative review", or asks to harden a change with multiple rounds of codex/claude review.
---

# review-anvil — Iterative Multi-Agent Fix/Review Loop

Wrap a code change in **N rounds of parallel reviewer subagents + orchestrator-applied fixes**. Each round = (parallel review by M agents, each with a distinct lens) → (you synthesize and **verify** findings) → (you apply fixes, run the build/test gate, commit) → next round.

## Preset skills

This is the **engine**. Three preset skills in the same plugin pin common configurations; each is a separate `skills/<name>/SKILL.md` whose `description` triggers activation cross-agent.

| Preset | Pins | Intent |
|---|---|---|
| `review-anvil` (engine) | nothing | Default fix/commit loop, or any custom param combination. |
| `review-anvil-readonly` | `commit_mode=none`; default `rounds=1` | Read-only review — no edits, no commits. |
| `review-anvil-pr [<locator>]` | `commit_mode=none`, `target=<locator>`, `report_path=<file>` | Review a GitHub PR and post the report back as a PR comment (orchestrates `scripts/pr-helper.sh`). Locator auto-detected from the current branch when omitted. |
| `review-anvil-improve-pr [<locator>]` | `commit_mode=per_fix`, `target=<base>...HEAD` | Improve a checked-out PR: fix commits across N rounds, then push. Targets the branch (not a PR locator), deliberately routing around the PR-target/per_fix rule below. |

## Parameters

Parse the user's free-form args string into:

| Param | Default | Plain-English forms |
|---|---|---|
| `rounds` | `3` | "5 rounds", "three rounds", "do 4 passes" |
| `agents` | `3` | "3 agents", "2 reviewers", or a mix like `"2 codex + 1 claude"` |
| `focus` | the four pillars (correctness, maintainability, simplicity, production blast-radius) | "focus on async correctness"; an `only:` prefix replaces the defaults instead of appending |
| `target` | auto-detect | "PR #42", "branch", "uncommitted", "src/auth/", "last 3 commits" |
| `allow_new_deps` | `false` | "allow new deps" — auto-apply fixes that introduce new imports/subsystems instead of deferring them |
| `min_fix_severity` | `medium` | "auto-fix high and above", "fix only critical" — minimum severity for auto-fix; lower findings are listed, not applied |
| `commit_mode` | `per_fix` | `per_fix` (one commit per fix-group) or `none` ("review only", "don't commit", "no fixes") |
| `verify_cmd` | auto-detect | "verify with `npm test`", `verify_cmd: none` to skip — build/test command run after each round's fixes (see "Build/test gate"; per_fix only) |
| `reviewer_timeout` | `600` | "timeout 10 minutes" — hard per-reviewer wall-clock cap in seconds for Bash-dispatched reviewers (see `run-reviewer.sh`). Default is ~3× the slowest legitimate reviewer observed in real runs (98–213s); doubled automatically for >5000-line diffs |
| `report_path` | unset | File path; when set, the engine writes the final report there (creating parent dirs) and prints exactly that path as its last output line so downstream consumers can pick it up |

### Parsing

- Split the args on top-level commas; canonicalize each segment to a `(param, value)` pair — explicit `key: value` maps directly, plain-English forms per the table. Unrecognized segments are noted and ignored.
- **First occurrence wins** per param; later duplicates are dropped with `warning: user-supplied <param>=<value> ignored — earlier value wins`. Unset params take defaults.
- Presets assemble `<pins>, <user-args>, <overridable defaults>`: pins come first so first-occurrence-wins makes them authoritative; defaults come last so user args beat them.
- **Pin-rejection (presets; defense in depth against the prose parser being talked into overrides):** before assembling, segment-split `$ARGUMENTS` as above, lowercase each segment's key (the text before its first `:`), and abort with `error: <param> is pinned by <preset-name> and cannot be overridden in args` if any key equals a pinned param. Match segment *keys*, never raw substrings — `focus: "target: PR safety"` has key `focus` and must pass. A host that cannot segment-split must abort (`error: pin-rejection unavailable in this environment; refusing to invoke engine without pin enforcement`), not degrade to substring scanning.
- `agents`: a count (use the mix table below) or an explicit mix naming `codex`/`codex-exec` / `claude`/`claude-exec` — honor a mix exactly.
- `target` auto-detect order: currently checked-out PR (e.g. `gh pr view --json number,headRefName`, a GitHub MCP query, or REST) → branch-vs-main diff (`git diff main...HEAD`) → uncommitted changes (`git diff` + `git diff --cached`). Empty args = all defaults.

### PR-target / per_fix incompatibility

If `target` is a GitHub PR locator (URL `https://<host>/<owner>/<repo>/pull/<N>`, slug `<owner>/<repo>#<N>`, or "PR #N"), the only valid `commit_mode` is `none`. Force it, and warn if the user asked for `per_fix`:

> `warning: PR locators are read-only — forcing commit_mode=none (use 'target: branch' to fix-and-commit on your checked-out PR branch).`

Reviewers of a PR locator see the GitHub-fetched diff, which may not match the local worktree; committing against a baseline the user can't see locally is unpredictable. Branch targets make the local tree the source of truth.

### Commit modes

- **`per_fix` (default)** — full loop: review → synthesize/verify → apply fixes → build/test gate → commit, each round.
- **`none` (review-only)** — review → synthesize/verify only. **No edits, no commits, no staging.** Every round reviews the same baseline, so `rounds > 1` buys reviewer redundancy, not refinement; the natural default is `rounds=1`. Skip Loop Mechanics §4 entirely; the round summary reads `Fixes applied: 0 (review-only)`; the auto-fix policy is still evaluated in the abstract so findings classify as would-apply / suggestions / deferred; the final report ends with a "Would-apply summary" instead of commit SHAs and a tuning suggestion.

### Posting reports externally

The engine never posts anywhere. Downstream consumers set `report_path`, let the engine write the report, and post after it returns — `review-anvil-pr` + its `pr-helper.sh` is the reference implementation.

### Examples

- `Skill review-anvil` → 3 rounds, 2 codex + 1 claude, four-pillar focus, auto-detected target.
- `Skill review-anvil "5 rounds, 2 codex + 1 claude, focus: async correctness, target: PR #42"`
- `Skill review-anvil "1 round, only: security, target: src/auth/"`
- `Skill review-anvil "fix only critical"` → severity gate raised to `critical`; everything else surfaces as suggestions.

## Default Mix Policy

When the user gives a count but no mix:

| `agents` | Mix |
|---|---|
| 1 | 1 codex-exec |
| 2 | 1 codex-exec + 1 claude-exec |
| 3 | 2 codex-exec + 1 claude-exec |
| 4 | 2 codex-exec + 2 claude-exec |
| 5 | 3 codex-exec + 2 claude-exec |
| N | ~60/40 codex/claude split, codex gets the odd one |

Rationale: codex-exec surfaces more issues per call in our usage, so it gets the larger share (and the `agents=1` slot).

## Loop Mechanics

Run the loop once per round for `rounds` total. Within a round:

### 1. Snapshot the target

Capture the target's state at round start so all reviewers see the same input:

- Non-PR targets (branch, uncommitted, path): materialize the diff with the appropriate `git diff …`.
- PR targets (always `commit_mode=none`): fetch the PR's diff via `gh pr diff <N> -R <owner>/<repo>` (or equivalent MCP/REST). The local worktree is irrelevant — reviewers see the PR as it exists on GitHub.
- Whenever PR context is available — a PR-locator target, or a preset that supplies it (`review-anvil-improve-pr` does, after `verify-checkout`) — fetch the PR title/body/base branch/file list too, then infer the PR's intended scope in one sentence (e.g. "performance optimization in annotation seeding", "left-sidebar UX reorganization"). Put that scope in every reviewer prompt. A finding is actionable only if the PR introduces/regresses it or if it directly undermines the PR's stated purpose. Obvious, high-confidence pre-existing defects may be mentioned, but only under a separate "Out-of-scope follow-ups" section — never as blockers or inline actionable review comments for the current PR.
- Likewise fetch the **dismissed findings** before dispatch: resolved review threads plus local suppressions, via `pr-helper.sh dismissed <host> <owner> <repo> <n>` (ships with `review-anvil-pr`; paginated, retried once). Include the itemized list in every reviewer prompt (DISMISSED FINDINGS block) and never report those findings again unless the new diff materially reintroduces the same bug in different code. If the lookup fails after retry, abort rather than risk repeating feedback the author already resolved.
- Note `git rev-parse HEAD` so the round summary can reference the exact baseline (informational-only for PR targets).

### 2. Dispatch reviewers in parallel

#### In Claude Code (the primary host)

**Use the Agent tool for `claude-exec` reviewers. Do NOT use `claude -p` via Bash — that path is for non-Claude hosts only.**

- **`claude-exec`**: Agent tool, `subagent_type: "general-purpose"`, the assembled Reviewer Prompt as `prompt`, `run_in_background: true`. The Agent tool streams natively, has no `--max-turns` ceiling, and inherits the session environment.
- **`codex-exec`**: Bash through the wrapper: `bash <wrapper> .review-anvil/round<N>-<label>.md <reviewer_timeout> -- codex exec --sandbox read-only -C <project-dir> '<prompt>'`, with `run_in_background: true`.
- Send all M reviewers in a *single message* with multiple tool calls. The harness notifies you on completion; do not poll.

#### In Codex CLI or other hosts without the Agent tool

- **`claude-exec`**: write the assembled prompt to a file, then:

  ```bash
  bash <wrapper> .review-anvil/round<N>-<label>.md <reviewer_timeout> -- \
    claude -p --max-turns 100 --no-session-persistence \
      --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" \
    < .review-anvil/round<N>-<label>.prompt.md
  ```

  `--allowedTools` is variadic and eats positional args, so the prompt MUST arrive via stdin (the wrapper passes its stdin through). **Do not size `--max-turns` to the task** — task-sized caps keep biting (8, then 20, were both hit in production), and a reviewer that hits the cap loses its entire output. The wrapper's wall-clock timeout is the real bound; `100` is a runaway backstop that should never bind (set explicitly because some hosts default to 8).

- **`codex-exec`**: same wrapper around `codex exec --sandbox read-only -C <project-dir> '<prompt>'`.
- Launch all M wrapper invocations as background shell processes and `wait`.

#### Bash-dispatched reviewers MUST go through `run-reviewer.sh`

Every shell-dispatched reviewer (codex-exec everywhere; claude-exec outside Claude Code) runs under `scripts/run-reviewer.sh` (next to this SKILL.md). **Never background a bare `claude -p ... > out.md 2>&1` and wait on the file** — in text mode nothing prints until the final answer, so a hung reviewer and a working one are both a 0-byte file (a production run waited on exactly that for many minutes). The wrapper:

```
run-reviewer.sh <out_file> <timeout_seconds> -- <command> [args...]
```

- Hard wall-clock timeout (`reviewer_timeout`, default 600s): TERM at the deadline, KILL 30s later.
- Captures exit status; stderr goes to `<out_file>.err` (kept for diagnosis).
- Prints one classification: `STATUS=ok` | `timeout` | `empty` (exit 0, nothing written) | `failed` (+ `EXIT_CODE=<n>`).

Treat any STATUS other than `ok` as a failed reviewer (see Failure handling), with the tail of `.err` as the reason. Reviewer output/prompt files live under `.review-anvil/`; clean them up after the round's synthesis.

**Resolving the wrapper** — same trusted-root rule as `pr-helper.sh`: host-exposed skill path (`${CLAUDE_PLUGIN_ROOT}/skills/review-anvil/scripts/run-reviewer.sh`) or the user-level install root (`~/.claude/skills/review-anvil/scripts/run-reviewer.sh`, or the host's documented home-directory skill root). Never project-scoped/worktree-local skill dirs — they're writable by the repo under review. If no trusted copy resolves, replicate the wrapper's contract inline (background, kill at deadline, check exit status, empty output = failure) rather than falling back to a bare redirect.

#### Last resort

If parallel dispatch is genuinely impossible (no Agent tool, no background bash), fall back to serial invocation and **say so in the round summary** — serial reviewers see the baseline at different wall-clock times; it's a degraded mode, not the design.

The `codex-exec` and `claude-exec` skills document the same recipes from the reviewer side; the canonical dispatch lives here.

### 3. Synthesize

When all reviewers return:

- **Dedup** on `(file, line, root cause)` when present, else `(area, root cause)`. Keep the highest-severity instance, record which reviewers raised it, and keep divergent anchors as `file_alternates: [...]`.
- **Group** by severity (`critical` → `nit`), then topic.
- Unparseable reviewer output: pass the prose through as "unstructured" findings in a separate section; no retry.

#### Verify findings before acting on them

Plausible-but-wrong findings are the dominant failure mode of LLM review, and both downstream actions are expensive: a bogus fix commit pollutes the branch, a bogus finding posted to a PR burns the author's trust. After dedup:

- **Dismissed check first (orchestrator judgment).** When a DISMISSED FINDINGS list exists, compare every merged finding against it *semantically* — same root cause counts even when the wording differs completely ("missing CSRF check" matches "no token validation on state-changing route"). Matches move to Deferred with reason `previously dismissed (<source>)` and are never auto-fixed or posted. You are the primary matcher here; the post-time script gate in `pr-helper.sh` only catches near-verbatim repeats (path match + text similarity ≥ 0.9) as a deterministic backstop.
- A `medium`+ finding raised by a **single** reviewer must be confirmed against the actual code before it is auto-fixed or reported as actionable: open the cited file and enough surrounding context (callers, configured runtime, tests) to confirm the issue is real and reachable — not merely plausible from the hunk.
- Findings raised independently by **2+ reviewers** skip verification; consensus is the signal (this is why dedup records who raised what).
- Failed verification → **Deferred** with reason `failed verification: <one line>` — never auto-fixed, never silently dropped.
- `low`/`nit` findings skip verification: they're below the auto-fix gate and surface as suggestions either way.

#### Approving out-of-scope follow-ups

A pre-existing issue outside the PR's scope can still be valuable, but it must not become an inline/blocking PR finding. Classify each out-of-scope follow-up:

- **Auto-approved follow-up** — create/queue separate work when all are true: severity is `critical`/`high` (or clearly reproducible `medium`), the bug is confirmed from code/tests/runtime evidence, it is not a product decision/style preference, it is not already tracked/resolved/dismissed, and the fix is plausibly separable from the current PR.
- **Needs human triage** — mention only as a non-blocking follow-up when the issue is real but severity/ownership/product intent is ambiguous.
- **Do not surface** — drop if speculative, low/nit, a product decision, already dismissed/tracked, or only discoverable by reviewing unrelated code paths deeply.

When `report_path` is set, write a sibling `<report_path>.followups.json` with any follow-ups:

```json
[
  {
    "approval": "auto_approved | needs_triage",
    "severity": "high",
    "area": "entity-resolution",
    "title": "Canonicalize merged co-mentions before seeding annotation prompts",
    "why": "Confirmed pre-existing bug; stale merged IDs can re-enter prompts.",
    "evidence": {"file": "apps/api/src/pipeline/seeder.rs", "line": 359},
    "separate_pr_reason": "Not introduced by this performance PR; should be fixed independently.",
    "dedupe_key": "entity-resolution merged co-mentions seeding"
  }
]
```

Downstream automation may file GitHub issues only for `auto_approved` entries after duplicate search; `needs_triage` stays in the PR report only.

### 4. Apply fixes

**Skip entirely when `commit_mode=none`** (the policy below is still evaluated in the abstract for the report).

Make the edits as the orchestrator. Commit one logical fix-group per commit, conventional-commit style: `fix(area):` correctness, `refactor(area):` maintainability/simplicity, `test(area):` tests, `chore(area):` production-readiness.

#### Auto-fix policy (proportionality rules)

1. **Severity gate.** Auto-fix only at severity ≥ `min_fix_severity`. Below-gate findings land under "Suggestions". Exception: an obvious one-line fix at any severity may be applied without bumping severity.
2. **No new dependencies (default).** A fix introducing a new import, package, or subsystem is deferred with reason `introduces new dependency: <X>` even above the gate; `allow_new_deps: true` opts in. Don't grow the architecture without permission.
3. **Round size cap.** A round's fixes may grow the target file by at most ~50% of its starting line count or 200 lines, whichever is larger; apply highest-severity first, defer the rest with `round size cap reached`.

Noise/false positives are also **deferred** with a one-line reason — never silently dropped.

#### Build/test gate (`verify_cmd`)

Fix commits must not leave the branch red. In `per_fix`:

- **Resolve:** explicit `verify_cmd` → use it; `verify_cmd: none` → record `Verification: skipped (user)`; unset → auto-detect (repo docs naming a test command; `package.json` `scripts.test`; `Makefile` `test`; pytest/cargo/go-test config). Nothing found → record `Verification: none detected` and proceed (downstream consumers surface the caveat).
- **Baseline:** run once before round 1; if already failing, gate only on *new* failures.
- **Gate each round:** run after the round's fixes. On a new failure: one fix-forward attempt if the cause is obvious (`fix(<area>): repair <verify_cmd> failure from round <N> fixes`), else `git revert --no-edit` the round's fix commits and defer the findings with `fix failed verification`. A round never ends with the gate newly red.

### 5. Round summary

Append to running output:

```
### Round N — <convergence flag>
- Parameters: rounds=3, target=acme/widgets#42 [pin], commit_mode=none [pin], focus=4-pillar
- Reviewers: <list dispatched>
- Findings: C critical, H high, M medium, L low, X nit
- Fixes applied: K commits (<sha1>..<shaN>)   # or "0 (review-only)"
- Verification: <cmd> — passed | failed → round reverted | none detected | skipped   # per_fix only
- Would-apply: W items                         # commit_mode=none only
- Suggestions: S items (sub-threshold severity; not applied)
- Deferred: D items (reasons: noise / new dependency / size cap / failed verification / product decision)
```

Pinned params carry `[pin]` (authority comes from preset argument order; the PR-target/per_fix rule is the final safety net). Convergence flag: `clean` (no findings), `nits_only` (nothing above `low`), `material_findings` (≥1 medium+).

### 6. Continue or finish

If rounds remain, start the next round; round N+1 reviews the new state including round N's commits.

**Early exit on convergence (`per_fix` only).** A `clean` or `nits_only` round ends the loop even if rounds remain — further rounds re-review converged code and mostly produce noise. Note `Converged after round N of R (early exit)` in the Total section. (In `commit_mode=none`, multi-round = reviewer redundancy over the same baseline; no early exit.)

After the final round, emit the **Final Report** (Output Format). If `report_path` is set:

1. Write the rendered report there (creating parent dirs).
2. Write a sibling `<report_path>.inline.json`: an array of GitHub PR review comment payloads for findings with both `file` and `line` —

   ```json
   [
     {"path": "src/auth.ts", "line": 50, "side": "RIGHT", "body": "**[high] auth** — Missing CSRF check.\n\nWhy: ...\n\nSuggested fix: ..."},
     {"path": "src/db.ts", "start_line": 100, "line": 110, "side": "RIGHT", "start_side": "RIGHT", "body": "..."}
   ]
   ```

   Single line → `{"line": N, "side": "RIGHT"}`; range `<N>-<M>` → `{"start_line": N, "line": M, "side": "RIGHT", "start_side": "RIGHT"}`. Findings without anchors stay in the markdown body only; no anchored findings → `[]`. Each `body` is a self-contained mini-report (severity + area + what + why + suggested_fix).
3. Write a sibling `<report_path>.approval.json` so the PR-posting helper can choose the GitHub review event:

   ```json
   {
     "event": "APPROVE | COMMENT",
     "reason": "No blocking in-scope findings; only low/nit suggestions remain."
   }
   ```

   Use `APPROVE` for review-only PR runs when all of these hold: at least one reviewer succeeded, dismissed/resolved-thread lookup succeeded, there are no `critical`/`high`/`medium` actionable in-scope findings, no in-scope deferred finding needs author action, and remaining comments are only `low`/`nit` suggestions or out-of-scope follow-ups. Use `COMMENT` otherwise. Out-of-scope follow-ups do not block approval.
4. Print the report path as the last output line; the `.inline.json` and `.approval.json` files are implied by convention.
5. For out-of-scope follow-ups, write optional sibling `<report_path>.followups.json` using the approval schema above. Automation that files issues may only act on `approval: "auto_approved"` after duplicate search.

### Failure handling

- A reviewer fails or times out → log `<agent>: failed (<reason>)` in the round summary and proceed; no retries. For Bash-dispatched reviewers, failure = wrapper STATUS `timeout`/`empty`/`failed`, reason = tail of `.err`.
- **All** reviewers fail → abort the loop and report. Never carry on with zero findings — that's a misleading clean signal.
- `git commit` fails (hook, conflict) → surface the error, stop the loop, leave partial fixes in the worktree. Never `--no-verify`, never amend earlier commits.

### Concurrency

Within a round: parallel (single multi-tool-call message). Between rounds: strictly sequential.

## Reviewer Prompt Template

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
- why: one-to-three-sentence explanation of why it matters
- suggested_fix: PROSE description of how to fix (no patches, no code
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
- **`commit_mode=none` multi-round:** nothing changes between rounds, so replace PRIOR ROUNDS with `None — review-only mode; this is an independent reviewer pass.` and drop the "do not repeat" paragraph from the task block.

## Output Format

During execution: print `Round 2/3: dispatching 2 codex-exec + 1 claude-exec on PR #42 …` before each round, the round summary block (§5) after.

### Final report

After the last round, emit a fresh top-level report (a new document, not a replacement for the per-round blocks):

```
# review-anvil report

**Target:** <e.g. "PR #42 (feature/auth-rewrite, 12 files, +340/-89)">
**Rounds:** <N>
**Mix per round:** <e.g. "2 codex-exec + 1 claude-exec">
**Focus:** <focus list actually used>
**Commit mode:** <per_fix | none>
**Auto-fix policy:** min severity = <medium>, allow_new_deps = <false>
**Verification:** <verify_cmd used, or "none detected" / "skipped">   # per_fix only
**Report path:** <only when report_path was set>
**Review decision:** APPROVE | COMMENT — <one-sentence reason>

## Scope
<For PR targets: one sentence summarizing what this PR is trying to change.>

## Round 1 — <convergence flag>
<the same lines as the §5 round summary, minus Parameters/Reviewers>

## Round 2 — <convergence flag>
…

## Total
- Total commits: T                          # per_fix only
- Findings addressed: A                     # per_fix; "Findings would-apply: A" in review-only
- Suggestions surfaced: S
- Findings deferred: D
- Converged after round N of R (early exit) # only when early exit fired
- Tuning suggestion: <one line; see rule below>   # omit in review-only

## Suggestions
- **[severity] area** — what (consider re-running with `min_fix_severity: <severity>` to apply)

## Deferred items
- **[severity] area** — what (deferred because: <reason — e.g. introduces new dependency: <X>; size cap reached; failed verification: <why>; product decision>)

## Out-of-scope follow-ups
- **[severity] area** — obvious pre-existing issue noticed during review (`auto_approved` or `needs_triage`; separate PR; why it is outside this PR's scope)

## Would-apply summary                      # commit_mode=none only
- **[severity] area** — what (would commit as `<type>(<area>): <subject>`)
```

`Findings addressed` = post-dedup count of unique findings auto-applied across all rounds.

### Tuning suggestion rule

Early exit already stops the loop when a round comes back clean, so the only tuning case left is non-convergence: if **every** completed round was `material_findings`, suggest `rounds = N + 1`; otherwise omit (the `Converged after round N of R` line covers the early-exit case).

## Edge Cases

| Case | Behavior |
|---|---|
| Missing reviewer backend | Validate only the backends the resolved mix actually names, before round 1. Abort with: "review-anvil requires the `<missing-skill>` skill from the mrshu-skills marketplace. Install via `/plugin install <missing-skill>@mrshu-skills` (Claude Code) or `npx skills add mrshu/agent-skills --skill <missing-skill>` (cross-agent)." |
| No diff in auto-detected target | Abort: "No target detected — nothing to review." Don't invent work. |
| Diff > ~5000 lines | Warn in the round status and continue; tell reviewers they may focus on the most impactful slice; double `reviewer_timeout` (unless the user set it explicitly). |
| `agents > 8` | Reject before round 1 — more dedup work than signal. |
| `rounds = 0` | Reject — almost certainly a typo. |
| Unparseable findings block | Use the prose as free-form findings; no retry; note `<agent>: unstructured findings (parse failed)`. |
| Reviewers contradict each other | Surface both under the same area with reviewers tagged; orchestrator judgment decides the fix; mention the disagreement in the round summary. |
| Re-runs | Not idempotent: a new run reviews the latest state, including the prior run's commits. Surface still-present deferred items under "Deferred from previous runs (still present)". |
