# Final selection — structure-first, fact-locked comments

## Decision

Select the final production contract in `references/report-artifacts.md`.
It combines:

- problem → impact → corrected outcome order;
- a private fact lock for identifiers, technical relationships, conditions,
  quantifiers, diagnostic certainty, concrete results, and valid behavior;
- an exact-phrase coverage map before emission;
- a reverse map that deletes draft relationships or boundaries with no source
  fact;
- structure edits before vocabulary edits;
- a conditional title rewrite that preserves actor, ownership, scope, and
  diagnostic modality, or restores the synthesized finding verbatim;
- neutral desired-state fix guidance instead of hedged `could` or commanding
  `must`;
- one-relationship sentences, concrete code actors, and only boundary-defining
  tests.

The canonical renderer examples and adversarial guidance now use the same
voice. This removes older `would`/`can` examples and “friendly next step”
instructions that competed with the final contract.

## Baseline diagnosis and research

The frozen corpus contains 22 inline comments from the latest available
2026-08-07 UTC review-anvil runs on the requested `every_eval_ever` PRs.
GitHub returned no 2026-08-08 UTC inline corpus when the experiment started.

Baseline comments averaged 54.3 words. Nine of 22 contained a sentence over 20
words. Clean GPT-5.6 evaluators scored overall readability 4/5, but repeatedly
identified delayed consequences, abstract noun chains, several code concepts
in one sentence, and hedged fix guidance as rereading costs.

The research-supported contract favors short active sentences, a concrete
failure and rationale, necessary local terminology, a bounded corrected
outcome, and respectful code-focused language. Readability is rejected when it
drops a trigger, condition, identifier, scope word, or fix boundary.

## Iteration history

| Iteration | Branch / commit | Main result | Decision |
|---|---|---|---|
| Baseline | `experiment/review-anvil-readability-baseline` / `28bd20d` | Frozen 22-comment corpus and three GPT-5.6 baseline evaluations | Reference |
| Problem → impact → outcome | `experiment/review-anvil-readability-1` / `6a79714` | 66/66 readability wins over baseline; two technical wording regressions | Keep structure, reject free paraphrase |
| Author cognitive-load check | `experiment/review-anvil-readability-2` / `dcf38e3` | 41 wins, 16 losses, 9 ties against iteration 1; model-sensitive fact drift remained | Keep concrete actor/example checks |
| Private fact lock | `experiment/review-anvil-readability-3` / `c78cea2` | 44 wins and 22 losses against iteration 2; several omissions remained | Keep lock, add coverage check |
| Structure-only hardening | `experiment/review-anvil-readability-final` / `b303bd3` | Identified modality and current-vs-desired-state failures | Keep, then align all renderers and strengthen title/coverage checks |

## Evaluation correction

The development-time strict comparisons put `source` beside the randomized
candidates. They were useful fact-loss diagnostics, but the byte-identical
baseline was visible and those runs are not final blind-readability evidence.

The final evaluation separates the concerns:

1. **Fact safety:** evaluators see the source and three randomized rewrites.
   They do not judge readability.
2. **Blind readability:** evaluators see four randomized versions without the
   source or any original/new label. They do not judge fact preservation.

Generation and evaluation both use fresh, sessionless GPT-5.6 Sol, Luna, and
Terra OMP agents with tools, skills, and rules disabled.

## Final 22-comment regression benchmark

This corpus informed the contract, so treat it as a regression benchmark, not
held-out generalization evidence.

Across three generators and three evaluators, the 22-comment sample received:

| Generator | Fact-safe judgments | Readability rankings above baseline |
|---|---:|---:|
| GPT-5.6 Sol | 64/66 | 59/66 |
| GPT-5.6 Luna | 65/66 | 66/66 |
| GPT-5.6 Terra | 66/66 | 66/66 |

The three flagged fact judgments were title modality or one omitted supporting
boundary. They are recorded in `actor-facts-*-result.txt`; no loss is hidden
behind the readability score.

## Untouched final holdout

Three development holdouts exposed unsafe title rewrites, a fix-target shift,
and an unsupported new fix relationship. Those findings produced conditional
title and outcome fallbacks plus a bidirectional fact lock.

After the bidirectional rule was frozen, the final test selected six different
untouched medium findings from earlier review-anvil reports on the same
requested PRs. Report-only inline annotations were excluded from the technical
source.

| Generator | Fact-safe judgments | Readability rankings above baseline | First-place readability wins |
|---|---:|---:|---:|
| GPT-5.6 Sol | 18/18 | 18/18 | 11 |
| GPT-5.6 Luna | 18/18 | 13/18 | 2 |
| GPT-5.6 Terra | 15/18 | 18/18 | 5 |
| Baseline | — | — | 0 |

Sol is the best fact-safe generator on the final untouched set: every corrected
fact judgment accepted every comment, and blind evaluators ranked it above the
baseline in all 18 judgments. The production change is model-independent; this
result is a deployment preference, not a hard-coded skill dependency.

One initial evaluator treated desired-state fix guidance as a diagnostic claim,
contrary to the evaluation rubric. Three clean adjudicators received explicit
diagnostic and fix-guidance fields and unanimously marked the rewrite fact-safe.
Terra omitted the required shared top-level parser and its entry-point location
in one comment; all three fact evaluators rejected that output.

## Limits

- The final untouched set has six historical findings from the requested PRs,
  not new inline comments from a later run. Re-run the frozen evaluation when
  the next untouched inline review corpus exists.
- LLM instruction following is not a proof. Prompt-only coverage reached
  100% fact safety for Sol and Luna on the final holdout, but other samples
  produced isolated title, omission, target, or unsupported-addition failures.
- A deterministic fact-coverage gate would provide a stronger guarantee, but
  it requires carrying structured fact-lock data through the artifact schema
  and adds runtime machinery. The prompt-only change remains the smaller
  production intervention.

## Evidence

- `corpus.json` and `baseline-gpt-5.6-*.txt`
- `iteration-{1,2,3}-assessment.md`
- `tournament-assessment.md`
- `actor-final-generator-*.json`
- `actor-facts-*-result.txt` and `actor-readability-*-result.txt`
- `bidirectional-unseen-holdout-corpus.json`
- `bidirectional-final-generator-*.json`
- `bidirectional-facts-*-result.txt` and
  `bidirectional-readability-*-result.txt`
- `bidirectional-sol-dispute.json`, `dispute-adjudicator-prompt.md`, and
  `bidirectional-sol-dispute-structured-*.txt`
- `final-unseen-holdout-corpus.json`, `postreview-unseen-holdout-corpus.json`,
  `clean-unseen-holdout-corpus.json`, and their result files contain
  development holdouts that drove the fallback and bidirectional-lock rules.
- `final-fact-evaluator-prompt.md`
- `final-readability-evaluator-prompt.md`
