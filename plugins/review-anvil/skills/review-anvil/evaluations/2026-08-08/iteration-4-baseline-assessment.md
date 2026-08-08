# Iteration 4 baseline — review request, not existing fix

## Corpus

The 2026-08-08 UTC GitHub queries contain author replies but no new review-anvil review on the requested PR set. This iteration therefore retains the frozen 22-comment 2026-08-07 corpus from PRs 190, 197, 203, 204, 223, 226, 227, 230, and 235.

The new baseline is the selected branch at `36804cc`: the 22 Sol comments in `actor-final-generator-sol.json`. Every source run was review-only; the reviewer applied no fix.

## Observed failure

Three fresh, sessionless Sol, Luna, and Terra evaluators assessed the selected comments in review-only context. All three marked all 22 comments as falsely implying that an existing fix had been implemented.

| Evaluator | Existing-fix presuppositions | Mean requested-change clarity | Fact-safe count |
|---|---:|---:|---:|
| Sol | 22/22 | 2.0/5 | 0/22 |
| Luna | 22/22 | 3.0/5 | 22/22 |
| Terra | 22/22 | 3.0/5 | 0/22 |

Sol and Terra treated the false implementation claim as an unsupported fact; Luna recorded the same ambiguity separately from technical preservation. The disagreement does not affect the central result: 66/66 judgments found the same presupposition.

Five additional clean Sol generation reps applied the current contract to six untouched review-only findings. Four of five reps produced false implementation language. Across 30 generated comments:

- 11 explicitly used `the fix` or `in the fix`;
- 13 used unmarked present-tense desired behavior that reads as current code;
- 6 retained suggestion grammar without implying implementation;
- one invented that the offline entry-point test “covers this boundary,” a purpose absent from the source.

The current contract therefore shapes the wrong speech act. It turns reviewer guidance into a report about code that does not exist.

## Research extension

Google's official code-review guidance says the developer, not the reviewer, is responsible for fixing the change. Reviewers should balance problem statements with direct guidance and make required versus optional intent explicit. The OpenDev study reports that usefulness depends on comprehensibility and politeness as well as technical contribution.

Sources:

- https://google.github.io/eng-practices/review/reviewer/comments.html
- https://arxiv.org/abs/2302.11686

## Design options

1. **Direct requested changes — selected.** Keep the diagnostic problem and consequence, then express source-backed remediation as concrete imperatives: `Use the shared top-level parser in the module entry point. Add one offline entry-point test.` This is actionable and does not claim implementation.
2. **Visible `Requested change:` label.** Maximally explicit, but adds repeated UI-like prose to every inline comment and competes with the existing severity label.
3. **Unmarked desired state.** Shortest, but repeats the baseline failure because present tense can describe current code.

## Selected contract

- Treat remediation as a request, not an observed fix.
- Never write `the fix`, `in the fix`, or `the corrected path` unless the source explicitly discusses an existing patch under review.
- For required findings, use one or two concrete imperative sentences backed exactly by the source plan.
- Preserve optionality for low or nit guidance with `Consider` or the source modal.
- If no source-backed remediation exists, stop after the consequence instead of inventing one.
- Do not invent a purpose for a requested test. Preserve `one offline entry-point test` exactly when that is all the source establishes.
- Keep the bidirectional fact lock, title fallback, identifiers, severity, IDs, and artifact protocol unchanged.

## Next experiment

Add failing contract tests for requested-change language, then replace the outcome recipe and renderer examples. Run five clean generation microtests, a three-generator fact/readability tournament, and a fresh untouched holdout before selection.
