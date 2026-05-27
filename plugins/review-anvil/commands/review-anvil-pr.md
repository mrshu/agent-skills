---
description: Read-only review of a code-review unit (GitHub PR, GitLab MR, Gitea PR, …) with the synthesized report posted back as a comment (notifies the author).
argument-hint: <locator> [rounds: N] [N codex + M claude] [focus: ...] [only: ...]
---

Thin wrapper around the `review-anvil` skill. Parses the first token as a review-unit locator, pins the safety params, and forwards to the skill. All other behavior — locator grammar, forge detection, posting strategy chain, validation — is defined in SKILL.md and inherited by this wrapper.

**Pins (non-overridable):** `commit_mode: none`, `target: <locator>`, `post_to_review: <locator>`
**Defaults (user can override):** `rounds: 2`

Assembly (per SKILL.md → "Wrapper pins vs. wrapper defaults"):

```
commit_mode: none, target: <locator>, post_to_review: <locator>, <user-args>, rounds: 2
```

The `<locator>` is the *first* whitespace-delimited token of `$ARGUMENTS`. The same locator string is used for both `target` and `post_to_review` so the skill's cross-parameter validation can compare canonical forms (see SKILL.md → "Resolving the locator"). If no locator is supplied, abort with: `usage: /review-anvil-pr <locator> [extra args]`.

Examples:

- `/review-anvil-pr 42` → bare integer; resolved against the current repo's default remote (see SKILL.md → "Bare-integer safety").
- `/review-anvil-pr acme/widgets#137 rounds: 1` → bare slug; defaults to github.com.
- `/review-anvil-pr gitlab.com:acme/widgets#137` → host-qualified slug; review and post on GitLab.
- `/review-anvil-pr https://github.com/acme/widgets/pull/137 only: security, 3 codex + 1 claude` → full URL; security-only review with a heavier reviewer mix.

Despite the `-pr` suffix, the wrapper accepts any forge URL the skill knows about (GitHub PR, GitLab MR, Gitea/Forgejo PR; v1 fully specifies GitHub and aborts during locator resolution for unsupported forges).
