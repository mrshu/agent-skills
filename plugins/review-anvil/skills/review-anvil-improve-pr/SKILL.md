---
name: review-anvil-improve-pr
description: Multi-agent review-and-improve loop for a GitHub PR you have checked out — posts a "starting" PR comment cc'ing the original author, runs N rounds of parallel reviewers, applies fix commits to the local branch after each round, pushes everything back to the PR, then edits the starting comment in-place with the synthesized report (or a failure summary). Auto-detects the PR from the currently checked-out branch when no locator is supplied. Use when the user wants to "improve a PR", "review and commit fixes", "iterate on my PR", or "review and push back" against a checked-out PR branch. Requires `gh` on PATH. Activates the `review-anvil` engine in per_fix mode.
---

# review-anvil-improve-pr

Productive counterpart to `review-anvil-pr`. Where `review-anvil-pr` is read-only and posts a review comment, this preset **actually modifies the code**: it announces itself on the PR up front, runs the review loop with `commit_mode=per_fix`, applies fix commits to the local branch across N rounds, pushes the result back to update the PR, then **edits the starting comment in-place** with the synthesized report (or a failure summary) — one comment in the PR timeline, two states.

The skill orchestrates six steps:

1. `scripts/pr-helper.sh verify-checkout [<locator>]` — locator parsing or auto-detect, then verify the local checkout matches the PR's head branch and is in a clean state. Captures the PR's base branch, author, marker UUID, and report path.
2. `scripts/pr-helper.sh post-start` — post a "starting" top-level PR comment cc'ing the original author, explaining what's about to happen and that the comment will be edited with the final summary. Captures the comment's ID (for the later edit) and start timestamp. The author gets a GitHub notification.
3. The [`review-anvil`](../review-anvil/SKILL.md) engine in `commit_mode=per_fix` on a branch-vs-base diff (NOT a PR-locator target — the engine's "PR-target / per_fix incompatibility" rule forbids that combination; this preset deliberately routes around it by targeting the local branch directly). The engine writes the final synthesized report to `report_path` — on failure paths too.
4. `git push` — once, after all rounds complete (or converge early) and only if the engine reported no failures and the build/test gate ended green, to publish the fix commits to the PR.
5. `scripts/pr-helper.sh post-update` — PATCH-edit the starting comment to replace its body with the final report (outcome=success) or a failure summary (outcome=failure). GitHub does NOT notify on edits, so the author isn't pinged again — the original `cc @author` notification at step 2 is the only ping.
6. Surface the final report inline + the comment URL to the user.

## Inputs

Same locator forms as `review-anvil-pr` — but you must already be on the PR's branch:

- **Omitted** — auto-detect via `gh pr view`; works when you're checked out on a PR branch.
- **Full GitHub URL** — `https://<host>/<owner>/<repo>/pull/<N>` for github.com or GitHub Enterprise.
- **Slug** — `<owner>/<repo>#<N>` (host defaults to github.com).

The helper script aborts cleanly if the current checkout doesn't match the named PR (wrong branch, dirty worktree, detached HEAD, divergent SHA). This is the safety net for "I'm on PR #42's branch, run improve" — without it, the engine could commit fixes to an unrelated local branch.

## How to invoke

### 0. Reject overrides of pinned params

Pins for this preset: `commit_mode`, `target`, `report_path`. Enforce mechanically — after resolving the helper (step 1), run:

```bash
bash <helper-path> check-pins review-anvil-improve-pr "commit_mode,target,report_path" "$ARGUMENTS"
```

Non-zero exit means a pinned param was overridden: surface the error verbatim and stop.

The pins are non-overridable for safety: `commit_mode=per_fix` is the whole point of this preset (read-only is what `review-anvil-pr` is for), `target=<base>...HEAD` is mechanically tied to the verified PR, and `report_path` is the file the post-summary step needs to read after the engine finishes.

### 1. Resolve the helper script

The helper lives at `../review-anvil-pr/scripts/pr-helper.sh` relative to this SKILL.md — this preset reuses the script from `review-anvil-pr` rather than duplicating it. Both presets ship in the same plugin and should be installed together.

To find the absolute path, in priority order:

1. **If the host exposes the loaded SKILL.md's path** for either skill (Claude Code via `${CLAUDE_PLUGIN_ROOT}/skills/review-anvil-pr/scripts/pr-helper.sh`), use that and stop.
2. **Otherwise, fall back to user-level skill install paths only**:
   - `~/.claude/skills/review-anvil-pr/scripts/pr-helper.sh` (Claude Code via `npx skills add`)
   - The home-directory skill root for the current host as `vercel-labs/skills` documents it.

   **Do not search project-scoped or worktree-local skill directories** — same security rule as in `review-anvil-pr`. The script must come from a trusted install root outside the reviewed repository.
3. **Verify the file exists before running it** — if no candidate resolves, abort with `error: review-anvil-pr/scripts/pr-helper.sh not found in any trusted skill root; install via 'npx skills add mrshu/agent-skills --skill review-anvil-pr'` (yes, the dependency is on `review-anvil-pr`, not on `review-anvil-improve-pr` itself).

### 2. Verify checkout

```bash
bash <helper-path> verify-checkout "<locator>"   # explicit form
bash <helper-path> verify-checkout               # auto-detect from current branch
```

The script runs `gh` preflight (auth + PR reachability), then verifies the local checkout: current branch matches the PR's head branch, HEAD is at-or-descended-from the PR's head SHA (descendants OK — unpushed local commits will be pushed at the end), and the worktree+index are clean. It also fetches the PR's base branch locally so the engine's diff target works.

On success, the script prints these KEY=VALUE lines on stdout:

```
HOST=github.com
OWNER=acme
REPO=widgets
N=137
HEAD_BRANCH=feature/auth-rewrite
HEAD_SHA=<the PR head commit at review time>
BASE_BRANCH=main
TITLE=<PR title>
AUTHOR=<github-login>
MARKER=<uuidv4>
REPORT_PATH=<absolute-path>/.review-anvil/final-report-<uuidv4>.md
```

If the locator was auto-detected, the script also prints `auto-detected PR: <url>` to stderr before the KEY=VALUE block. If HEAD is ahead of the PR's published head (unpushed local commits), the script prints a `note:` to stderr — surface that to the user so they know what will get pushed.

Capture all values. Echo to the user: `improving PR: $HOST/$OWNER/$REPO#$N — $TITLE ($HEAD_BRANCH → $BASE_BRANCH), author: @$AUTHOR`.

On non-zero exit, surface the script's stderr verbatim and stop. Do not dispatch reviewers.

Then fetch the PR's dismissed findings (resolved review threads + local suppressions) for the reviewer prompts:

```bash
bash <helper-path> dismissed "$HOST" "$OWNER" "$REPO" "$N"
```

Capture the output — an itemized list, or `None.` — for step 4. On non-zero exit, abort: re-litigating feedback the author already resolved is exactly what this lookup prevents.

### 3. Post the "starting" comment

Before any review work begins:

```bash
bash <helper-path> post-start "$HOST" "$OWNER" "$REPO" "$N" "$MARKER" "$AUTHOR"
```

The script creates a top-level PR comment that:
- Embeds the marker UUID (for later lookup if needed).
- Begins `review-anvil-improve-pr started on this PR. cc @<author>.`
- Explains what's about to happen and that the comment will be edited with the final result.
- Includes a `Started: <ISO-8601 UTC>` timestamp.

Then it looks up the comment by marker (with one retry for read-after-write lag), captures the comment ID + URL, and prints these KEY=VALUE lines:

```
COMMENT_ID=12345678
COMMENT_URL=https://github.com/acme/widgets/pull/137#issuecomment-12345678
STARTED_AT=2026-06-07T10:00:00Z
```

Capture all three. Echo to the user: `starting comment posted: $COMMENT_URL`. The PR author receives a GitHub notification from the `@-mention`.

If `post-start` fails *before* posting (network blip, gh auth issue), abort — nothing to clean up. One failure mode is different: the script can die *after* posting, when the marker lookup can't recover the comment ID ("posted starting comment but could not recover its ID"). In that case a starting comment **does** exist on the PR — abort the run and apply the Recovery procedure below to edit it manually.

### 4. Activate the engine

Activate the `review-anvil` skill with this argument string (extra user args go after the pinned params; the engine's own `rounds: 3` default applies when the user doesn't pass one):

```
commit_mode: per_fix, target: <BASE_BRANCH>...HEAD, report_path: <REPORT_PATH>, <extra-user-args>
```

`<BASE_BRANCH>` and `<REPORT_PATH>` come from step 2. Using `<BASE_BRANCH>...HEAD` (three-dot diff) targets exactly the commits that distinguish this PR from its base. Pinning `report_path` makes the engine write the final synthesized report to a file that step 6 (`post-update`) can read.

Supply the dismissed-findings list captured in step 2 as the engine's `DISMISSED FINDINGS FOR THIS PR` reviewer-prompt block — the branch target means the engine won't fetch it itself.

Note: do **not** pin a PR locator as `target` — the engine's "PR-target / per_fix incompatibility" rule would force `commit_mode=none` and defeat the point of this preset. Targeting the branch directly is the intended escape hatch.

The user may override `rounds:` (default is the engine's `rounds: 3` for productive loops). They should not override `commit_mode`, `target`, or `report_path` — these are pinned for safety; the step-0 segment-rejection above blocks override attempts.

The engine runs the multi-round loop, committing fix-groups along the way and writing the final synthesized report to `<REPORT_PATH>` when it's done. The engine's build/test gate (`verify_cmd`, auto-detected unless the user passes one) runs after each round's fixes, so the report's Verification lines are the evidence the PR author needs to trust the pushed commits — if the engine recorded `Verification: none detected`, that caveat travels to the PR in the posted report. If any round fails (reviewer-all-fail, git-commit error, build/test gate newly red after the revert path), the engine stops the loop and surfaces the failure — **skip the push (step 5) and call `post-update` with `outcome=failure`** (step 6) so the starting comment gets replaced with a failure summary rather than dangling.

### 5. Push

Only after the engine reports a successful run: all requested rounds completed (or the loop converged early — that counts as success), no `git commit failed` or `all reviewers failed` errors in the round summaries, and **every round's Verification state is one of** `passed`, `failed → round reverted`, `pre-existing failures (no new)`, `none detected`, or `skipped` — i.e. never newly red (these are exactly the engine's round-summary states):

```bash
git push origin "$HEAD_BRANCH"
```

If the engine's run was partial or failed, **do not push**. Go straight to step 6 with `outcome=failure`. The report file at `<REPORT_PATH>` contains the engine's final state including failure details; `post-update` will use it to populate the comment.

If the engine succeeded but `git push` fails (permission denied, conflict, etc.), the fix commits exist locally but didn't reach the PR. Still call step 6 with `outcome=failure` so the comment reflects the actual state. Tell the user the local commits remain in `<HEAD_BRANCH>` for them to investigate.

### 6. Update the comment with the final summary

Always run this step, regardless of step 4/5 outcome. Pass `outcome=success` only if both the engine and the push completed cleanly:

```bash
bash <helper-path> post-update "$HOST" "$OWNER" "$REPO" "$N" "$COMMENT_ID" "$MARKER" "$REPORT_PATH" "$AUTHOR" "$OUTCOME" "$STARTED_AT"
```

On a `success` outcome the helper also re-applies dismissed-finding suppression to the report before editing the comment (non-fatal: if the thread lookup fails, it warns and posts the unfiltered report — a dangling "starting" comment would be worse).

`$OUTCOME` is `success` or `failure`. The script PATCH-edits the starting comment (identified by `$COMMENT_ID`), replacing its body entirely with:

- A header line: `review-anvil-improve-pr completed on this PR. cc @<author>.` (success) OR `review-anvil-improve-pr **failed** on this PR. cc @<author>.` (failure).
- A horizontal rule + the full report from `<REPORT_PATH>`.
- A footer: `Started: $STARTED_AT; Completed: <ISO-8601 UTC> (outcome: <outcome>)`.

GitHub does **not** notify on comment edits, so the author isn't pinged again — the original `cc @author` notification from step 3 is the only ping.

Before calling `post-update` on a success outcome, read `<REPORT_PATH>.followups.json` (if present) and surface its entries to the user — the script deletes it afterwards. The script cleans up all four artifacts (`<REPORT_PATH>`, `.inline.json`, `.approval.json`, `.followups.json`) and removes the `.review-anvil/` directory when no other run's artifacts remain.

If `post-update` itself fails (rare: transient `gh` issue, comment was deleted by hand mid-run), surface the error but **do not undo the push** — the fix commits are already on the PR and a missing comment edit is recoverable. The user can manually edit the starting comment using the comment ID. The report file remains on disk for that purpose (cleanup is skipped on `post-update` failure).

### 7. Report back

Surface the engine's final report inline. Echo a two-line summary:
- `pushed N commits to $HOST/$OWNER/$REPO#$N ($HEAD_BRANCH)` with `N` from the final report's Total section. If step 5 was skipped (failure path), say `did not push (engine/run failure)` instead.
- `comment $COMMENT_URL updated with outcome=$OUTCOME` (or `comment update failed: ...` if step 6 errored).

## Examples

- *"Improve the PR I'm on."* — user is checked out on a PR branch; agent invokes `verify-checkout` with no locator; helper auto-detects.
- *"Run 5 rounds on acme/widgets#137."* — user passes the slug and asks for more rounds; engine default is overridden via the trailing `rounds: 5` arg.
- *"Review and improve this PR with focus on production safety."* — user asks for a non-default focus; flows through as `focus: production blast-radius` (or similar) to the engine.

## Constraints

- Requires `gh`, `uuidgen`, `jq` (a real binary — gh's `--jq` is built-in gojq and doesn't count), plus `uv` (preferred; falls back to `python3`) for dismissed-finding handling. `verify-checkout` preflights all of these so a missing dependency fails before the expensive review. The helper honors the same environment switches as `review-anvil-pr` (`REVIEW_ANVIL_NO_APPROVE`, `REVIEW_ANVIL_SKIP_DISMISSED`, `REVIEW_ANVIL_DISMISSALS`).
- **Mutates the local working tree and pushes to the PR.** Use `review-anvil-pr` (read-only + comment) when you only want feedback without applying fixes.
- The user must already be on the PR's branch with a clean worktree. The verify-checkout step enforces this and gives clear recovery instructions on failure (e.g. `gh pr checkout <N>`).
- The PR must be one you have push access to. `git push` will fail with a normal git error if not — the script doesn't pre-check push permissions.
- Supports github.com and GitHub Enterprise — same handling as `review-anvil-pr`.

## Recovery: dangling "starting" comment

The two-step `post-start` / `post-update` flow has one failure mode the previous one-shot didn't: if the orchestrator crashes (or the agent host loses context, or the user interrupts) **between step 3 and step 6**, the PR is left with a "starting" comment that promises an edit-that-never-comes. The fix commits may or may not have been pushed depending on where the crash happened.

This is rare but recoverable. If you find a dangling starting comment:

1. Find the comment URL on the PR. The body starts with `<!-- review-anvil-marker: <UUID> -->` and `review-anvil-improve-pr started on this PR.` The numeric comment ID is at the end of the URL (`...#issuecomment-<ID>`).
2. Edit the comment manually with `gh api`:
   ```bash
   gh api repos/<owner>/<repo>/issues/comments/<COMMENT_ID> -X PATCH \
     -F body="review-anvil-improve-pr failed: orchestrator did not complete. No reliable summary available."
   ```
   Or use the GitHub web UI's "Edit" menu on the comment.

If the orchestrator is still alive and the engine completed but step 6 was somehow skipped, the report is still on disk at the path printed by step 4 — you can paste it into the edit body verbatim.

If the engine never ran (crash between steps 3 and 4), nothing was pushed; just edit the comment to a "did not complete" note as above.

## Pairing

Depends on the `review-anvil` engine AND the `review-anvil-pr` preset (whose `scripts/pr-helper.sh` this skill reuses). All three ship in the same plugin and should be installed together (`npx skills add mrshu/agent-skills --skill review-anvil --skill review-anvil-pr --skill review-anvil-improve-pr`, or just `--all`).
