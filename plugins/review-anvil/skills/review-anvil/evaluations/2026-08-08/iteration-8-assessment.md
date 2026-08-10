# Iteration 8 assessment — obligations with modal boundaries

## Design

Iteration eight separates a modal source sentence into two layers:

1. the smallest new actor-action-target mechanism the author must add;
2. the modal boundary that says where or how that mechanism may act.

Standalone permissions and allowed follow-ups remain prose. The canonical example requests `Add a no-match check` and preserves `It can stop before existing-output discovery or publication` separately. The unresolved-key permission remains non-imperative.

## Development corpus

Sol, Luna, and Terra each generated one complete 22-comment output in clean, sessionless `omp` runs. Four independent fact judges evaluated all three candidates with randomized labels.

## Fact gate

| Judge | Sol safe | Luna safe | Terra safe |
|---|---:|---:|---:|
| Claude Opus | 22/22 | 22/22 | 22/22 |
| GPT-5.6 Sol | 22/22 | 22/22 | 22/22 |
| GPT-5.6 Luna | 22/22 | 22/22 | 21/22 |
| GPT-5.6 Terra | 22/22 | 22/22 | 21/22 |

Sol and Luna both passed the required **88/88** fact gate. The prior iteration-seven failures were absent:

- the existing-output change remained an explicit request;
- the no-match check remained explicit while its early-stop boundary stayed modal;
- unresolved-key reporting remained a permission;
- provider-prefixed tests retained the reachable-path boundary.

Terra was rejected. One comment omitted the `--models` target, and one test request no longer explicitly covered the mismatched collection-directory path.

## Fact-safe candidate selection

The two fact-safe outputs were compared blindly:

| Judge | Sol wins | Luna wins | Ties |
|---|---:|---:|---:|
| Claude Opus | 3 | 1 | 18 |
| GPT-5.6 Sol | 1 | 3 | 18 |
| GPT-5.6 Luna | 0 | 2 | 20 |
| GPT-5.6 Terra | 1 | 3 | 18 |
| **Total** | **5** | **9** | **74** |

Luna advanced because it won the cross-judge majority. The disagreement was narrow. Claude preferred Sol where it detached preservation constraints into short sentences and used `It` after the no-match action. The three GPT judges generally preferred Luna's explicit repeated subject and tighter attachment of constraints to actions.

## Baseline readability gate

The selected Luna output was compared with the frozen baseline:

| Judge | Baseline wins | Luna wins | Ties |
|---|---:|---:|---:|
| Claude Opus | 0 | 5 | 17 |
| GPT-5.6 Sol | 0 | 5 | 17 |
| GPT-5.6 Luna | 0 | 5 | 17 |
| GPT-5.6 Terra | 0 | 4 | 18 |
| **Total** | **0** | **19** | **69** |

Claude Opus mean scores changed as follows:

| Dimension | Baseline | Luna | Delta |
|---|---:|---:|---:|
| Defect clarity | 4.136 | 4.136 | 0.000 |
| Action recall | 3.591 | 4.045 | +0.454 |
| Scanability | 3.909 | 4.273 | +0.364 |
| Naturalness | 4.227 | 4.182 | -0.045 |
| Cognitive ease | 3.591 | 3.591 | 0.000 |

All judges preferred the candidate on multiple comments, and none preferred the baseline on any comment. Explicit grouping consistently exposed required tests and second implementation actions. The measured tradeoff is a small average naturalness loss from headings and repeated subjects; no judge considered that sufficient to choose the baseline comment.

## Decision

Advance iteration eight to the sealed holdout. It is the first contract that satisfies both development gates:

- two independent generator outputs are unanimously fact-safe;
- the selected output wins a clear cross-judge readability majority with no baseline wins or model-sensitive regression.

The holdout must determine whether the modality split generalizes beyond the development corpus before iteration eight is selected as the final branch.
