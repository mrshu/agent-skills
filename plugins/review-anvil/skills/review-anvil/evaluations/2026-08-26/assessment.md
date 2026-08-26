# Final clarity-pass assessment

## Decision

Keep the final clarity pass. It makes the complete historical reviews easier to scan and act on while preserving the frozen facts, actions, dispositions, identities, suggestions, and report/inline coordinates.

The production change runs one clean renderer after synthesis, reproduction, and adversarial review have frozen the report packet. It validates the rendered bundle deterministically, then action-lock audits report and inline surfaces independently. Invalid output restores the pre-clarity artifacts and forces `COMMENT`.

## Historical comparison

The frozen sample contains three prior `evaleval/every_eval_ever` review-anvil reviews:

- PR #190 review `4870915628`: 11 findings, 7 inline comments;
- PR #204 review `4884442134`: 5 findings, 3 inline comments;
- PR #230 review `4870883842`: 6 findings, 2 inline comments.

`source-snapshot.json` contains the verbatim source reports and comments with per-body SHA-256 checksums. `extract-corpus.py` verifies those checksums and regenerates `corpus.json` without the earlier external-worktree dependency.

The top-level reports became shorter while retaining every location and requested boundary:

| Review | Before | After | Reduction |
|---|---:|---:|---:|
| PR #190 | 736 words | 646 words | 12.2% |
| PR #204 | 616 words | 594 words | 3.6% |
| PR #230 | 518 words | 453 words | 12.5% |

The larger gain is structural: each active finding now keeps its defect, consequence, code location, and requested change together. Run mechanics, earlier feedback, low/nit suggestions, and deferred items remain collapsed.

The complete rendered comparison is `before-after.md`.

## Blind readability result

Three clean judges evaluated 15 randomized pairs: 3 complete reports and 12 inline comments. Hidden machine metadata was removed before judging; visible report IDs and code locations remained.

| Surface | After wins | Before wins | Ties |
|---|---:|---:|---:|
| Top-level reports | 9 | 0 | 0 |
| Inline comments | 36 | 0 | 0 |
| **Total** | **45** | **0** | **0** |

Mean scores:

| Dimension | Before | After | Delta |
|---|---:|---:|---:|
| Defect clarity | 4.489 | 5.000 | +0.511 |
| Action recall | 3.800 | 5.000 | +1.200 |
| Scanability | 3.756 | 5.000 | +1.244 |
| Naturalness | 3.578 | 4.844 | +1.266 |
| Cognitive ease | 3.733 | 5.000 | +1.267 |

No final after-version received a hard fact/action failure. Earlier judgment rounds did expose four missing evidence predicates; those predicates were restored before this final run.

## Safety gates

The deterministic validator covers:

- exact decision, metadata/disposition ledger, and visible metadata rows;
- complete modern and legacy report-ID inventory;
- one complete report line per current finding, with exact report-specific location, priority, area, and terminal marker;
- configurable inline severity eligibility, exact inline anchors, severity, suggestions, and reintroduction state;
- exact requested-work inventory and no unknown, missing, or duplicate items.

The action-lock experiment then used explicit surface-specific fact locks. Initial strict audits exposed remaining evidence and no-change-boundary losses. The affected rows were repaired and passed two clean re-auditors. The final report-location pass covered all 22 report items and passed both 22/22 audits.

## Micro-test

Five stateless control samples used the previous split finding/action template; all five repeated issues across separate sections. Five final-recipe samples kept every ID once and avoided a second action section. An intermediate wording variant invented test outcomes in four of five samples; the final prompt now permits only supplied verification, and all five final samples avoided that failure.

See `microtest-results.json`.

## Limits

- Three historical reviews from one repository are not cross-repository generalization evidence.
- The judges are clean sessions but not a human PR-author timing study.
- Prompt-following and LLM audits are probabilistic; deterministic inventory and metadata checks therefore remain mandatory.
- The final renderer adds one model call plus the two-auditor wave and any single repair wave.
