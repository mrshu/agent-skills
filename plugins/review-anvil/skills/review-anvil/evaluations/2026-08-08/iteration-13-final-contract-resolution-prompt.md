You are a clean final contract verifier. Use only the supplied current text. Do not propose broad improvements. Verify whether the prior closure findings are resolved: (1) the whole-body rationale was truncated; (2) source-free evidence had no permitted repair; (3) bucket direction, source freeze, request-only-field retirement, numeric ID handling, fallback exemption, safe suggestion preservation, and assessment disclosure lacked complete coverage. Return JSON only: {"critical":[],"important":[],"minor":[],"resolved":true,"reason":"..."}. Set resolved false for any current actionable contradiction or omission and quote it exactly.

ACTION LOCK:
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


SKILL EXCERPT:
   Single line → `{"line": N, "side": "RIGHT"}`; range `<N>-<M>` → `{"start_line": N, "line": M, "side": "RIGHT", "start_side": "RIGHT"}`. Findings without anchors stay in the markdown body only; no anchored findings → `[]`. Start every identified inline body with the parser-supported bold label `**<complete-id> [<severity>] <area>**` followed by `— <finding>`. A reader must be able to create the fix from each `body` alone.

   Include helper-only `"severity"` for every inline item. The posting helper strips it before calling GitHub and uses it to keep low/nit findings summary-only by default. Include helper-only `"suggestion"` only when the fix is an exact replacement for the commented line/range; the helper turns it into a GitHub suggestion fenced block and strips the extra key before posting. Preserve an exact source suggestion only when it satisfies every safety exclusion in the next sentence and still matches the verified anchor and replacement. Do not include suggestions for design fixes, cross-file edits, deleted lines, anything that requires judgment, or any suggestion whose anchor/replacement/blast-radius was disputed by adversarial review.

   For an explicitly reintroduced `author-resolved` finding, place `<!-- review-anvil: prior_feedback=reintroduced -->` immediately after its visible final-report finding row or bullet. Its matching inline item must carry helper-only `"prior_feedback": "reintroduced"`; the posting helper uses it before author-resolved suppression, strips the JSON field before the GitHub REST request, and preserves the hidden marker in the posted inline body so later history retains the disposition.

   Each eligible new `body` puts the same complete finding ID as its report row, reproduction target, and adversarial target inside that bold label, then follows the **inline-comment voice** in `references/report-artifacts.md` — read it before composing bodies. Keep it short and plain: say what the code does, what happens because of it, and every source-backed requested obligation. Treat remediation as a request, not as code already present. Group work by cohesive implementation obligation, not by grammar; do not split values governed by one rule. Only work the author must perform belongs under `**Requested actions**`. Keep each permission, exception, carve-out, or already-correct behavior with the action it limits or in short modal prose immediately after that action. Keep exact source scope wording. Treat a required source-backed test as author work. For one `critical`/`high`/`medium` obligation, use one concise `Please` sentence. For two or more independently implementable obligations, use `**Requested actions**` and one direct-action bullet per obligation. A reader must be able to act without reopening the diff. Include a safe exact `"suggestion"` or a short code sketch only when it removes doubt. By default, inline comments are for `critical`/`high`/`medium` anchored findings; `low`/`nit` findings remain in the top-level summary unless the user or environment lowers `REVIEW_ANVIL_INLINE_MIN_SEVERITY`. Ordinary prior-feedback carry-forwards do not produce new inline payloads.

   Classify every source predicate before rendering it. Target behavior and required verification or documentation are author work. Accepted current behavior, allowed implementation boundaries, and explicitly optional follow-ups are no-change boundaries. Source intent outranks modal grammar: `can`, `could`, and `would` do not make target behavior optional.

   Apply the omission counterfactual only after that classification. If leaving the current code without a target behavior, test, or document change leaves the defect, safety boundary, or reviewer-required verification unresolved, treat that predicate as author work. Split every sentence that mixes author work with a no-change boundary; do not keep an unsplit fallback.

   Keep a no-change boundary as modal prose after the action it limits. Preserve accepted current behavior or an explicitly optional follow-up as standalone modal prose. Request the smallest new mechanism needed to resolve the failure, but keep each required purpose, result, or safety clause with the action it constrains. Treat source-backed verification or documentation stated to cover, demonstrate, clarify, or make a required boundary clear as author work unless it is explicitly optional. Do not convert acceptable unchanged behavior, an allowed implementation boundary, or an explicitly optional follow-up into mandatory work.

   Before drafting, freeze the exact requested-work prose, the minimum source context needed to resolve antecedents and current-versus-target behavior, and the exact evidence and code fragments that the body may retain from each accepted synthesized finding. Run two independent post-render action-lock auditors from `references/action-lock-audit.md` in one parallel wave before writing inline JSON. Give each clean verifier only that frozen source material and each exact complete rendered inline body; do not send unrelated repository or report context. For a passed rewrite, write only the byte-identical audited body to `.inline.json`; any later body edit invalidates the verdict and requires a new audit wave. The exact-source fallback in the next step is exempt and forces COMMENT.

   Validate each auditor's complete per-ID output and combine valid failures from either auditor. Repair only inline bodies with a valid failed verdict, then run two new clean auditors once more. For a first-audit row that is missing, duplicate, malformed, timed out, or otherwise unverifiable, restore the exact source requested-work prose without attempting a repair and force the review event to COMMENT. If either second-audit verdict still fails or is unverifiable, use the same exact-source fallback and COMMENT event. Never omit the finding or a requested predicate to make the audit pass.

3. Write a sibling `<report_path>.approval.json` so the PR-posting helper can choose the GitHub review event (review-only PR runs; for other runs write `{"event": "COMMENT"}` or omit the file — the helper defaults to COMMENT):

   ```json
   {
     "event": "APPROVE | COMMENT",
     "head_sha": "<the HEAD_SHA the preset captured at init/verify-checkout>",
     "adversarial_mode": "off | auto | challenge | targeted | full | strict",
     "approval_allowed": true,
     "reason": "No high/critical in-scope findings; medium-and-lower items are left to the author."
   }
   ```

   Include `"head_sha"` — the `HEAD_SHA` the preset captured at init/verify-checkout time — so the posting helper can verify the approval still matches the reviewed state (it downgrades to COMMENT if the PR head moved mid-run). Include `"adversarial_mode"` and set `"approval_allowed": false` when approval must be mechanically disabled, including explicit `adversarial: off` in a PR run or any run where an action-lock exact-source fallback has been used.

   Use `APPROVE` for review-only PR runs when all of these hold: `approve` is not `never`, at least one reviewer succeeded, no action-lock exact-source fallback has been used, there are no `critical`/`high` actionable in-scope findings, no `critical`/`high` in-scope deferred finding needs author action, no prior `critical`/`high` open or resolved-but-still-present item remains unaddressed, no unresolved `critical`/`high` adversarial dispute remains, and remaining items are only `medium`/`low`/`nit` findings, suggestions, deferred notes, or out-of-scope follow-ups. Medium-and-lower in-scope findings should still be posted clearly, but the review event is approval: leave those fixes to the author. Use `COMMENT` otherwise. Out-of-scope follow-ups do not block approval.
4. Print the report path as the last output line; the `.inline.json` and `.approval.json` files are implied by convention.
5. For out-of-scope follow-ups, write the sibling `<report_path>.followups.json` once, after the final round, using the follow-ups schema from §3 "Approving out-of-scope follow-ups" (NOT the `.approval.json` schema above). The posting helper deletes it after a successful post, so any consumer (surfacing follow-ups to the user, filing issues for `auto_approved` entries after duplicate search) must read it **before** the post/post-update step — the presets do this.

REPORT EXCERPT:
## ASD-STE100-Inspired Language

Apply `asd-ste100-inspired.md` to generated reports and comments. Use the
author-facing profile. Preserve evidence tokens verbatim.

## Inline-comment voice (bodies in `.inline.json`)

The voice rules below do not replace the mandatory two-auditor action-lock gate
in `action-lock-audit.md`; every rewritten draft body must pass that gate before
it enters `.inline.json`. The exact-source fallback is exempt and
forces COMMENT.

Write each inline comment in plain language about the code at that line. Use
comments for `critical`, `high`, and `medium` problems; put `low` and `nit`
items in the summary.

Start every identified inline finding with the parser-supported bold label
`**<complete-id> [<severity>] <area>**` followed by `— <finding>`.
The title states the failure, not only its technical category.
The report row, inline body, reproduction target, and adversarial target use the same complete finding ID unchanged.
ID reuse produces an inline body only when the finding is otherwise eligible
for a new inline; ordinary prior-feedback carry-forwards do not create a new inline thread.

Before rewriting, make a private fact lock from the final synthesized finding.
Record only:

- code identifiers, numbers, and quoted diagnostics;
- technical verbs and actor-action-target relationships;
- triggers and conditions;
- quantifiers, scope words, and certainty such as `all`, `only`, `can`, and
  `must`;
- the concrete bad result;
- valid behavior that the requested change must preserve.

Do not put the fact lock in the comment. Compare the draft with the fact lock.
Every relationship and boundary must still match.
Clarity does not permit a stronger, broader, or different claim.
If shorter wording changes a fact, restore the fact and simplify a different
part of the sentence.

Edit structure before vocabulary.
Keep an exact supporting phrase for every fact-lock item.
Privately map every fact-lock item to its exact supporting phrase in the draft.
Do not emit until every fact-lock item has a supporting phrase.
Preserve a verified exact source suggestion only when it satisfies every
safety exclusion in the engine `SKILL.md`; otherwise omit it.
Privately map every draft relationship and boundary back to one fact-lock item.
Delete any draft claim that has no source fact.
If deletion would break the meaning, restore the source sentence.
You may reorder clauses and split sentences to show problem, impact, and the

ASSESSMENT EXCERPT:
  valid holdout evidence.
- **Per-comment model oracle in production:** readable and safe in the artifact,
  but adds latency, model variance, and a selector that has not been validated
  independently.

## Independent contract review

Claude Opus found two load-bearing contract defects after the stress test:

1. an earlier edit had replaced the end of the low/nit inline-severity rule
   with a literal ellipsis; and
2. request-only audit extraction could hide an invented action elsewhere in a
   body.

It also found that fallback was absent from the approval criteria and audit ID
typing was underspecified. The first recheck found narrower modal-predicate and
ID-echo gaps. A second verification found that the predicate ledger was still
one-directional, fallback conflicted with byte identity, and labels or evidence
could be misclassified as source-free predicates. The closure check then found
a truncated whole-body sentence and no permitted repair for source-free
evidence; both are fixed.

The final contract uses bidirectional predicate ledgers, gives every
source-free predicate a direction-specific issue bucket, passes all exact
source material used by the body, excludes formatting metadata from semantic
predicates, requires verbatim canonical ID echo, validates rows independently,
scopes byte identity to passing rewrites, permits removal of source-free
predicates, and preserves only safe exact suggestions. Language-contract
assertions cover the bucket directions, source freeze, full-body sentence,
retired request-only field, ID handling, repair, and fallback invariants.

All Critical and Important findings and Minor B7-B13 from the review sequence
are resolved in the current contract. The remaining risk is empirical: the
hardened contract still needs the in-domain frozen run in Best option 2. The
review sequence is recorded in `iteration-13-final-contract-{review,recheck,verification,finalcheck}-claude.md`.

## Best options

1. **Keep the iteration-12 rendering direction plus this branch's hardening.**
   It has the strongest local evidence and closes the full-body audit,
