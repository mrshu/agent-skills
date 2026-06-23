---
name: review-anvil-readonly
description: Multi-agent code review without any edits or commits — requested rounds of parallel reviewers, synthesis, and a final report. Use when the user wants a code review of a diff, branch, path, or PR but does NOT want any fixes applied automatically (no edits, no commits, no staging). Activates the `review-anvil` engine in read-only mode.
---

# review-anvil-readonly

Thin preset that runs the multi-agent review loop without applying any fixes. Activates the [`review-anvil`](../review-anvil/SKILL.md) engine skill with `commit_mode=none` and a default of `rounds=1`.

## How to invoke

The agent reads the user's request, then activates `review-anvil` with this argument string:

```
commit_mode: none, <pass-through any args the user specified>, rounds: 1
```

**Assembly order matters.** The engine parses left-to-right with first-occurrence-wins precedence. Pinned values (`commit_mode: none`) go *before* user args so the pin is authoritative. Defaults the user can override (`rounds: 1`) go *after* user args so any user-supplied `rounds: N` wins.

**Pin-rejection (defense in depth).** Pins for this preset: `commit_mode`. If the `review-anvil-pr` helper script is resolvable (this preset ships no script of its own), enforce mechanically: `bash <pr-helper-path> check-pins review-anvil-readonly "commit_mode" "$ARGUMENTS"` — non-zero exit means abort with the script's error verbatim. Otherwise apply the engine's prose pin-rejection algorithm ("Parsing" section); the abort-message preset name is `review-anvil-readonly`.

Pass-through args the user may specify (non-exhaustive — any engine param not pinned here works; each is documented in the engine's SKILL.md):

- `target: PR #42` / `target: src/auth/` / `target: branch` / `target: uncommitted` — what to review
- `focus: <topic>` — narrow the four-pillar focus, or `only: <topic>` to replace it
- `rounds: N` — the user's value wins over the default `rounds: 1`
- `agents: 2 codex + 1 claude` — custom reviewer mix
- `min_fix_severity: <sev>` — drives the would-apply/suggestions split in the read-only report
- `adversarial: auto|challenge|targeted|full|strict` — optional adversarial review that attacks false positives and disproportionate/bloated fix plans before the final report
- `adversarial_rounds: 1|2`, `disagreement_policy: defer|comment` — tune the adversarial gate; it remains read-only and bounded
- `reviewer_timeout: <seconds>`, `report_path: <file>` — as in the engine

After the engine completes, surface the synthesized report inline. **Do not** follow with edits, commits, or any side effects — that's exactly what `commit_mode=none` rules out.

Adversarial review is still `commit_mode=none`: no edits, no commits, no
staging, no pushes. Temporary prompt/reviewer/report artifacts under
`.review-anvil/` or an explicit `report_path` are allowed. It can make the
report more conservative by dropping false positives, deferring harmful or
tech-debt-heavy fix plans, hardening fix prose, or stripping unsafe suggestion
blocks.

Default local policy: leave adversarial review off for ordinary fast/local
reviews. Append `adversarial: auto` when the user asks for a careful,
skeptical, high-confidence, low-noise, thorough, or production-ready read-only
review. Do not append it when the user asks for a quick/rough/sanity pass unless
they explicitly request adversarial review.

## When not to use this

- If the user wants fixes applied and committed, activate `review-anvil` directly with `commit_mode=per_fix` (or just leave it default).
- If the user wants the report posted back to a GitHub PR comment, activate `review-anvil-pr` instead.

## Engine reference

See [`../review-anvil/SKILL.md`](../review-anvil/SKILL.md) for: full parameter surface, mix policy, focus options, reviewer prompt template, and final report format. This preset is a one-line argument addition; all behavior comes from the engine.
