---
name: review-anvil
description: Iteratively refine code via requested rounds of parallel subagent review and orchestrator-applied fixes, with bounded adaptive continuation enabled by default for productive runs. Use when the user says "let's do three rounds", "fix/review loop", "back-and-forth review", "iterative review", or asks to harden a change with multiple rounds of codex/claude review.
---

# review-anvil — Iterative Multi-Agent Fix/Review Loop

Wrap a code change in **requested rounds of parallel reviewer subagents + orchestrator-applied fixes**. Each round = (parallel review by M agents, each with a distinct lens) → (you synthesize and **verify** findings) → (you apply fixes, run the build/test gate, commit) → next round. In productive `per_fix` runs, the orchestrator may continue adaptively after the requested rounds until convergence or `max_rounds`.

## Preset skills

This is the **engine**. Three preset skills in the same plugin pin common configurations; each is a separate `skills/<name>/SKILL.md` whose `description` triggers activation cross-agent.

| Preset | Pins | Intent |
|---|---|---|
| `review-anvil` (engine) | nothing | Default fix/commit loop, or any custom param combination. |
| `review-anvil-readonly` | `commit_mode=none`; default `rounds=1` | Read-only review — no edits, no commits. |
| `review-anvil-pr [<locator>]` | `commit_mode=none`, `target=<locator>`, `report_path=<file>` | Review a GitHub PR and post the report back as a PR comment (orchestrates `scripts/pr-helper.sh`). Locator auto-detected from the current branch when omitted. |
| `review-anvil-improve-pr [<locator>]` | `commit_mode=per_fix`, `target=<base>...HEAD`, `report_path=<file>` | Improve a checked-out PR: fix commits across requested rounds plus any adaptive continuation, then push. Targets the branch (not a PR locator), deliberately routing around the PR-target/per_fix rule below. |

## Parameters

Parse the user's free-form args string into:

| Param | Default | Plain-English forms |
|---|---|---|
| `rounds` | `3` | "5 rounds", "three rounds", "do 4 passes" |
| `max_rounds` | `per_fix`: `min(max(6, rounds), rounds + adaptive budget)` — budget 1/2/3 for small/medium/large diffs (see Parsing); `rounds` for `commit_mode=none` | "max 4 rounds", "allow one extra round", "3 rounds, continue if needed"; "exactly 3 rounds", "only 3 rounds", or "no extra rounds" keeps `max_rounds=rounds` |
| `agents` | `3` | "3 agents", "2 reviewers", or a mix like `"2 codex + 1 claude"` |
| `focus` | the four pillars (correctness, maintainability, simplicity, production blast-radius) | "focus on async correctness"; an `only:` prefix replaces the defaults instead of appending |
| `target` | auto-detect | "PR #42", "branch", "uncommitted", "src/auth/", "last 3 commits" |
| `allow_new_deps` | `false` | "allow new deps" — auto-apply fixes that introduce new imports/subsystems instead of deferring them |
| `min_fix_severity` | `medium` | "auto-fix high and above", "fix only critical" — minimum severity for auto-fix; lower findings are listed, not applied |
| `commit_mode` | `per_fix` | `per_fix` (one commit per fix-group) or `none` ("review only", "don't commit", "no fixes") |
| `approve` | `allowed` | "never approve", "comment only", `approve: never` — always write `{"event": "COMMENT"}` to `.approval.json`. Presets additionally export `REVIEW_ANVIL_NO_APPROVE=1` so the helper enforces it mechanically. Only meaningful for review-only PR runs |
| `reproduction` | `auto` | `auto`, `on`, or `off` — default-on batched reproduction of uncertain `medium`+ findings before auto-fix/reporting; "skip reproduction" disables it and marks single-reviewer material findings as unconfirmed |
| `adversarial` | `off` | `off`, `auto`, `challenge`, `targeted`, `full`, or `strict` — read-only post-synthesis review that attacks candidate findings and would-apply plans before they become final guidance |
| `adversarial_rounds` | `1` | one adversarial pass by default; max 2, and a second pass runs only when the first pass materially changes `medium`+ guidance |
| `disagreement_policy` | `defer` | `defer` moves unresolved material disputes to Deferred; `comment` keeps the finding actionable but forces review-only PR approvals to COMMENT |
| `verify_cmd` | auto-detect | "verify with `npm test`", `verify_cmd: none` to skip — build/test command run after each round's fixes (see "Build/test gate"; per_fix only) |
| `reviewer_timeout` | `600` (`420` for small diffs) | "timeout 10 minutes" — hard per-reviewer wall-clock cap in seconds for Bash-dispatched reviewers (see `run-reviewer.sh`). Default is ~3× the slowest legitimate reviewer observed in real runs (98–213s); when unset and the diff is under ~500 changed lines (added+removed — the same measure as the adaptive budget tiers), requested rounds use `420` (~2× that observed max) so a hung reviewer pins the wave 3 minutes less. Adaptive rounds always use the full base value — `600`, or `1200` after the >5000-line doubling (doubling transforms the base; the small-diff reduction never applies to adaptive rounds). Explicit user values are never scaled or doubled |
| `report_path` | unset | File path; when set, the engine writes the final report there (creating parent dirs) and prints exactly that path as its last output line so downstream consumers can pick it up |

### Parsing

- Split the args on top-level commas; canonicalize each segment to a `(param, value)` pair — explicit `key: value` maps directly, plain-English forms per the table. Unrecognized segments are noted and ignored.
- **First occurrence wins** per param; later duplicates are dropped with `warning: user-supplied <param>=<value> ignored — earlier value wins`. Unset params take defaults.
- Presets assemble `<pins>, <user-args>, <overridable defaults>`: pins come first so first-occurrence-wins makes them authoritative; defaults come last so user args beat them.
- **Pin-rejection (presets; defense in depth against the prose parser being talked into overrides):** before assembling, segment-split `$ARGUMENTS` as above, lowercase each segment's key (the text before its first `:`), and abort with `error: <param> is pinned by <preset-name> and cannot be overridden in args` if any key equals a pinned param. Match segment *keys*, never raw substrings — `focus: "target: PR safety"` has key `focus` and must pass. A host that cannot segment-split must abort (`error: pin-rejection unavailable in this environment; refusing to invoke engine without pin enforcement`), not degrade to substring scanning.
- `agents`: a count (use the mix table below) or an explicit mix naming `codex`/`codex-exec` / `claude`/`claude-exec` — honor a mix exactly.
- `target` auto-detect order: currently checked-out PR (e.g. `gh pr view --json number,headRefName`, a GitHub MCP query, or REST) → branch-vs-main diff (`git diff main...HEAD`) → uncommitted changes (`git diff` + `git diff --cached`). Empty args = all defaults.
- `rounds` is the requested count. Resolve `max_rounds` after `rounds`, the final `commit_mode` (including the PR-locator rule below), and the target: the `per_fix` default is `min(max(6, rounds), rounds + budget)`, where the adaptive budget scales with the target's changed-line count (added+removed in the materialized diff; materialize it once at resolution — `per_fix` targets are always local git diffs): under ~200 lines → `1`, up to ~1000 → `2`, above → `3`. The `min()` against the legacy `max(6, rounds)` cap makes the scaling a pure reduction: runs with `rounds >= 6` gain nothing. Default to `rounds` for `commit_mode=none`; reject `max_rounds < rounds`. Phrases like "allow one extra round" set `max_rounds=rounds+1`, and explicit caps like `max_rounds: 4` or "up to 4 rounds" set the cap directly. Phrases like "continue if needed" restore the legacy `max(6, rounds)` cap unless paired with an explicit cap. Phrases that constrain the round count itself — "exactly 3 rounds", "only 3 rounds", "3 rounds only", or "no extra rounds" — force `max_rounds=rounds`. Do **not** treat `only:` focus syntax or severity gates like "fix only critical" as exact-round requests.
- Adaptive continuation is on by default for `per_fix`. A plain "3 rounds" means `rounds=3` with `max_rounds` between `4` and `6` by diff size, so the organizing agent may continue after round 3 if §6 says another pass is justified. Use "exactly 3 rounds", "only 3 rounds", "no extra rounds", or `max_rounds: 3` when the run must stop at the requested count.
- If `commit_mode=none` and the user explicitly set `max_rounds > rounds`, warn and collapse `max_rounds` to `rounds`. Extra normal rounds review the same baseline, so use `rounds` for reviewer redundancy and `adversarial` for skeptical challenge.
- `reproduction=auto` and `reproduction=on` both run the selective batched reproduction gate in §3. `auto` may skip dispatch only when there are no candidates. `off` is allowed for speed, but the round summary and final report must say it was disabled; unconfirmed single-reviewer `medium`+ findings stay in Deferred unless the orchestrator independently reproduced them from code/tests/runtime evidence.
- `adversarial` applies only when `commit_mode=none`. If set with `per_fix`, warn and ignore it — productive mode already applies real fixes and gates them with the build/test command. Reject `adversarial_rounds > 2`; adversarial loops must be bounded. `auto` means choose the cheapest sufficient adversarial mode after normal synthesis using the default policy below.

### PR-target / per_fix incompatibility

If `target` is a GitHub PR locator (URL `https://<host>/<owner>/<repo>/pull/<N>`, slug `<owner>/<repo>#<N>`, or "PR #N"), the only valid `commit_mode` is `none`. Force it, and warn if the user asked for `per_fix`:

> `warning: PR locators are read-only — forcing commit_mode=none (use 'target: branch' to fix-and-commit on your checked-out PR branch).`

Reviewers of a PR locator see the GitHub-fetched diff, which may not match the local worktree; committing against a baseline the user can't see locally is unpredictable. Branch targets make the local tree the source of truth.

### Commit modes

- **`per_fix` (default)** — full loop: review → synthesize/reproduce/verify → apply fixes → build/test gate → commit, each round.
- **`none` (review-only)** — review → synthesize/reproduce/verify only. **No edits, no commits, no staging.** Read-only mode may write temporary prompt/reviewer/report artifacts under `.review-anvil/` and the explicit `report_path`; it must not modify source files, the index, commits, branches, or remotes. Every normal round reviews the same baseline, so `rounds > 1` buys reviewer redundancy, not code refinement; the natural default is `rounds=1`, and adaptive continuation is disabled by collapsing `max_rounds` to `rounds`. Skip Loop Mechanics §4 entirely; the round summary reads `Fixes applied: 0 (review-only)`; the auto-fix policy is still evaluated in the abstract so findings classify as would-apply / suggestions / deferred. Optional adversarial review is a separate post-synthesis gate that attacks finding validity and fix proportionality without pretending code changed.

### Posting reports externally

The engine never posts anywhere. Downstream consumers set `report_path`, let the engine write a GitHub-ready PR report, and post after it returns — `review-anvil-pr` + its `pr-helper.sh` is the reference implementation.

When `report_path` is set, optimize the report for a PR timeline reader, not for archival completeness. The per-round console output and reviewer artifacts are the transcript; the posted report is the decision summary plus the few findings that need action.
Adaptive continuation details belong in Run Details unless they change the review decision; do not paste per-round continuation reasoning into PR reports.

### Examples

- `Skill review-anvil` → 3 requested rounds, adaptive up to 4–6 total rounds by diff size, 2 codex + 1 claude, four-pillar focus, auto-detected target.
- `Skill review-anvil "5 rounds, 2 codex + 1 claude, focus: async correctness, target: PR #42"`
- `Skill review-anvil "3 rounds, max_rounds: 4"` → 3 requested rounds, then at most 1 adaptive round if the continuation policy allows it.
- `Skill review-anvil "1 round, only: security, target: src/auth/"`
- `Skill review-anvil "fix only critical"` → severity gate raised to `critical`; everything else surfaces as suggestions.
- `Skill review-anvil "target: PR #42, adversarial: auto"` → normal review first, then adversarial review only if the synthesized findings/fix plans need a validity or proportionality challenge.

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

Run the loop for the requested `rounds`, then continue adaptively up to
`max_rounds` only when §6 allows adaptive continuation. Within a round:

### 1. Snapshot the target

Capture the target's state at round start so all reviewers see the same input:

- Non-PR targets (branch, uncommitted, path): materialize the diff with the appropriate `git diff …`.
- PR targets (always `commit_mode=none`): fetch the PR's diff via `gh pr diff <N> -R <owner>/<repo>` (or equivalent MCP/REST). The local worktree is irrelevant — reviewers see the PR as it exists on GitHub.
- Whenever PR context is available — a PR-locator target, or a preset that supplies it (`review-anvil-improve-pr` does, after `verify-checkout`) — fetch the PR title/body/base branch/file list too, then infer the PR's intended scope in one sentence (e.g. "performance optimization in annotation seeding", "left-sidebar UX reorganization"). Put that scope in every reviewer prompt. A finding is actionable only if the PR introduces/regresses it or if it directly undermines the PR's stated purpose. Obvious, high-confidence pre-existing defects may be mentioned, but only under a separate "Out-of-scope follow-ups" section — never as blockers or inline actionable review comments for the current PR.
- Likewise gather the complete **PR review history** before dispatch: when a preset supplied the ledger (improve-pr captures it at verify-checkout time), use that; for PR-locator targets fetch it via `pr-helper.sh history <host> <owner> <repo> <n>` (ships with `review-anvil-pr`; threads, review bodies, and fallback comments are paginated and retried once). Include the status-tagged ledger in every reviewer prompt (PR REVIEW HISTORY block): `open` threads, `resolved` threads, `outdated` anchors, summary-only `reported` findings, prior `deferred`/`review-dismissed` items, and explicit local `suppressed` findings. Pending reviews are not shown to the author and are excluded. Before dispatch, semantically coalesce entries with the same root cause (summary wording often differs from its inline comment), retaining every source URL and state; explicit suppression wins, otherwise preserve all observed states. If lookup fails after retry, abort rather than review without prior feedback — unless the user opted into degraded mode (`REVIEW_ANVIL_SKIP_DISMISSED=1`), which also forces the review decision to COMMENT.
- Note `git rev-parse HEAD` so the round summary can reference the exact baseline (informational-only for PR targets).

### 2. Dispatch reviewers in parallel

#### In Claude Code (the primary host)

**Use the Agent tool for `claude-exec` reviewers. Do NOT use `claude -p` via Bash — that path is for non-Claude hosts only.**

- **`claude-exec`**: Agent tool, `subagent_type: "general-purpose"`, the assembled Reviewer Prompt as `prompt`, `run_in_background: true`. The Agent tool streams natively, has no `--max-turns` ceiling, and inherits the session environment.
- **`codex-exec`**: Bash through the wrapper: `REVIEW_ANVIL_REQUIRE_FINDINGS=1 bash <wrapper> .review-anvil/round<N>-<label>.md <reviewer_timeout> -- codex exec --ephemeral --sandbox read-only -C <project-dir> '<prompt>' < /dev/null`, with `run_in_background: true`. The validation flag makes the wrapper reject confirmation-only, plan-only, or otherwise incomplete responses that do not end with the required fenced findings block. `--ephemeral` prevents reviewer sessions from leaking into later dispatches. The `< /dev/null` is load-bearing: codex takes its prompt as argv and must not inherit an open stdin — the wrapper passes its stdin through (`<&0`, which the claude fallback needs), and codex blocking on a never-closing fd 0 is a known hang class from real runs.
- Send all M reviewers in a *single message* with multiple tool calls. The harness notifies you on completion; do not poll.

#### In Codex CLI or other hosts without the Agent tool

- **`claude-exec`**: write the assembled prompt to a file, then:

  ```bash
  REVIEW_ANVIL_REQUIRE_FINDINGS=1 bash <wrapper> .review-anvil/round<N>-<label>.md <reviewer_timeout> -- \
    claude -p --max-turns 100 --no-session-persistence \
      --permission-mode dontAsk --output-format text \
      --tools "Bash,Read,Glob,Grep" \
      --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" \
    < .review-anvil/round<N>-<label>.prompt.md
  ```

  `--tools` restricts the built-in tool set; `--allowedTools` auto-approves the listed safe tool uses and is variadic, so the prompt MUST arrive via stdin (the wrapper passes its stdin through). `--permission-mode dontAsk` keeps the fallback non-interactive by denying anything outside the allowed/read-only path. **Do not size `--max-turns` to the task** — task-sized caps keep biting (20 was hit in production), and a reviewer that hits the cap loses its entire output. The wrapper's wall-clock timeout is the real bound; `100` is a runaway backstop that should never bind.

- **`codex-exec`**: same validation-enabled wrapper around `codex exec --ephemeral --sandbox read-only -C <project-dir> '<prompt>' < /dev/null` — stdin from `/dev/null` here too.
- Launch all M wrapper invocations as background shell processes and `wait`.

#### Bash-dispatched reviewers MUST go through `run-reviewer.sh`

Every shell-dispatched reviewer (codex-exec everywhere; claude-exec outside Claude Code) runs under `scripts/run-reviewer.sh` (next to this SKILL.md). **Never background a bare `claude -p ... > out.md 2>&1` and wait on the file** — in text mode nothing prints until the final answer, so a hung reviewer and a working one are both a 0-byte file (a production run waited on exactly that for many minutes). The wrapper:

```
run-reviewer.sh <out_file> <timeout_seconds> -- <command> [args...]
```

- Hard wall-clock timeout (`reviewer_timeout`, default 600s): TERM at the deadline, KILL 30s later.
- Captures exit status; stderr goes to `<out_file>.err` (kept for diagnosis).
- Prints one classification: `STATUS=ok` | `timeout` | `empty` (exit 0, nothing written) | `protocol` (normal-review output did not end with a complete fenced findings block) | `failed` (+ `EXIT_CODE=<n>`).

Treat any STATUS other than `ok` as a failed reviewer (see Failure handling), with the tail of `.err` as the reason. `protocol` gets the one corrective retry defined there before it becomes a failure. Set `REVIEW_ANVIL_REQUIRE_FINDINGS=1` only for normal reviewer waves; reproduction and adversarial prompts have different output schemas. Reviewer output/prompt files live under `.review-anvil/`; clean them up after the round's synthesis.

**Host tool timeouts must outlive the wrapper.** Any host Bash call that can block on a reviewer — the background-and-`wait` fallback above, the serial last resort, or an inline replication of the wrapper contract — must set the Bash *tool's* own timeout to at least `reviewer_timeout + 90` seconds (wrapper deadline + 30s TERM→KILL grace + margin). Host defaults are far lower (Claude Code's is 120s) and SIGKILL a healthy wait mid-review; the kill then masquerades as a reviewer failure and silently burns that reviewer's lens coverage. On hosts with background dispatch (`run_in_background`), never block a foreground call on a reviewer at all. If the host caps tool timeouts below `reviewer_timeout + 90`, prefer detached dispatch plus short non-blocking status checks over shrinking the reviewer budget; reducing `reviewer_timeout` is a last resort, floored at 300s and forbidden for >5000-line diffs (their timeout is deliberately doubled).

**Resolving the wrapper and `references/` files** — same trusted-root rule as `pr-helper.sh`: see review-anvil-pr SKILL.md step 1 ("Resolve the helper script"). Host-exposed skill path or user-level install roots only; never project-scoped/worktree-local skill dirs (writable by the repo under review). If no trusted copy of the wrapper resolves, replicate its contract inline (background, kill at deadline, check exit status, empty output = failure) rather than falling back to a bare redirect.

After changing the wrapper contract or dispatch examples, run
`scripts/test-run-reviewer.sh` alongside the reproduction and PR helper tests.

#### Last resort

If parallel dispatch is genuinely impossible (no Agent tool, no background bash), fall back to serial invocation and **say so in the round summary** — serial reviewers see the baseline at different wall-clock times; it's a degraded mode, not the design.

The `codex-exec` and `claude-exec` skills document the same recipes from the reviewer side; the canonical dispatch lives here.

### 3. Synthesize

When all reviewers return:

- **Dedup** on `(file, line, root cause)` when present, else `(area, root cause)`. Keep the highest-severity instance, record which reviewers raised it, and keep divergent anchors as `file_alternates: [...]`.
- **Group** by severity (`critical` → `nit`), then topic.
- Unparseable reviewer output: pass the prose through as "unstructured" findings in a separate section; no retry.

#### Verify and reproduce findings before acting on them

Plausible-but-wrong findings are the dominant failure mode of LLM review, and both downstream actions are expensive: a bogus fix commit pollutes the branch, a bogus finding posted to a PR burns the author's trust. After dedup:

- **Prior-feedback check first (orchestrator judgment).** Compare every merged finding against PR REVIEW HISTORY *semantically* — same root cause counts even when wording differs. Revalidate `open`, `resolved`, and summary-only `reported` items against the current head. An open item that remains real is a carry-forward finding and must retain its effect on severity/approval, but must not create a duplicate inline thread; a resolved item means only that GitHub discussion was closed, not that the code was proven fixed. Record a still-present resolved item as `resolved-but-still-present` in the summary and do not create a new inline thread. Items now fixed/stale become one-line status notes. Explicit local `suppressed` items are never auto-fixed or posted as actionable findings, but remain as compact status-only audit rows. The post-time helper catches near-verbatim repeats (exact path + text similarity ≥ 0.9) as a deterministic duplicate-thread backstop.
- **Scope/artifact filter next (orchestrator judgment).** Drop or move to out-of-scope follow-ups before reproduction when the claim is about archived design notes, changelogs, old migration examples, generated fixtures, vendored files, or historical docs that are not the review's live product surface. Do not spend verifier budget proving historical provenance is stale. Conversely, live docs that users rely on — README usage, CLI help, API docs, config reference, plugin metadata, or marketplace copy — are product surface and may become reproduction candidates when they drift from code/runtime behavior.
- Assign stable report-local IDs before reproduction/adversarial dispatch: findings are `RAVF001`, `RAVF002`, ... and would-apply plans are `RAVW001`, `RAVW002`, ... . The canonical grammar is `RAV([FW])([0-9]{3,})`; the PR helper may accept legacy dashed IDs like `F-001` / `W-001` at parsing boundaries, but new reports should emit only the canonical no-punctuation form.
- Build `REPRODUCTION CANDIDATES` after prior-feedback classification and ID assignment:
  - every `medium`+ finding raised by exactly one reviewer,
  - every `medium`+ deletion/dead-code/unused/redundant-code/simplification finding, and any deletion/simplification that would remove runtime code, public docs/API, compatibility behavior, or another high-blast-radius surface, regardless of reviewer count,
  - every `critical`/`high` finding whose evidence is mostly inferred from a hunk rather than confirmed from code/runtime context,
  - every finding the orchestrator is materially uncertain about after reading the cited files.
- When `reproduction=auto` or `on` and candidates exist, dispatch **one batched reproduction verifier** using `references/reproduction-prompt.md`. Do not spawn one verifier per finding unless the batch is too large to fit in one prompt. Dispatch it backgrounded under the Concurrency section's deadline rule — never an unbounded foreground wait. The verifier is not another broad review pass; it returns `confirmed`, `refuted`, `unclear`, `narrowed`, or `downgraded` verdicts for supplied `RAVF###` IDs only.
- Apply reproduction verdicts before auto-fix/reporting:
  - `confirmed` and `narrowed` findings may remain actionable, with narrowed wording when supplied.
  - `downgraded` findings re-enter the normal severity gates after changing severity.
  - `refuted` findings are dropped from final Findings (or, if useful for transparency, one-line Deferred notes).
  - `unclear` findings move to Deferred with `We set this aside because <plain-language description of the missing proof>.` Rewrite the verifier's reason; do not copy it.
- Findings raised independently by **2+ reviewers** and not listed as reproduction candidates may skip batched reproduction; consensus is the signal (this is why dedup records who raised what). Still open enough code/context before destructive action to ensure the fix path is coherent.
- **Deletions ("delete this"/dead/unused/redundant) require reproduction plus execution when `per_fix` applies the cut** — the highest-blast-radius, highest-false-positive class. In `per_fix`, after reproduction confirms the cut, apply it and run the full test suite: a **red gate means keep it**. A green gate is necessary but not sufficient (it only proves *test-covered* behavior), so the reproduction/skeptic pass must also look for a concrete reason the code must stay, visible in the diff (trust boundary, aliasing copy, ordering, back-compat, dedup, edge semantics — or another specific contract). The two cover different blind spots: the gate catches callers the skeptic can't see; the skeptic catches behavior no test exercises. Block **only** on a red gate or a specific skeptic refutation — not on generic "there might be an unseen caller" (that's what the gate tests). Read-only mode has only the skeptic. Blocked → **Deferred** (`failed reproduction: still needed — <what>`).
- If `reproduction=off`, say so in the round summary and final report. Required reproduction candidates — including single-reviewer `medium`+ findings, deletion/high-risk findings, and orchestrator-uncertain findings — cannot become actionable unless the orchestrator independently reproduces them from code/tests/runtime evidence; otherwise move them to Deferred with `We set this aside because the needed check was not run.`
- `low`/`nit` findings skip verification: they're below the auto-fix gate and surface as suggestions either way.

Canonical examples for where reproduction helps and where it must stay out of
the way live in `references/reproduction-examples.md`. After changing this
policy or the reproduction prompt, run `scripts/test-reproduction-policy.sh`
alongside the PR helper tests.

#### Approving out-of-scope follow-ups

A pre-existing issue outside the PR's scope can still be worth noting, but it must not become an inline/blocking PR finding. Classify each out-of-scope follow-up:

- **Auto-approved follow-up** — create/queue separate work when all are true: severity is `critical`/`high` (or clearly reproducible `medium`), the bug is confirmed from code/tests/runtime evidence, it is not a product decision/style preference, it is not already tracked in prior PR feedback or explicitly suppressed, and the fix is plausibly separable from the current PR.
- **Needs human triage** — mention only as a non-blocking follow-up when the issue is real but severity/ownership/product intent is ambiguous.
- **Do not surface** — drop if speculative, low/nit, a product decision, already dismissed/tracked, or only discoverable by reviewing unrelated code paths deeply.

When `report_path` is set, write follow-ups once, after the final round, to `<report_path>.followups.json` — schema in `references/report-artifacts.md`. Automation may file issues only for `auto_approved` entries after duplicate search; presets read the file before posting (the helper deletes it afterwards).

#### Optional adversarial review (`commit_mode=none` only)

When `adversarial` is not `off`, run a bounded post-synthesis gate after
dedup/reproduction and before writing the final report artifacts. Read
`references/adversarial-prompt.md` before dispatching adversarial reviewers.
Dispatch every adversary of the selected mode in parallel — one message,
multiple background tool calls, exactly like §2 reviewers, under the
Concurrency section's deadline rule — and synthesize verdicts when all return
or the deadline fires. Never await one adversary before launching the next.

Adversarial review is not another broad review pass and not a simulated patch
application. It attacks the candidate synthesis:

- **Finding validity** — false-positive claims, wrong anchors, dismissed
  findings, out-of-scope issues, over-severity, and missing reachability
  evidence.
- **Fix proportionality** — suggested fixes that would technically address a
  problem but create more trouble than they solve: harmful blast radius,
  unnecessary dependencies, bloated abstractions, future tech debt, non-local
  churn, unsafe deletions, brittle tests, or symptom fixes that miss root cause.
- **Report safety** — unsafe one-click GitHub suggestions, unclear fix paths,
  overconfident approvals, and actionable comments that should be deferred.

Modes:

| Mode | Dispatch | Intent |
|---|---|---|
| `auto` | Chosen after synthesis | Selects `off`, `challenge`, `targeted`, or `strict` using the default policy below. |
| `challenge` | 1 adversary | Cheap local check over all `medium`+ findings and would-apply plans. |
| `targeted` | 2 adversaries | Recommended PR mode: false-positive/scope auditor + fix-plan breaker. Force a deletion skeptic when any would-apply item removes code. |
| `full` | 3 adversaries | Adds second-order bug hunting across interacting plans, config, migrations, and tests. |
| `strict` | Same as `full` | Approval-sensitive: any required adversary failure or unresolved `high`+ dispute forces COMMENT. |

Role mapping:

- `challenge`: one combined adversary using the core prompt plus both the
  `false-positive-scope-auditor` and `fix-plan-breaker` role additions.
- `targeted`: two adversaries, one `false-positive-scope-auditor` and one
  `fix-plan-breaker`; add/replace with the deletion skeptic behavior from
  `fix-plan-breaker` when any would-apply plan removes code.
- `full`/`strict`: `false-positive-scope-auditor`, `fix-plan-breaker`, and
  `second-order-bug-hunter`; add `report-auditor` only if the report/approval
  artifact itself is the risky surface.

Default policy:

- Local `review-anvil-readonly` defaults to `off`. If the user asks for careful,
  skeptical, high-confidence, low-noise, or thorough read-only review, the
  orchestrator should append `adversarial: auto` unless the user explicitly
  asked for a fast/rough pass.
- `review-anvil-pr` defaults to `adversarial: auto` because GitHub output is
  public reviewer speech and may include inline comments, one-click
  suggestions, or an approval event.
- Explicit user input wins: `adversarial: off` disables the gate; explicit
  `challenge`/`targeted`/`full`/`strict` uses that mode. In review-only PR runs,
  explicit `adversarial: off` also forces `.approval.json` to `{"event":
  "COMMENT"}`; unchallenged LLM review should not satisfy branch protection by
  accident.

`auto` selection after normal synthesis:

- First estimate **meaningful changed size** from the reviewed snapshot. Exclude
  generated/vendor/build artifacts, lockfiles, and snapshot/fixture churn unless
  those files are the review's product surface. Treat `>1000` meaningful changed
  lines or `>20` meaningful files as large, and `>5000` meaningful changed
  lines, `>50` meaningful files, or several interacting subsystems as very
  large. Size is an escalation floor, not the only signal: a small risky auth or
  migration diff can still choose `targeted`, while a huge mechanical rename
  may stay below `full` after exclusions.
- Use `off` only when approval is disabled/impossible and the result is clean
  or low/nit-only, has no `medium`+ inline comments, no GitHub suggestion
  blocks, no `critical`/`high` actionable or deferred author-action items, and
  no would-apply plan with deletion, dependency, non-local behavior, or
  abstraction/churn risk. For local non-PR runs, ignore the approval condition.
- Use `challenge` for small or self-authored comment-only reviews with material
  feedback but no suggestion blocks, no high-risk fix plans, and `approve:
  never` / `REVIEW_ANVIL_NO_APPROVE=1`.
- Use `targeted` when candidate output includes any `medium`+ inline comment,
  any GitHub suggestion block, any `critical`/`high` actionable/deferred item,
  any would-apply plan that removes code, adds dependencies, changes behavior
  non-locally, touches auth/security/data/schema/migrations/concurrency/config,
  or looks like abstraction/tech-debt risk, or when open/resolved prior PR
  feedback touches the same files/root causes, or when the diff is large by
  meaningful changed size.
- Use `full` when the meaningful diff is very large or cross-cutting across
  several subsystems, unless exclusions show it is mostly mechanical/generated
  churn. `full` adds second-order plan scrutiny without making approval more
  brittle by itself.
- Use `strict` only when the user explicitly asks for approval-sensitive
  behavior or branch protection / CODEOWNER requirements are confirmed. If any
  required adversary fails, times out, or returns unparseable output in `strict`,
  force `COMMENT`. Do not escalate to `strict` merely because branch protection
  is unknown; use `targeted` and force `COMMENT` if approval safety cannot be
  established.

Build would-apply plans from the same fix groups `per_fix` would have
committed: each plan lists covered finding IDs, the simulated conventional-
commit subject, the intended fix path, risk tags such as
`deletion`/`dependency`/`non-local`/`abstraction`, and any exact suggestion
blocks that would be emitted. For local non-PR reviews, set
`CANDIDATE APPROVAL` to `not-applicable`; for PR/report-path reviews, set it to
the tentative `.approval.json` event/reason. Adversarial reviewers return
verdicts against those IDs using the schema in `adversarial-prompt.md`.

Apply verdicts conservatively:

- `drop` only when concrete evidence shows a false positive, dismissed finding,
  or out-of-scope claim.
- `defer` when the issue may be real but the proposed fix is harmful,
  bloated, tech-debt-heavy, too non-local, or disproportionate for this PR.
- `modify` to harden or simplify the prose fix path while keeping the finding
  actionable.
- `uphold` when the finding and fix path survive challenge.

Generic uncertainty does **not** defer a finding. The adversary must cite code,
configuration, tests, runtime behavior, status-aware PR feedback, or PR scope
evidence. Adversaries must not create new actionable findings. If they notice a
new issue while attacking a `RAVW###` plan, record it only as a second-order plan
risk or follow-up; it remains Deferred unless the orchestrator runs a separate
normal review/verification pass.

Adversarial review may make the output more conservative. It must never make a
speculative fix more authoritative. It can strip unsafe `"suggestion"` fields
from `.inline.json`, move items to Deferred, harden/simplify fix prose, or
downgrade approval. It must not create patches, commits, or final actionable
findings from unverified adversarial ideas.

Run at most `adversarial_rounds` passes, capped at 2. A second adversarial pass
runs only when the first pass materially changes `medium`+ guidance, changes
approval, or rewrites a would-apply plan. `RAVW###` verdicts affect fix plans,
suggestions, and fix prose only; linked `RAVF###` findings change only when an
independent `RAVF###` verdict refutes or defers them. With
`disagreement_policy=defer`, unresolved `medium` adversarial disputes move the
item to Deferred but do not by themselves block `APPROVE`; unresolved
`critical`/`high` disputes block `APPROVE`. With
`disagreement_policy=comment`, unresolved `medium`+ disputes keep the item
actionable but force the review event to `COMMENT`.

### 4. Apply fixes

**Skip entirely when `commit_mode=none`** (the policy below is still evaluated in the abstract for the report).

Otherwise **read `references/fix-application.md` before making any edit**: it defines the conventional-commit fix-group style, the auto-fix proportionality rules (severity gate >= `min_fix_severity`; no new dependencies without `allow_new_deps`; per-round size cap; noise is deferred with a reason, never silently dropped), and the build/test gate (`verify_cmd` resolution, baseline run, fix-forward-or-revert, revert-failure escalation). The invariant: **a round never ends with the build/test gate newly red**.

### 5. Round summary

Append to running output:

```
### Round N — <convergence flag>
- Parameters: rounds=3, max_rounds=3, target=acme/widgets#42 [pin], commit_mode=none [pin], focus=4-pillar
- Reviewers: <list dispatched>
- Earlier review comments: none | <open> open, <resolved> closed, <reported> summary-only, <suppressed> skipped; <still-present>/<fixed>/<stale> after checking
- What I noticed: C critical, H high, M medium, L low, N nit
- Fixes applied: K commits (<sha1>..<shaN>)   # or "0 (review-only)"
- Verification: <cmd> — passed | failed → round reverted | pre-existing failures (no new) | none detected | skipped   # per_fix only
- Checks: off | skipped (no findings needed checking) | <C> concerns checked, <confirmed> confirmed, <refuted> ruled out, <deferred> set aside, <downgraded> lowered in priority; <elapsed>
- Things to try: W items                         # commit_mode=none only
- Second check: off | <mode>, <A> reviewers, <upheld> kept, <hardened> clarified, <deferred> set aside, <dropped> removed
- Other notes: S items (low-priority items; not applied)
- Set aside: D items (reasons: noise / new dependency / size cap / not confirmed / failed verification / product decision)
- More rounds: off | not continued because <reason> | continued to round <next_round> because <reason>; cap=<max_rounds>
```

Pinned params carry `[pin]` (authority comes from preset argument order; the PR-target/per_fix rule is the final safety net). Convergence flag: `clean` (no findings), `nits_only` (nothing above `low`), `material_findings` (≥1 medium+).

### 6. Continue or finish

If completed rounds are still below `rounds`, start the next requested round;
round N+1 reviews the new state including round N's commits.

**Early exit on convergence (`per_fix` only).** A `clean` or `nits_only`
round ends the loop even if requested or adaptive rounds remain — further
rounds re-review converged code and mostly produce noise. Note this in Run
Details, e.g. `Rounds: N completed (R requested + A adaptive, max M); converged
after round N of R requested`. (In `commit_mode=none`, multi-round = reviewer
redundancy over the same baseline; no early exit and no adaptive continuation.)

**Adaptive continuation (`per_fix` only).** After the requested `rounds` are
complete, the orchestrator may start one more round only while
`completed_rounds < max_rounds` and all continuation criteria hold:

- The latest round was `material_findings` and produced at least one **new**
  material finding. New = not raised in any earlier round, or a
  reproduction-confirmed re-detection of a finding a previous round fixed and
  verified (evidence the fix failed — the core case continuation exists for).
  Unconfirmed or refuted re-detections and items already Deferred do not count.
- The latest round applied at least one verified fix commit, or changed a
  risky/shared surface where another pass is likely to catch second-order bugs.
- Verification for the latest round ended `passed`; `skipped`, `none detected`,
  `pre-existing failures (no new)`, and `failed → round reverted` are acceptable
  for requested rounds but not strong enough to justify extra automatic work.
- All expected reviewers succeeded with parseable output. Degraded reviewer
  signal can finish requested rounds, but it must not trigger adaptive rounds.
  During an adaptive round, this is a hard gate before §4: any reviewer failure,
  timeout, empty output, or unparseable findings block stops the run before
  applying fixes from that adaptive round, writes a failure report when
  `report_path` is set, and prevents improve-PR pushes.
- The remaining risk is likely to converge with another review/fix pass. Do not
  extend for low/nit-only feedback, suggestions below `min_fix_severity`, items
  already Deferred, product decisions, new-dependency deferrals, size-cap
  deferrals, or repeated findings that were not fixed.

Record the continuation decision in the final requested round's summary and in
the adaptive round summary when one runs. If an adaptive round still has
`material_findings` and hits `max_rounds`, finish and use the tuning suggestion
rule; do not keep extending without a larger explicit cap.

After the final round, emit the **Final Report** (Output Format). If `report_path` is set:

1. Write the rendered PR report there (creating parent dirs).
2. Write a sibling `<report_path>.inline.json`: an array of GitHub PR review comment payloads for findings with both `file` and `line` —

   ```json
   [
     {"path": "src/auth.ts", "line": 50, "side": "RIGHT", "severity": "high", "body": "**[high] auth** — Refresh creates a session before CSRF validation\n\nThe handler rotates the session before it checks the state token. A stale tab can create a new session with an invalid token.\n\nWe could check the state token before rotating the session. A missing-state-token test would cover this path."},
     {"path": "src/db.ts", "start_line": 100, "line": 110, "side": "RIGHT", "start_side": "RIGHT", "severity": "medium", "body": "**[medium] db** — Retry accounting records success before the write succeeds\n\nThe retry block increments `attempts_succeeded` before `insert_event` returns. A timeout records success even when no row was written.\n\nOne option is to increment the counter only after `insert_event` succeeds. A timeout test would cover this path.", "suggestion": "result = insert_event(payload)\nattempts_succeeded += 1\nreturn result"}
   ]
   ```

   Single line → `{"line": N, "side": "RIGHT"}`; range `<N>-<M>` → `{"start_line": N, "line": M, "side": "RIGHT", "start_side": "RIGHT"}`. Findings without anchors stay in the markdown body only; no anchored findings → `[]`. A reader must be able to create the fix from each `body` alone.

   Include helper-only `"severity"` for every inline item. The posting helper strips it before calling GitHub and uses it to keep low/nit findings summary-only by default. Include helper-only `"suggestion"` only when the fix is an exact replacement for the commented line/range; the helper turns it into a GitHub suggestion fenced block and strips the extra key before posting. Do not include suggestions for design fixes, cross-file edits, deleted lines, anything that requires judgment, or any suggestion whose anchor/replacement/blast-radius was disputed by adversarial review.

   Each `body` follows the **inline-comment voice** in `references/report-artifacts.md` — read it before composing bodies. Keep it short and plain: say what the code does, what happens because of it, and a friendly next step. A reader must be able to act without reopening the diff. Include a safe exact `"suggestion"` or a short code sketch only when it removes doubt. By default, inline comments are for `critical`/`high`/`medium` anchored findings; `low`/`nit` findings remain in the top-level summary unless the user or environment lowers `REVIEW_ANVIL_INLINE_MIN_SEVERITY`. The same voice applies to the report's Things to try, Set aside, and Outside this change prose.

3. Write a sibling `<report_path>.approval.json` so the PR-posting helper can choose the GitHub review event (review-only PR runs; for other runs write `{"event": "COMMENT"}` or omit the file — the helper defaults to COMMENT):

   ```json
   {
     "event": "APPROVE | COMMENT",
     "head_sha": "<the HEAD_SHA the preset captured at init/verify-checkout>",
     "adversarial_mode": "off | auto | challenge | targeted | full | strict",
     "approval_allowed": true,
     "reason": "No high/critical in-scope findings; medium-and-lower items are left to the author."
   }
   ```

   Include `"head_sha"` — the `HEAD_SHA` the preset captured at init/verify-checkout time — so the posting helper can verify the approval still matches the reviewed state (it downgrades to COMMENT if the PR head moved mid-run). Include `"adversarial_mode"` and set `"approval_allowed": false` when approval must be mechanically disabled (for example explicit `adversarial: off` in a PR run).

   Use `APPROVE` for review-only PR runs when all of these hold: `approve` is not `never`, at least one reviewer succeeded, there are no `critical`/`high` actionable in-scope findings, no `critical`/`high` in-scope deferred finding needs author action, no prior `critical`/`high` open or resolved-but-still-present item remains unaddressed, no unresolved `critical`/`high` adversarial dispute remains, and remaining items are only `medium`/`low`/`nit` findings, suggestions, deferred notes, or out-of-scope follow-ups. Medium-and-lower in-scope findings should still be posted clearly, but the review event is approval: leave those fixes to the author. Use `COMMENT` otherwise. Out-of-scope follow-ups do not block approval.
4. Print the report path as the last output line; the `.inline.json` and `.approval.json` files are implied by convention.
5. For out-of-scope follow-ups, write the sibling `<report_path>.followups.json` once, after the final round, using the follow-ups schema from §3 "Approving out-of-scope follow-ups" (NOT the `.approval.json` schema above). The posting helper deletes it after a successful post, so any consumer (surfacing follow-ups to the user, filing issues for `auto_approved` entries after duplicate search) must read it **before** the post/post-update step — the presets do this.

### Failure handling

- A reviewer fails or times out in a requested round → log `<agent>: failed (<reason>)` in the round summary and proceed; no retries except the protocol-only case below. For Bash-dispatched reviewers, failure = wrapper STATUS `timeout`/`empty`/`failed`, reason = tail of `.err`; `protocol` follows the next rule. In an adaptive round, any reviewer failure is an abort before fixes from that round are applied.
- **Protocol-only corrective retry:** a non-empty response that asks for confirmation, emits only a plan/status update, or otherwise omits the complete fenced findings block is not review output. Bash reviewers surface this as `STATUS=protocol`; detect the same shape directly for Agent-tool reviewers. Re-dispatch that reviewer exactly once on the same snapshot and lens with this prefix: `PROTOCOL RETRY: Begin the already-authorized read-only review immediately. Do not ask for confirmation or present a plan. Return the completed review now and end with the required fenced findings block.` Do not answer the confirmation request and do not count the first attempt as a reviewer result. If the retry also violates the protocol, record the reviewer as failed (`confirmation/plan-only output after corrective retry`) and follow the normal requested/adaptive-round failure rules. This is the only content-level retry; do not retry weak, clean, or merely unstructured reviews.
- A dispatch call — foreground or background — that dies with exit 143 or ends with **no `STATUS=` line** in its output was killed by the *host tool's* timeout before the wrapper could classify — misconfigured dispatch (see §2 "Host tool timeouts"), not a reviewer failure. Fix the dispatch mode (raise the tool timeout or go detached) and re-dispatch that reviewer exactly once; only a second identical death counts as a failed reviewer.
- **All** reviewers fail → abort the loop and report. Never carry on with zero findings — that's a misleading clean signal.
- `git commit` fails (hook, conflict) → surface the error, stop the loop, leave partial fixes in the worktree. Never `--no-verify`, never amend earlier commits.
- **On any abort, if `report_path` is set, write a failure report to it before stopping** — the usual header block, a `## Failure` section stating what happened and at which round, plus any completed round summaries. Downstream consumers (`review-anvil-improve-pr`'s post-update step) depend on the file existing on every exit path, success or failure. Write `{"event": "COMMENT"}` to `.approval.json` in this case.

### Concurrency

Within a round: parallel (single multi-tool-call message). Between rounds: strictly sequential.

Synthesis-side dispatches — the batched reproduction verifier and every adversary — follow the same parallel rule (all agents of a pass launched backgrounded in one message, never serially awaited) and get a hard deadline equal to the **effective** `reviewer_timeout` (after any >5000-line doubling):

- Bash dispatches enforce the deadline mechanically: run them under `run-reviewer.sh` with that cap.
- Agent-tool dispatches have no built-in timeout — the source of a production run hanging forever at "awaiting verdicts". Give each dispatch wave exactly **one** one-shot deadline alarm: a single background `sleep <cap>` Bash task launched in the same message as the agents, killed as soon as they all return. When the alarm fires first, salvage every complete per-ID verdict already present in output files, apply the Edge Cases rows to whatever is missing (reproduction verifier failure → safe-side Deferred; adversary failure → continue and note; `strict` → COMMENT), and record `timed out at <cap>s` in Run Details.

No recurring or polling timers: the harness notifies on completion, so the one-shot alarm above is the only sanctioned wakeup. After the final report is emitted (and its path printed, when `report_path` is set), kill any still-pending alarm — nothing may fire after completion.

## Reviewer Prompt Template

**Read `references/reviewer-prompt.md` (next to this SKILL.md; same trusted-root resolution as scripts) at dispatch time.** It defines the per-reviewer lens assignment (the four pillars partition across reviewers — M identical prompts buy redundancy and dedup work, not coverage), the context block (TARGET / PRIOR ROUNDS / SCOPE OF THIS REVIEW / PR REVIEW HISTORY / YOUR LENS), the fixed task block (review principles, severity guide, structured finding keys, the fenced findings-YAML output contract), and the fill-in rules (itemized PRIOR ROUNDS construction; `commit_mode=none` variations). Reviewers return prose findings only — never patches.

When `adversarial` is enabled, normal reviewers still use `reviewer-prompt.md`.
When `reproduction` dispatches, the verifier uses
`references/reproduction-prompt.md` and receives only the stable candidate
finding IDs selected by synthesis. The post-synthesis adversaries use
`references/adversarial-prompt.md` and receive the surviving stable candidate
finding / would-apply IDs produced by synthesis and reproduction.

## Output Format

During execution: print `Round 2/3: dispatching 2 codex-exec + 1 claude-exec on PR #42 …` before requested rounds, or `Round 4 (adaptive; requested 3, max 4): dispatching …` for adaptive rounds, then the round summary block (§5) after.

### Final report

After the last round, emit a fresh top-level report (a new document, not a replacement for the per-round blocks).

The final report is an external-facing decision summary. It must include every finding, but it should read like a scan-friendly index, not a transcript. Do not paste raw reviewer output, full round transcripts, repeated metadata, or paragraph-sized low-priority notes. Put each finding in exactly one focused row or bullet, grouped by severity/priority. Keep the decision, result, scope, and actionable critical/high/medium findings visible. Use progressive disclosure for supporting detail whenever the destination supports it: GitHub uses collapsed `<details>` blocks; other destinations should use their native disclosure controls. If the destination cannot collapse content, post a concise decision summary and preserve the complete report in an attached artifact or stable link. Never hide blockers only in an expandable section. If the report feels too bulky, rewrite and organize it yourself; do not depend on the posting helper to compact or shorten it.

```
# ⚒️ review-anvil report

**Review decision:** APPROVE | COMMENT — <one-sentence reason>   # review-only PR runs
**Result:** <one sentence: blockers/non-blockers/fixes/verification outcome>
**Scope:** <For PR targets: one sentence summarizing what this PR is trying to change.>
**Verification:** <verify_cmd used, or "none detected" / "skipped">   # per_fix only
**Checks:** off | skipped (no findings needed checking) | <C> concerns checked; <confirmed> confirmed, <refuted> ruled out, <deferred> set aside, <downgraded> lowered in priority
**Second check:** off | <mode>, <A> reviewers; <upheld> kept, <hardened> clarified, <deferred> set aside, <dropped> removed

## Earlier review comments
<For PR-context runs, list each earlier comment once as open, still present after
being marked resolved, fixed, no longer relevant, or intentionally skipped.
Keep its original URL and short reason. Omit this section for non-PR runs.
These rows affect the review decision even when no new inline comment is
needed. Keep 1-3 rows visible; for 4+ rows use a collapsed block with summary
`Earlier review comments (N items)`. Preserve the exact internal status in the
artifact; write the visible explanation in plain language.>

## What I noticed
<Show every confirmed issue once. Critical/high issues go first, then medium,
then low/nit. Start with the facts: what the code does and what happens because
of it. Inline comments carry supporting evidence and a friendly next step when
useful. Otherwise, add the smallest supporting fact to what you noticed. If
none: "No confirmed problems found.">

| ID | Priority | Topic | Code location | What I noticed |
|---|---|---|---|---|
| RAVF001 | high | auth | `src/auth.ts:42` | Refresh creates a session before it checks CSRF validation |

<If the table would be hard to read, use grouped bullets instead:>

- **[high] auth** `src/auth.ts:42` — Refresh creates a session before it checks CSRF validation. (`RAVF001`; inline)

<details>
<summary>Non-blocking low/nit findings</summary>

- **[low] docs** — The CLI help could use the same option name.
- **[nit] tests** — One option is to share the duplicate fixture setup.

</details>

## Changes made / Things to try
<For per_fix: focused commit list or "No fixes were made." For review-only:
include each thing to try as one short, plain-language behavior change. In
external reports, collapse this section when it contains more than 3 items.>

- `<sha>` — <subject>                         # per_fix only
- **[severity] area** — We could <plain-language behavior change>. (`RAVF001`)   # commit_mode=none only

## Set aside / Outside this change
<Include each item not addressed here in one line. Collapse this section when
it contains more than 3 items. Omit it when empty.>

- **[severity] area** — set aside because <reason>.
- **[medium] config** — set aside after the second check: the fix is too large for a one-line default.
- **[severity] area** — follow-up outside this change: <why separate>.

<details>
<summary>Run details</summary>

- Target: <e.g. "PR #42 (feature/auth-rewrite, 12 files, +340/-89)">
- Rounds: <completed> completed (<requested> requested + <adaptive> adaptive, max <max_rounds>); <convergence/adaptive stop note>   # productive adaptive-capable runs
- Rounds: <completed>/<requested> completed; adaptive off; <convergence note>   # review-only/exact/no-extra runs
- Mix: <e.g. "2 codex-exec + 1 claude-exec">
- Focus: <focus list actually used>
- Earlier review comments: none | <total> comments; <open>/<still-present>/<fixed>/<not-relevant>/<skipped>
- Finding counts: <C critical, H high, M medium, L low, N nit; other notes S>
- Checks: off | skipped | concerns=<C>; confirmed=<confirmed>/ruled-out=<refuted>/set-aside=<deferred>/lowered=<downgraded>; elapsed=<duration>
- Second check: off | <mode>; reviewers=<A>; kept=<kept>/clarified=<clarified>/set-aside=<deferred>/removed=<removed>; approval changed yes/no
- Set aside: <D> items; reasons=<reasons>
- Next time: <one line; see rule below>   # omit in review-only

</details>

---
_Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._
```

`Findings addressed` = post-dedup count of unique findings auto-applied across all rounds.

### Tuning suggestion rule

Omit in review-only. Early exit already stops the loop when a round comes back
clean, and an adaptive round that converges needs no tuning suggestion. The
remaining cases:

- If every completed round was `material_findings` and `max_rounds == rounds`,
  suggest re-enabling adaptive continuation (`max_rounds = rounds + 1`) or
  setting `rounds = N + 1` for the next run.
- If the adaptive cap was reached and the final round was still
  `material_findings`, suggest increasing `max_rounds` by 1 only when the final
  round applied verified fixes; otherwise suggest resolving Deferred blockers or
  verification gaps before adding more rounds.
- If adaptive continuation was blocked by skipped/missing verification, suggest
  setting a trustworthy `verify_cmd` before increasing `rounds`.

When the cap that bound was the diff-size-scaled default, name the tier and the
exact value to re-run with, e.g. `small-diff adaptive cap (rounds+1=4) reached;
re-run with max_rounds: 5 to continue`.

## Edge Cases

| Case | Behavior |
|---|---|
| Missing reviewer backend | Validate only the backends the resolved mix actually names, before round 1. Abort with: "review-anvil requires the `<missing-skill>` skill from the mrshu-skills marketplace. Install via `/plugin install <missing-skill>@mrshu-skills` (Claude Code) or `npx skills add mrshu/agent-skills --skill <missing-skill>` (cross-agent)." |
| No diff in auto-detected target | Abort: "No target detected — nothing to review." Don't invent work. |
| Raw diff > ~5000 lines | Warn in the round status and continue; tell reviewers they may focus on the most impactful slice; double `reviewer_timeout` (unless the user set it explicitly). For `adversarial: auto`, estimate meaningful changed size after exclusions; very large meaningful diffs select at least `full`, but generated/mechanical churn alone does not force deeper adversarial review. |
| `agents > 8` | Reject before round 1 — more dedup work than signal. |
| `rounds = 0` | Reject — almost certainly a typo. |
| `max_rounds < rounds` | Reject before round 1 — the adaptive cap cannot be below the requested round count. |
| User-supplied `max_rounds > rounds` with `commit_mode=none` | Warn and set `max_rounds=rounds`; read-only extra rounds are explicit redundancy via `rounds`, not adaptive refinement. |
| `adversarial` with `per_fix` | Warn and ignore — productive mode verifies real fixes with the build/test gate. |
| `adversarial_rounds > 2` | Reject before dispatch — adversarial review is bounded critique, not an open-ended debate. |
| Reproduction verifier failure | Keep consensus findings that did not require reproduction, but move required single-reviewer `medium`+ and deletion/high-risk candidates to Deferred with `failed reproduction: verifier unavailable`; never silently promote them. |
| Adversary failure | Continue with the normal synthesized report and note the failure in Run Details; in `strict`, any required adversary failure forces `COMMENT`. |
| Unparseable findings block | Confirmation/plan-only output follows the one protocol retry above. Otherwise, in requested rounds use substantive review prose as free-form findings with no retry and note `<agent>: unstructured findings (parse failed)`; in adaptive rounds, abort before fixes from that round are applied. |
| Reviewers contradict each other | Surface both under the same area with reviewers tagged; orchestrator judgment decides the fix; mention the disagreement in the round summary. |
| Re-runs | Not idempotent: a new run reviews the latest state, including the prior run's commits. Surface still-present deferred items under "Deferred from previous runs (still present)". |
