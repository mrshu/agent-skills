# Iteration 3 — private technical fact lock

## Change

Before rewriting an inline finding, the agent now records a private fact lock:
identifiers, numbers, technical verbs, actor-action-target relationships,
triggers, conditions, quantifiers, certainty, concrete results, and valid
behavior that must survive the fix. It then compares the draft with that lock.
The lock never appears in the author-facing comment.

This intervention addresses the factual drift seen in earlier outputs without
adding another model call or visible review-process prose.

## TDD evidence

`test-report-language.sh` first failed because no fact-lock contract existed.
See `iteration-3-red.txt`. It passed after the contract was added.

## Clean-agent generation

A fresh GPT-5.6 Sol OMP agent generated `iteration-3-candidate.json` from the
same frozen 22-comment corpus.

## Blind comparison against iteration 2

Fresh GPT-5.6 Sol, Luna, and Terra evaluators compared iteration 3 with
iteration 2. Luna received reversed labels.

| Evaluator | Iteration-3 label | Iteration 3 wins | Iteration 2 wins | Ties | Overall |
|---|---:|---:|---:|---:|---|
| GPT-5.6 Sol | B | 20 | 2 | 0 | iteration 3 |
| GPT-5.6 Luna | A | 2 | 20 | 0 | iteration 2 |
| GPT-5.6 Terra | B | 22 | 0 | 0 | iteration 3 |
| **Total** | — | **44** | **22** | **0** | **iteration 3** |

Technical judgments favored iteration 3 on 18 comments and iteration 2 on 11,
with 37 ties. Two evaluators strongly preferred the fact-locked output; Luna
strongly preferred iteration 2. The split shows substantial model sensitivity,
although the aggregate still favors iteration 3 two to one.

## Remaining fact losses

The fact lock reduced verb drift but did not eliminate omission:

- comment `3737266652` lost the explicit requirements to record caught parsing
  and schema errors and let valid rows continue;
- comment `3737042592` lost that the guard specifically compares the directory
  name with the selected collection;
- comment `3737044371` lost the requirement to preserve the last complete ledger
  if replacement fails;
- one evaluator found that commit provenance was no longer explicit in
  `3737266656`.

These are not acceptable final-state losses even though most technical
judgments were ties or wins.

## Decision and next experiment

Keep the fact-lock concept, but strengthen its verification. The next draft
must map every locked fact to an exact phrase in the body before emission.
Unlike the current general comparison instruction, a coverage check makes an
omission observable to the authoring agent. The final selection must also use a
multi-candidate tournament against the baseline, not one generation sample.
