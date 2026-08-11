# Iteration 13 assessment — production-path stress test and hardening

## Decision

Keep the iteration-12 rendering direction and the iteration-13 contract
hardening on this branch as the best local skill revision. The hardening:

- restores the truncated low/nit inline-severity rule;
- sends each complete rendered body to both action-lock auditors instead of an
  extracted request subset;
- canonicalizes audit IDs as strings; and
- mechanically disables approval after an exact-source action-lock fallback.

The decision is deliberately scoped. The iteration-12 corpus supports the
rendering direction on review-anvil findings, but it informed the contract.
The fresh iteration-13 corpus is a raw-comment stress test, not in-domain
generalization evidence and not proof of lossless arbitrary-comment rewriting.

## Corpus chronology and contamination boundary

The first iteration-13 corpus contained 31 comments. Its renderer prompt was
changed after dense outputs were inspected, so that corpus is development
evidence only. It is retained under `iteration-13-unseen-holdout-*`. The
contamination boundary is recorded in
`iteration-13-untouched-final-corpus.json` and
`iteration-13-untouched-final-before-after.md`.

The final corpus was frozen at `2026-08-11T02:16:59Z`, after the renderer
contract hash was locked. It contains 25 comments:

- 24 untouched historical comments from `evaleval/every_eval_ever`, selected by
  a predeclared hash rule;
- one public cross-repository comment from `dotnet/sign`;
- zero comments inspected, added, or removed after the freeze.

GitHub exposed no newly published public `every_eval_ever` review-anvil inline
comment after the iteration-12 selection point, so the final corpus is a
post-selection historical holdout, not a future temporal holdout. It excludes
review-anvil labels and contains raw human or Copilot prose. Apply that
out-of-domain limitation to the positive readability/action results and the
negative whole-comment fact results alike. Top-level review artifacts were
unavailable for this comment-sampled gate and are explicitly labeled
unavailable in the rendered artifact.

## Production-shaped stress test

The run exercised the iteration-12 production shape:

1. one clean Luna renderer;
2. two action-lock auditors, Claude Opus and GPT-5.6 Sol;
3. one repair pass over the union of failures;
4. two new auditors for repaired rows;
5. exact-source fallback after a repeated material failure.

The clean calls were sessionless and disabled tools, skills, and rules. The
individual outputs are committed, but the invocation commands are not captured
in a frozen benchmark runner. Sol was reused across audit, fact-diagnostic, and
readability roles; Sol and Terra are from the same GPT model family.

### Action-lock result

| Stage | Claude Opus | GPT-5.6 Sol | Raw union |
|---|---:|---:|---:|
| Initial Luna draft | 22/25 pass | 21/25 pass | 5 failed IDs |
| Repair pass | 4/5 pass | 3/5 pass | 2 failed IDs |

The repaired body for `3652735574` retained its opening author question, but the
harness's `rendered_requested_work` field omitted it. Correcting that extraction
and re-auditing the unchanged body produced two passes. This third check was a
harness correction outside the contract's prescribed two waves. Under the
iteration-12 text, the second-wave failure would have triggered exact-source
fallback and COMMENT.

This incident exposed a fail-open inverse: an extracted request subset could
also omit an invented action from the body. The hardened contract now sends the
exact complete body to each auditor and prohibits request-only extraction.

`3161743720` failed Sol's second audit because the request did not retain the
source result clause that the plot must stay accurate for `--top-n 3` or another
value. The fail-safe restored the exact source comment and forces COMMENT with
`approval_allowed: false`.

Final production output:

- 20 first-pass Luna rewrites;
- 4 repaired Luna rewrites;
- 1 exact-source fallback;
- 24 action-audited rewrites plus 1 lossless source fallback.

## Out-of-domain readability stress test

Three blind judges compared the production-shaped output with the frozen raw
comments. Version order was randomized per comment. The judges were clean
sessions, but not fully model-independent: Sol was reused in other roles, and
Sol and Terra share the GPT family.

| Judge | Production wins | Baseline wins | Ties |
|---|---:|---:|---:|
| Claude Opus | 11 | 7 | 7 |
| GPT-5.6 Sol | 11 | 5 | 9 |
| GPT-5.6 Terra | 11 | 8 | 6 |
| **Total** | **33** | **20** | **22** |

One exact-source fallback made three pairs identical. Across the 24 changed
rows, the result is 33 production wins, 20 baseline wins, and 19 ties.

Aggregate mean deltas versus baseline:

| Dimension | All 25 | Changed 24 |
|---|---:|---:|
| Defect clarity | +0.120 | +0.125 |
| Action recall | +0.680 | +0.709 |
| Scanability | -0.227 | -0.236 |
| Naturalness | +0.293 | +0.305 |
| Cognitive ease | -0.066 | -0.070 |

The output makes requested work easier to identify, but does not dominate raw
prose on scanability or cognitive ease. Source suggestion blocks were omitted
from several stress-test rewrites, and judges cited those concrete blocks in
baseline wins. That loss is part of the negative scanability result, not
diagnostic noise. The hardened contract now preserves a verified exact source
suggestion when it meets every existing anchor and safety exclusion; the
stress-test scores were not rerun after that contract fix.

Because the sources are raw comments rather than synthesized findings, none of
these deltas establishes production generalization.

## Whole-comment fact diagnostic

The production gate audits requested work and behavioral boundaries. It is not
a whole-comment fact gate. Two separate diagnostic judges compared the final
production bodies with the raw historical comments:

| Judge | Fact-safe | Flagged |
|---|---:|---:|
| Claude Opus | 21/25 | 4 |
| GPT-5.6 Sol | 17/25 | 8 |

Both judges flagged `2952666730`, `3102848524`, `3493867085`, and
`3699205371`. The shared flags include an omitted `.pre-commit-config.yaml`
locator, a dropped `longer-term` qualifier, strengthened `a bit` language and
lost first-person provenance, and a removed generated-by footer. Sol also
counted omitted suggestion-block examples and speaker framing.

The same out-of-domain qualification applies in both directions. These flags do
not prove that normalized review-anvil findings lose the same facts, and the
positive readability and action scores do not prove that they generalize to
review-anvil findings. They do show that the iteration-12 request-subset audit
must not be advertised as whole-comment protection. The hardened contract now
audits each full emitted body; structured fact IDs remain a stronger future
option if an in-domain corpus shows residual losses.

## Two-renderer selection artifact

A separate analysis combined fact-safe finalists from Sol and Luna. It is not
the production path because it uses a per-comment oracle and a whole-comment
fact fail-safe.

On the 25-comment final corpus it retained 21 rewrites and restored four exact
source comments. Three blind judges gave it 32 wins, 12 baseline wins, and 31
ties. It improved defect clarity, action recall, and naturalness, while average
scanability and cognitive ease remained slightly below baseline.

Across the earlier 47-comment development and held-out selection corpus:

- the two production judges gave the selected renderer 94/94 fact-safe and
  action-locked judgments after repair;
- their strict selected-versus-baseline rankings were 73–21;
- a later Claude judge independently recorded 31 selected wins, 1 baseline win,
  and 15 ties; these scores are not summed with the strict four-way rankings
  because the judgment scales differ;
- Claude initially marked 44/47 action-locked, then a focused readjudication
  against three authoritative behavior examples resolved all three
  disagreements without changing the comments; and
- selected beat repaired Sol 50–44 across the original two judges.

These development results justify the rendering direction, but not adding a
second production renderer without a deterministic selector.

## Rejected alternatives

- **Free readability rewrite:** large early readability gains, but title
  modality, qualifiers, and implementation boundaries drifted.
- **Declarative desired-state prose:** could read as already-implemented code
  in a review-only run.
- **Grammar-selected bullets:** improved scanning but promoted permissions,
  exceptions, and accepted behavior into false author actions.
- **Single post-render auditor:** one judge repeatedly missed obligations or
  returned malformed output.
- **Dense-source adaptation after inspection:** useful tuning evidence, but not
  valid holdout evidence.
- **Per-comment model oracle in production:** readable and safe in the artifact,
  but adds latency, model variance, and a selector that has not been validated
  independently.

## Independent contract review

Claude Opus found two load-bearing contract defects after the stress test:

1. an earlier edit had replaced the end of the low/nit inline-severity rule
   with a literal ellipsis; and
2. request-only audit extraction could hide an invented action elsewhere in a
   body.

It also found that fallback was absent from the approval criteria and audit ID
typing was underspecified. The first recheck found narrower modal-predicate and
ID-echo gaps. A second verification found that the predicate ledger was still
one-directional, fallback conflicted with byte identity, and labels or evidence
could be misclassified as source-free predicates. The closure check then found
a truncated whole-body sentence and no permitted repair for source-free
evidence; both are fixed.

The final contract uses bidirectional predicate ledgers, gives every
source-free predicate a direction-specific issue bucket, passes all exact
source material used by the body, excludes formatting metadata from semantic
predicates, requires verbatim canonical ID echo, validates rows independently,
scopes byte identity to passing rewrites, permits removal of source-free
predicates, and preserves only safe exact suggestions. Language-contract
assertions cover the bucket directions, source freeze, full-body sentence,
retired request-only field, ID handling, repair, and fallback invariants.

All Critical and Important findings and Minor B7-B13 from the review sequence
are resolved in the current contract. The remaining risk is empirical: the
hardened contract still needs the in-domain frozen run in Best option 2. The
review sequence is recorded in `iteration-13-final-contract-{review,recheck,verification,finalcheck}-claude.md`.
A final clean prompt-only Claude verification returned `resolved: true` with no
Critical or Important findings.

## Best options

1. **Keep the iteration-12 rendering direction plus this branch's hardening.**
   It has the strongest local evidence and closes the full-body audit,
   severity-rule, ID-type, and approval fail-open gaps.
2. **Highest-priority experiment: create an in-domain frozen corpus.** Run the
   engine review-only on unseen PRs, freeze the synthesized findings, exact
   requested-work prose, and any verified source suggestion before rendering,
   lock the renderer hash, then audit and judge. This does not require waiting
   for new public review comments.
3. **Automate the benchmark.** Commit one runner that freezes corpus
   construction, commands, randomization keys, suggestion preservation,
   validation, decoding, and changed-row aggregation before more wording
   changes.
4. **Add structured predicate and fact IDs only if the in-domain run still
   loses facts.** They can replace prose reparsing, but are a larger change than
   the full-body audit fix.
5. **Then reduce preservation density and run a human PR-author study.** Measure
   rereading time, tone, whether exact suggestions help, and whether the next
   edit is obvious while protecting conditions mechanically.
6. **Keep dual rendering optional.** Require a deterministic,
   model-independent selector and a new cross-repository corpus first.
7. **Evaluate complete top-level reviews separately.** This gate covers inline
   comments only.

## Primary evidence

- `iteration-12-assessment.md`
- `iteration-13-untouched-final-corpus.json`
- `iteration-13-production-path-final-comments.json`
- `iteration-13-production-path-before-after.md`
- `iteration-13-production-path-action-audit-*-retry.json`
- `iteration-13-production-path-action-reaudit-*.json`
- `iteration-13-production-path-readability-decoded.json`
- `iteration-13-production-path-fact-diagnostic-summary.json`
- `iteration-13-untouched-final-before-after.md`
- `iteration-13-untouched-final-readability-decoded.json`
- `iteration-13-selected-47-claude-adjudication.json`
- `iteration-13-final-contract-review-claude.md`
- `iteration-13-final-contract-recheck-claude.md`
- `iteration-13-final-contract-verification-claude.md`
- `iteration-13-final-contract-finalcheck-claude.md`
- `iteration-13-final-contract-resolution-claude.json`
