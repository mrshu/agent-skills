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

## Manual action-lock audit

The four fact judges treated retained words as complete preservation. A
source-unit audit found that the frozen Luna output left five necessary
post-change behaviors as modal prose rather than explicit author requests:

- `3725853155`: enter invalid rows in `SourceConversionResult`;
- `3725853159`: mark missing prompt content in legacy snapshots;
- `3725913004`: reject existing logical output until replacement is atomic;
- `3726043665`: fail by default for symlinks, roots, and populated targets;
- `3726043679`: restrict tolerance to scale classification.

The complete 25-comment audit is in `holdout-action-lock-audit.json`. It applies
a counterfactual test to every proposed behavior: if omitting the behavior
leaves the reported defect or a required boundary unresolved, it is author
work regardless of modal wording. Explicit preservation clauses remain
constraints.

## Amended decision

Iteration eight does not pass the sealed holdout. The representative Luna
output fails five of 25 action locks even though the text remains factually
present and readability judges prefer it. Sol makes those actions explicit,
but cannot replace Luna post hoc because `holdout-finalists.json` froze Luna
before the holdout was opened.

Iteration eight remains a useful readability result and a diagnostic for the
next contract. It does not advance to final selection.
