---
name: review-anvil-readonly
description: Multi-agent code review without any edits or commits — N rounds of parallel reviewers, synthesis, and a final report. Use when the user wants a code review of a diff, branch, path, or PR but does NOT want any fixes applied automatically (no edits, no commits, no staging). Activates the `review-anvil` engine in read-only mode.
---

# review-anvil-readonly

Thin preset that runs the multi-agent review loop without applying any fixes. Activates the [`review-anvil`](../review-anvil/SKILL.md) engine skill with `commit_mode=none` and a default of `rounds=1`.

## How to invoke

The agent reads the user's request, then activates `review-anvil` with this argument string:

```
commit_mode: none, <pass-through any args the user specified>, rounds: 1
```

**Assembly order matters.** The engine parses left-to-right with first-occurrence-wins precedence. Pinned values (`commit_mode: none`) go *before* user args so the pin is authoritative. Defaults the user can override (`rounds: 1`) go *after* user args so any user-supplied `rounds: N` wins.

**Pin-rejection (defense in depth).** Pins for this preset: `commit_mode`. Before assembling, apply the canonical pin-rejection algorithm defined in the engine SKILL.md → "Parsing" (pin-rejection) (segment-parse `$ARGUMENTS`, lowercase the key of each segment, abort if any key matches `commit_mode`). The preset name in the abort message is `review-anvil-readonly`.

Pass-through args the user may specify (each documented in the engine's SKILL.md):

- `target: PR #42` / `target: src/auth/` / `target: branch` / `target: uncommitted` — what to review
- `focus: <topic>` — narrow the four-pillar focus, or `only: <topic>` to replace it
- `rounds: N` — the user's value wins over the default `rounds: 1`
- `agents: 2 codex + 1 claude` — custom reviewer mix

After the engine completes, surface the synthesized report inline. **Do not** follow with edits, commits, or any side effects — that's exactly what `commit_mode=none` rules out.

## When not to use this

- If the user wants fixes applied and committed, activate `review-anvil` directly with `commit_mode=per_fix` (or just leave it default).
- If the user wants the report posted back to a GitHub PR comment, activate `review-anvil-pr` instead.

## Engine reference

See [`../review-anvil/SKILL.md`](../review-anvil/SKILL.md) for: full parameter surface, mix policy, focus options, reviewer prompt template, and final report format. This preset is a one-line argument addition; all behavior comes from the engine.
