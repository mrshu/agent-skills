# Iteration 4 assessment — review requests, not fictional fixes

## Trigger

The PR #190 source review explicitly reported `Fixes applied: 0 (review-only)`. The prior selected rewrite changed its proposed remediation from “The module entry point can use the shared top-level parser” to “The fix uses the shared top-level parser.” That sentence falsely described code as implemented. The same contract produced `The fix` or `In the fix` in 13 of 15 clean fact-evaluator failures and in all six comments of one five-run generation sample.

## Final intervention

The production contract keeps the established fact lock and problem → impact order, but renders remediation as requested work:

- treat remediation as a request, not observed code;
- give every source-backed action in a critical, high, or medium finding its own short sentence beginning with `Please` and a direct action verb;
- preserve suggestion grammar for low and nit guidance;
- use `the fix` or `the corrected path` only when the source explicitly describes an existing patch;
- omit remediation when no source-backed requested change exists;
- never invent the purpose of a requested test.

The same rule appears in `SKILL.md`, `references/report-artifacts.md`, `references/reviewer-prompt.md`, `references/asd-ste100-inspired.md`, both PR presets, and `scripts/test-report-language.sh`.

An intermediate version put two or three actions into one polite sentence. Independent review rejected it because it conflicted with the one-relationship-per-sentence rule. The final contract and canonical examples split parser, validation, state, retry, and test actions into separate `Please` sentences.

## Repeated six-comment gate

Five fresh sessionless GPT-5.6 Sol generators rewrote the six comments that exposed the false-fix pattern. All five produced the same 14 `Please` requests across six comments. None used `The fix`, `In the fix`, or `the corrected path`.

Three randomized fact evaluators and three blind readability evaluators compared the first generated sample with the preserved false-fix baseline:

- fact safety: 18/18 for the split-request version and 0/18 for the false-fix baseline;
- readability: 18/18 first-place judgments for the split-request version;
- split-request output: mean 40.5 words and 4.2 short sentences, with zero false-fix phrases.

| Dimension | False-fix baseline | Split-request version |
|---|---:|---:|
| Problem clarity | 4.94 | 4.94 |
| Consequence clarity | 4.94 | 4.94 |
| Requested-change clarity | 2.72 | 5.00 |
| Actionability | 4.33 | 5.00 |
| Tone | 4.67 | 5.00 |
| Cognitive ease | 3.94 | 4.56 |

## Full 22-comment regression benchmark

A fresh Sol generator rewrote all 22 frozen 2026-08-07 comments. Three fact evaluators and three blind readability evaluators compared it with the previously selected branch output.

- raw fact safety: 65/66 for the split-request output and 0/66 for the previous output in the verified review-only context;
- adjudicated fact safety: 66/66 after three clean Sol/Luna/Terra adjudicators rejected the lone claimed loss; that evaluator quoted `The fix` even though the candidate said `Please`;
- readability: 62/66 first-place judgments for the split-request output and 4/66 for the previous output;
- previous output: mean 65.3 words, 3.9 sentences, and 14 false-fix phrases by the local lexical check;
- split-request output: mean 57.9 words, 4.1 shorter sentences, and zero false-fix phrases.

| Dimension | Previous selected output | Split-request output |
|---|---:|---:|
| Problem clarity | 4.98 | 4.53 |
| Consequence clarity | 5.00 | 5.00 |
| Requested-change clarity | 1.52 | 4.95 |
| Actionability | 4.14 | 4.95 |
| Tone | 4.35 | 4.98 |
| Cognitive ease | 4.00 | 4.47 |

The lower aggregate problem-title score is the remaining tradeoff. The original problem and consequence facts stayed intact after adjudication; the large gain comes from removing the false current-state reading and separating requested actions.

## Post-freeze semantic holdout

The first proposed holdout used new numeric IDs but repeated five earlier root causes under their original IDs. Independent review rejected it. The replacement set was deduplicated by numeric ID, source review ID, path, trigger, root cause, result, and nearest behavioral analogue before generation:

- `3725747241`: source dataset identity versus routing collection;
- `3725871268`: PEP 508 marker handling in a package-resource test;
- `3726043677`: evidence-free group score rescaling;
- `3726043685`: declared versus runtime `huggingface_hub` capability;
- `3729389316`: source rows lost before parsing because of an exact cell pattern;
- `3729389321`: a wheel omits a required registry snapshot data file.

These findings came from four source reviews on PRs #160, #209, #220, and #224. Their IDs, source review IDs, paths, and root causes did not appear in any earlier evaluation artifact.

Three fresh generators produced six comments each. Three fact evaluators and three blind readability evaluators then judged them:

| Generator | Fact-safe judgments | First-place readability wins |
|---|---:|---:|
| GPT-5.6 Sol | 18/18 | 8/18 |
| GPT-5.6 Luna | 15/18 | 10/18 |
| GPT-5.6 Terra | 18/18 | 0/18 |

Sol is selected because fact safety is a hard gate and it is materially more readable than the other fact-safe generator. Luna was often most readable, but all three fact evaluators found that it weakened “require `--dump`” to “use `--dump`.” Every generator produced request language and no false-fix phrase.

## Decision

Keep iteration 4. It corrects a verified factual and pragmatic error, wins both blind comparisons, passes a semantically unseen post-freeze gate with Sol, and needs no runtime machinery or schema change.

## Next experiments

1. Carry a structured `review_mode` or remediation-status field into final rendering so productive fix runs can safely describe code already applied without inferring context from prose.
2. Add a deterministic source-to-draft relationship map only if later corpora expose prompt-only omissions; it offers a stronger guarantee but adds schema and runtime complexity.
3. Re-run the frozen protocol on the next genuinely new review-anvil inline corpus.
4. Measure author reading time and correct restatement, not only LLM preference, before changing the split `Please` request form again.
