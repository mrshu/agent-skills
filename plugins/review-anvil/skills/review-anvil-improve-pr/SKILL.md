---
name: review-anvil-improve-pr
description: Multi-agent review-and-improve loop for a GitHub PR you have checked out — runs N rounds of parallel reviewers, applies fix commits to the local branch after each round, then pushes everything back to the PR. Auto-detects the PR from the currently checked-out branch when no locator is supplied. Use when the user wants to "improve a PR", "review and commit fixes", "iterate on my PR", or "review and push back" against a checked-out PR branch. Requires `gh` on PATH. Activates the `review-anvil` engine in per_fix mode.
---

# review-anvil-improve-pr

Productive counterpart to `review-anvil-pr`. Where `review-anvil-pr` is read-only and posts a review comment, this preset **actually modifies the code**: it runs the review loop with `commit_mode=per_fix`, applies fix commits to the local branch across N rounds, and pushes the result back to update the PR.

The skill orchestrates four steps:

1. `scripts/pr-helper.sh verify-checkout [<locator>]` — locator parsing or auto-detect, then verify the local checkout matches the PR's head branch and is in a clean state. Captures the PR's base branch for the diff target.
2. The [`review-anvil`](../review-anvil/SKILL.md) engine in `commit_mode=per_fix` on a branch-vs-base diff (NOT a PR-locator target — the engine's v0.4.1 incompatibility rule forbids that combination; this preset deliberately routes around it by targeting the local branch directly).
3. `git push` — once, after all rounds complete and only if the engine reported no failures, to publish the fix commits to the PR.
4. Surface the final report to the user inline; the PR is updated by the push.

## Inputs

Same locator forms as `review-anvil-pr` — but you must already be on the PR's branch:

- **Omitted** — auto-detect via `gh pr view`; works when you're checked out on a PR branch.
- **Full GitHub URL** — `https://<host>/<owner>/<repo>/pull/<N>` for github.com or GitHub Enterprise.
- **Slug** — `<owner>/<repo>#<N>` (host defaults to github.com).

The helper script aborts cleanly if the current checkout doesn't match the named PR (wrong branch, dirty worktree, detached HEAD, divergent SHA). This is the safety net for "I'm on PR #42's branch, run improve" — without it, the engine could commit fixes to an unrelated local branch.

## How to invoke

### 0. Reject overrides of pinned params

Pins for this preset: `commit_mode`, `target`. Apply the canonical pin-rejection algorithm defined in the engine SKILL.md → "Preset pin-rejection" (segment-parse `$ARGUMENTS`, lowercase the key of each segment, abort if any key matches one of the pinned params). The preset name in the abort message is `review-anvil-improve-pr`.

The pins are non-overridable for safety: `commit_mode=per_fix` is the whole point of this preset (read-only is what `review-anvil-pr` is for), and `target=<base>...HEAD` is mechanically tied to the verified PR.

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
BASE_BRANCH=main
TITLE=<PR title>
```

If the locator was auto-detected, the script also prints `auto-detected PR: <url>` to stderr before the KEY=VALUE block. If HEAD is ahead of the PR's published head (unpushed local commits), the script prints a `note:` to stderr — surface that to the user so they know what will get pushed.

Capture all values. Echo to the user: `improving PR: $HOST/$OWNER/$REPO#$N — $TITLE ($HEAD_BRANCH → $BASE_BRANCH)`.

On non-zero exit, surface the script's stderr verbatim and stop. Do not dispatch reviewers.

### 3. Activate the engine

Activate the `review-anvil` skill with this argument string (extra user args go between the pinned params and the rounds default):

```
commit_mode: per_fix, target: <BASE_BRANCH>...HEAD, <extra-user-args>
```

`<BASE_BRANCH>` is the PR's base from step 2. Using `<BASE_BRANCH>...HEAD` (three-dot diff) targets exactly the commits that distinguish this PR from its base, which is what we want to review.

Note: do **not** pin a PR locator as `target` — the engine's "PR-target / per_fix incompatibility" rule would force `commit_mode=none` and defeat the point of this preset. Targeting the branch directly is the intended escape hatch.

The user may override `rounds:` (default is the engine's `rounds: 3` for productive loops). They should not override `commit_mode` or `target` — these are pinned for safety; the step-0 segment-rejection above blocks override attempts.

The engine runs the multi-round loop, committing fix-groups along the way. If any round fails (reviewer-all-fail, git-commit error), the engine stops the loop and surfaces the failure.

### 4. Push

Only after the engine reports a successful run (all requested rounds completed, no `git commit failed` or `all reviewers failed` errors in the round summaries):

```bash
git push origin "$HEAD_BRANCH"
```

If the engine's run was partial or failed, **do not push**. Surface the engine's failure to the user, leave the partial commits in the local branch, and recommend they investigate before pushing manually.

### 5. Report back

Surface the engine's final report inline. Echo a one-line summary: `pushed N commits to <HOST>/<OWNER>/<REPO>#<N> (<HEAD_BRANCH>)` with `N` being the count from the final report's Total section.

## Examples

- *"Improve the PR I'm on."* — user is checked out on a PR branch; agent invokes `verify-checkout` with no locator; helper auto-detects.
- *"Run 5 rounds on acme/widgets#137."* — user passes the slug and asks for more rounds; engine default is overridden via the trailing `rounds: 5` arg.
- *"Review and improve this PR with focus on production safety."* — user asks for a non-default focus; flows through as `focus: production blast-radius` (or similar) to the engine.

## Constraints

- Requires `gh` on `PATH` and `uuidgen` (used by the shared helper).
- **Mutates the local working tree and pushes to the PR.** Use `review-anvil-pr` (read-only + comment) when you only want feedback without applying fixes.
- The user must already be on the PR's branch with a clean worktree. The verify-checkout step enforces this and gives clear recovery instructions on failure (e.g. `gh pr checkout <N>`).
- The PR must be one you have push access to. `git push` will fail with a normal git error if not — the script doesn't pre-check push permissions.
- Supports github.com and GitHub Enterprise — same handling as `review-anvil-pr`.

## Pairing

Depends on the `review-anvil` engine AND the `review-anvil-pr` preset (whose `scripts/pr-helper.sh` this skill reuses). All three ship in the same plugin and should be installed together (`npx skills add mrshu/agent-skills --skill review-anvil --skill review-anvil-pr --skill review-anvil-improve-pr`, or just `--all`).
