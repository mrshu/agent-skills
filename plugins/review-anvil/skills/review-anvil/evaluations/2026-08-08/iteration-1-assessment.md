# Iteration 1 — problem, impact, outcome

## Change

The inline contract now gives the authoring agent a positive three-part recipe:
problem, impact, and corrected outcome. Titles name the failure. Each sentence
explains one code relationship. Required identifiers are tied to their role.
The reviewer prompt now produces raw `what`, `why`, `evidence`, and
`suggested_fix` fields in the same order.

The change also removes the instruction to vary the grammar of next steps. That
stylistic optimization competed with clarity and encouraged awkward hedging.

## TDD evidence

Before the skill change, `test-report-language.sh` failed because
`report-artifacts.md` did not define the ordered recipe. See
`iteration-1-red.txt`. After the change, the same test passed, including the
existing provenance-ID contract.

## Clean-agent generation

A fresh GPT-5.6 Sol OMP agent received only:

- `rewrite-prompt.md`;
- frozen `corpus.json`;
- the changed `report-artifacts.md` contract.

The agent rewrote all 22 comments into `iteration-1-candidate.json`.

## Blind comparison

Three fresh OMP evaluators used GPT-5.6 Sol, Luna, and Terra. Each ran with no
session, tools, skills, or rules. Candidate labels were reversed for Luna to
check position bias.

| Evaluator | Candidate label | Candidate readability wins | Baseline wins | Ties | Overall |
|---|---:|---:|---:|---:|---|
| GPT-5.6 Sol | B | 22 | 0 | 0 | candidate |
| GPT-5.6 Luna | A | 22 | 0 | 0 | candidate |
| GPT-5.6 Terra | B | 22 | 0 | 0 | candidate |
| **Total** | — | **66** | **0** | **0** | **candidate** |

All three evaluators preferred the candidate on immediate comprehension,
consequence clarity, actionability, sentence clarity, and scanability. The
position reversal did not change the outcome.

## Regression found

Readability improved, but the generation step changed one technical verb:

- In comment `3737044354`, the source says rollback “covers only files created
  by that call.” The candidate says rollback “restores only files created by
  that call.” Cleanup and restoration are not the same operation.

Terra also flagged comment `3737053181`: the candidate states that
`lower_is_better=False` marks a neutral measure as higher-is-better. The source
more carefully says consumers *can interpret* the Boolean that way.

These are small wording changes with correctness risk. Iteration 1 therefore
proves the structure, but it is not yet the final contract.

## Next experiment

Reduce cognitive load further without paraphrasing technical relationships:
front-load the concrete failure, define the role of each necessary code term,
and prefer a minimal example over abstract noun phrases. Keep the iteration-1
recipe and add an explicit evidence-preservation gate in a later pass.
