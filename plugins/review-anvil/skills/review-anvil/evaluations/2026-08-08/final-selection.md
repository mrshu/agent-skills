# Final selection — structure-first, fact-locked comments

## Decision

Select iteration 3 plus the final structure-only hardening. The production
contract keeps the problem → impact → outcome reading order and private fact
lock, then edits structure before vocabulary. Every locked fact needs an exact
supporting phrase. Diagnostic modality, technical verbs, quantifiers, scope,
valid behavior, IDs, and concrete outcomes remain intact.

Fix guidance uses a neutral desired state instead of hedged `could` or
commanding `must`. It names `the fix` or `the corrected path` when present-tense
wording could otherwise look like current behavior.

## Why the earlier tournament rejected every generated iteration

Three fresh GPT-5.6 agents compared the baseline with iterations 1–3 while the
original comment was a separate technical reference. The baseline won 22/22,
22/22, and 21/21. The candidates were easier to read in the earlier pairwise
comparisons, but free paraphrase had changed or omitted at least one source
relationship in most comments. Readability cannot justify that risk.

## Hardening experiments

1. Structure-only editing retained exact phrases but did not distinguish
   diagnostic modality from recommendation grammar. Strict evaluators marked
   only 26 of 66 candidate judgments fact-safe; the common regression was
   changing `can` or `could` into certain or mandatory behavior.
2. Preserving diagnostic modality and expressing fixes as neutral desired
   states raised fact safety to 65/66. It won 55 readability judgments, lost 10,
   and tied 1. One evaluator found that a desired state could read as behavior
   that already exists.
3. Explicitly naming `the fix` or `the corrected path` removed that ambiguity.
   All three evaluators marked every candidate comment fact-safe: **66/66**.
   The hardened comments won **55/66** readability judgments; the baseline won
   11. Sol preferred the candidate 22–0, Luna 22–0, and Terra split 11–11.
   Sol and Luna selected the candidate overall; Terra selected the baseline
   overall after its tied per-comment count.

## Mechanical language check

| Measure | Baseline | Final hardened candidate |
|---|---:|---:|
| Mean words | 54.3 | 54.0 |
| Mean sentences | 3.8 | 4.1 |
| Mean words per sentence | 14.33 | 13.44 |
| Comments over 80 words | 2 | 1 |
| Comments with a sentence over 20 words | 9 | 8 |
| Longest sentence | 24 | 24 |

The gain comes from sentence boundaries, ordering, concrete actors, and clear
fix status—not from deleting technical content.

## Artifacts

- `tournament-result-gpt-5.6-{sol,luna,terra}.txt`: baseline and iterations
  1–3 tournament
- `hardening-eval-gpt-5.6-{sol,luna,terra}.txt`: first structure-only attempt
- `hardening-2-eval-gpt-5.6-{sol,luna,terra}.txt`: modality-safe attempt
- `hardening-3-eval-gpt-5.6-{sol,luna,terra}.txt`: final strict comparison
- `hardening-3-candidate.json`: selected generated comments
- `strict-pairwise-evaluator-prompt.md`: material-fact safety and readability
  rubric
