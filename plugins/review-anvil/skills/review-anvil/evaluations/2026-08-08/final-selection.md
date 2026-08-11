# Final selection — fact-locked requested changes

> Superseded by `iteration-13-assessment.md`, which stress-tests and hardens
> the iteration-12 production contract and records its current limits.

## Decision

Select the final production contract in `references/report-artifacts.md`.
It combines:

- problem → impact → requested change order;
- a private fact lock for identifiers, technical relationships, conditions,
  quantifiers, diagnostic certainty, concrete results, and valid behavior;
- an exact-phrase coverage map before emission;
- a reverse map that deletes draft relationships or boundaries with no source
  fact;
- structure edits before vocabulary edits;
- a conditional title rewrite that preserves actor, ownership, scope, and
  diagnostic modality, or restores the synthesized finding verbatim;
- separate source-backed `Please` requests for every critical/high/medium
  action, with suggestion grammar retained for low/nit guidance;
- one-relationship sentences, concrete code actors, and only source-backed
  boundary-defining tests.

The canonical renderer examples and reviewer guidance now use the same voice.
This removes older `would`/`can` examples, fictional `The fix` outcomes, and
“friendly next step” instructions that competed with the final contract.

## Baseline diagnosis and research

The frozen corpus contains 22 inline comments from the latest available
2026-08-07 UTC review-anvil runs on the requested `every_eval_ever` PRs.
GitHub returned no 2026-08-08 UTC inline corpus when the experiment started.

Baseline comments averaged 54.3 words. Nine of 22 contained a sentence over 20
words. Clean GPT-5.6 evaluators scored overall readability 4/5, but repeatedly
identified delayed consequences, abstract noun chains, several code concepts
in one sentence, and hedged fix guidance as rereading costs.

The research-supported contract favors short active sentences, a concrete
failure and rationale, necessary local terminology, a source-backed requested
change, and respectful code-focused language. Readability is rejected when it
drops a trigger, condition, identifier, scope word, or change boundary.

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

## Pre-correction untouched holdout

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

Sol was the best fact-safe generator under the then-current rubric. The original
PR #190 review later verified that the run applied zero fixes. That evidence
showed that declarative desired-state prose could falsely read as implemented
code; iteration 4 below supersedes this holdout's wording conclusion while
retaining its title and fact-lock evidence.

Terra omitted the required shared top-level parser and its entry-point location
in one comment; all three fact evaluators rejected that output.

## Review-only requested-change correction

Five clean generators reproduced the failure before the correction. The final
contract gives each source-backed critical/high/medium action its own short
`Please` sentence and retains suggestion grammar for low/nit guidance.

On the full 22-comment regression corpus, three fact evaluators and three blind
readability evaluators produced:

- 66/66 adjudicated fact-safe judgments for the requested-change output versus
  0/66 for the previous false-fix output;
- 62/66 first-place readability judgments for the requested-change output;
- requested-change clarity of 4.95/5 versus 1.52/5;
- zero false-fix phrases versus 14 in the previous selected output.

A post-freeze holdout then selected six RAV comments whose IDs, source review
IDs, paths, root causes, and nearest behavioral analogues were absent from all
earlier artifacts. Sol and Terra each received 18/18 fact-safe judgments; Luna
received 15/18 after weakening a required `--dump` gate. Sol won 8/18 blind
first-place readability judgments versus Terra's 0/18, so Sol remains the
recommended generator when model choice is available.

## Limits

- The semantic holdout has six historical findings from four prior source
  reviews, not new inline comments from a later run. Re-run the frozen
  evaluation when the next untouched inline review corpus exists.
- LLM instruction following is not a proof. Prompt-only coverage reached 100%
  fact safety for Sol and Terra on the semantic holdout, but Luna weakened one
  required boundary.
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
- `iteration-4-baseline-assessment.md` and `iteration-4-assessment.md`
- `iteration-4-split-{micro,full,semantic}-*.json`
- `iteration-4-semantic-unseen-holdout-corpus.json`
- `iteration-4-{fact,readability}-evaluator-prompt.md`
- `iteration-4-untouched-{fact,readability}-evaluator-prompt.md`
