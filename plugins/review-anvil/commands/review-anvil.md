---
description: Iterative multi-agent review-and-fix loop — N rounds of parallel codex-exec + claude-exec reviewers, with edits and per-fix-group commits.
argument-hint: [rounds] [N codex + M claude] [focus: ...] [only: ...] [target: ...] [min_fix_severity: ...] [allow_new_deps]
---

Invoke the `review-anvil` skill with the user's free-form arguments and no pinned parameters — the full skill arg surface is available.

Concretely:

- Read the args as a free-form string: `$ARGUMENTS`
- Invoke: `Skill review-anvil` with `$ARGUMENTS` verbatim.

This is the *productive* path: the skill reviews, synthesizes, applies fixes, and creates one commit per logical fix-group per round. Use `/review-anvil-review` if you want a read-only pass instead.

Examples:

- `/review-anvil` → 3 rounds, default mix (2 codex + 1 claude), four-pillar focus, auto-detected target, auto-fix gated at severity ≥ medium.
- `/review-anvil 5 rounds, focus: async correctness, target: PR #42` → fully specified.
- `/review-anvil only: security, fix only critical` → narrow focus, severity gate raised to critical.
- `/review-anvil allow new deps, focus: production blast-radius` → opt into the prod-hardening pass.

See `Skill review-anvil` / SKILL.md for the full parameter surface (`rounds`, `agents`, `focus`, `target`, `min_fix_severity`, `allow_new_deps`, `commit_mode`, `post_to_review`).
