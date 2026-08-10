# Iteration 10 assessment — coherent contract, unreliable one-pass rendering

## Design

Iteration 10 replaced the ambiguous modal-word heuristic with an ordered
semantic classification:

1. Classify each predicate as target work, required verification or
   documentation, accepted current behavior, an allowed implementation
   boundary, or an explicitly optional follow-up.
2. Apply the omission counterfactual only after that classification.
3. Split every mixed sentence. Do not keep an unsplit fallback.
4. Keep required purpose, result, and safety clauses attached to the mechanism
   they constrain.
5. Give accepted current behavior and optional follow-ups explicit standalone
   modal-prose paths.

The contract also adds direct examples for requested tests written with
`would`, mixed required/permission sentences, and accepted current behavior.

## Contract gate

Two clean `omp` agents read the complete skill and contract files with no
session, tools, skills, or injected rules. Sol and Terra both returned
`approve`, found no material contradiction or precedence gap, and classified
all six stress cases as required.

`test-report-language.sh` also passes. It now rejects the old mixed-permission
example and the permissive grouping rule that allowed one invariant to split.

## Generator gate

Sol, Luna, and Terra each rewrote all 47 diagnostic comments with valid schema
and unique IDs. All three failed the action-lock pre-gate, so none advanced to
fact or readability ranking.

Representative failures:

- Sol turned the permitted no-match stopping point into a mandatory position,
  left valid-metric preservation implicit, promoted a legacy no-change
  boundary into a bullet, and weakened two required actions to modal prose.
- Luna promoted `retrieved_timestamp` permission into a request, left the
  legacy missing-content action implicit, and left required failure and
  tolerance behavior modal.
- Terra dropped two exact documentation/test boundaries, promoted an accepted
  legacy state into an action, and left required default failure modal.

The complete deterministic rejection reasons are in
`iteration-10-selection.json`.

## Decision

Do not select a one-pass candidate. The contract now says the right thing, but
47-comment generation still loses the classification under load. More wording
or more examples would add cognitive load without addressing the execution
failure.

The next experiment should keep this contract and add a separate post-render
action-lock audit. That audit must compare only the source requested-work
predicates with the rendered request section, identify the exact mismatch, and
repair only failed comments. Independence matters: the renderer's private
self-check did not catch its own mistakes.
