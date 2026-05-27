---
description: Read-only review of a GitHub PR with the synthesized report posted back as a PR comment (notifies the author).
argument-hint: <pr-number-or-url> [rounds] [N codex + M claude] [focus: ...] [only: ...]
---

Invoke the `review-anvil` skill in **review-only mode** against a specific PR. The skill posts the synthesized report back to that PR via the host's GitHub interface (see SKILL.md → "Posting to a PR" for the strategy chain — `gh`, GitHub MCP, or raw REST API). This command does **not** prescribe a GitHub client; it only forwards the PR locator and lets the skill pick.

Steps:

1. Parse the first whitespace-delimited token of `$ARGUMENTS` as the PR identifier. Accept any of: a bare number (`42`), an `<owner>/<repo>#<N>` slug, or a full PR URL (`https://github.com/<owner>/<repo>/pull/<N>`). Keep the full form — the skill's posting step needs `owner`/`repo` for any non-default-repo target.
2. If no PR identifier is supplied, abort with: `usage: /review-anvil-pr <pr-number-or-url> [extra args]`.
3. Assemble the skill arg string per SKILL.md → "Wrapper pins vs. wrapper defaults":
   - **Pins (prepend, non-overridable):** `commit_mode: none`, `target: PR #<locator>`, `post_to_pr: <locator>` (carry the full locator — URL, slug, or bare number as supplied)
   - **User args:** the rest of `$ARGUMENTS` after the PR identifier
   - **Default (append, user can override):** `rounds: 2`
   Concretely: `commit_mode: none, target: PR #<locator>, post_to_pr: <locator>, <user-args>, rounds: 2`
4. Invoke: `Skill review-anvil` with the assembled arg string.

The skill is responsible for:
- Resolving the locator into `owner`/`repo`/`number` (URL parse, slug parse, or remote inference for bare numbers).
- Running the full review loop with no edits/commits.
- After the final round, posting the report to the PR via whichever strategy the host environment supports (`gh` → GitHub MCP → REST API), and surfacing the resulting comment URL — or `posted (URL unavailable)` if the chosen strategy cannot return one.
- Falling back to inline-only review with a one-line warning if every posting strategy fails.

Examples:

- `/review-anvil-pr 42` → 2 rounds on PR 42 of the current repo, default mix, default focus, post synthesis back to PR.
- `/review-anvil-pr acme/widgets#137 rounds: 1` → single-round quick review of PR 137 in acme/widgets (no working-dir dependency), posted back.
- `/review-anvil-pr https://github.com/acme/widgets/pull/137 only: security, 3 codex + 1 claude` → security-only review with a heavier reviewer mix.

Notes:

- Never include `commit_mode: per_fix` here — `/review-anvil-pr` is intentionally read-only because the PR's branch may not be checked out locally and pushing commits to someone else's PR is rarely the intent. The pin guarantees this even if `$ARGUMENTS` tries to override it.
- This command does not preflight the PR's reachability — the skill's posting step degrades gracefully if posting fails, so a separate preflight would only duplicate that logic and couple the wrapper to a specific GitHub client.
