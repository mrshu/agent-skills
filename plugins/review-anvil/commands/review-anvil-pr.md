---
description: Read-only review of a GitHub PR with the synthesized report posted back as a PR comment (notifies the author).
argument-hint: <pr-number-or-url> [rounds] [N codex + M claude] [focus: ...] [only: ...]
---

Invoke the `review-anvil` skill in **review-only mode** against a specific PR, then post the final report back to that PR as a top-level `gh pr comment` so the author is notified.

Steps:

1. Parse the first whitespace-delimited token of `$ARGUMENTS` as the PR identifier. Accept either a bare number (`42`) or a full PR URL (`https://github.com/owner/repo/pull/42`). Extract the PR number `N`.
2. If no PR identifier is supplied, abort with: `usage: /review-anvil-pr <pr-number-or-url> [extra args]`.
3. Verify the PR is reachable: `gh pr view <locator> --json number,headRefName,author,title` (where `<locator>` is the URL, `<owner>/<repo>#<N>`, or bare `<N>` per step 4a). If this fails:
   - If the failure is fatal — i.e. the user supplied a non-existent PR or `gh` is not installed at all — stop and surface the error, since dispatching reviewers against an invalid target would waste budget on useless work.
   - If the failure is *recoverable in spirit* — `gh` is installed but unauthenticated, or the API is temporarily down — proceed to dispatch reviewers anyway so the user still gets an inline report, but **clear `post_to_pr`** for this run so the skill does not attempt the post step that would also fail. Print a single-line warning: `warning: gh preflight failed (<reason>); proceeding with inline review and disabling post_to_pr`.
   This matches the skill-level "If gh is not installed or the post fails for any reason, print the report inline and a single-line warning" rule for the post step — failures at preflight and at post time both degrade to inline-only review rather than aborting.
4. Assemble the skill arg string per SKILL.md → "Wrapper pins vs. wrapper defaults":
   - **Pins (prepend, non-overridable):** `commit_mode: none`, `target: PR #<N>` (or the full locator — see step 4a below), `post_to_pr: <N>` (full locator)
   - **User args:** the rest of `$ARGUMENTS` after the PR identifier
   - **Default (append, user can override):** `rounds: 2`
   Concretely: `commit_mode: none, target: PR #<N>, post_to_pr: <N>, <user-args>, rounds: 2`
4a. **Preserve owner/repo identity.** If the user passed a full PR URL (`https://github.com/<owner>/<repo>/pull/<N>`), do **not** discard `owner/repo`. Either:
   - pass the full URL through to `gh pr view` / `gh pr comment` (both accept a URL in place of `<N>`), or
   - parse `owner/repo` and pass `-R <owner>/<repo>` to every `gh` invocation.
   The pinned `post_to_pr` parameter must carry the full locator (URL or `owner/repo#N`), not just the bare integer, so the skill's posting step targets the correct repository even from a different working directory.
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
