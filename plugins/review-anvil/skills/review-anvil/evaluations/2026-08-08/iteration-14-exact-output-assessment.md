# Iteration 14 assessment — exact old versus final-contract output

## Decision

Use the `b3f2ad2` contract as the best tested candidate. This run closes the
prior evidence gap: it generated final-contract output from the verbatim
previous review-anvil comments, ran the complete review-scoped action-lock
pipeline, and then compared the exact surviving output blindly.

The previous side is verbatim output observed in 16 GitHub reviews. The exact
skill commit that produced those historical comments was not recorded. The new
side uses contract commit `b3f2ad2c4c5e872a6e059d8e64c056ad615ab2ca`.

## Exact pipeline result

The corpus contains 47 accepted inline findings from 16 reviews. The clean
renderer and auditors received frozen prose and contract rules only; they did
not inspect repositories.

- 33 bodies passed the first Claude Opus and GPT-5.6 Sol audit wave.
- 14 bodies entered the single repair wave.
- 13 repaired bodies passed new Claude Opus and GPT-5.6 Terra auditors.
- 1 body used the exact-source fallback.
- 46 of 47 final bodies differ from the previous output.
- The fallback sets `approval_allowed` to `false`; the event must be `COMMENT`.
- Every auditor response had complete IDs, valid row schemas, consistent
  status, and matching counts.

## Blind readability result

Version order was independently randomized per comment. Three clean judges
scored defect clarity, action recall, scanability, naturalness, and cognitive
ease. They did not receive chronology or authorship labels.

| Judge | Final contract | Previous | Tie |
|---|---:|---:|---:|
| Claude Opus | 45 | 0 | 2 |
| GPT-5.6 Sol | 45 | 1 | 1 |
| GPT-5.6 Terra | 43 | 3 | 1 |
| **Total** | **133** | **4** | **4** |

Aggregate mean scores and final-minus-previous deltas:

| Dimension | Final | Previous | Delta |
|---|---:|---:|---:|
| Defect clarity | 5.000 | 4.879 | +0.121 |
| Action recall | 4.950 | 3.724 | +1.226 |
| Scanability | 4.518 | 3.964 | +0.554 |
| Naturalness | 4.404 | 4.029 | +0.375 |
| Cognitive ease | 4.660 | 3.894 | +0.766 |

The four previous-output wins concern three comments. Judges preferred the
previous wording where the new version repeated an `llm_scoring` condition,
made a tightly coupled legacy-snapshot change into three bullets, or where one
judge preferred tentative prose over an explicit rejection-and-test list. The
single fallback was identical and produced three ties.

## Scope and limitations

- This is exact inline-comment output from the final contract, not a top-level
  review evaluation.
- The historical previous output is verbatim, but its producing skill commit is
  unknown.
- Sol and Terra are separate clean sessions from the same GPT model family.
- Model judgments are not a substitute for a human PR-author timing study.
- The test does not measure latency or cost from two audit waves and repair.

## Primary artifacts

- `iteration-14-exact-old-vs-new.md`
- `iteration-14-exact-old-vs-new.json`
- `iteration-14-verbatim-prior-output-corpus.json`
- `iteration-14-exact-final-first-audit-summary.json`
- `iteration-14-exact-final-second-audit-summary.json`
- `iteration-14-exact-readability-decoded.json`
