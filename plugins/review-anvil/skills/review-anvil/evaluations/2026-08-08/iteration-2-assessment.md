# Iteration 2 — author cognitive-load check

## Change

Iteration 2 keeps the problem → impact → outcome structure and adds a final
author check before emitting an inline body:

- the title and first sentence answer what breaks and when;
- abstract labels become a code actor plus a direct verb;
- hard-to-visualize paths, counts, and state changes get one minimal example;
- generic test advice and sentences that repeat the title are removed.

This is a distinct intervention from iteration 1. It targets the rereading cost
caused by abstract noun phrases and mental simulation rather than only paragraph
order.

## TDD evidence

Before adding the author check, `test-report-language.sh` failed on the missing
contract. See `iteration-2-red.txt`. The same test passed after the change.

## Clean-agent generation

A fresh GPT-5.6 Sol OMP agent rewrote the frozen 22-comment corpus using the
updated contract. Its output is `iteration-2-candidate.json`.

## Blind comparison against iteration 1

Fresh GPT-5.6 Sol, Luna, and Terra evaluators compared iteration 2 with
iteration 1. Labels were reversed for Luna.

| Evaluator | Iteration-2 label | Iteration 2 wins | Iteration 1 wins | Ties | Overall |
|---|---:|---:|---:|---:|---|
| GPT-5.6 Sol | B | 18 | 1 | 3 | iteration 2 |
| GPT-5.6 Luna | A | 6 | 14 | 2 | iteration 1 |
| GPT-5.6 Terra | B | 17 | 1 | 4 | iteration 2 |
| **Total** | — | **41** | **16** | **9** | **iteration 2** |

Two of three evaluators and 62% of all per-comment judgments preferred the new
cognitive-load check. This is a useful but less decisive gain than iteration 1.
The Luna disagreement shows that small generation differences can outweigh the
contract for some comments.

Technical judgments favored iteration 2 on 25 comments, iteration 1 on 8, with
33 ties. However, evaluators still found wording drift in individual outputs:

- neutral metric semantics sometimes lost the distinction between “consumers
  can interpret” and “the field marks” a direction;
- the specific identity-path check became a generic semantic check;
- one snapshot comment omitted explicit reuse across all four requests;
- the all-unconvertible-files scope became less precise in one wording.

Some flagged losses belonged to iteration 1 rather than iteration 2 because the
reversed pair exposed weaknesses in both generated samples. The consistent
lesson is that readability instructions alone do not protect technical verbs,
quantifiers, and named boundaries.

## Decision and next experiment

Keep the author check: it wins a clear aggregate majority and targets the
reported cognitive burden directly. The next iteration must add an explicit
fact-lock step: copy technical relationships from the synthesized finding
before simplifying prose, then compare the draft against those facts. This
should preserve the readability gain while preventing `covers` → `restores`,
`can interpret` → `marks`, and scope/quantifier drift.
