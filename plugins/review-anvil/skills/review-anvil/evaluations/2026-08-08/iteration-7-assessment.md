# Iteration 7 assessment — semantic modal classification

## Design

Iteration seven changed classification from modal-word heuristics to source semantics. A proposed check, validation, write, report, or test remains author work even when the source uses `can`, `could`, or `would`. Every requested source unit must map to either an explicit author request or a visible no-change constraint.

## Development corpus

The frozen development corpus contains 22 inline comments from the reviewed PRs. Sol, Luna, and Terra each generated one complete 22-comment candidate with clean, sessionless `omp` runs. Candidate labels were randomized independently for fact and readability judging.

## Fact gate

Four independent judges evaluated all three candidates: Claude Opus, GPT-5.6 Sol, GPT-5.6 Luna, and GPT-5.6 Terra.

| Judge | Sol safe | Luna safe | Terra safe |
|---|---:|---:|---:|
| Claude Opus | 22/22 | 21/22 | 22/22 |
| GPT-5.6 Sol | 21/22 | 20/22 | 20/22 |
| GPT-5.6 Luna | 21/22 | 17/22 | 19/22 |
| GPT-5.6 Terra | 21/22 | 21/22 | 20/22 |

No candidate passed the required 100% cross-judge fact gate. Sol had the highest total, 85/88, and no Claude fact loss, so it advanced only to a diagnostic readability comparison.

The material failures were:

1. Luna treated the explicit request to leave existing output unchanged as behavior needing no change.
2. Terra wrote `Stop a no-match check`, reversing which operation stops processing.
3. All candidates made the permitted early-stop boundary unconditional. The source requires adding a no-match check but says the check *can* stop before existing-output discovery or publication.
4. All candidates turned permission to report unresolved keys after preserving valid metrics into a mandatory action.
5. Terra dropped the test boundary that provider-prefixed keys cover the reachable nested-serialization path.

Two additional Luna findings were adjudicated as judge false positives. Keeping the nonzero exit conditional on failures and keeping file-symlink behavior unchanged are preservation constraints; explicit no-change prose preserves rather than weakens them.

## Readability gate

Sol was compared blindly with the frozen baseline. Raw results were:

| Judge | Baseline wins | Sol wins | Ties |
|---|---:|---:|---:|
| Claude Opus | 0 | 6 | 16 |
| GPT-5.6 Sol | 0 | 6 | 16 |
| GPT-5.6 Luna | 2 | 4 | 16 |
| GPT-5.6 Terra | 0 | 6 | 16 |

Both reported GPT-5.6 Luna baseline wins contained winner-label errors: each rationale preferred the version with explicit bullets, but those bullets belonged to Sol. After correcting the internally inconsistent labels, every judge recorded 6 Sol wins, 0 baseline wins, and 16 ties. Aggregate adjudicated result: **24 Sol wins, 0 baseline wins, 64 ties**.

Claude Opus mean scores changed as follows:

| Dimension | Baseline | Sol | Delta |
|---|---:|---:|---:|
| Defect clarity | 4.045 | 4.045 | 0.000 |
| Action recall | 3.682 | 4.227 | +0.545 |
| Scanability | 3.818 | 4.364 | +0.546 |
| Naturalness | 4.000 | 4.000 | 0.000 |
| Cognitive ease | 3.273 | 3.545 | +0.272 |

## Decision

Reject iteration seven as a finalist despite its unanimous readability improvement. It fails the 100% fact gate by conflating two distinct relationships:

- a new mechanism the author must add;
- the modal boundary that says where that mechanism may act.

It also mistakes a standalone permitted follow-up for mandatory work.

## Next refinement

Use a two-layer representation:

1. Extract the smallest new actor-action-target obligation.
2. Preserve modal boundaries and permitted follow-ups as prose attached to that obligation.

For the no-match example, request `Add a no-match check` and retain `It can stop before existing-output discovery or publication` as modal prose. Keep `Unresolved keys can be reported after the valid metrics are preserved` as permission prose, not an action bullet.
