# Iteration 9 assessment — reject the contract, keep the rendering direction

## Question

Can a source-unit action lock recover the readability gains from iteration 8
without allowing necessary post-change behavior to remain modal prose?

## Result

Not yet. The clean Sol generator produced a strong rendering result, but the
written contract is internally ambiguous. Iteration 9 is not a safe final
skill.

All three generators returned 47 schema-valid comments. The readability test
randomized baseline and Sol labels independently for each of the 22 development
comments. Across three clean judges, Sol won 22 comparisons, baseline won 4,
and 40 tied. Sol improved action recall, scanability, and cognitive ease for all
three judges. Naturalness fell slightly: 0.228 points for Claude, 0.136 for Sol,
and 0.046 for Terra.

The two complete fact/action audits found no common fact loss in the Sol output.
Their action labels were not reliable enough to act as ground truth. They often
called source-backed regression tests or target-state constraints optional
because the source used `would`, `can`, or similar modal wording. Those raw
results remain in `iteration-9-summary.json`; the assessment does not silently
reinterpret them as passes.

## Independent contract review

A clean Claude Opus review returned `changes requested`:

- **P0:** The omission-counterfactual rule can promote a permitted boundary to
  author work, while the nearby modality rule forbids that promotion. The
  contract does not say which rule wins.
- **P0:** A predicate such as "Unresolved keys can be reported after the valid
  metrics are preserved" remains underdetermined. Different readers can treat
  it as mandatory work or allowed behavior.
- **P1:** The dense-sentence fallback can preserve a mixed action and modality
  sentence instead of resolving its units.

These are contract defects even though Sol happened to render the diagnostic
corpus well. Luna and Terra demonstrated the failure mode by leaving necessary
post-change boundaries in prose on several stress cases.

## Corpus status

The 25-comment historical holdout was opened during iteration 8. It is
therefore diagnostic evidence here, not a sealed holdout. A read-only scan for
same-day comments created after the original cutoff found zero eligible
comments across zero PRs. No second same-day sealed holdout exists.

## Decision and next step

Reject commit `98c0ac8` as the final skill. Preserve the branch and evidence
because it identifies a useful rendering direction:

1. Keep one short diagnosis paragraph.
2. Put independently required work in `**Requested actions**` bullets.
3. Keep true preservation rules and permissions in prose next to the action
   they constrain.

The next contract must define precedence explicitly. First classify current
behavior versus target behavior. Then apply the omission counterfactual to the
target state. Modal grammar must never decide the classification, but an
explicitly optional follow-up must never become mandatory work. Mixed
sentences must be split before rendering; there is no dense-sentence escape
hatch.
