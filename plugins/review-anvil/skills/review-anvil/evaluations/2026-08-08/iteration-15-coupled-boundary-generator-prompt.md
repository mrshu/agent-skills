Render one GitHub inline review comment from the source under the contract. Do not inspect a repository, add facts, omit facts, or turn no-change boundaries into separate work. Return valid JSON only: {"id":"3737291965","body":"<complete body>"}. The visible title must be natural and hide ID, severity, and area. End with exactly `<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=filesystem-traversal -->` as the final nonblank line.

CONTRACT:
Prefer a direct verb with a concrete target, condition, or destination.
Use an imperative only for work the author must perform. Use modal prose for
behavior that may remain unchanged.
Do not force an actor or destination that the source does not establish.
Group requested work by implementation obligation, not by grammar.
Classify each source predicate before rendering it:

1. Identify whether it describes accepted current behavior, target behavior
   needed to resolve the finding, required verification or documentation, an
   allowed implementation boundary, or an explicitly optional follow-up.
2. Classify target behavior and required verification or documentation as
   author work. Classify accepted current behavior, allowed implementation
   boundaries, and explicitly optional follow-ups as no-change boundaries.
3. Apply the omission counterfactual only after that classification. If leaving
   the current code without the target behavior, test, or documentation would
   leave the defect, safety boundary, or reviewer-required verification
   unresolved, it is author work.
4. Split every source sentence that mixes author work with a no-change boundary
   into predicates for classification; do not preserve an unsplit fallback.

Source intent outranks modal grammar. `Please`, a direct request, or source
words such as `must`, `need`, and `required` identify author work. A
source-backed check, test, document change, or example stated to cover,
demonstrate, clarify, or make a required boundary clear is author work unless
the source explicitly calls it optional or additional. Words such as `can`,
`could`, and `would` do not make that work optional.

A permission is not author work only when it describes acceptable unchanged
behavior, an allowed implementation boundary, or an explicitly optional
follow-up. Words such as `remain`, `keep`, `leave`, `unchanged`, and `still`
identify preservation only when the source says the current behavior is
already acceptable.

An obligation is one cohesive change that can be implemented and verified
independently. Extract its smallest actor-action-target change without
detaching a purpose, result, or safety clause that constrains that change.
Create a separate obligation only when the source requires another
independently implementable action. If a new mechanism is needed to resolve
the failure, request that mechanism and keep only its permitted behavior as modal prose.
Do not split a list of values governed by one rule into repeated actions.
Two verbs that establish one invariant on the same record or output remain one obligation.

A no-change boundary is not a separate obligation. Keep it out of
`**Requested actions**` as a separate bullet. When accepted current behavior
directly constrains a requested change, keep it in the same sentence using
`without changing …` or `while keeping … unchanged`. If that sentence would
be dense, use short modal prose immediately after the action. Preserve other
accepted current behavior as standalone modal prose. Preserve a standalone
optional follow-up as standalone modal prose after the required request, or
after the consequence when no request exists.

For example: `Files containing only intentionally skipped derived rows can remain explicit exclusions; no change is requested for them.`
For a coupled boundary: `Reject directory-target symlinks without changing file-symlink behavior.`

Make a distinct path separate only when the source requires the author to
change that path independently. A required source-backed test is author work
and is separate when it has its own exact boundary.
Reuse exact source wording for scope and collection phrases; do not replace
them with inferred member names.

Before writing, map every source predicate to author work or a no-change
boundary. Do not emit until every author-work predicate appears as an explicit
request.
For each source-backed obligation in a critical, high, or medium finding, make
its requested status explicit. For exactly one obligation, write one short
request sentence beginning with `Please` and a direct action verb.
For two or more independently implementable obligations, use this form:

```md
**Requested actions**

- <Direct verb, target, and necessary condition or destination.>
- <Direct verb, target, and a distinct implementation or exact test boundary.>
```

Order required behavior changes before required tests. Keep no-change
constraints with the action they limit or in the modal prose immediately after
it.
Do not repeat `Please` in the bullets; the heading establishes request mode.
Avoid repeating a long shared phrase across bullets.
Keep suggestion grammar for low and nit guidance.
Never write `the fix`, `in the fix`, or `the corrected path` unless the source
explicitly discusses an existing patch under review.
Apply the actor-action-target check to requested-change sentences as well as titles.
If a requested change shifts the target, restore the source plan sentence verbatim.
If no source-backed requested change exists, stop after the consequence.
Do not invent why a requested test exists.
Delete a source clause only when another retained clause states the same fact.
If an exact phrase is hard to place, keep the whole source sentence.

Write the visible body in this order:

1. **Problem:** Name the code behavior and trigger.
2. **Impact:** State the concrete bad result.
3. **Requested change:** State the exact action or decision. Include a test only
   when the source requests it; do not invent what the test proves.
The first visible sentence adds a trigger, mechanism, result, or fix boundary that the title does not already state. If the title fully states the problem and consequence, begin with the next new fact or the request.

After the visible body, append the exact finding-metadata marker as the final
nonblank line.

Each sentence explains one relationship between code concepts. Name the
function, field, command, or request that acts. Tie each necessary identifier
to its role in the failure. Use a pronoun only when its antecedent is the
immediately preceding subject and cannot be confused with another identifier.
Use one minimal example only when it makes a path, count, or state change easier
to see. Do not show the Problem, Impact, or Requested change labels in the final
comment.


SOURCE:
**RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target

`Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.

The expansion can reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged. Tests for both directory-symlink inputs and an accepted file symlink would cover the boundary.