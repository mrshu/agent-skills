You are one clean independent post-render action-lock auditor. Do not dispatch other agents. Do not inspect a repository. Do not rewrite comments. Apply the rules below directly to every row and return valid pretty-printed JSON only.

Copy each input ID verbatim into the output. Treat IDs as opaque JSON strings;
never parse, normalize, or reformat them.
Return exactly one item for every input ID, no unknown or duplicate IDs.

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
5. Require every author-work predicate to appear as a direct request. Reject a
   draft that leaves it only in modal prose.
6. Reject every action bullet or direct request derived only from a no-change
   boundary.
7. Map every semantic predicate in the complete `rendered_body` back to a
   source predicate, regardless of grammar. This includes requested work,
   author-facing questions, permissions, exceptions, no-change boundaries,
   accepted behavior, optional follow-ups, evidence, and code-sketch behavior.
   The required label and Markdown structure are not semantic predicates.
8. Reject every unmatched rendered predicate. Record unmatched author work in
   `false_actions` and every other source-free predicate in
   `invented_predicates`. Keep `fact_losses` for source predicates that the
   draft omits or changes. Preserve each matched action target, condition,
   scope, quantifier, order, modality, exact test boundary, path, and
   identifier.

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

```json
{
  "items": [
    {
      "id": "RAV-RUN3-R1-F001",
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
must return exactly one item for every input ID. For each input ID, accept a
verdict only when exactly one item has the exact canonical string ID, valid
status and all four issue-array fields, and internally consistent status. Do
not coerce an ID's type or value. Unknown or malformed items and mismatched
top-level counts are protocol errors, but they do not invalidate another
unique, well-formed matching item. A well-formed matching row remains usable.
A row passes only when both auditors return a valid `pass`. Union valid
failures. For every missing, duplicate, malformed, timed-out, or otherwise
unverifiable row, restore the exact source requested-work prose
without attempting a repair and force COMMENT.

AUDIT ROWS FOR PR #204 REVIEW 4871126847:
[
  {
    "id": "AUDIT:3725972277",
    "source_context": "**RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.",
    "source_requested_work": "Current main can be integrated before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`.",
    "rendered_body": "**RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout.\n\nInstalled packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.\n\nPlease integrate current main before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`."
  },
  {
    "id": "AUDIT:3725972282",
    "source_context": "**RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.",
    "source_requested_work": "The expected value can come from the imported schema version.",
    "rendered_body": "**RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`.\n\nThe test fails after integration.\n\nPlease take the expected value from the imported schema version."
  },
  {
    "id": "AUDIT:3725972285",
    "source_context": "**RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.",
    "source_requested_work": "`accuracy` can remain the metric ID while task-specific evaluation names preserve benchmark identity.",
    "rendered_body": "**RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs.\n\nThis fragments the global accuracy join key.\n\nPlease keep `accuracy` as the metric ID and use task-specific evaluation names to preserve benchmark identity."
  },
  {
    "id": "AUDIT:3725972287",
    "source_context": "**RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.",
    "source_requested_work": "The collection target can reject existing output JSON before UUID generation or batch publication.",
    "rendered_body": "**RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID.\n\nA populated target can hold duplicate logical records.\n\nPlease reject existing output JSON in the collection target before UUID generation or batch publication."
  }
]
