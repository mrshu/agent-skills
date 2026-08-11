# Iteration 12 assessment — final renderer selection

## Question

Does a repaired Sol rendering beat the repaired Luna rendering after both use the independent action-lock gate?

## Experiment

The final corpus contains 47 inline comments: the 22 comments available from the requested `every_eval_ever` review runs and 25 comments that were held out until iteration 8, then used to develop later contracts. Clean, sessionless OMP agents ran with tools, skills, and rules disabled.

Sol generated a fresh 47-comment candidate. Independent Sol and Terra auditors flagged the union of three comments, and Sol repaired those comments. The final blind comparison randomized four versions per finding: today's or prior baseline, repaired Luna, Sol before audit, and repaired Sol. Fact/action judges saw the source but did not judge style; readability judges did not see the source.

## Generator audit result

The first Sol-renderer audit passed 45/47 comments for the Sol judge and 44/47 for the Terra judge. Their union required three repairs. The repaired Sol candidate passed all 47 fact and action predicates in the final two-judge rerun.

The repaired Luna candidate had one remaining edge case. It turned an allowed existing-output rejection boundary into a direct action. Both production-protocol auditors detected that failure after the boundary example was added. The repaired comment then passed both auditors.

## Final fact and action gate

| Version | Sol judge | Terra judge |
|---|---:|---:|
| Selected repaired Luna | 47/47 fact-safe and action-locked | 47/47 fact-safe and action-locked |
| Repaired Sol | 47/47 fact-safe and action-locked | 47/47 fact-safe and action-locked |
| Baseline | 15/47 action-locked | 16/47 action-locked |

All three versions preserved the diagnosis facts in the final run. The baseline result shows why fact safety alone is insufficient: required author work often remained in modal prose, and a Sol judge found two accepted behaviors phrased as actions.

## Blind readability

Across the two clean readability judges:

| Pair | All comments | Today's 22 | Prior held-out 25 |
|---|---:|---:|---:|
| Selected vs baseline | **73–21** | **26–18** | **47–3** |
| Selected vs repaired Sol | **50–44** | — | — |

On the 30 comments where selected and repaired Sol differed, selected won **35–25**. The selected publication-boundary repair was evaluated separately because it replaced the unsafe Luna wording. Sol ranked selected first; Terra ranked repaired Sol first; both ranked baseline last. Substituting that result leaves selected ahead 50–44 overall.

## Decision

Select the repaired Luna evidence path and retain the independent post-render action-lock audit. The selected 47-comment output is in `iteration-12-selected-comments.json`.

The production contract now:

1. classifies every source predicate by behavior before rendering;
2. makes every required author obligation an explicit request;
3. preserves accepted behavior, permissions, and optional follow-ups as no-change boundaries;
4. uses one concise `Please` sentence for one obligation and a short action list for two or more;
5. audits rendered obligation status with two independent verifiers;
6. repairs valid failures, rechecks them, and restores exact source prose for any second failure or unverifiable row.

## What the rounds established

| Stage | Finding | Next step chosen |
|---|---|---|
| Structure-first rewrites | Problem → consequence → action was much easier to scan, but free paraphrase changed facts. | Add a private fact lock. |
| Cognitive-load and fact-lock rounds | Shorter prose still lost conditions, ownership, or modality. | Use bidirectional source-to-draft and draft-to-source checks. |
| Review-only correction | Declarative desired-state prose read as if the fix already existed. | Make required work explicit with `Please`. |
| Action-list rounds | Bullets improved multi-action recall, but grammar-based splitting promoted permissions into work. | Classify behavior before choosing prose form. |
| Semantic contract round | A dense one-pass prompt was coherent but every generator still missed at least one action predicate. | Add an independent post-render gate. |
| Action-lock round | Audit and bounded repair recovered all adjudicated predicates while retaining the readability gain. | Compare the strongest two repaired renderers. |
| Final renderer round | Repaired Luna beat repaired Sol 50–44 and baseline 73–21, with 94/94 final fact/action judgments. | Keep repaired Luna as evidence; ship the model-independent audit contract. |

## Recommendations

1. **Ship the current branch contract.** It has the strongest observed balance: 94/94 final fact/action judgments and a 73–21 blind readability win over baseline.
2. **Keep the audit mandatory for emitted inline comments.** The initial final generators still missed two or three comments. Prompt-only generation is not reliable enough.
3. **If model choice is exposed, prefer Luna for rendering and use different model families for the two auditors.** Luna won the combined final readability comparison; model diversity reduces correlated classification errors.
4. **Next, move obligation classes into structured synthesis artifacts.** Carry `author_work`, `no_change`, and `optional_followup` predicates with stable IDs into the renderer. A deterministic coverage check could then replace part of the LLM audit and reduce latency.
5. **Validate on a newly sealed cross-repository corpus.** The 25-comment set was held out only through iteration 8 and then informed later contracts. A new cross-repository corpus and human PR-author study are the highest-value generalization checks.
6. **Automate this benchmark.** Freeze corpus construction, randomization keys, fact/action decoding, and pairwise aggregation in one local runner before tuning wording again.

## Limits

- The benchmark contains 47 comments from one repository. The 22-comment current test bed and the 25-comment prior held-out set both informed the final contract, so neither is evidence of generalization beyond this repository.
- Readability is judged by language models, not by the developers who received the original reviews.
- Pairwise preferences are model-sensitive. The final decision uses the combined two-judge result and rejects any candidate that fails either fact/action gate.
- The independent gate adds two auditor calls per wave, plus two more if repair is needed. The exact-source fallback protects correctness when repair does not converge or an audit result is unverifiable.
