---
description: Read-only review of a GitHub PR with the synthesized report posted back as a PR comment (notifies the author).
argument-hint: <pr-number-or-url> [rounds: N] [N codex + M claude] [focus: ...] [only: ...]
---

Thin wrapper around the `review-anvil` skill. Parses the first token as a GitHub PR locator, pins the safety params, and forwards to the skill. Locator grammar, posting strategy chain, and validation are defined in SKILL.md.

**Pins (non-overridable):** `commit_mode: none`, `target: <locator>`, `post_to_review: <locator>`
**Defaults (user can override):** `rounds: 2`

Assembly (per SKILL.md → "Wrapper pins vs. wrapper defaults"):

```
commit_mode: none, target: <locator>, post_to_review: <locator>, <user-args>, rounds: 2
```

The `<locator>` is the *first* whitespace-delimited token of `$ARGUMENTS`. The same locator string is used for both `target` and `post_to_review` so the skill's cross-parameter validation can compare canonical forms. If no locator is supplied, abort with: `usage: /review-anvil-pr <pr-number-or-url> [extra args]`.

Examples:

- `/review-anvil-pr 42` → bare integer; resolved against the current repo's GitHub remote. **Note:** the bare-integer safety check (SKILL.md → "Bare-integer safety") refuses to proceed if the current branch does not match the PR's head branch, with no waiver — pass the URL or `<owner>/<repo>#<N>` slug form if you're not on the PR's branch.
- `/review-anvil-pr acme/widgets#137 rounds: 1` → slug form; explicit repo identity.
- `/review-anvil-pr https://github.com/acme/widgets/pull/137 only: security, 3 codex + 1 claude` → full URL; security-only review with a heavier reviewer mix.

v1 supports github.com and GitHub Enterprise. Non-GitHub URLs (GitLab, Gitea, etc.) abort during locator resolution; multi-forge support is a v2 concern.
