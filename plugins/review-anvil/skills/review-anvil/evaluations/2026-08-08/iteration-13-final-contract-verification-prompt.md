Research only. Do not edit files or run tests.

Perform a final focused verification of the current review-anvil branch after
the fixes to A1, A2, and B1-B6 in
`skills/review-anvil/evaluations/2026-08-08/iteration-13-final-contract-recheck-claude.md`.

Verify:
- every rendered predicate, including invented modal boundaries and accepted
  behavior, is mapped to a source predicate and has an output issue bucket;
- auditors are explicitly told to copy opaque canonical IDs verbatim;
- per-row validation preserves valid sibling rows and fails closed only for
  affected rows;
- the emitted body must be byte-identical to the audited body;
- verified exact source suggestions are preserved;
- the assessment no longer mixes ranking scales and records the review fixes;
- report-artifacts formatting is consistent.

Read the current diff, skill, action-lock reference, report-artifacts reference,
language tests, assessment, and prior two review files. Return remaining
Critical, Important, and Minor findings with exact paths/lines, then a Verdict.
State `none` for empty severity sections. Do not repeat resolved findings.
