# Post-Render Action-Lock Audit

Run this audit after drafting all inline comment bodies and before writing the
inline JSON artifact. Its only purpose is to prevent a readability rewrite from
hiding author work, inventing work, or changing a requested boundary.

## Inputs

Before drafting, freeze the exact requested-work prose from each accepted
synthesized finding. Include its permissions, accepted current behavior,
exceptions, tests, documentation, purpose clauses, and safety clauses. Also
freeze the minimum source context needed to resolve pronouns, identifiers, and
whether a predicate describes current or target behavior.

Build one audit row per inline body:

```json
{
  "id": "RAV-RUN3-R1-F001",
  "source_context": "<exact title and diagnostic prose>",
  "source_requested_work": "<exact frozen source prose>",
  "rendered_requested_work": "<request and boundary prose from the draft>"
}
```

Use `source_context` only to resolve antecedents and current-versus-target
status. Do not derive new work from it. Do not include unrelated evidence or
report sections. Return every input ID exactly once.

## Independent auditor prompt

Dispatch two clean read-only verifier subagents in one parallel wave. Neither
auditor may have rendered the comments. Use different model families when the
runtime permits it. Give them only these rules and the audit rows. The auditors
must not inspect or edit the repository.

Compare source meaning with rendered obligation status. Do not classify by modal grammar.

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
7. Preserve the action target, condition, scope, quantifier, order, modality,
   exact test boundary, and exact path or identifier.

Before returning a verdict, build an internal predicate ledger for each item.
Quote every source predicate, classify it, and point to its exact rendered
phrase and obligation status. Split every mixed sentence before checking it.
Return `pass` only when every ledger row is mapped correctly. Do not include
the ledger in the output.

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
      "repair_instructions": []
    }
  ],
  "pass_count": 0,
  "fail_count": 0
}
```

Use `pass` only when all three issue arrays are empty. Name the exact source
predicate and rendered phrase in every failure. Never rewrite a comment.

Validate each auditor independently before using its verdicts. It must return
exactly one item for every input ID, no unknown or duplicate IDs, valid status
and issue-array fields, and counts that match the items. A row passes only when
both auditors return a valid `pass`. For valid failures, take the union of
their issues and repair instructions. For every missing, duplicate, malformed,
timed-out, or otherwise unverifiable row, restore the exact source
requested-work prose without attempting a repair and force COMMENT.

## Repair and fail-safe

The renderer repairs only comments with a valid failed verdict. Apply each audit instruction without
changing the title, diagnosis, evidence, severity, complete ID, or already
passing requested-work predicates.

After the semantic repair, reapply the inline-comment form: use one concise
`Please` sentence for exactly one author obligation, or `**Requested actions**`
with one bullet per obligation for two or more. Never use a one-item action
list. Audit the repaired rows once more with two new clean auditors under the
same validation and union rules.

If either second-audit verdict fails or is unverifiable, restore the exact
source requested-work prose for that comment and force the review event to
COMMENT. Do not paraphrase the failed request section. A denser fact-safe
request is better than a readable comment that changes what the author must do.
