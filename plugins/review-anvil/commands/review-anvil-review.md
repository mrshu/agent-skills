---
description: Read-only review pass — N rounds of parallel codex-exec + claude-exec reviewers, no edits, no commits.
argument-hint: [rounds] [N codex + M claude] [focus: ...] [only: ...] [target: ...]
---

Invoke the `review-anvil` skill with `commit_mode=none` pinned and `rounds=1` as the default. Pass through any remaining free-form arguments the user supplied.

Concretely:

- Read the args as a free-form string: `$ARGUMENTS`
- Build the skill arg string by **prepending** `commit_mode: none, rounds: 1, ` and then concatenating `$ARGUMENTS`. (If the user explicitly supplied `rounds: N` in their args, their value wins because their string is parsed after — this is fine; the default-rounds line above is just for the no-args case.)
- Invoke: `Skill review-anvil` with the assembled arg string.

Examples of what the user might type:

- `/review-anvil-review` → 1 round, default mix, auto-detected target, no commits.
- `/review-anvil-review 2 rounds, focus: security` → 2 rounds of reviewer redundancy on the security axis, no commits.
- `/review-anvil-review target: PR #42, only: production blast-radius` → review PR 42 for prod-readiness only, no commits.
- `/review-anvil-review 3 claude reviewers, target: src/auth/` → 1 round × 3 claude-exec reviewers on src/auth/, no commits.

The skill will emit the standard final report inline. Because `commit_mode=none`, the report includes a "Would-apply" block showing which findings *would* have been auto-fixed if the user re-runs without `-review`.
