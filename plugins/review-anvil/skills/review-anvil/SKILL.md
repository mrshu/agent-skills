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
| `review-anvil-improve-pr [<locator>]` | `commit_mode=per_fix`, `target=<base>...HEAD`, `report_path=<file>` | Improve a checked-out PR: fix commits across N rounds, then push. Targets the branch (not a PR locator), deliberately routing around the PR-target/per_fix rule below. |

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
| `approve` | `allowed` | "never approve", "comment only", `approve: never` — always write `{"event": "COMMENT"}` to `.approval.json`. Presets additionally export `REVIEW_ANVIL_NO_APPROVE=1` so the helper enforces it mechanically. Only meaningful for review-only PR runs |
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
- Likewise gather the **dismissed findings** before dispatch: when a preset supplied the list (improve-pr captures it at verify-checkout time), use that; for PR-locator targets fetch it yourself via `pr-helper.sh dismissed <host> <owner> <repo> <n>` (ships with `review-anvil-pr`; paginated, retried once). Include the itemized list in every reviewer prompt (DISMISSED FINDINGS block) and never report those findings again unless the new diff materially reintroduces the same bug in different code. If the lookup fails after retry, abort rather than risk repeating feedback the author already resolved — unless the user opted into degraded mode (`REVIEW_ANVIL_SKIP_DISMISSED=1`), which also forces the review decision to COMMENT.
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

**Resolving the wrapper and `references/` files** — same trusted-root rule as `pr-helper.sh`: see review-anvil-pr SKILL.md step 1 ("Resolve the helper script"). Host-exposed skill path or user-level install roots only; never project-scoped/worktree-local skill dirs (writable by the repo under review). If no trusted copy of the wrapper resolves, replicate its contract inline (background, kill at deadline, check exit status, empty output = failure) rather than falling back to a bare redirect.

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
- Findings raised independently by **2+ reviewers** skip verification; consensus is the signal (this is why dedup records who raised what) — *except deletion findings, see below*.
- **Deletion findings must be *proven*, not just judged, regardless of reviewer count.** Findings whose action is removal or inlining — "delete this", dead/unused code, a needless abstraction, a redundant check — are the highest-blast-radius class and the dominant false positive: reviewers recommend cutting *load-bearing* code (a trust boundary, a genuinely-varying abstraction, a flag read elsewhere, a defensive copy, ordering/atomicity, wire-format back-compat, an import-cycle dup, a test seam — **and reasons not in this list**) roughly half the time. Treat each deletion as a falsifiable hypothesis:
  - **Empirical proof (when fixes are applied, `per_fix`): the build/test gate is the experiment** — apply the cut and keep it only if the gate stays green; a deletion that turns it red is falsified and reverted. This is the strongest evidence and should be preferred when available.
  - **A green gate is necessary but not sufficient** — it only proves *test-covered* behavior, and the load-bearing reasons above are usually untested (security, wire compat, aliasing copies, ordering/atomicity), so a passing build can *falsely* confirm a harmful cut. So also verify as a skeptic *trying to refute the cut* from the actual callers/readers, tests, comments, and configured runtime — covering behavior no test exercises. In read-only mode (`commit_mode=none`) the skeptic is the **only** available proof; nothing is executed.
  - Both checks **override the 2+-reviewer skip** — two reviewers co-flagging a live unit is correlated error, not verification. Refuted by either → **Deferred** with reason `failed verification: load-bearing (<what depends on it>)`.
- Failed verification → **Deferred** with reason `failed verification: <one line>` — never auto-fixed, never silently dropped.
- `low`/`nit` findings skip verification: they're below the auto-fix gate and surface as suggestions either way.

#### Approving out-of-scope follow-ups

A pre-existing issue outside the PR's scope can still be valuable, but it must not become an inline/blocking PR finding. Classify each out-of-scope follow-up:

- **Auto-approved follow-up** — create/queue separate work when all are true: severity is `critical`/`high` (or clearly reproducible `medium`), the bug is confirmed from code/tests/runtime evidence, it is not a product decision/style preference, it is not already tracked/resolved/dismissed, and the fix is plausibly separable from the current PR.
- **Needs human triage** — mention only as a non-blocking follow-up when the issue is real but severity/ownership/product intent is ambiguous.
- **Do not surface** — drop if speculative, low/nit, a product decision, already dismissed/tracked, or only discoverable by reviewing unrelated code paths deeply.

When `report_path` is set, write follow-ups once, after the final round, to `<report_path>.followups.json` — schema in `references/report-artifacts.md`. Automation may file issues only for `auto_approved` entries after duplicate search; presets read the file before posting (the helper deletes it afterwards).

### 4. Apply fixes

**Skip entirely when `commit_mode=none`** (the policy below is still evaluated in the abstract for the report).

Otherwise **read `references/fix-application.md` before making any edit**: it defines the conventional-commit fix-group style, the auto-fix proportionality rules (severity gate >= `min_fix_severity`; no new dependencies without `allow_new_deps`; per-round size cap; noise is deferred with a reason, never silently dropped), and the build/test gate (`verify_cmd` resolution, baseline run, fix-forward-or-revert, revert-failure escalation). The invariant: **a round never ends with the build/test gate newly red**.

### 5. Round summary

Append to running output:

```
### Round N — <convergence flag>
- Parameters: rounds=3, target=acme/widgets#42 [pin], commit_mode=none [pin], focus=4-pillar
- Reviewers: <list dispatched>
- Findings: C critical, H high, M medium, L low, X nit
- Fixes applied: K commits (<sha1>..<shaN>)   # or "0 (review-only)"
- Verification: <cmd> — passed | failed → round reverted | pre-existing failures (no new) | none detected | skipped   # per_fix only
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

   Single line → `{"line": N, "side": "RIGHT"}`; range `<N>-<M>` → `{"start_line": N, "line": M, "side": "RIGHT", "start_side": "RIGHT"}`. Findings without anchors stay in the markdown body only; no anchored findings → `[]`. A reader must be able to create the fix from each `body` alone.

   Each `body` follows the **inline-comment voice** defined in `references/report-artifacts.md` — read it before composing bodies. In one line: three short parts (observable-problem header; mechanism with one concrete downstream consequence; fix path complete enough to implement without re-investigation), addressed to the code never the author, calm register (the severity tag carries the urgency), one honest clause of credit when genuine. The same voice applies to the report's Suggestions, Deferred, and Out-of-scope follow-ups prose.

3. Write a sibling `<report_path>.approval.json` so the PR-posting helper can choose the GitHub review event (review-only PR runs; for other runs write `{"event": "COMMENT"}` or omit the file — the helper defaults to COMMENT):

   ```json
   {
     "event": "APPROVE | COMMENT",
     "head_sha": "<the HEAD_SHA the preset captured at init/verify-checkout>",
     "reason": "No high/critical in-scope findings; medium-and-lower items are left to the author."
   }
   ```

   Include `"head_sha"` — the `HEAD_SHA` the preset captured at init/verify-checkout time — so the posting helper can verify the approval still matches the reviewed state (it downgrades to COMMENT if the PR head moved mid-run).

   Use `APPROVE` for review-only PR runs when all of these hold: `approve` is not `never`, at least one reviewer succeeded, there are no `critical`/`high` actionable in-scope findings, no `critical`/`high` in-scope deferred finding needs author action, and remaining items are only `medium`/`low`/`nit` findings, suggestions, deferred notes, or out-of-scope follow-ups. Medium-and-lower in-scope findings should still be posted clearly, but the review event is approval: leave those fixes to the author. Use `COMMENT` otherwise. Out-of-scope follow-ups do not block approval.
4. Print the report path as the last output line; the `.inline.json` and `.approval.json` files are implied by convention.
5. For out-of-scope follow-ups, write the sibling `<report_path>.followups.json` once, after the final round, using the follow-ups schema from §3 "Approving out-of-scope follow-ups" (NOT the `.approval.json` schema above). The posting helper deletes it after a successful post, so any consumer (surfacing follow-ups to the user, filing issues for `auto_approved` entries after duplicate search) must read it **before** the post/post-update step — the presets do this.

### Failure handling

- A reviewer fails or times out → log `<agent>: failed (<reason>)` in the round summary and proceed; no retries. For Bash-dispatched reviewers, failure = wrapper STATUS `timeout`/`empty`/`failed`, reason = tail of `.err`.
- **All** reviewers fail → abort the loop and report. Never carry on with zero findings — that's a misleading clean signal.
- `git commit` fails (hook, conflict) → surface the error, stop the loop, leave partial fixes in the worktree. Never `--no-verify`, never amend earlier commits.
- **On any abort, if `report_path` is set, write a failure report to it before stopping** — the usual header block, a `## Failure` section stating what happened and at which round, plus any completed round summaries. Downstream consumers (`review-anvil-improve-pr`'s post-update step) depend on the file existing on every exit path, success or failure. Write `{"event": "COMMENT"}` to `.approval.json` in this case.

### Concurrency

Within a round: parallel (single multi-tool-call message). Between rounds: strictly sequential.

## Reviewer Prompt Template

**Read `references/reviewer-prompt.md` (next to this SKILL.md; same trusted-root resolution as scripts) at dispatch time.** It defines the per-reviewer lens assignment (the four pillars partition across reviewers — M identical prompts buy redundancy and dedup work, not coverage), the context block (TARGET / PRIOR ROUNDS / SCOPE OF THIS REVIEW / DISMISSED FINDINGS / YOUR LENS), the fixed task block (review principles, severity guide, structured finding keys, the fenced findings-YAML output contract), and the fill-in rules (itemized PRIOR ROUNDS construction; `commit_mode=none` variations). Reviewers return prose findings only — never patches.

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
**Review decision:** APPROVE | COMMENT — <one-sentence reason>   # review-only PR runs

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
