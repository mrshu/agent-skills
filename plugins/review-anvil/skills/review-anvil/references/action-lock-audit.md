# Post-Render Action-Lock Audit

Run this audit after the final clarity pass drafts all top-level report items
and inline comment bodies, before any final artifact is written. Its only
purpose is to prevent a readability rewrite from hiding author work, inventing
work, or changing a requested boundary on either surface.

## Inputs

Before drafting, freeze the exact requested-work prose from each accepted
synthesized finding. Include its permissions, accepted current behavior,
exceptions, tests, documentation, purpose clauses, and safety clauses. Also
freeze the exact source title and diagnosis plus the
exact evidence and code fragments that the body may retain. Include source
suggestions. Do not give the auditors unrelated repository or report context.

Build one audit row per rendered surface. Convert each finding ID to a canonical
opaque string before dispatch. If an original ID contains only digits, prefix
it with `AUDIT:`. A finding can have both a `report` and an `inline` row; the
`(id, surface)` pair is the audit identity.

```json
{
  "id": "RAV-RUN3-R1-F001",
  "surface": "report | inline",
  "request_mode": "required | suggested | summary | boundary",
  "source_context": "<exact source material used by this rendered surface>",
  "source_fact_lock": ["<exact actor/action/target, condition, impact, or evidence predicate>"],
  "source_requested_work": "<exact frozen source prose>",
  "rendered_body": "<exact complete report item or inline body>"
}
```

Derive `request_mode` from the frozen severity, disposition, emitted inline
inventory, and surface. Inline rows and material report rows without an emitted
inline comment use `required`. Low/nit suggestions use `suggested`. Report rows
backed by emitted inline comments use `summary`. Deferred and outside-scope rows
use `boundary`.

Do not extract or summarize a request-only subset.
The auditors need the whole rendered body.

Use `source_context` only to resolve antecedents and current-versus-target
status, and to confirm source support for rendered evidence or code.
Do not derive new work from it. Return every input `(id, surface)` pair exactly
once. Each ID is the canonical string.

## Independent auditor prompt

Dispatch two clean read-only verifier subagents in one parallel wave. Neither
auditor may have rendered the report or comments. Use different model families
when the runtime permits it. Give them only these rules and the audit rows. The
auditors must not inspect or edit the repository.

Copy each input ID and `surface` verbatim into the output. Treat IDs as opaque
JSON strings; never parse, normalize, or reformat them. Return exactly one item
for every input `(id, surface)` pair, with no unknown or duplicate pairs.

Compare source meaning with rendered obligation status.
Do not classify by modal grammar.

For each source predicate:

1. Classify target behavior and required verification or documentation as
   author work.
2. Classify accepted current behavior, allowed implementation boundaries, and
   explicitly optional follow-ups as no-change boundaries.
3. Treat a source-backed check, test, document change, or example stated to
   cover, demonstrate, clarify, or make a required boundary clear as author
   work unless the source explicitly calls it optional or additional.
4. Split mixed predicates. Keep a required purpose, result, or safety clause
   attached to the action it constrains.
5. For `required`, require every author-work predicate to appear as a direct
   request. Reject a draft that leaves it only in modal prose.
6. For `suggested`, require every suggested-work predicate to remain visible
   with suggestion grammar. Reject an omission or a rewrite that makes the
   suggestion mandatory. Do not fail suggestion grammar merely because it is
   not imperative.
7. For `summary`, require only the supplied summary fact lock. Its empty
   `source_requested_work` is intentional; do not demand inline actions on the
   report surface.
8. For `boundary`, preserve the issue and disposition reason without turning
   either into new author work.
9. Reject every action bullet or direct request derived only from a no-change
   boundary.
10. Map every semantic predicate in the complete `rendered_body` back to a
    source predicate, regardless of grammar. This includes requested work,
    author-facing questions, permissions, exceptions, no-change boundaries,
    accepted behavior, optional follow-ups, evidence, and code-sketch behavior.
    Required Markdown and hidden metadata are not semantic predicates.
11. Reject every unmatched rendered predicate. Record unmatched author work in
    `false_actions` and every other source-free predicate in
    `invented_predicates`. Keep `fact_losses` for source predicates that the
    draft omits or changes.

When accepted current behavior directly constrains a required action, keep the
constraint coupled using `without changing …` or `while keeping … unchanged`.
Coupling a no-change boundary to its action does not turn that boundary into
author work.

Audit report and inline surfaces independently. Every predicate supplied to an
audit row must appear on that row's surface. A fact present only on another
surface does not satisfy the ledger.

Fact locks are surface-specific. Put report-location predicates only in
`report` rows. Inline anchors are validated by the clarity bundle validator and
do not belong in an inline body's `source_fact_lock`.

Every `source_fact_lock` predicate must appear semantically unchanged on that
row's surface. It can be shorter only when every actor, action, target,
condition, qualifier, concrete impact, evidence identifier, and path remains.


Before returning a verdict, build source-to-rendered and rendered-to-source
predicate ledgers for each item. Quote and classify every predicate in each
direction, then point to its exact counterpart and obligation status. Split
every mixed sentence before checking it. Return `pass` only when both ledgers
are complete and mapped correctly. Do not include the ledgers in the output.

Use source context to settle meaning before applying those rules:

- If the source requests a new report “while keeping the nonzero exit
  conditional on failures,” saving the report is author work. The already
  correct exit condition is a no-change boundary.
- If the diagnosis says each task currently receives a different metric ID,
  “`accuracy` can remain the metric ID” is target behavior and therefore author
  work.
- “Unresolved keys can be reported after valid metrics are preserved” mixes
  required preservation with an allowed reporting follow-up. Make preservation
  explicit; do not request reporting.
- “Leave the unit unset otherwise” inside a direct request is author work.
  “`pwc_scale` remains in details” is a no-change boundary when the context
  says it is already there.
- “Add a no-match check. It can stop before existing-output discovery or
  publication.” requests the check but permits its stopping point. Do not turn
  the permitted point into a “Stop before…” action.
- “Retrieval time can remain only in `retrieved_timestamp`” is a no-change
  boundary when the context shows that field already records retrieval time.
  Do not fold it into the stable-ID request.
- If construction currently fails after files are written, “Complete output
  can stage before publication” is author work. “Existing logical output can
  be rejected until replacement is atomic, with sidecar validation kept
  streaming” preserves two allowed boundaries; do not turn either into an
  action.
- Preserve every source condition on accepted current behavior exactly.

Return valid, pretty-printed JSON only:

Do not wrap JSON in a Markdown fence.
```json
{
  "items": [
    {
      "id": "RAV-RUN3-R1-F001",
      "surface": "report | inline",
      "status": "pass | fail",
      "missing_author_work": [],
      "false_actions": [],
      "fact_losses": [],
      "invented_predicates": [],
      "repair_instructions": []
    }
  ],
  "pass_count": 0,
  "fail_count": 0
}
```

Use `pass` only when all four issue arrays are empty. Name the exact source or
rendered predicate and its counterpart in every failure.
Never rewrite a comment.
Use `false_actions` for source-free author work, `invented_predicates` for
other source-free rendered predicates, and `fact_losses` only for omitted or
changed source predicates.

Validate returned items independently before using their verdicts. The auditor
must return exactly one item for every input `(id, surface)` pair. For each
pair, accept a verdict only when exactly one item has the exact canonical
string ID, exact surface, valid status, all four issue-array fields, and
internally consistent status. Do not coerce an ID's type or value. Unknown or
malformed items and mismatched top-level counts are protocol errors, but they
do not invalidate another unique, well-formed matching item. A well-formed
matching row remains usable. A row passes only when both auditors return a
valid `pass`. Union valid failures. For every missing, duplicate, malformed,
timed-out, or otherwise unverifiable row, restore the exact source
requested-work prose on that surface without attempting a repair and force
COMMENT.

## Repair and fail-safe

The renderer repairs only surfaces with a valid failed verdict.
Apply each audit instruction without changing the surface-specific fact lock,
evidence, severity, complete ID, anchor, suggestion, disposition, or already
passing requested-work predicates. Remove source-free predicates named by
`false_actions` or `invented_predicates`.

For an inline repair, restore the two-paragraph human form: problem/result,
then requested work. Prefer the renderer's direct-by-default voice, keep
optional work optional, and use a question only for a source-level unresolved
choice. Voice is generation guidance, not an audit verdict. Pass or fail only
on source facts, required work, optionality, permissions, and no-change
boundaries.

Use bullets only for three or more independent obligations. For a `summary`
report repair, keep one short diagnosis sentence and do not add inline requested
work. For a `required` report row without an emitted inline comment, keep the
problem, result, and request self-contained. A `boundary` repair keeps the issue
and disposition reason without creating author work.

Audit repaired rows once more with two new clean auditors under the same
validation and union rules.

If either second-audit verdict fails or is unverifiable, restore the exact
source requested-work prose for that surface and force the review event to
COMMENT. Do not paraphrase the failed request section or add new prose. A
denser source-verbatim request is better than a readable surface that changes
what the author must do.

The byte-identity rule applies to passed rewrites. Each emitted report item or
`.inline.json` body must be byte-identical to the audited `rendered_body`; any
later edit requires a new two-auditor wave. An exact-source fallback is exempt
because it replaces the failed request with frozen source prose and forces
COMMENT.
