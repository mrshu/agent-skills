# Post-Render Action-Lock Audit

Run this audit after drafting all inline comment bodies and before writing the
inline JSON artifact. Its only purpose is to prevent a readability rewrite from
hiding author work, inventing work, or changing a requested boundary.

## Inputs

Before drafting, freeze the exact requested-work prose from each accepted
synthesized finding. Include its permissions, accepted current behavior,
exceptions, tests, documentation, purpose clauses, and safety clauses. Also
freeze the exact source title and diagnosis plus the
exact evidence and code fragments that the body may retain. Include source
suggestions. Do not give the auditors unrelated repository or report context.

Build one audit row per inline body. Convert each finding ID to a canonical
opaque string before dispatch.
If an original ID contains only digits, prefix it with `AUDIT:`.

```json
{
  "id": "RAV-RUN3-R1-F001",
  "source_context": "<exact source material used by the rendered body>",
  "source_requested_work": "<exact frozen source prose>",
  "rendered_body": "<exact complete inline body>"
}
```

Do not extract or summarize a request-only subset.
The auditors need the whole rendered body.

Use `source_context` only to resolve antecedents and current-versus-target
status, and to confirm source support for rendered evidence or code.
Do not derive new work from it. Return every input ID exactly once.
Each ID is the canonical string.

## Independent auditor prompt

Dispatch two clean read-only verifier subagents in one parallel wave. Neither
auditor may have rendered the comments. Use different model families when the
runtime permits it. Give them only these rules and the audit rows. The auditors
must not inspect or edit the repository.

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

## Repair and fail-safe

The renderer repairs only comments with a valid failed verdict.
Apply each audit instruction without changing source-backed title, diagnosis,
evidence, severity, complete ID, or already passing requested-work predicates.
Remove any source-free predicate named by `false_actions` or
`invented_predicates`.

After the semantic repair, reapply the inline-comment form: use one concise
`Please` sentence for exactly one author obligation, or `**Requested actions**`
with one bullet per obligation for two or more. Never use a one-item action
list. Audit the repaired rows once more with two new clean auditors under the
same validation and union rules.

If either second-audit verdict fails or is unverifiable, restore the exact
source requested-work prose for that comment and force the review event to
COMMENT. Do not paraphrase the failed request section or add new prose. A
denser source-verbatim request is better than a readable comment that changes
what the author must do.

The byte-identity rule applies to passed rewrites. Their `.inline.json` body
must be byte-identical to the audited `rendered_body`; any later edit requires
a new two-auditor wave. An exact-source fallback is exempt because it replaces
the failed request with frozen source prose and forces COMMENT.
