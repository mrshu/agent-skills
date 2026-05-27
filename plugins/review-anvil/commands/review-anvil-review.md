---
description: Read-only review pass — N rounds of parallel codex-exec + claude-exec reviewers, no edits, no commits.
argument-hint: [rounds: N] [N codex + M claude] [focus: ...] [only: ...] [target: ...]
---

Thin wrapper around the `review-anvil` skill. Pins read-only mode, forwards everything else. See SKILL.md → "Wrapper pins vs. wrapper defaults" for assembly semantics.

**Pin (non-overridable):** `commit_mode: none`
**Default (user can override):** `rounds: 1`

Assembly:

```
commit_mode: none, <user-args>, rounds: 1
```

Examples:

- `/review-anvil-review` → 1 round, default mix, auto-detected target, no commits.
- `/review-anvil-review rounds: 2, focus: security` → 2 rounds of reviewer redundancy on the security axis.
- `/review-anvil-review target: PR #42, only: production blast-radius` → review PR 42 for prod-readiness only.
- `/review-anvil-review 3 claude reviewers, target: src/auth/` → 1 round × 3 claude-exec reviewers on src/auth/.

The skill emits the standard final report inline. Because `commit_mode=none`, the report includes a "Would-apply summary" block listing the fixes that would have been auto-applied if the user re-runs without `-review`.
