You are a strict independent reviewer. Research only; do not edit files.

Review commit `98c0ac8` against parent `411b002` in the current repository. This is a language-contract change for review-anvil inline comments. The intended invariant is:

1. Every post-change behavior whose omission leaves the reported defect or a required boundary unresolved must be an explicit author request, even when written with `can`, `could`, or `may`.
2. True preservation constraints and genuinely optional follow-ups must remain modal prose and must not become action bullets.
3. Compound sentences must be classified predicate by predicate.
4. The contract must remain easy for clean agents to follow and must not contradict existing reviewer/report rules.

Stress-test the change against these previously missed source behaviors:

- enter invalid rows in `SourceConversionResult`;
- mark missing prompt content while legacy values remain unset;
- reject existing logical output while sidecar validation remains streaming;
- fail by default for symlinks, roots, and populated targets until an ownership manifest exists;
- restrict tolerance to scale classification while adding a strict pre-publication check.

Also verify that this standalone permission stays optional: `Unresolved keys can be reported after the valid metrics are preserved.`

Inspect the full relevant contract, not only changed lines. Check for contradictions, ambiguous terminology, false-action risk, missing tests/examples, unnecessary complexity, and maintainability. Do not judge generated evaluation results; review the contract and its static tests.

Return:

- Verdict: `ready` or `changes requested`.
- Findings ordered by severity (`P0`, `P1`, `P2`) with exact file:line references, evidence, consequence, and a concrete fix.
- A short note on whether the six stress cases are classified correctly by the written rules.
- If there are no material findings, say so explicitly.
