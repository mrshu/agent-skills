# Iteration 11 assessment — independent action-lock audit

## Question

Can a post-render verifier preserve the iteration-10 readability gain while preventing a readable rewrite from changing what the author must do?

## Change

The engine now freezes the minimum source context and exact requested-work prose for every accepted finding. A clean verifier compares that source with each rendered request section, classifies target work separately from accepted current behavior, and returns structured failures. The renderer repairs only failed comments, runs the audit once more, and restores the exact source prose if the second audit still fails.

The verifier uses a predicate ledger before passing an item. The contract includes counterexamples for mixed modal clauses, tests and documentation, permitted stopping points, retrieval-time identity, unresolved-key reporting, and proof-gated metric metadata.

## Audit development

| Gate | Sol | Terra | Result |
|---|---:|---:|---|
| First audit, requested work only | 38/47 pass | 41/47 pass | Too many context-free classification errors |
| Full audit with source context | 41/47 pass | 43/47 pass | Better, but missed known mixed predicates |
| Eight-case edge corpus after predicate ledger | 7 intended failures detected; safe control passed | 5 intended failures detected; safe control passed | Sol matched the adjudicated edge set |
| Seven repaired comments, second audit | 7/7 pass | 7/7 pass | Repair converged |

The first two rounds are retained as negative evidence. Adding source context removed false classifications such as treating an already-correct exit condition as new work. The predicate ledger and concrete counterexamples improved recall without failing the `llm_scoring` safe control.

## Final fact and action gate

Both clean final judges produced the same decoded result:

| Version | Fact-safe | Action-locked | False actions |
|---|---:|---:|---:|
| Today/unseen baseline | 47/47 | 15/47 (Sol), 16/47 (Terra) | 2 (Sol), 0 (Terra) |
| Luna before audit | 45/47 | 39/47 | 2 |
| Luna after audit and repair | 47/47 | 46/47 observed; 47/47 adjudicated | 0 |

Both final judges marked `3737449070` unlocked because they treated optional unresolved-key reporting as mandatory work. That contradicts the source predicate and the audit contract: valid metrics must be preserved; unresolved keys *can* be reported afterward. Both independent post-repair auditors passed the item. `iteration-11-final-fact-action-adjudication.json` records the correction.

## Final readability

The final corpus randomized the baseline, Sol, Luna before audit, and Luna after audit for each of 47 comments.

### Repaired Luna versus baseline

| Slice | Sol judge | Terra judge | Combined |
|---|---:|---:|---:|
| All 47 comments | 41–6 | 34–13 | **75–19** |
| 39 changed comments | 36–3 | 29–10 | **65–13** |
| Today’s 22 comments | 17–5 | 10–12 | **27–17** |
| 25-comment unseen holdout | 24–1 | 24–1 | **48–2** |

Winner counts also favored repaired Luna for the Sol judge (19, versus Sol 13, pre-audit Luna 10, baseline 5). The Terra judge preferred the unrepaired Sol wording (20) over repaired Luna (11), pre-audit Luna (9), and baseline (7). The two judges split almost evenly on repaired Luna versus unrepaired Sol: 48–46 combined.

On the seven repaired comments, repaired Luna beat pre-audit Luna 6–1 for the Sol judge and 4–3 for the Terra judge. The safety repair therefore did not impose a readability penalty.

## Decision

Accept the action-lock audit and repair protocol. It turns a readable but unsafe 45/47 candidate into an adjudicated 47/47 fact-safe and action-locked candidate while preserving a large readability win over baseline.

Run one final bounded experiment on a new branch: apply the same audit and repair process to the competing Sol rendering. The readability judges disagree on Sol versus repaired Luna, so repairing Sol is the only remaining high-value comparison. If repaired Sol does not beat repaired Luna under both fact/action gates and combined readability, keep repaired Luna as the selected evidence path.
