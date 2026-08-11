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

AUDIT ROWS FOR PR #190 REVIEW 4870915628:
[
  {
    "id": "AUDIT:3725853148",
    "source_context": "**RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.",
    "source_requested_work": "Network-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access.",
    "rendered_body": "**RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution.\n\nTwo network runs can fetch different input under the same identity.\n\nPlease resolve network-mode refs once to a commit SHA. Offline replay can keep the stored immutable ref without network access."
  },
  {
    "id": "AUDIT:3725853152",
    "source_context": "**RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.",
    "source_requested_work": "The module entry point can use the shared parser, with one offline entry-point test covering its defaults.",
    "rendered_body": "**RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace.\n\nThis handler now reads missing fields and fails before conversion.\n\n**Requested actions**\n\n- Use the shared parser in the module entry point.\n- Add one offline entry-point test covering its defaults."
  },
  {
    "id": "AUDIT:3725853155",
    "source_context": "**RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.",
    "source_requested_work": "Numeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.",
    "rendered_body": "**RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling.\n\nThey can omit the headline metric or abort strict JSON publication.\n\nPlease validate numeric fields as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`."
  },
  {
    "id": "AUDIT:3725853159",
    "source_context": "**RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.",
    "source_requested_work": "New snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.",
    "rendered_body": "**RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content.\n\nOffline records cannot reconstruct the generation prompt.\n\nPlease store pinned prompt content in new snapshots. Legacy snapshots can leave this typed value unset and mark the missing content."
  },
  {
    "id": "AUDIT:3725853163",
    "source_context": "**RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.",
    "source_requested_work": "Live mode can query present-null entries while offline behavior remains unchanged.",
    "rendered_body": "**RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null.\n\nA known gap cannot discover a new registry entry until the snapshot refreshes.\n\nPlease make live mode query present-null entries. Offline behavior can remain unchanged."
  },
  {
    "id": "AUDIT:3725853168",
    "source_context": "**RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.",
    "source_requested_work": "Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.",
    "rendered_body": "**RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nPlease make exact canonical IDs win first. Normalized spellings can resolve only when one organization owns them."
  }
]
