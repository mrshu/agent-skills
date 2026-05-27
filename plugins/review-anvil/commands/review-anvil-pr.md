---
description: Read-only review of a GitHub PR with the synthesized report posted back as a PR comment (notifies the author).
argument-hint: <pr-number-or-url> [rounds] [N codex + M claude] [focus: ...] [only: ...]
---

Invoke the `review-anvil` skill in **review-only mode** against a specific PR, then post the final report back to that PR as a top-level `gh pr comment` so the author is notified.

Steps:

1. Parse the first whitespace-delimited token of `$ARGUMENTS` as the PR identifier. Accept either a bare number (`42`) or a full PR URL (`https://github.com/owner/repo/pull/42`). Extract the PR number `N`.
2. If no PR identifier is supplied, abort with: `usage: /review-anvil-pr <pr-number-or-url> [extra args]`.
3. Verify the PR is reachable: `gh pr view <N> --json number,headRefName,author,title`. If this fails, surface the gh error and stop — do not proceed to dispatch reviewers.
4. Build the skill arg string by prepending:
   - `commit_mode: none`
   - `target: PR #<N>`
   - `post_to_pr: <N>`
   - default `rounds: 2` (one round is often enough for read-only PR feedback; two gives the reviewers a chance to converge on what matters most — the user can override by passing `rounds: K` in the trailing args)
   …and then appending the remaining `$ARGUMENTS` after the PR identifier so the user's overrides win.
5. Invoke: `Skill review-anvil` with the assembled arg string.

The skill is responsible for:
- Running the full review loop with no edits/commits.
- After the final round, writing the report to a temp file and posting it via `gh pr comment <N> --body-file <path>`.
- Reporting the resulting comment URL back inline.

Examples:

- `/review-anvil-pr 42` → 2 rounds on PR 42, default mix, default focus, post synthesis back to PR.
- `/review-anvil-pr 42 only: security, 3 codex + 1 claude` → security-only review with a heavier reviewer mix.
- `/review-anvil-pr https://github.com/acme/widgets/pull/137 rounds: 1` → single-round quick review of PR 137, posted back.

Notes:

- Never include `commit_mode: per_fix` here — `/review-anvil-pr` is intentionally read-only because the PR's branch may not be checked out locally and pushing commits to someone else's PR is rarely the intent.
- If `gh` is missing or the post fails, the skill still prints the report inline; the post failure is surfaced as a single-line warning, not a hard abort.
