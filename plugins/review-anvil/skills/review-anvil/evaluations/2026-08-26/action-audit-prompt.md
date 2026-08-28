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
  "request_mode": "required | suggested | boundary",
  "source_context": "<exact source material used by this rendered surface>",
  "source_fact_lock": ["<exact actor/action/target, condition, impact, or evidence predicate>"],
  "source_requested_work": "<exact frozen source prose>",
  "rendered_body": "<exact complete report item or inline body>"
}
```

Derive `request_mode` from severity, disposition, and surface. Inline rows and
critical/high/medium report-table rows use `required`. Low/nit report-table rows
use `suggested`. Deferred and outside-scope rows use `boundary`.

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

Use bullets only for three or more independent inline obligations. A report
repair keeps the fixed one-line table shape and restores the complete issue,
impact, and requested or suggested change in its cells. A `boundary` repair
keeps the issue and disposition reason without creating author work.

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


## Frozen audit rows

```json
{
  "items": [
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F001",
      "surface": "report",
      "request_mode": "required",
      "source_context": "Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect the join key.\n\n**RAV-RUN2-R1-F001 [medium] model-identity** \u2014 Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect this join key.\n\nOnly model IDs emitted by the pinned snapshot need vendored resolution. The source-derived ID can remain a marked fallback.",
      "source_fact_lock": [
        "Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect the join key."
      ],
      "source_requested_work": [
        "Only model IDs emitted by this pinned snapshot can receive vendored registry resolution. The source ID can remain a marked fallback.",
        "Only model IDs emitted by the pinned snapshot need vendored resolution. The source-derived ID can remain a marked fallback."
      ],
      "rendered_body": "| Medium | `every_eval_ever/converters/alpaca_eval/adapter.py:602` | Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases therefore cannot affect the join key. | Apply vendored registry resolution only to model IDs emitted by this pinned snapshot while keeping the source-derived ID as a marked fallback. <!-- review-anvil-report: id=RAV-RUN2-R1-F001 severity=medium area=model-identity path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=602 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F002",
      "surface": "report",
      "request_mode": "required",
      "source_context": "Explicit branch or tag refs are not resolved before use in stable IDs and provenance URLs. Two network runs can fetch different input under the same identity.\n\n**RAV-RUN2-R1-F002 [medium] reproducibility** \u2014 Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.\n\nNetwork-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access.",
      "source_fact_lock": [
        "Explicit branch or tag refs are not resolved before use in stable IDs and provenance URLs. Two network runs can fetch different input under the same identity."
      ],
      "source_requested_work": [
        "Network-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access."
      ],
      "rendered_body": "| Medium | `every_eval_ever/converters/alpaca_eval/adapter.py:838` | Explicit branch and tag refs remain unresolved when they enter stable IDs and provenance URLs. Two network runs can therefore fetch different input under one identity. | Pin network refs once to a commit SHA while keeping offline replay on its stored immutable ref without network access. <!-- review-anvil-report: id=RAV-RUN2-R1-F002 severity=medium area=reproducibility path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=838 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F003",
      "surface": "report",
      "request_mode": "required",
      "source_context": "The module entry point builds the old argument namespace. The changed handler reads missing fields and fails before conversion.\n\n**RAV-RUN2-R1-F003 [medium] cli** \u2014 The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.\n\nThe module entry point can use the shared parser, with one offline entry-point test covering its defaults.",
      "source_fact_lock": [
        "The module entry point builds the old argument namespace. The changed handler reads missing fields and fails before conversion."
      ],
      "source_requested_work": [
        "The module entry point can use the shared top-level parser and one offline entry-point test.",
        "The module entry point can use the shared parser, with one offline entry-point test covering its defaults."
      ],
      "rendered_body": "| Medium | `every_eval_ever/cli.py:383` | This entry point still builds the old arguments. The changed handler reads missing fields and fails before conversion. | Use the shared top-level parser in this module entry point and add one offline entry-point test covering its defaults. <!-- review-anvil-report: id=RAV-RUN2-R1-F003 severity=medium area=cli path=every_eval_ever%2Fcli.py start_line=- line=383 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F005",
      "surface": "report",
      "request_mode": "required",
      "source_context": "Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.\n\n**RAV-RUN2-R1-F005 [medium] input-validation** \u2014 Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.\n\nNumeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.",
      "source_fact_lock": [
        "Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication."
      ],
      "source_requested_work": [
        "Populated numeric cells can validate as finite values within their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.",
        "Numeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`."
      ],
      "rendered_body": "| Medium | `every_eval_ever/converters/alpaca_eval/adapter.py:302` | Populated invalid `win_rate` values bypass row-level error handling. They can hide the main metric or abort strict JSON publication. | Validate each populated numeric value as finite under its metric rules before building results, and send invalid rows to `SourceConversionResult`. <!-- review-anvil-report: id=RAV-RUN2-R1-F005 severity=medium area=input-validation path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=302 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F007",
      "surface": "report",
      "request_mode": "required",
      "source_context": "`GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.\n\n**RAV-RUN2-R1-F007 [medium] generation-provenance** \u2014 `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.\n\nNew snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.",
      "source_fact_lock": [
        "`GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt."
      ],
      "source_requested_work": [
        "New snapshots can store pinned prompt content. Legacy snapshots can leave the typed value unset and mark missing content.",
        "New snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content."
      ],
      "rendered_body": "| Medium | `every_eval_ever/converters/alpaca_eval/adapter.py:643` | `GenerationArgs.prompt_template` stores an upstream path instead of the prompt, so offline records cannot reconstruct it. | Store pinned prompt content for new snapshots. For legacy snapshots, leave this typed value unset and mark the missing content. <!-- review-anvil-report: id=RAV-RUN2-R1-F007 severity=medium area=generation-provenance path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=643 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F009",
      "surface": "report",
      "request_mode": "required",
      "source_context": "Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.\n\n**RAV-RUN2-R1-F009 [medium] registry-resolution** \u2014 Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.\n\nLive mode can query present-null entries while offline behavior remains unchanged.",
      "source_fact_lock": [
        "Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes."
      ],
      "source_requested_work": [
        "Live mode can query present-null entries while offline behavior stays unchanged.",
        "Live mode can query present-null entries while offline behavior remains unchanged."
      ],
      "rendered_body": "| Medium | `every_eval_ever/helpers/eval_card_registry.py:245` | Live lookup skips entries already marked missing in the local snapshot, so it cannot discover a new registry value until that snapshot refreshes. | Query those entries in live mode while keeping offline behavior unchanged. <!-- review-anvil-report: id=RAV-RUN2-R1-F009 severity=medium area=registry-resolution path=every_eval_ever%2Fhelpers%2Feval_card_registry.py start_line=- line=245 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F011",
      "surface": "report",
      "request_mode": "required",
      "source_context": "Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\n**RAV-RUN2-R1-F011 [medium] registry-identity** \u2014 Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nExact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.",
      "source_fact_lock": [
        "Normalized organization collisions can rewrite an exact canonical ID to another canonical organization."
      ],
      "source_requested_work": [
        "Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them."
      ],
      "rendered_body": "| Medium | `every_eval_ever/tools/refresh_eval_card_registry.py:151` | Normalized organization collisions can redirect an exact canonical ID to another canonical organization. | Prefer exact canonical IDs and resolve normalized names only when one organization owns them. <!-- review-anvil-report: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity path=every_eval_ever%2Ftools%2Frefresh_eval_card_registry.py start_line=- line=151 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F004",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "The fixed default smoke directory keeps UUID-named output from earlier runs.",
      "source_fact_lock": [
        "The fixed default smoke directory keeps UUID-named output from earlier runs.",
        "Report location: every_eval_ever/cli.py:624."
      ],
      "source_requested_work": [
        "A temporary-directory context can own and remove default smoke output while preserving explicit output paths."
      ],
      "rendered_body": "| Low | `every_eval_ever/cli.py:624` | The fixed default smoke directory keeps UUID-named output from earlier runs. | Consider using a temporary-directory context that cleans it up while preserving explicit output paths. <!-- review-anvil-report: id=RAV-RUN2-R1-F004 severity=low area=output-lifecycle path=every_eval_ever%2Fcli.py start_line=- line=624 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F006",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "The primary description always says 805 judged instructions, even when `n_total` is smaller.",
      "source_fact_lock": [
        "The primary description always says 805 judged instructions, even when `n_total` is smaller.",
        "Report location: every_eval_ever/converters/alpaca_eval/adapter.py:438."
      ],
      "source_requested_work": [
        "The primary description can use the validated row denominator."
      ],
      "rendered_body": "| Low | `every_eval_ever/converters/alpaca_eval/adapter.py:438` | The primary description always says 805 judged instructions even when `n_total` is smaller. | Consider using the validated row denominator. <!-- review-anvil-report: id=RAV-RUN2-R1-F006 severity=low area=metric-semantics path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=438 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F008",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "Every row is marked third-party, including a model developed by the evaluating organization.",
      "source_fact_lock": [
        "Every row is marked third-party, including a model developed by the evaluating organization.",
        "Report location: every_eval_ever/converters/alpaca_eval/adapter.py:893."
      ],
      "source_requested_work": [
        "Canonical evaluator and model-developer organizations can determine the relationship."
      ],
      "rendered_body": "| Low | `every_eval_ever/converters/alpaca_eval/adapter.py:893` | Every row is marked third-party, even when the evaluator developed the model. | Consider using the canonical evaluator and developer organizations. <!-- review-anvil-report: id=RAV-RUN2-R1-F008 severity=low area=source-metadata path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=893 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F010",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "A prior live error causes later successful exact misses to report `registry_unavailable`.",
      "source_fact_lock": [
        "A prior live error causes later successful exact misses to report `registry_unavailable`.",
        "Report location: every_eval_ever/helpers/eval_card_registry.py:267."
      ],
      "source_requested_work": [
        "Each cached live lookup can carry a hit, miss, or error result. Aggregate errors can remain separate."
      ],
      "rendered_body": "| Low | `every_eval_ever/helpers/eval_card_registry.py:267` | A prior live error causes a later successful exact miss to record `registry_unavailable`. | Consider recording a hit, miss, or error for each cached live lookup while keeping aggregate errors separate. <!-- review-anvil-report: id=RAV-RUN2-R1-F010 severity=low area=registry-provenance path=every_eval_ever%2Fhelpers%2Feval_card_registry.py start_line=- line=267 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F001",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect the join key.\n\n**RAV-RUN2-R1-F001 [medium] model-identity** \u2014 Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect this join key.\n\nOnly model IDs emitted by the pinned snapshot need vendored resolution. The source-derived ID can remain a marked fallback.",
      "source_fact_lock": [
        "Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect the join key."
      ],
      "source_requested_work": [
        "Only model IDs emitted by this pinned snapshot can receive vendored registry resolution. The source ID can remain a marked fallback.",
        "Only model IDs emitted by the pinned snapshot need vendored resolution. The source-derived ID can remain a marked fallback."
      ],
      "rendered_body": "Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases therefore cannot affect the join key.\n\nApply vendored registry resolution only to model IDs emitted by this pinned snapshot while keeping the source-derived ID as a marked fallback.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=model-identity -->"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F002",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "Explicit branch or tag refs are not resolved before use in stable IDs and provenance URLs. Two network runs can fetch different input under the same identity.\n\n**RAV-RUN2-R1-F002 [medium] reproducibility** \u2014 Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.\n\nNetwork-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access.",
      "source_fact_lock": [
        "Explicit branch or tag refs are not resolved before use in stable IDs and provenance URLs. Two network runs can fetch different input under the same identity."
      ],
      "source_requested_work": [
        "Network-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access."
      ],
      "rendered_body": "Explicit branch and tag refs remain unresolved when they enter stable IDs and provenance URLs. Two network runs can therefore fetch different input under one identity.\n\nPin network refs once to a commit SHA while keeping offline replay on its stored immutable ref without network access.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F002 severity=medium area=reproducibility -->"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F003",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "The module entry point builds the old argument namespace. The changed handler reads missing fields and fails before conversion.\n\n**RAV-RUN2-R1-F003 [medium] cli** \u2014 The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.\n\nThe module entry point can use the shared parser, with one offline entry-point test covering its defaults.",
      "source_fact_lock": [
        "The module entry point builds the old argument namespace. The changed handler reads missing fields and fails before conversion."
      ],
      "source_requested_work": [
        "The module entry point can use the shared top-level parser and one offline entry-point test.",
        "The module entry point can use the shared parser, with one offline entry-point test covering its defaults."
      ],
      "rendered_body": "This entry point still builds the old arguments. The changed handler reads missing fields and fails before conversion.\n\nUse the shared top-level parser in this module entry point and add one offline entry-point test covering its defaults.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=cli -->"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F005",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.\n\n**RAV-RUN2-R1-F005 [medium] input-validation** \u2014 Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.\n\nNumeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.",
      "source_fact_lock": [
        "Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication."
      ],
      "source_requested_work": [
        "Populated numeric cells can validate as finite values within their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.",
        "Numeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`."
      ],
      "rendered_body": "Populated invalid `win_rate` values bypass row-level error handling. They can hide the main metric or abort strict JSON publication.\n\nValidate each populated numeric value as finite under its metric rules before building results, and send invalid rows to `SourceConversionResult`.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F005 severity=medium area=input-validation -->"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F007",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "`GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.\n\n**RAV-RUN2-R1-F007 [medium] generation-provenance** \u2014 `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.\n\nNew snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.",
      "source_fact_lock": [
        "`GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt."
      ],
      "source_requested_work": [
        "New snapshots can store pinned prompt content. Legacy snapshots can leave the typed value unset and mark missing content.",
        "New snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content."
      ],
      "rendered_body": "`GenerationArgs.prompt_template` stores an upstream path instead of the prompt, so offline records cannot reconstruct it.\n\nStore pinned prompt content for new snapshots. For legacy snapshots, leave this typed value unset and mark the missing content.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F007 severity=medium area=generation-provenance -->"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F009",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.\n\n**RAV-RUN2-R1-F009 [medium] registry-resolution** \u2014 Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.\n\nLive mode can query present-null entries while offline behavior remains unchanged.",
      "source_fact_lock": [
        "Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes."
      ],
      "source_requested_work": [
        "Live mode can query present-null entries while offline behavior stays unchanged.",
        "Live mode can query present-null entries while offline behavior remains unchanged."
      ],
      "rendered_body": "Live lookup skips entries already marked missing in the local snapshot, so it cannot discover a new registry value until that snapshot refreshes.\n\nQuery those entries in live mode while keeping offline behavior unchanged.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F009 severity=medium area=registry-resolution -->"
    },
    {
      "case_id": "every_eval_ever-pr-190-review-4870915628",
      "id": "RAV-RUN2-R1-F011",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\n**RAV-RUN2-R1-F011 [medium] registry-identity** \u2014 Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nExact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.",
      "source_fact_lock": [
        "Normalized organization collisions can rewrite an exact canonical ID to another canonical organization."
      ],
      "source_requested_work": [
        "Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them."
      ],
      "rendered_body": "Normalized organization collisions can redirect an exact canonical ID to another canonical organization.\n\nPrefer exact canonical IDs and resolve normalized names only when one organization owns them.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity -->"
    },
    {
      "case_id": "every_eval_ever-pr-204-review-4884442134",
      "id": "RAV-RUN3-R1-F001",
      "surface": "report",
      "request_mode": "required",
      "source_context": "`--replace-existing` deletes prior records before replacement preflight. A later validation or write failure can leave the target without its prior records.\n\n**RAV-RUN3-R1-F001 [high] publication** \u2014 `--replace-existing` deletes prior records before replacement preflight\n\nLines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.\n\nThe replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.",
      "source_fact_lock": [
        "`--replace-existing` deletes prior records before replacement preflight. A later validation or write failure can leave the target without its prior records.",
        "Lines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records."
      ],
      "source_requested_work": [
        "The replacement path could preflight all new records and retain recoverable old files until every new write succeeds. Failure tests across several model routes would cover the rollback.",
        "The replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path."
      ],
      "rendered_body": "| High | `every_eval_ever/adapters/open_medical_llm/adapter.py:601` | With `--replace-existing`, lines 601\u2013602 delete the old files before `save_evaluation_logs()` checks or writes the new batch. Its rollback covers only newly created files, so later validation or write failure can leave no old records. | Preflight all new records, retain recoverable old files until every new write and route transition succeeds, and add mid-write failure tests across several model routes to cover the rollback path. <!-- review-anvil-report: id=RAV-RUN3-R1-F001 severity=high area=publication path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=601 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-204-review-4884442134",
      "id": "RAV-RUN3-R1-F002",
      "surface": "report",
      "request_mode": "required",
      "source_context": "Alias reconciliation uses the current Hugging Face canonical repository in `evaluation_id`. The same source file can receive a different identity after alias metadata changes.\n\n**RAV-RUN3-R1-F002 [high] evaluation-identity** \u2014 Alias metadata can change the identity of the same source file\n\n`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.\n\nThe raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing.",
      "source_fact_lock": [
        "Alias reconciliation uses the current Hugging Face canonical repository in `evaluation_id`. The same source file can receive a different identity after alias metadata changes.",
        "`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity."
      ],
      "source_requested_work": [
        "The original dataset model path can remain the evaluation identity input. The reconciled repository can continue to drive model metadata and routing.",
        "The raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing."
      ],
      "rendered_body": "| High | `every_eval_ever/adapters/open_medical_llm/adapter.py:397` | `evaluated_model_repo()` returns the current Hugging Face canonical repository, and `make_log()` puts it in `evaluation_id`. A later alias redirect can give the same source file a second identity. | Use the raw dataset model path for identity while keeping the reconciled repository for metadata and routing. <!-- review-anvil-report: id=RAV-RUN3-R1-F002 severity=high area=evaluation-identity path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=397 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-204-review-4884442134",
      "id": "RAV-RUN3-R1-F003",
      "surface": "report",
      "request_mode": "required",
      "source_context": "Non-finite scores pass conversion but fail strict batch serialization after worker accounting. One malformed record can block all valid records.",
      "source_fact_lock": [
        "Non-finite scores pass conversion but fail strict batch serialization after worker accounting. One malformed record can block all valid records.",
        "Report location: every_eval_ever/adapters/open_medical_llm/adapter.py:301."
      ],
      "source_requested_work": [
        "The existing `require_finite_number` helper can validate accuracy and uncertainty inside `make_result`. The worker boundary will then account for the selected source file."
      ],
      "rendered_body": "| Medium | `every_eval_ever/adapters/open_medical_llm/adapter.py:301` | Non-finite scores pass conversion but fail strict batch serialization after worker accounting, so one bad record blocks all valid records. | Validate accuracy and uncertainty with `require_finite_number` inside `make_result` so the worker boundary records the selected source file. <!-- review-anvil-report: id=RAV-RUN3-R1-F003 severity=medium area=record-isolation path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=301 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-204-review-4884442134",
      "id": "RAV-RUN3-R1-F004",
      "surface": "report",
      "request_mode": "required",
      "source_context": "A run with exclusions but no failures does not persist its accounting report. A report from an earlier failed run also remains unchanged.\n\n**RAV-RUN3-R1-F004 [medium] source-accounting** \u2014 Exclusions-only runs do not persist their accounting report\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.\n\nAn atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger.",
      "source_fact_lock": [
        "A run with exclusions but no failures does not persist its accounting report. A report from an earlier failed run also remains unchanged.",
        "`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current."
      ],
      "source_requested_work": [
        "An atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger."
      ],
      "rendered_body": "| Medium | `every_eval_ever/adapters/open_medical_llm/adapter.py:585` | `failure_report()` already includes exclusions, but this branch saves it only when failures exist. The five documented baseline exclusions get no durable record, and an older failure report can remain current. | Replace the report atomically after successful publication so failures, exclusions, and clean runs are recorded without losing the last complete report. <!-- review-anvil-report: id=RAV-RUN3-R1-F004 severity=medium area=source-accounting path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=585 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-204-review-4884442134",
      "id": "RAV-RUN3-R1-F005",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "`--limit 0` processes all models. Negative limits use Python negative slicing.",
      "source_fact_lock": [
        "`--limit 0` processes all models. Negative limits use Python negative slicing.",
        "Report location: every_eval_ever/adapters/open_medical_llm/adapter.py:568."
      ],
      "source_requested_work": [
        "Negative limits can be rejected, and slicing can run whenever the value is not `None`."
      ],
      "rendered_body": "| Low | `every_eval_ever/adapters/open_medical_llm/adapter.py:568` | `--limit 0` processes every model, while negative limits use Python negative slicing. | Consider rejecting negatives and slicing for every non-`None` limit. <!-- review-anvil-report: id=RAV-RUN3-R1-F005 severity=low area=CLI path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=568 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-204-review-4884442134",
      "id": "RAV-RUN3-R1-F001",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "`--replace-existing` deletes prior records before replacement preflight. A later validation or write failure can leave the target without its prior records.\n\n**RAV-RUN3-R1-F001 [high] publication** \u2014 `--replace-existing` deletes prior records before replacement preflight\n\nLines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.\n\nThe replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.",
      "source_fact_lock": [
        "`--replace-existing` deletes prior records before replacement preflight. A later validation or write failure can leave the target without its prior records.",
        "Lines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records."
      ],
      "source_requested_work": [
        "The replacement path could preflight all new records and retain recoverable old files until every new write succeeds. Failure tests across several model routes would cover the rollback.",
        "The replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path."
      ],
      "rendered_body": "With `--replace-existing`, lines 601\u2013602 delete the old files before `save_evaluation_logs()` checks or writes the new batch. Its rollback covers only newly created files, so later validation or write failure can leave no old records.\n\nPreflight all new records, retain recoverable old files until every new write and route transition succeeds, and add mid-write failure tests across several model routes to cover the rollback path.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F001 severity=high area=publication -->"
    },
    {
      "case_id": "every_eval_ever-pr-204-review-4884442134",
      "id": "RAV-RUN3-R1-F002",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "Alias reconciliation uses the current Hugging Face canonical repository in `evaluation_id`. The same source file can receive a different identity after alias metadata changes.\n\n**RAV-RUN3-R1-F002 [high] evaluation-identity** \u2014 Alias metadata can change the identity of the same source file\n\n`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.\n\nThe raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing.",
      "source_fact_lock": [
        "Alias reconciliation uses the current Hugging Face canonical repository in `evaluation_id`. The same source file can receive a different identity after alias metadata changes.",
        "`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity."
      ],
      "source_requested_work": [
        "The original dataset model path can remain the evaluation identity input. The reconciled repository can continue to drive model metadata and routing.",
        "The raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing."
      ],
      "rendered_body": "`evaluated_model_repo()` returns the current Hugging Face canonical repository, and `make_log()` puts it in `evaluation_id`. A later alias redirect can give the same source file a second identity.\n\nUse the raw dataset model path for identity while keeping the reconciled repository for metadata and routing.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F002 severity=high area=evaluation-identity -->"
    },
    {
      "case_id": "every_eval_ever-pr-204-review-4884442134",
      "id": "RAV-RUN3-R1-F004",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "A run with exclusions but no failures does not persist its accounting report. A report from an earlier failed run also remains unchanged.\n\n**RAV-RUN3-R1-F004 [medium] source-accounting** \u2014 Exclusions-only runs do not persist their accounting report\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.\n\nAn atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger.",
      "source_fact_lock": [
        "A run with exclusions but no failures does not persist its accounting report. A report from an earlier failed run also remains unchanged.",
        "`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current."
      ],
      "source_requested_work": [
        "An atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger."
      ],
      "rendered_body": "`failure_report()` already includes exclusions, but this branch saves it only when failures exist. The five documented baseline exclusions get no durable record, and an older failure report can remain current.\n\nReplace the report atomically after successful publication so failures, exclusions, and clean runs are recorded without losing the last complete report.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F004 severity=medium area=source-accounting -->"
    },
    {
      "case_id": "every_eval_ever-pr-230-review-4870883842",
      "id": "RAV-RUN1-R1-F003",
      "surface": "report",
      "request_mode": "required",
      "source_context": "The new warning stays hidden in the default rich output until PR #221 is included. The current renderer returns after `PASS` for valid reports.\n\n**RAV-RUN1-R1-F003 [medium] warning-visibility** \u2014 The new warning stays hidden in the default rich output without PR #221\n\nWarning severity leaves the report valid. The current rich renderer prints `PASS` and returns before its warning loop.\n\nPR #221 is already listed as a prerequisite. After rebase, one default-rich CLI check for this warning would confirm the complete path.",
      "source_fact_lock": [
        "The new warning stays hidden in the default rich output until PR #221 is included. The current renderer returns after `PASS` for valid reports.",
        "Warning severity leaves the report valid. The current rich renderer prints `PASS` and returns before its warning loop."
      ],
      "source_requested_work": [
        "PR #221 can remain the merge prerequisite. After rebase, this warning needs one check through the default rich CLI path.",
        "PR #221 is already listed as a prerequisite. After rebase, one default-rich CLI check for this warning would confirm the complete path."
      ],
      "rendered_body": "| Medium | `every_eval_ever/validator/validation_core.py:832` | Warnings do not make the report invalid, so the rich renderer returns after `PASS` before it prints them. The new warning is hidden until PR #221 is included. | PR #221 can remain the merge prerequisite. After rebasing, add one default-rich CLI check for this warning to confirm the complete path. <!-- review-anvil-report: id=RAV-RUN1-R1-F003 severity=medium area=warning-visibility path=every_eval_ever%2Fvalidator%2Fvalidation_core.py start_line=- line=832 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-230-review-4870883842",
      "id": "RAV-RUN1-R1-F004",
      "surface": "report",
      "request_mode": "required",
      "source_context": "This adds a registered validator rule, but the required `datastore-gate.md` contributor guidance does not describe it.\n\n**RAV-RUN1-R1-F004 [medium] contributor-guidance** \u2014 The new registered warning is missing from the required datastore gate guide\n\nThe repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.\n\nA short section can state the alias trigger, warning-only result, and single-record evidence limit.",
      "source_fact_lock": [
        "This adds a registered validator rule, but the required `datastore-gate.md` contributor guidance does not describe it.",
        "The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide."
      ],
      "source_requested_work": [
        "`datastore-gate.md` can state the alias trigger, warning-only result, and single-record evidence limit.",
        "A short section can state the alias trigger, warning-only result, and single-record evidence limit."
      ],
      "rendered_body": "| Medium | `every_eval_ever/validator/validation_core.py:835` | Repository instructions require validator guidance in `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md`. This PR adds the registered warning but leaves that guide unchanged. | Add a short section there covering the alias trigger, warning-only result, and single-record evidence limit. <!-- review-anvil-report: id=RAV-RUN1-R1-F004 severity=medium area=contributor-guidance path=every_eval_ever%2Fvalidator%2Fvalidation_core.py start_line=- line=835 disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-230-review-4870883842",
      "id": "RAV-RUN1-R1-F001",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "The maintainer refresh tool replaces the tracked snapshot with a direct truncating write. An interrupted refresh can leave invalid JSON for later semantic validation.",
      "source_fact_lock": [
        "The maintainer refresh tool replaces the tracked snapshot with a direct truncating write. An interrupted refresh can leave invalid JSON for later semantic validation."
      ],
      "source_requested_work": [
        "A same-directory temporary file can preserve the live snapshot until replacement. Cleanup and file-mode preservation keep that path tidy."
      ],
      "rendered_body": "| Low | \u2014 | The maintainer refresh tool replaces the tracked snapshot with a direct truncating write, so interruption can leave invalid JSON for later semantic validation. | Consider a same-directory temporary file that preserves the live snapshot until replacement and keeps the path tidy through cleanup and file-mode preservation. <!-- review-anvil-report: id=RAV-RUN1-R1-F001 severity=low area=refresh-safety path=- start_line=- line=- disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-230-review-4870883842",
      "id": "RAV-RUN1-R1-F002",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "The check proves a registry alias mismatch from one record. It cannot prove that the collection currently uses two directory spellings.",
      "source_fact_lock": [
        "The check proves a registry alias mismatch from one record. It cannot prove that the collection currently uses two directory spellings."
      ],
      "source_requested_work": [
        "The warning can name the observed alias relation. Directory splitting can stay a conditional result when both spellings are published."
      ],
      "rendered_body": "| Low | \u2014 | The check proves a registry alias mismatch from one record, but it cannot prove that the collection currently uses two directory spellings. | Consider naming the observed alias and mentioning split directories only when both spellings are published. <!-- review-anvil-report: id=RAV-RUN1-R1-F002 severity=low area=diagnostic-scope path=- start_line=- line=- disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-230-review-4870883842",
      "id": "RAV-RUN1-R1-F005",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "Malformed endpoint records can raise `AttributeError` or `KeyError` outside the tool's concise error path.",
      "source_fact_lock": [
        "Malformed endpoint records can raise `AttributeError` or `KeyError` outside the tool's concise error path."
      ],
      "source_requested_work": [
        "Small checks for consumed fields can report the endpoint and record index without adding a schema layer."
      ],
      "rendered_body": "| Low | \u2014 | Malformed endpoint records can escape the concise error path with `AttributeError` or `KeyError`. | Consider small checks limited to consumed fields that report the endpoint and record index without adding a schema layer. <!-- review-anvil-report: id=RAV-RUN1-R1-F005 severity=low area=refresh-errors path=- start_line=- line=- disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-230-review-4870883842",
      "id": "RAV-RUN1-R1-F006",
      "surface": "report",
      "request_mode": "suggested",
      "source_context": "A custom `--base-url` fetch still records the production URL in `_source`.",
      "source_fact_lock": [
        "A custom `--base-url` fetch still records the production URL in `_source`."
      ],
      "source_requested_work": [
        "`_source` can use the effective URL after removing user information, query parameters, and fragments."
      ],
      "rendered_body": "| Low | \u2014 | A custom `--base-url` still records the production URL in `_source`. | Consider using the effective URL after removing user information, query parameters, and fragments. <!-- review-anvil-report: id=RAV-RUN1-R1-F006 severity=low area=refresh-provenance path=- start_line=- line=- disposition=active --> |"
    },
    {
      "case_id": "every_eval_ever-pr-230-review-4870883842",
      "id": "RAV-RUN1-R1-F003",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "The new warning stays hidden in the default rich output until PR #221 is included. The current renderer returns after `PASS` for valid reports.\n\n**RAV-RUN1-R1-F003 [medium] warning-visibility** \u2014 The new warning stays hidden in the default rich output without PR #221\n\nWarning severity leaves the report valid. The current rich renderer prints `PASS` and returns before its warning loop.\n\nPR #221 is already listed as a prerequisite. After rebase, one default-rich CLI check for this warning would confirm the complete path.",
      "source_fact_lock": [
        "The new warning stays hidden in the default rich output until PR #221 is included. The current renderer returns after `PASS` for valid reports.",
        "Warning severity leaves the report valid. The current rich renderer prints `PASS` and returns before its warning loop."
      ],
      "source_requested_work": [
        "PR #221 can remain the merge prerequisite. After rebase, this warning needs one check through the default rich CLI path.",
        "PR #221 is already listed as a prerequisite. After rebase, one default-rich CLI check for this warning would confirm the complete path."
      ],
      "rendered_body": "Warnings do not make the report invalid, so the rich renderer returns after `PASS` before it prints them. The new warning is hidden until PR #221 is included.\n\nPR #221 can remain the merge prerequisite. After rebasing, add one default-rich CLI check for this warning to confirm the complete path.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F003 severity=medium area=warning-visibility -->"
    },
    {
      "case_id": "every_eval_ever-pr-230-review-4870883842",
      "id": "RAV-RUN1-R1-F004",
      "surface": "inline",
      "request_mode": "required",
      "source_context": "This adds a registered validator rule, but the required `datastore-gate.md` contributor guidance does not describe it.\n\n**RAV-RUN1-R1-F004 [medium] contributor-guidance** \u2014 The new registered warning is missing from the required datastore gate guide\n\nThe repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.\n\nA short section can state the alias trigger, warning-only result, and single-record evidence limit.",
      "source_fact_lock": [
        "This adds a registered validator rule, but the required `datastore-gate.md` contributor guidance does not describe it.",
        "The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide."
      ],
      "source_requested_work": [
        "`datastore-gate.md` can state the alias trigger, warning-only result, and single-record evidence limit.",
        "A short section can state the alias trigger, warning-only result, and single-record evidence limit."
      ],
      "rendered_body": "Repository instructions require validator guidance in `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md`. This PR adds the registered warning but leaves that guide unchanged.\n\nAdd a short section there covering the alias trigger, warning-only result, and single-record evidence limit.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F004 severity=medium area=contributor-guidance -->"
    }
  ]
}
```

Audit all rows now. Return raw valid JSON only.
