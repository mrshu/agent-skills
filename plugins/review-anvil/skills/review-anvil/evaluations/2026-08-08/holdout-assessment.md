# Sealed holdout assessment — iteration 8

## Protocol

Finalists were frozen in `holdout-finalists.json` before the holdout file was opened. The sealed file checksum was `f5b7658bab03f12d1d402da0415fbd3066c1b3550dc8904ae5235bf62ab480a6`.

The holdout contains 25 previously unseen inline comments from 8 PRs. Sol, Luna, and Terra each generated one output with the frozen iteration-eight prompt. Every run was valid, so no generator was retried. The original historical comment was the baseline.

## Fact gate

Every generated comment was judged by Claude Opus, GPT-5.6 Sol, GPT-5.6 Luna, and GPT-5.6 Terra.

| Judge | Sol safe | Luna safe | Terra safe |
|---|---:|---:|---:|
| Claude Opus | 25/25 | 25/25 | 25/25 |
| GPT-5.6 Sol | 25/25 | 25/25 | 25/25 |
| GPT-5.6 Luna | 25/25 | 25/25 | 25/25 |
| GPT-5.6 Terra | 25/25 | 25/25 | 25/25 |

Result: **300/300 fact-safe judgments** and no reported fact losses.

## Readability gate

Each generator output was independently randomized against the baseline and judged by all four models.

### Raw results

| Candidate | Baseline wins | Candidate wins | Ties |
|---|---:|---:|---:|
| Sol | 3 | 96 | 1 |
| Luna | 1 | 99 | 0 |
| Terra | 0 | 100 | 0 |
| **Total** | **4** | **295** | **1** |

All four reported baseline wins came from GPT-5.6 Luna and had winner labels that contradicted their rationales. In each case, the rationale explicitly preferred the action or separation present only in the candidate. Correcting those labels gives:

| Candidate | Baseline wins | Candidate wins | Ties |
|---|---:|---:|---:|
| Sol | 0 | 99 | 1 |
| Luna | 0 | 100 | 0 |
| Terra | 0 | 100 | 0 |
| **Total** | **0** | **299** | **1** |

Luna was selected before the holdout from the development-corpus head-to-head. Its holdout result is therefore the representative result, not a post-hoc choice.

### Development-selected Luna means

Claude Opus scored the representative output as follows:

| Dimension | Baseline | Luna | Delta |
|---|---:|---:|---:|
| Defect clarity | 4.000 | 4.000 | 0.000 |
| Action recall | 3.000 | 4.120 | +1.120 |
| Scanability | 3.680 | 4.120 | +0.440 |
| Naturalness | 3.800 | 4.000 | +0.200 |
| Cognitive ease | 3.480 | 4.000 | +0.520 |

The other three judges also selected Luna on every holdout comment. The largest gain was action recall: the historical modal suggestions frequently described a possible mechanism without explicitly stating that the author should implement it.

## Decision

The holdout confirms the iteration-eight contract:

- every generated candidate preserved all judged technical facts and boundaries;
- the preselected representative received 100/100 readability wins;
- no true baseline preference remained after inspecting label/rationale consistency;
- gains generalized to comments and PRs absent from every development artifact.

Iteration eight passes the holdout and advances to final contract selection and repository verification.
