You are one new clean independent post-render action-lock auditor. Do not dispatch other agents. Do not inspect a repository. Do not rewrite comments. Apply the rules below directly to every repaired row and return valid pretty-printed JSON only.

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

REPAIRED AUDIT ROWS FOR PR #235 REVIEW 4884964333:
[
  {
    "id": "AUDIT:3737449070",
    "source_context": "**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.",
    "source_requested_work": "Source metric specs or an operator-supplied definition can establish the semantics. Unresolved keys can be reported after the valid metrics are preserved.",
    "rendered_body": "**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds.\n\nA finite custom key does not prove that direction.\n\n**Requested actions**\n\n- Use source metric specs or an operator-supplied definition to establish the semantics.\n- Preserve the valid metrics.\n\nUnresolved keys can be reported after the valid metrics are preserved."
  },
  {
    "id": "AUDIT:3737449081",
    "source_context": "**RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.",
    "source_requested_work": "The same metric-definition mapping used for direction and bounds can supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.",
    "rendered_body": "**RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy.\n\n`metric_name` keeps the source label but does not provide the cross-source join key.\n\nPlease use the same metric-definition mapping used for direction and bounds to supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics."
  },
  {
    "id": "AUDIT:3737449098",
    "source_context": "**RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved; directory input reports the same failure class correctly.",
    "source_requested_work": "A small lighteval-local file-result path can give both entry modes the same report-before-raise behavior.",
    "rendered_body": "**RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`.\n\nParse or conversion errors exit non-zero, but the structured failure report is never saved. Directory input reports the same failure class correctly.\n\nPlease add a small lighteval-local file-result path so both entry modes report before raising."
  },
  {
    "id": "AUDIT:3737449101",
    "source_context": "**RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.",
    "source_requested_work": "One recursive sanitizer for mappings and lists can protect these values before serialization. Tests with provider-prefixed key names would cover the reachable path without recording secret values.",
    "rendered_body": "**RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized.\n\nSupported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.\n\n**Requested actions**\n\n- Apply one recursive sanitizer to mappings and lists before serialization to protect these values.\n- Add tests with provider-prefixed key names that cover the reachable path without recording secret values."
  }
]
