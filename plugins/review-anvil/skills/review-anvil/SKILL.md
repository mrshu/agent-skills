---
name: review-anvil
description: Iteratively refine code via N rounds of parallel subagent review and orchestrator-applied fixes. Use when the user says "let's do three rounds", "fix/review loop", "back-and-forth review", "iterative review", or asks to harden a change with multiple rounds of codex/claude review. Configurable rounds, agent count/mix, focus, and target.
---

# review-anvil — Iterative Multi-Agent Fix/Review Loop

Wrap a code change in **N rounds of parallel reviewer subagents + orchestrator-applied fixes**. Each round = (parallel review by M agents, each with a distinct lens) → (you synthesize and **verify** findings) → (you apply fixes, run the build/test gate, commit) → next round.

## Preset skills

This is the **engine** skill. Three preset skills in the same plugin wrap common invocation patterns:

| Preset skill | Pins | Use it when |
|---|---|---|
| `review-anvil` (this engine) | nothing — full parameter surface available | The agent wants the default fix/commit loop, or a custom param combination not covered by the presets. |
| `review-anvil-readonly` | `commit_mode=none`, default `rounds=1` | The user wants a read-only review pass — no edits, no commits. |
| `review-anvil-pr [<locator>]` | `commit_mode=none`, `target=<locator>`, `report_path=.review-anvil/final-report-<UUID>.md` | The user wants to **review** a GitHub PR (no edits) and post the synthesized report back as a PR comment. Locator is optional — the preset auto-detects from the current branch when omitted. Orchestrates `scripts/pr-helper.sh` for the GitHub-specific bits. |
| `review-anvil-improve-pr [<locator>]` | `commit_mode=per_fix`, `target=<base>...HEAD` (branch, not PR locator) | The user wants to **improve** a GitHub PR they have checked out — review + apply fix commits across N rounds + `git push` back to the PR. Locator is optional (auto-detect). Reuses `pr-helper.sh verify-checkout` for the safety preflight (current branch matches PR head, clean worktree). Deliberately routes around the engine's "PR-target / per_fix incompatibility" rule by targeting the branch directly. |

Presets are cross-agent: each is a separate `skills/<name>/SKILL.md` with a `description` that triggers activation for its intent. The Claude Code plugin used to ship slash-command wrappers (`/review-anvil`, `/review-anvil-review`, `/review-anvil-pr`) over the same flows; v0.4 dropped those in favor of the cross-agent skill split.

## How to Use

The user invokes the skill with a free-form args string. Parse it to extract these parameters:

| Param | Default | Plain-English forms |
|---|---|---|
| `rounds` | `3` | "5 rounds", "three rounds", "do 4 passes" |
| `agents` | `3` | "3 agents", "2 reviewers", or a mix like `"2 codex + 1 claude"`, `"three claude reviewers and one codex"` |
| `focus` | the four pillars (correctness, maintainability, simplicity, production blast-radius) | "focus on async correctness", "only: security" (the `only:` prefix replaces defaults instead of appending) |
| `target` | auto-detect | "PR #42", "branch", "uncommitted", "src/auth/", "last 3 commits" |
| `allow_new_deps` | `false` | "allow new deps", "allow new dependencies" — auto-apply fixes that introduce new imports/subsystems instead of deferring them |
| `min_fix_severity` | `medium` | "auto-fix high and above", "fix only critical", `min_fix_severity: high` — minimum severity for auto-fix; lower findings are listed but not applied |
| `commit_mode` | `per_fix` | `per_fix` (current behaviour: one commit per fix-group), `none` (review-only: no edits, no commits — used by the `review-anvil-readonly` and `review-anvil-pr` preset skills). Plain-English: "review only", "don't commit", "no fixes". |
| `verify_cmd` | auto-detect | "verify with `npm test`", `verify_cmd: pytest -q`, or `verify_cmd: none` to skip — the build/test command run after each round's fixes to prove they don't break the project (see "Build/test gate"). Only meaningful in `commit_mode=per_fix`. |
| `reviewer_timeout` | `900` | "timeout 10 minutes", `reviewer_timeout: 600` — hard per-reviewer wall-clock cap (seconds) for Bash-dispatched reviewers (see the `run-reviewer.sh` wrapper under Loop Mechanics §2). |
| `report_path` | unset | Absolute or relative file path. When set, the skill writes the final report to this file (creating parent dirs) in addition to printing it inline. The skill's last printed line is exactly the path (no quoting, no trailing whitespace) so downstream consumers can pick it up. Used by `review-anvil-pr` to hand the report off to a post-processing script that posts it as a PR comment. |

### Parsing semantics

The argument string is parsed **left-to-right** with **first-occurrence-wins** precedence per canonical parameter. Concretely:

1. **Tokenize** the args into comma-separated segments.
2. **Canonicalize** each segment to a `(parameter, value)` pair:
   - Explicit `key: value` segments map directly (`commit_mode: none` → `(commit_mode, none)`).
   - Plain-English forms map to their canonical parameter (`"review only"`, `"don't commit"`, `"no fixes"` → `(commit_mode, none)`; `"3 codex + 1 claude"` → `(agents, "3 codex + 1 claude")`; etc.). All recognized aliases live in the parameter table's "Plain-English forms" column.
   - Unrecognized segments are noted but ignored.
3. **Apply first-occurrence-wins**: for each canonical parameter, the *first* `(parameter, value)` pair in source order is authoritative. Subsequent pairs for the same parameter are dropped with a one-line warning (`warning: user-supplied <param>=<value> ignored — earlier value <param>=<earlier> wins`).
4. **Fill in defaults**: any parameter not set after parsing takes its default from the parameter table.

This makes preset-skill "pins" (assembled as `<pin>, <user-args>`) authoritative without any extra mechanism: the preset's pin is just the first occurrence, and the user's later attempt is a dropped duplicate.

### Parsing rules

- `agents` may be a single number (use the default mix policy below) **or** a plain-English mix. If a mix is given, honor it exactly. The mix may name `codex`/`codex-exec` or `claude`/`claude-exec`.
- `focus` defaults are *appended* to user input. If the user prefixes their focus with `only:`, replace defaults with their list.
- `target` auto-detection precedence (when not specified):
  1. Currently checked-out PR — detect via the host's GitHub interface (e.g. `gh pr view --json number,headRefName 2>/dev/null`, a GitHub MCP query, or a REST `GET /repos/{owner}/{repo}/commits/{branch}/pulls` lookup); if a PR is found, use its diff.
  2. Else, if the current branch differs from `main`, use the branch-vs-main diff (`git diff main...HEAD`).
  3. Else, use uncommitted changes (`git diff` and `git diff --cached`).
- If the args string is missing or empty, use all defaults.
- **Preset skill conventions.** Preset skills (`review-anvil-readonly`, `review-anvil-pr`, `review-anvil-improve-pr`) activate this engine with a fixed set of parameters. A preset's SKILL.md instructs the agent to assemble the argument string with safety-critical params first (`commit_mode: none, target: <locator>, …, <user-args>, rounds: <default>`). The engine's first-occurrence-wins parser then makes the preset's values authoritative whenever the user's pass-through args try to override them. The engine's "PR-target / per_fix incompatibility" rule (below) is the final safety net for the one dangerous combination.

- **Preset pin-rejection (defense in depth).** Each preset declares a list of pinned params it considers non-overridable. Before assembling the argument string, the preset scans `$ARGUMENTS` for user-supplied attempts to redefine any pinned param and aborts with a clear error. The canonical detection algorithm (preset SKILL.mds reference this rather than restating it):
  1. Split `$ARGUMENTS` on top-level commas (do not descend into quoted strings or nested values).
  2. For each segment, strip leading/trailing whitespace and extract the part before the first `:` as the key candidate.
  3. Lowercase the key (the engine parser canonicalizes keys case-insensitively; the rejection check must match).
  4. If the lowercased key exactly matches a pinned param name (e.g. `commit_mode`, `target`, `report_path`), abort with: `error: <param> is pinned by <preset-name> and cannot be overridden in args`.

  This segment-based approach avoids the false positives of a naive substring/regex match — a value like `focus: "target: PR safety"` contains the substring `target:` inside the focus value, but its segment key is `focus`, so the check correctly passes.

  Segment splitting is universally implementable (every host that can run a skill can split a string on commas). There is no regex fallback: a fallback that scans raw text re-introduces the substring false-positive class this algorithm exists to eliminate, and a host that genuinely cannot perform the segment split cannot meaningfully enforce pin safety in the first place. If a preset finds itself unable to apply this algorithm in a given environment, it must abort with `error: pin-rejection unavailable in this environment; refusing to invoke engine without pin enforcement` — not degrade to a less safe alternative.

### PR-target / per_fix incompatibility

If `target` classifies as a GitHub PR locator (URL `https://<host>/<owner>/<repo>/pull/<N>`, slug `<owner>/<repo>#<N>`, or the plain-English form `PR #<N>` which normalizes to a bare-integer locator), the only valid `commit_mode` is `none`. Force `commit_mode=none` regardless of the requested mode and emit a one-line warning if the user explicitly asked for `per_fix`:

> `warning: PR locators are read-only — forcing commit_mode=none (use 'target: branch' to fix-and-commit on your checked-out PR branch).`

The reasoning: when the target is a PR locator, the reviewers see the GitHub-fetched PR diff, which may not match the local working tree. Allowing per-fix commits in that combination silently couples reviewer baseline to local state in ways the user can't predict — and the user's actual intent for "review and commit fixes on a PR I have checked out" is better served by targeting the branch directly (`target: branch`), where the local working tree *is* the source of truth and `git diff` against the merge base is unambiguous.

### Commit modes

The skill has two operating modes, selected by `commit_mode`:

- **`per_fix` (default)** — full loop: review → synthesize → **apply fixes** → **commit** → next round. Each round leaves new commits in the worktree.
- **`none` (review-only)** — review → synthesize → next round. **No edits, no commits, no staging.** Each round reviews the *same* baseline state (since nothing changes between rounds), so `rounds > 1` only buys reviewer redundancy, not iterative refinement. The natural default for `commit_mode=none` is `rounds=1`.

When `commit_mode=none`:
- Skip Loop Mechanics §4 entirely.
- Round summary "Fixes applied" line becomes `Fixes applied: 0 (review-only)`.
- Findings are still grouped/severity-sorted and surfaced; the auto-fix policy still classifies items as "would-apply", "suggestions", and "deferred" so the user can see what *would* have happened.
- The final report omits commit SHAs and the "Tuning suggestion" line; instead it ends with a "Would-apply summary" block listing the fixes that would have been made.

### Posting reports externally

The engine does not post anywhere. When a downstream consumer (a preset skill, an agent script, an automation) wants to forward the final report somewhere, it sets `report_path` so the engine writes the report to a known file, and the consumer handles posting after the engine returns. The `review-anvil-pr` preset skill is the reference implementation for this pattern — see its `SKILL.md` + `scripts/pr-helper.sh`. Other downstream consumers (post to Slack, email, etc.) follow the same shape.

### Example invocations

- `Skill review-anvil` → 3 rounds, default mix (2 codex + 1 claude), default four-pillar focus, auto-detected target. Auto-fix gated at severity ≥ medium and no new dependencies.
- `Skill review-anvil "5 rounds, 2 codex + 1 claude, focus: async correctness, target: PR #42"`
- `Skill review-anvil "1 round, only: security, target: src/auth/"`
- `Skill review-anvil "three rounds, three claude reviewers"` → 3 rounds × 3 claude-exec.
- `Skill review-anvil "allow new deps, focus: production blast-radius"` → opt into the prod-hardening pass; auto-applies fixes that introduce new imports/subsystems.
- `Skill review-anvil "fix only critical"` → severity gate raised to `critical`; surfaces everything else as suggestions in the report without editing the file.

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

- For non-PR targets (branch, uncommitted, path): run the appropriate `git diff …` command(s) to materialize the diff as text.
- For PR targets (canonical `<owner>/<repo>#<N>`, always `commit_mode=none`): fetch the PR's diff via the host's GitHub interface — `gh pr diff <N> -R <owner>/<repo>`, or the equivalent MCP / REST call (`GET /repos/{owner}/{repo}/pulls/{N}` with `Accept: application/vnd.github.v3.diff`). The local working tree is irrelevant to this snapshot — reviewers see whatever the PR currently is on GitHub.
- Note the commit SHA at round start (`git rev-parse HEAD`) so the round summary can reference the exact baseline. For PR targets in `commit_mode=none`, the local SHA is informational only.

### 2. Dispatch reviewers in parallel

Pick the dispatch mechanism by host. The right choice matters: the wrong path costs you streaming output, runs into artificial `--max-turns` limits, or wastes a new process when an in-session subagent would do.

#### In Claude Code (the primary host)

**Use the Agent tool for `claude-exec` reviewers. Use Bash with `codex exec` for `codex-exec` reviewers. Do NOT use `claude -p` via Bash — that path is for non-Claude hosts only.**

- **`claude-exec` reviewers**: dispatch via the **Agent tool** with `subagent_type: "general-purpose"`. The Agent tool streams output natively (the user sees progress, not a buffered dump), has no artificial `--max-turns` ceiling (so reviewers that explore the codebase don't get cut off — round 1 of an early review-anvil-on-itself run hit `--max-turns 8` and lost the reviewer's output), and inherits the running session's environment without spawning a new process. Pass the assembled **Reviewer Prompt Template** as the `prompt`. Set `run_in_background: true` so multiple reviewers within a round run in parallel.

- **`codex-exec` reviewers**: dispatch via **Bash** through the `run-reviewer.sh` wrapper (below): `bash <wrapper> .review-anvil/round<N>-<label>.md <reviewer_timeout> -- codex exec --sandbox read-only -C <project-dir> '<prompt>'`. Claude Code has no Codex-equivalent Agent tool. Use `run_in_background: true` for parallel dispatch.

- **Parallel dispatch**: send all M reviewers in a *single message* with multiple tool calls (a mix of Agent and Bash, each with `run_in_background: true`). The harness notifies you when each completes; do not poll.

#### In Codex CLI or other agents without Claude Code's Agent tool

- **`claude-exec` reviewers**: write the assembled prompt to a file, then shell out through the wrapper:

  ```bash
  bash <wrapper> .review-anvil/round<N>-<label>.md <reviewer_timeout> -- \
    claude -p --max-turns 100 --no-session-persistence \
      --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" \
    < .review-anvil/round<N>-<label>.prompt.md
  ```

  `--allowedTools` is variadic and eats positional args, so the prompt MUST arrive via stdin (the wrapper passes its own stdin through). **Do not size `--max-turns` to the task.** Task-sized caps keep biting: 8 was too low, then 20 was hit in production by reviewers that explore callers and tests per the review principles — and a reviewer that hits the cap mid-investigation loses its entire output, the worst possible outcome. The wrapper's wall-clock timeout is the real bound on a runaway reviewer; `--max-turns 100` is only a backstop against pathological loops and should never bind on a legitimate review (it's set explicitly because some host setups default the cap to 8).

- **`codex-exec` reviewers**: same wrapper, wrapping `codex exec --sandbox read-only -C <project-dir> '<prompt>'`.

- **Parallel dispatch**: launch all M wrapper invocations as background shell processes (`... &`) and `wait` on them.

#### Bash-dispatched reviewers MUST go through `run-reviewer.sh`

Every reviewer dispatched via a shell (codex-exec everywhere; claude-exec outside Claude Code) runs under `scripts/run-reviewer.sh`, which lives next to this SKILL.md. **Never run a bare `claude -p ... > out.md 2>&1` (or equivalent) in the background and wait on the file.** In `claude -p` text mode nothing is printed until the final answer, so a hung reviewer is indistinguishable from one still working — a production run sat on a 0-byte output file for many minutes with no way to tell. The wrapper closes that hole:

```
run-reviewer.sh <out_file> <timeout_seconds> -- <command> [args...]
```

- Hard wall-clock timeout (`reviewer_timeout`, default 900s): TERM at the deadline, KILL 30s later.
- Captures the command's exit status; stderr goes to `<out_file>.err` (kept for diagnosis).
- Prints exactly one classification: `STATUS=ok` | `STATUS=timeout` | `STATUS=empty` (exit 0 but nothing written) | `STATUS=failed` (+ `EXIT_CODE=<n>`).

Treat any STATUS other than `ok` as a failed reviewer per "Failure handling", with the tail of `<out_file>.err` as the reason — an empty output file is an explicit failure, never something to keep waiting on. Reviewer output/prompt files go under `.review-anvil/`; clean them up after the round's synthesis.

**Resolving the wrapper.** Same trusted-root rule as `pr-helper.sh` in the `review-anvil-pr` preset: use the host-exposed skill path (`${CLAUDE_PLUGIN_ROOT}/skills/review-anvil/scripts/run-reviewer.sh` in Claude Code) or the user-level install root (`~/.claude/skills/review-anvil/scripts/run-reviewer.sh`, or the host's documented home-directory skill root). Never resolve it from project-scoped/worktree-local skill directories — those are writable by the repo under review. If no trusted copy resolves, replicate the wrapper's contract inline (background the command, kill it at the deadline, check exit status, treat an empty output file as failure) rather than falling back to a bare redirect.

#### Last resort

If parallel dispatch is genuinely impossible in a given host (no Agent tool, no background bash), fall back to serial invocation but **report this in the round summary** so the user can switch hosts for future runs. Serial reviewers undermine the cross-reviewer dedup story (reviewers see the same baseline but at different wall-clock times) — it's a degraded mode, not the design.

The `codex-exec` and `claude-exec` skills in this marketplace document the same recipes from the reviewer-skill side; the canonical dispatch lives here.

### 3. Synthesize

When all reviewers return, merge their findings:

- **Dedup** overlapping issues. Prefer `(file, line, root cause)` as the dedup key when both fields are present; fall back to `(area, root cause)` when they're not. Keep the highest-severity instance and note which reviewers raised it. Preserve `file` and `line` on the surviving instance — if two reviewers flag the same root cause at different file/line anchors, keep both anchors as `file_alternates: [...]` on the merged finding (downstream consumers can pick).
- **Group** by severity (`critical` → `nit`), then by topic within severity.
- **Drop** any item already addressed in this round's earlier fixes (defensive — shouldn't normally happen in v1 since fixes happen after synthesis).

If a reviewer's output is unparseable, label its findings "unstructured" and pass through the prose into a separate section of the synthesis. Do not retry.

#### Verify findings before acting on them

Plausible-but-wrong findings are the dominant failure mode of LLM review, and both downstream actions are expensive: a bogus fix commit pollutes the branch, and a bogus finding posted to a PR burns the author's trust. So after dedup:

- Every finding of severity `medium` or higher that was raised by a **single** reviewer must be confirmed by the orchestrator against the actual code before it can be auto-fixed (`per_fix`) or reported as actionable: open the cited file and enough surrounding context (callers, the configured runtime, existing tests) to confirm the issue is real and reachable — not merely plausible from the diff hunk alone.
- Findings raised independently by **two or more** reviewers may skip verification — cross-reviewer consensus is the signal (this is why the dedup step records which reviewers raised each finding).
- Findings that fail verification move to **Deferred** with reason `failed verification: <one line>`. They are never auto-fixed and never silently dropped — the user (and PR author, for posted reports) can see what was claimed and why it didn't hold up.
- `low`/`nit` findings skip verification: they're below the auto-fix gate and the cost isn't justified; they surface as suggestions either way.

### 4. Apply fixes

**Skip this step entirely when `commit_mode=none`.** In review-only mode, jump straight to step 5 — no edits, no staging, no commits. The auto-fix policy below is still evaluated *in the abstract* so the final report can show the user which items *would* have been applied vs. deferred, but no files are touched.

Make the edits as the orchestrator. Group fixes by topic and **commit one logical fix-group per commit**, conventional-commit style:

- `fix(area): <what>` — for bug/correctness fixes
- `refactor(area): <what>` — for maintainability/simplicity changes
- `test(area): <what>` — when adding tests
- `chore(area): <what>` — for production-readiness tweaks (logging, error handling, config)

#### Auto-fix policy (proportionality rules)

The orchestrator does **not** auto-apply every finding. Three rules gate what becomes code edits versus what gets listed in the report's deferred section:

1. **Severity gate.** Only auto-fix findings at severity ≥ `min_fix_severity` (default `medium`). Findings below the gate are listed under "Suggestions" in the round summary and final report, but the file is not edited. Exception: an obvious one-line fix at any severity (e.g., removing a single unused import that the reviewer flagged as `nit`) is fine — apply it without bumping the severity.

2. **No new dependencies (default).** A fix that introduces a new import, requires installing a new package, or stands up a new subsystem (rate-limit table, middleware, separate datastore, etc.) is **deferred** with reason `introduces new dependency: <X>`, even if its severity passes the gate. The user opts into these by re-invoking with `allow_new_deps: true`. The intent is: don't grow the architecture without explicit permission, even when the finding is real.

3. **Round size cap.** A single round's fixes cannot grow the target file by more than ~50% of its starting line count, or 200 lines absolute, whichever is larger. If proposed fixes exceed the cap, the orchestrator applies the highest-severity ones first and defers the rest with reason `round size cap reached`. The cap is per-round, so the next round can apply more if the previous one filled the budget.

Items judged noise (e.g., reviewer disagreement with house style, false positives) are also **deferred**, not silently dropped. Record each deferred item with a one-line reason: noise, sub-threshold severity, new dependency, size cap, failed verification, or product/architecture decision.

#### Build/test gate (`verify_cmd`)

Fix commits must not leave the branch red — pushing "fixes" that break the build is worse than doing nothing. In `commit_mode=per_fix`:

- **Resolve the command.** `verify_cmd` explicit → use it. `verify_cmd: none` → skip the gate and record `Verification: skipped (user)`. Unset → auto-detect, in order: a test/build command named in repo docs (CLAUDE.md, CONTRIBUTING, README); `package.json` `scripts.test`; a `Makefile` `test` target; pytest/cargo/go-test project config. If nothing is detected, record `Verification: none detected` and proceed — downstream consumers (e.g. `review-anvil-improve-pr`) surface that caveat to the PR author.
- **Establish the baseline.** Run the command once before round 1. If it already fails at baseline, record that and gate only on *new* failures — don't block the loop on pre-existing red.
- **Gate each round.** After applying a round's fixes, run the command. On a new failure: make **one** fix-forward attempt if the cause is obvious from the output (commit as `fix(<area>): repair <verify_cmd> failure from round <N> fixes`); otherwise `git revert --no-edit` the round's fix commits and defer the associated findings with reason `fix failed verification`. A round never ends with the gate newly red.

### 5. Round summary

Append a short markdown block to running output:

```
### Round N — <convergence flag>
- Parameters: rounds=3, target=acme/widgets#42 [pin], commit_mode=none [pin], report_path=.review-anvil/final-report-<UUID>.md [pin], focus=4-pillar
- Reviewers: <list of agents dispatched>
- Findings: C critical, H high, M medium, L low, X nit
- Fixes applied: K commits (<sha1>..<shaN>)   # or "0 (review-only)" when commit_mode=none
- Verification: <cmd> — passed | failed → round reverted | none detected | skipped   # per_fix only
- Would-apply: W items                         # only printed when commit_mode=none
- Suggestions: S items (sub-threshold severity; not applied)
- Deferred: D items (see below; reasons: noise / new dependency / size cap / failed verification / product decision)
```

Each pinned parameter carries an inline `[pin]` annotation in the Parameters line. Pin authority comes from the preset skill's argument assembly (it places pinned values first in the string, and first-occurrence-wins parsing makes them authoritative — see "Preset skill conventions"). The "PR-target / per_fix incompatibility" rule (in "How to Use") is the final safety net for the one dangerous combination.

The convergence flag is one of:
- `clean` — no findings at all
- `nits_only` — no findings above `low` severity
- `material_findings` — at least one `medium` or higher

### 6. Continue or finish

If the round number is less than `rounds`, start the next round (back to step 1). Round N+1 reviews the new state — its prior-round summary input includes the commits from round N.

**Early exit on convergence (`per_fix` only).** If a round's convergence flag is `clean` or `nits_only`, stop the loop after that round even if rounds remain — further rounds re-review converged code and mostly produce noise. Note `Converged after round N of R (early exit)` in the final report's Total section. In `commit_mode=none`, multi-round runs exist purely for reviewer redundancy over the same baseline, so early exit does not apply there.

After the final round, emit the **Final Report** described under "Output Format." If `report_path` is set:

1. Write the rendered report to that file (creating parent dirs).
2. Write a sibling **inline-comments JSON artifact** at `<report_path>.inline.json` containing the array of GitHub PR review comment payloads for findings that have both `file` and `line` populated. Format:
   ```json
   [
     {"path": "src/auth.ts", "line": 50, "side": "RIGHT", "body": "**[high] auth** — Missing CSRF check.\n\nWhy: ...\n\nSuggested fix: ..."},
     {"path": "src/db.ts", "start_line": 100, "line": 110, "side": "RIGHT", "start_side": "RIGHT", "body": "..."}
   ]
   ```
   - Findings with only `line: <N>` produce `{"line": N, "side": "RIGHT"}`.
   - Findings with `line: <N>-<M>` produce `{"start_line": N, "line": M, "side": "RIGHT", "start_side": "RIGHT"}`.
   - Findings without `file` and `line` are NOT included (they remain in the markdown report body).
   - If no findings have anchors, the JSON file contains the empty array `[]`.
   - The `body` of each entry is a self-contained mini-report (severity + area + what + why + suggested_fix) so GitHub's inline-comment UI is informative without needing to consult the top-level body.
3. Print the report path on the skill's last output line — downstream consumers pick it up. The sibling `.inline.json` is implied by the convention; consumers that care look for it adjacent to the report.

### Failure handling

- If a reviewer agent fails or times out, log it in the round summary as `<agent>: failed (<reason>)` and proceed with the others. No retries. For Bash-dispatched reviewers, "fails or times out" is determined by the `run-reviewer.sh` wrapper's STATUS (`timeout`, `empty`, `failed`) — use the tail of the `.err` file as `<reason>`.
- If **all** reviewers in a round fail, abort the loop and report what happened. Do not "carry on" with zero findings — that produces a misleading clean signal.
- If `git commit` fails (pre-commit hook, conflicts), surface the error and stop the loop. Do not bypass hooks.

### Concurrency

- Within a round: parallel (single multi-tool-call message).
- Between rounds: strictly sequential (round N+1 needs round N's commits to exist).

## Reviewer Prompt Template

Each reviewer subagent receives a self-contained prompt assembled from a **context block** and a **task block**. The context block carries the reviewer's individual lens; the task block is identical for every reviewer.

### Lens assignment

M identical prompts buy redundancy and dedup work, not coverage — so when M ≥ 2, partition the focus areas into per-reviewer **lenses**. The four default pillars map to four lens packs:

| Lens pack | Covers |
|---|---|
| `correctness` | correctness, data flow, edge cases; verify what the layer below actually does in the configured backend/runtime, not what the abstract API promises |
| `simplicity` | simplicity; "should this code exist?" — question abstractions/layers before reviewing their implementation; dead code; redundant defense-in-depth where one layer is broken |
| `blast-radius` | production blast-radius: failure modes, fallback paths that swallow errors, operational concerns (logging, config, migrations, rollout) |
| `maintainability` | maintainability; cross-file consistency (is the same pattern handled differently elsewhere in the repo?); test coverage of the change; `pragma: no cover`/`noqa`/lint-suppression smells |

Assignment by reviewer count:

| M | Lenses |
|---|---|
| 1 | all four pillars (no split) |
| 2 | A: correctness + blast-radius; B: simplicity + maintainability |
| 3 | A: correctness; B: blast-radius; C: simplicity + maintainability |
| 4 | one pack each |
| >4 | cycle through the packs — duplicate assignments add redundancy on top of coverage |

User-supplied `focus:` additions are explicit priorities — append them to **every** reviewer's lens. `only:` with a single topic → all reviewers share it (pure redundancy); `only:` with multiple topics → partition them across reviewers like the pillars.

### Context block (orchestrator fills in)

```
You are a strict code reviewer for round {N} of {ROUNDS}.

TARGET
{Description of the target — e.g. "PR #42 (12 files, +340/-89) on branch
feature/auth-rewrite"; or "diff between `main` and `feature/x` (`git diff
main...HEAD`)"; or "uncommitted changes in src/auth/ (`git diff` +
`git diff --cached`)". Include the actual diff text or instructions to
fetch it. For PR-locator targets add: "the local checkout may not match
the PR head — trust the PR diff, and fetch file contents at the PR head
SHA via `gh` when you need surrounding context."}

PRIOR ROUNDS
{Per prior round: the round's addressed and deferred findings as
one-line items, so this reviewer can actually avoid re-raising them.
  Round 1 (7 fixes applied, commits a1b2c3d..7e8f9a0; verification passed):
    addressed:
      - [high] auth — missing CSRF check on token refresh
      - [medium] error-handling — bare except swallows DB errors
    deferred:
      - [medium] db — pool sizing (introduces new dependency: pgbouncer)
If this is round 1, write "None — this is round 1."}

YOUR LENS
{This reviewer's lens pack(s) from the assignment table, as bullets,
plus any user-supplied focus additions.}
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

Severity guide:
- critical: data loss, security breach, production crash
- high: correctness bug or major maintainability problem
- medium: should fix but not blocking
- low: style or minor
- nit: preference

Do not repeat issues already addressed or deferred in prior rounds
(see PRIOR ROUNDS). Deferrals are deliberate decisions — re-raise one
only if you believe the deferral reason is wrong, and say why.

For each issue, return a structured finding with these keys:
- severity: one of critical|high|medium|low|nit
- area: short topic tag (e.g. "auth", "db-migration", "error-handling")
- what: one-sentence description of the problem
- why: one-to-three-sentence explanation of why it matters
- suggested_fix: PROSE description of how to fix (no patches, no code
  blocks unless quoting a single short line for clarity)
- file: (OPTIONAL) repo-relative path to the file the finding is
  about, e.g. "src/auth.ts". Omit for findings without a specific
  file anchor (architectural / overview observations).
- line: (OPTIONAL) line number on the "new" side of the diff, or a
  range `<start>-<end>` for multi-line findings, e.g. "42" or
  "42-50". Omit if `file` is omitted or if the finding isn't
  anchorable to a specific line.

Output format: a markdown report. End the report with a fenced
```findings block containing one YAML list item per finding, like:

  ```findings
  - severity: high
    area: auth
    file: src/auth.ts
    line: 42-50
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
- The assembled prompt is passed to whatever dispatch mechanism Loop Mechanics §2 specifies for the current host — Agent tool with `subagent_type: "general-purpose"` for claude-exec reviewers in Claude Code; the `run-reviewer.sh` wrapper around `codex exec` for codex-exec reviewers everywhere; the wrapper around `claude -p` for claude-exec reviewers in non-Claude-Code hosts.
- Reviewers must return **prose findings only**. The skill rejects (or simply ignores) any embedded patches.
- The PRIOR ROUNDS block is constructed from each prior round's synthesis: a header line `Round N (K fixes applied, <sha1>..<shaN>; verification <passed|failed → reverted|none detected>):` followed by `addressed:` and `deferred:` sub-lists with one `- [severity] area — what (reason)` line per finding. Severity counts alone are useless to a reviewer told not to repeat issues — it cannot know *which* issues were addressed from counts.
- **In `commit_mode=none` (review-only)**, no findings are addressed between rounds, so the "Do not repeat issues already addressed in prior rounds" instruction in the task block does not apply — every round reviews the same baseline. For review-only multi-round runs, replace the PRIOR ROUNDS block with: `PRIOR ROUNDS\nNone — review-only mode; this is an independent reviewer pass.` and drop the "addressed in prior rounds" line from the task block. Multi-round review-only is purely for reviewer redundancy.

## Output Format

### During execution

Print a one-line status before each round:

```
Round 2/3: dispatching 2 codex-exec + 1 claude-exec on PR #42 …
```

Append the round summary block (defined under Loop Mechanics, step 5) after each round completes.

### Final report

After the last round completes, emit a fresh top-level report below the running output. The report is a new document — not a replacement for the per-round blocks already printed during execution.

`Findings addressed` in the Total section equals the post-dedup count of unique findings auto-applied across all rounds. `Suggestions` and `Deferred` are tracked separately. Use this structure:

```
# review-anvil report

**Target:** <description, e.g. "PR #42 (feature/auth-rewrite, 12 files, +340/-89)">
**Rounds:** <N>
**Mix per round:** <e.g. "2 codex-exec + 1 claude-exec">
**Focus:** <comma-separated focus list actually used>
**Commit mode:** <per_fix | none>
**Auto-fix policy:** min severity = <medium>, allow_new_deps = <false>
**Verification:** <verify_cmd actually used, or "none detected" / "skipped">   # per_fix only
**Report path:** <only when report_path was set: the absolute path the report was written to>

## Round 1 — <convergence flag>
- Findings: C critical, H high, M medium, L low, X nit
- Fixes applied: K commits (<sha1>..<shaK>)         # commit_mode=per_fix
  # OR: Fixes applied: 0 (review-only)              # commit_mode=none
- Verification: <cmd> — passed | failed → reverted  # per_fix only
- Would-apply: W items                              # only when commit_mode=none
- Suggestions: S items
- Deferred: D items

## Round 2 — <convergence flag>
…

## Total
- Total commits: T                                  # commit_mode=per_fix only — omit in review-only
- Findings addressed: A                             # commit_mode=per_fix; "Findings would-apply: A" in review-only
- Suggestions surfaced: S
- Findings deferred: D
- Converged after round N of R (early exit)         # only when early exit fired
- Tuning suggestion: <one line; see rule below — omitted in most runs>
  # In commit_mode=none, omit Tuning suggestion entirely — convergence
  # is meaningless when no fixes are applied between rounds.

## Suggestions
For each sub-threshold finding (severity below `min_fix_severity`):
- **[severity] area** — what (consider re-running with `min_fix_severity: <severity>` to apply)

## Deferred items
For each deferred item across all rounds:
- **[severity] area** — what (deferred because: reason — e.g. introduces new dependency: <X>; size cap reached; failed verification: <why>; product/architecture decision)

## Would-apply summary (commit_mode=none only)
For each finding the auto-fix policy would have applied (severity ≥ min_fix_severity, no new deps, within size cap):
- **[severity] area** — what (would commit as `<type>(<area>): <subject>`)
```

### Tuning suggestion rule

With early exit on convergence (Loop Mechanics §6), the loop stops itself when a round comes back clean — so the only tuning case left is the loop *not* converging:

- If **every** completed round was `material_findings`, suggest `rounds = N + 1` next time (the loop hadn't converged).
- If early exit fired, the `Converged after round N of R` line already tells the user the effective round count — no separate suggestion needed.
- Otherwise omit the suggestion.

## Edge Cases

### Missing reviewer dependency

`review-anvil` dispatches `codex-exec` and/or `claude-exec` subagents according to the resolved reviewer mix. Validate only the backends the mix actually uses — not both unconditionally. Concretely, after resolving the mix (from the `agents` parameter or the default-mix table), enumerate the backends it names and check that each required Skill resolves before round 1. If any required reviewer skill is missing, abort with:

> "review-anvil requires the `<missing-skill>` skill from the mrshu-skills marketplace. Install via your host's skill installer — e.g. Claude Code: `/plugin install <missing-skill>@mrshu-skills`; cross-agent (Codex CLI, Cursor, OpenCode, …): `npx skills add mrshu/agent-skills --skill <missing-skill>`."

For example, a request like `Skill review-anvil "3 codex reviewers"` resolves to `3 codex-exec`, so only `codex-exec` need be installed; missing `claude-exec` is irrelevant for that run. A request with the default mix (2 codex + 1 claude) requires both. This matters for cross-agent use cases where the user has opted into a single-backend setup (e.g. Codex-only hosts).

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
