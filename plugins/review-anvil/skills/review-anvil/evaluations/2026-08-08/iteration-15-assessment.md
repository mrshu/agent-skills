# Iteration 15 assessment — maximum-human inline comments

## Decision

Select `experiment/review-anvil-readability-15-maximum-human` as the best
local candidate. It keeps provenance and severity available to the posting and
history machinery, but removes those machine fields from the rendered prose.
Inline comments now lead with the failure, explain its consequence, and end
with one explicit request or a short action list.

The comparison baseline is the exact final-contract output from commit
`b3f2ad2c4c5e872a6e059d8e64c056ad615ab2ca`. That version had already beaten
the verbatim historical review-anvil comments. The historical corpus contains
47 accepted inline findings from 16 reviews on `evaleval/every_eval_ever`.

## Implementation

Each new inline body uses this visible order:

1. Natural title that names the failure, not its category.
2. Evidence and concrete consequence.
3. One `Please …` request or `**Requested actions**` for independent tasks.
4. No-change constraints in the same action sentence when they directly limit
   the requested change; otherwise short modal prose.

The final nonblank line is hidden metadata:

```html
<!-- review-anvil: id=<complete-id> severity=<severity> area=<area> -->
```

`pr-helper.sh` parses that terminal marker before legacy bold-label fallbacks,
preserves it after suggestion and prior-feedback augmentation, strips
helper-only JSON fields, and posts the natural body unchanged. Duplicate
suppression and history recovery continue to use the complete finding ID.

## Exact generation and audits

A clean `omp` agent running GPT-5.6 Luna generated all 47 bodies from the
frozen source findings and the new contract. It had no repository, skill, or
tool access.

The raw generation preserved all IDs and bodies, but independent checks found
work that the production action-lock gate is designed to catch:

- One helper severity field drifted from `high` to `critical`.
- Both initial fact-and-action auditors found the same missing report-capability
  fact and collection scope in comment `3737266661`.
- Readability outlier review found five other bodies where exact identifiers,
  title precision, or coupled action constraints could be clearer.

Six bodies were repaired; one helper severity field was corrected. Every
repaired body then passed two independent fact-and-action audits. Final
structural validation passed all 47 rows: input order, JSON shape, natural title,
exact hidden ID/severity/area marker, helper severity, code identifiers, and
numeric evidence.

## Blind readability result

A/B order was randomized per comment. Judges received neither chronology nor
authorship labels. Repaired outliers were rejudged with fresh clean sessions.

| Judge | Maximum-human | Iteration 14 | Tie |
|---|---:|---:|---:|
| GPT-5.6 Luna | 47 | 0 | 0 |
| GPT-5.6 Sol | 47 | 0 | 0 |
| Claude Opus | 47 | 0 | 0 |
| **Total** | **141** | **0** | **0** |

Majority outcome by dimension:

| Dimension | Maximum-human | Iteration 14 | Tie |
|---|---:|---:|---:|
| Defect clarity | 47 | 0 | 0 |
| Action recall | 46 | 0 | 1 |
| Scanability | 47 | 0 | 0 |
| Naturalness | 47 | 0 | 0 |
| Cognitive ease | 47 | 0 | 0 |

The one action-recall tie is the publication comment: both variants retain the
same two requested actions, while the maximum-human version improves the title
and removes visible provenance fields.

The last two targeted changes matter. A direct or glob-expanded directory
symlink is now rejected “while keeping file-symlink behavior unchanged,” and
converted output-log count is reported separately “while keeping results files
as the source-record grain.” This keeps a directly coupled safety boundary in
the action the author must remember without creating a false extra task.

## Verification

The complete local review-anvil suite passed:

- `test-report-language.sh`
- `test-identifiers.sh`
- `test-run-reviewer.sh`
- `test-reproduction-policy.sh`
- `test-pr-helper.sh`

Final independent code review found two cutover gaps before commit. The report
suppression pass did not carry canonical IDs into history matching, and the
natural-title parser rejected `*` inside code spans such as `` `*.json` ``.
Both paths now have red-green regression coverage.

A direct `pr-helper.sh process-inline` smoke test also passed. The processed
payload contained only GitHub-supported keys; its suggestion block preceded the
hidden prior-feedback marker, and the terminal finding-metadata marker remained
last.

## Limitations

- Clean model judges are not a substitute for a timed study with human PR
  authors.
- The historical comments are verbatim, but their exact producing skill commit
  was not recorded.
- The corpus covers accepted inline findings. It does not measure top-level
  review summaries, GitHub email rendering, latency, or token cost.

## Recommended next steps

1. Run a blinded human PR-author study in the GitHub UI. Measure time to state
   the defect, consequence, requested change, and preservation boundary.
2. Inspect GitHub notification email and mobile rendering of the terminal HTML
   marker. The web UI hides it, but raw/API consumers can retrieve it.
3. Add a fixed holdout corpus from another repository before changing the
   wording contract again. Keep the current 47 comments frozen as a regression
   set, not a tuning set.
4. Measure generation and two-auditor latency. Optimize cost only after the
   human study confirms the readability gain.

## Primary artifacts

- `iteration-15-maximum-human-comments.json`
- `iteration-15-maximum-human-final-selection.json`
- `iteration-15-maximum-human-final-validation.json`
- `iteration-15-maximum-human-readability-prompt.md`
- `iteration-15-maximum-human-readability-{luna,sol,claude}.txt`
- `iteration-15-maximum-human-action-audit-{sol,claude}.txt`
- `iteration-15-maximum-human-smoke.inline.json`
