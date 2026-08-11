You are the original clean renderer performing the one permitted repair wave for review-anvil commit b3f2ad2c4c5e872a6e059d8e64c056ad615ab2ca. Repair only the failed bodies below. Apply the union of both auditors' valid failures. Preserve all source-backed title, diagnosis, evidence, severity, ID, requested work, and no-change boundaries. Remove source-free predicates. Do not inspect a repository.

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

INLINE FORM RULES:
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
requested change.
You may remove filler and exact repetition.
Do not replace technical verbs, quantifiers, or scope words.
Preserve modals that express diagnostic certainty.
Treat remediation as a requested change, not as observed code.
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
4. Split every sentence that mixes author work with a no-change boundary.
   Classify each predicate separately; do not preserve an unsplit fallback.

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
`**Requested actions**` and with the action it limits. State it as short modal
prose immediately after that action when combining them would make the request
dense. Preserve accepted current behavior as standalone modal prose. Preserve
a standalone optional follow-up as standalone modal prose after the required
request, or after the consequence when no request exists.

For example: `Files containing only intentionally skipped derived rows can remain explicit exclusions; no change is requested for them.`

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

Write the body in this order:

1. **Problem:** Name the code behavior and trigger.
2. **Impact:** State the concrete bad result.
3. **Requested change:** State the exact action or decision. Include a test only
   when the source requests it; do not invent what the test proves.

Each sentence explains one relationship between code concepts. Name the
function, field, command, or request that acts. Tie each necessary identifier
to its role in the failure. Use a pronoun only when its antecedent is the
immediately preceding subject and cannot be confused with another identifier.
Use one minimal example only when it makes a path, count, or state change easier
to see. Do not show the Problem, Impact, or Requested change labels in the final
comment.

Before emitting the body, run this author check:

- The title and first sentence answer: what breaks, and when?
- Replace an abstract label with the code actor and a direct verb.
- The title names the actor that produces the concrete bad result.
- Do not attribute an aggregate run's result to one file or record inside it.
- Rewrite the title only when every fact-lock item in it still matches.
- Preserve title qualifiers and ownership, including diagnostic modals and scope words.
- If the title changes the actor, action, target, condition, scope, or certainty,
  restore the synthesized finding sentence verbatim.
- When a path, count, or state change is hard to picture, give one minimal example instead of making the reader simulate it.
- Remove a test sentence only when the source does not request it. Keep every source-backed required verification with its exact boundary.
- Remove any sentence that repeats the title without adding a trigger, result,
  constraint, or fix boundary.

For an explicitly reintroduced author-resolved finding, put `<!-- review-anvil: prior_feedback=reintroduced -->` immediately after the visible final-report finding row or bullet. Its matching inline item carries helper-only `"prior_feedback": "reintroduced"`; the posting helper strips that JSON field before the GitHub REST request while preserving the hidden marker in the posted inline body for later PR-history handling.
Use short everyday words. Prefer one clear sentence over a dense explanation.

```
**RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace

The changed handler reads missing fields and fails before conversion.

**Requested actions**

- Use the shared top-level parser in the module entry point.
- Add one offline entry-point test.
```

When one code change has a no-change constraint, keep the constraint in prose:

```
**RAV-RUN3-R1-F002 [medium] input-validation** — Invalid populated cells become absent values

The fallback also accepts invalid or zero denominators.

Please use separate rules for uncertainty, counts, and positive denominators to keep bad rows in the failure report.
Empty optional cells can remain allowed.
```

Modal wording does not make requested verification optional:

```md
**Requested actions**

- Reject every publisher base that is an immediate child of canonical `data`.
- Add mismatched source and `collection_override` tests for this path.
```

Return valid JSON only as {"comments":[{"id":"<exact canonical ID>","body":"<complete repaired body>"}]}. Return each input ID once in input order. No Markdown fences or explanations.

FAILED ROWS:
[
  {
    "id": "AUDIT:3737044371",
    "source_context": "**RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.",
    "source_requested_work": "An atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger.",
    "current_rendered_body": "**RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report.\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.\n\nPlease replace the report atomically after successful publication, including failures, exclusions, and fully clean runs.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3737044371",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [],
        "fact_losses": [
          "Source predicate \"without losing the last complete ledger\" — the required safety clause constraining the atomic report replacement — has no counterpart in `rendered_body`. The rendered request \"Please replace the report atomically after successful publication, including failures, exclusions, and fully clean runs.\" carries the action, the ordering condition (\"after successful publication\"), and the record scope (\"failures, exclusions, and fully clean runs\"), but drops the no-loss result the source attaches to that same action."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Reattach the source safety clause \"without losing the last complete ledger\" to the existing atomic report replacement request, leaving the action, the \"after successful publication\" ordering, and the \"failures, exclusions, and fully clean runs\" scope unchanged."
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3737044371",
        "status": "fail",
        "missing_author_work": [
          "The required source safety predicate “without losing the last complete ledger” has no direct rendered request. Its nearest counterpart, “Please replace the report atomically after successful publication,” requests atomic replacement but does not explicitly require preservation of the last complete ledger."
        ],
        "false_actions": [],
        "fact_losses": [
          "The source predicate “without losing the last complete ledger” is omitted. The rendered counterpart “Please replace the report atomically after successful publication, including failures, exclusions, and fully clean runs” preserves the mechanism, timing, and report contents but not the explicit safety result."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Attach the source requirement to preserve the last complete ledger to the direct atomic-replacement request."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3737266661",
    "source_context": "**RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.",
    "source_requested_work": "The shared report already supports exclusions. It can be saved for either collection while the nonzero exit stays conditional on failures.",
    "current_rendered_body": "**RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty.\n\nAn exclusions-only run succeeds but loses each excluded source reference and reason.\n\nPlease save the shared report for either collection. The nonzero exit can stay conditional on failures.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3737266661",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [],
        "fact_losses": [
          "Source predicate \"The shared report already supports exclusions.\" has no counterpart anywhere in `rendered_body`. It is accepted current behavior (a no-change boundary) establishing that exclusion support in the shared report needs no new work; the rendered text only states \"Please save the shared report for either collection.\", which requests the save but drops the existing-support fact."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Restore the omitted no-change boundary \"The shared report already supports exclusions.\" as a non-action statement alongside the existing request to save the shared report for either collection, and keep \"The nonzero exit can stay conditional on failures.\" as a permitted boundary rather than an action."
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3737266661",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [],
        "fact_losses": [
          "The source no-change predicate \"The shared report already supports exclusions\" has no rendered counterpart. \"Please save the shared report for either collection\" preserves the required save action but does not preserve the accepted current capability."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Restore the omitted source predicate \"The shared report already supports exclusions\" as a non-action statement while retaining the existing save request and the no-change boundary that nonzero exit remains conditional on failures."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3737383919",
    "source_context": "**RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.",
    "source_requested_work": "Requiring one or more values would block the first path. A no-match check can stop before existing-output discovery or publication.",
    "current_rendered_body": "**RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run.\n\nA nonempty filter with no matches instead exits successfully with zero logs.\n\n**Requested actions**\n\n- Require one or more values for `--models`.\n- Stop a no-match run before existing-output discovery or publication.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3737383919",
        "status": "fail",
        "missing_author_work": [
          "Source `A no-match check can stop before existing-output discovery or publication.` requests adding a no-match check (author work). The rendered body has no direct request to add the check; the only related bullet, `Stop a no-match run before existing-output discovery or publication.`, requests the permitted stopping point instead of the check."
        ],
        "false_actions": [
          "Rendered bullet `Stop a no-match run before existing-output discovery or publication.` is an action derived only from the source's allowed boundary `can stop before existing-output discovery or publication`, which permits where the check may stop rather than requiring a stop."
        ],
        "fact_losses": [
          "Source predicate `can stop before existing-output discovery or publication` is a permission (modality: may). The draft renders it as a mandate in the bullet `Stop a no-match run before existing-output discovery or publication.`, changing its modality from permitted boundary to required action."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Render the source's author work as the direct request: the no-match check itself must be requested, matching source predicate `A no-match check`.",
          "Do not render `can stop before existing-output discovery or publication` as an action; keep it as the permitted stopping point it is in the source, or omit it from the action list.",
          "Leave the matched bullet `Require one or more values for `--models`.` unchanged; it correctly maps to source predicate `Requiring one or more values would block the first path.`"
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3737383919",
        "status": "fail",
        "missing_author_work": [
          "Source author-work predicate “A no-match check” has no exact direct-request counterpart. Rendered “Stop a no-match run before existing-output discovery or publication” requests a stopping point instead of directly requesting the no-match check."
        ],
        "false_actions": [
          "Rendered action “Stop a no-match run before existing-output discovery or publication” turns the source no-change boundary “can stop before existing-output discovery or publication” into required author work."
        ],
        "fact_losses": [
          "Source author-work result “Requiring one or more values would block the first path” is reduced to rendered “Require one or more values for `--models`”; the required result of blocking the bare-`--models` full-source-run path is not attached to the action.",
          "Source boundary “can stop before existing-output discovery or publication” permits that stopping point, while rendered “Stop a no-match run before existing-output discovery or publication” changes the permission into an obligation."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Directly request the no-match check and preserve its target behavior.",
          "Keep “before existing-output discovery or publication” as an allowed implementation boundary, not an action.",
          "Attach the result of blocking the bare-`--models` full-source-run path to the one-or-more-values action."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3737449070",
    "source_context": "**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.",
    "source_requested_work": "Source metric specs or an operator-supplied definition can establish the semantics. Unresolved keys can be reported after the valid metrics are preserved.",
    "current_rendered_body": "**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds.\n\nA finite custom key does not prove that direction.\n\n**Requested actions**\n\n- Use source metric specs or an operator-supplied definition to establish the semantics.\n- Report unresolved keys after preserving the valid metrics.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3737449070",
        "status": "fail",
        "missing_author_work": [
          "Source predicate 'Unresolved keys can be reported after the valid metrics are preserved' carries the required preservation of the valid metrics. The rendered body never requests that preservation directly; it survives only as the subordinate clause 'after preserving the valid metrics' inside the reporting bullet."
        ],
        "false_actions": [
          "Rendered bullet 'Report unresolved keys after preserving the valid metrics.' turns the allowed reporting follow-up of 'Unresolved keys can be reported after the valid metrics are preserved' into requested author work."
        ],
        "fact_losses": [],
        "invented_predicates": [],
        "repair_instructions": [
          "Make the preservation of the valid metrics its own direct request derived from 'Unresolved keys can be reported after the valid metrics are preserved', and drop the requested-action framing of unresolved-key reporting, leaving that follow-up as a permitted option rather than a bullet."
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3737449070",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [
          "The rendered direct request `Report unresolved keys after preserving the valid metrics.` has no source-backed author-work counterpart for reporting. Its source counterpart, `Unresolved keys can be reported after the valid metrics are preserved.`, makes reporting an optional follow-up; only preservation of valid metrics is required author work."
        ],
        "fact_losses": [
          "The source predicate `Unresolved keys can be reported after the valid metrics are preserved.` permits reporting only as an optional follow-up, but the rendered counterpart `Report unresolved keys after preserving the valid metrics.` changes that optional predicate into mandatory author work."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Remove unresolved-key reporting from the requested actions while retaining preservation of valid metrics as an explicit direct request."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3737449081",
    "source_context": "**RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.",
    "source_requested_work": "The same metric-definition mapping used for direction and bounds can supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.",
    "current_rendered_body": "**RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy.\n\n`metric_name` keeps the source label but does not provide the cross-source join key.\n\nPlease use the same metric-definition mapping for direction and bounds, canonical global IDs, and stable namespaced IDs for defined lighteval-specific metrics.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3737449081",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [
          "Rendered predicate 'use the same metric-definition mapping for direction and bounds' requests direction-and-bounds work. The source clause 'The same metric-definition mapping used for direction and bounds' only identifies which existing mapping to reuse; the source requests only that it 'supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics'."
        ],
        "fact_losses": [
          "The source predicate 'The same metric-definition mapping used for direction and bounds can supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics' is changed: 'used for direction and bounds' is an identifying description of the mapping, and the rendered body converts it into a third requested use coordinated with 'canonical global IDs' and 'stable namespaced IDs', losing the supply relation between the mapping and the IDs."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Restore 'used for direction and bounds' as an identifier of the existing metric-definition mapping rather than a requested outcome, and keep the request limited to that mapping supplying canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics."
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3737449081",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [
          "The rendered request `Please use the same metric-definition mapping for direction and bounds` turns the mapping's existing direction-and-bounds role into author work. The source counterpart, `The same metric-definition mapping used for direction and bounds`, identifies the existing mapping; the source requests only that it supply canonical global IDs and stable namespaced IDs."
        ],
        "fact_losses": [
          "The source predicate `the same metric-definition mapping used for direction and bounds` is an identifying no-change predicate, but the rendered counterpart `use the same metric-definition mapping for direction and bounds` changes its obligation status into a direct action."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Keep the mapping's direction-and-bounds role outside the action scope and request only that the identified mapping supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3737449098",
    "source_context": "**RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved; directory input reports the same failure class correctly.",
    "source_requested_work": "A small lighteval-local file-result path can give both entry modes the same report-before-raise behavior.",
    "current_rendered_body": "**RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`.\n\nParse or conversion errors exit non-zero, but the structured failure report is never saved. Directory input reports the same failure class correctly.\n\nPlease add a lighteval-local file-result path so both entry modes report before raising.",
    "auditor_failures": [
      {
        "auditor": "sol",
        "id": "AUDIT:3737449098",
        "status": "fail",
        "missing_author_work": [
          "The source author-work predicate `A small lighteval-local file-result path` requires a small implementation path. Its rendered counterpart, `Please add a lighteval-local file-result path`, omits that size boundary from the direct request."
        ],
        "false_actions": [],
        "fact_losses": [
          "The rendered counterpart `a lighteval-local file-result path` drops the source qualifier `small` from `A small lighteval-local file-result path`, changing the requested implementation boundary."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Restore the source's `small` implementation boundary in the direct request for the lighteval-local file-result path."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3737449101",
    "source_context": "**RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.",
    "source_requested_work": "One recursive sanitizer for mappings and lists can protect these values before serialization. Tests with provider-prefixed key names would cover the reachable path without recording secret values.",
    "current_rendered_body": "**RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized.\n\nSupported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.\n\n**Requested actions**\n\n- Apply one recursive sanitizer to mappings and lists before serialization.\n- Add tests with provider-prefixed key names without recording secret values.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3737449101",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [],
        "fact_losses": [
          "Source predicate 'Tests with provider-prefixed key names would cover the reachable path without recording secret values' loses its required test boundary. Rendered bullet 'Add tests with provider-prefixed key names without recording secret values.' keeps the key-name scope and the no-secret-values constraint but omits 'cover the reachable path', so the tests are no longer tied to the nested path that reaches published `additional_details`."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Reattach the required result 'cover the reachable path' to the test request derived from 'Tests with provider-prefixed key names would cover the reachable path without recording secret values', keeping the 'without recording secret values' constraint on the same action."
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3737449101",
        "status": "fail",
        "missing_author_work": [
          "The source verification predicate `Tests with provider-prefixed key names would cover the reachable path` requires the tests to cover the reachable path. The rendered counterpart, `Add tests with provider-prefixed key names without recording secret values.`, requests the test data and safety boundary but does not directly require coverage of that path."
        ],
        "false_actions": [],
        "fact_losses": [
          "The rendered test request omits the source result predicate `cover the reachable path`; provider-prefixed key names and the prohibition on recording secret values remain, but the exact required coverage boundary is no longer stated."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Make coverage of the reachable nested-value serialization path an explicit part of the direct test request while retaining provider-prefixed key names and the prohibition on recording secret values."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3725747243",
    "source_context": "**RAV-RUN1-R1-F003 [high] record-identity** — `evaluation_id` changes every time the same record is converted\n\nThe current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.",
    "source_requested_work": "A stable source-run timestamp or deterministic token can keep the required ID shape while `retrieved_timestamp` records retrieval time.",
    "current_rendered_body": "**RAV-RUN1-R1-F003 [high] record-identity** — `evaluation_id` changes every time the same record is converted.\n\nThe current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.\n\nPlease use a stable source-run timestamp or deterministic token to keep the required ID shape, while `retrieved_timestamp` records retrieval time.",
    "auditor_failures": [
      {
        "auditor": "sol",
        "id": "AUDIT:3725747243",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [],
        "fact_losses": [
          "The source no-change boundary, \"`retrieved_timestamp` records retrieval time,\" is changed by the rendered predicate, \"Please use a stable source-run timestamp or deterministic token to keep the required ID shape, while `retrieved_timestamp` records retrieval time,\" which folds that boundary into the direct request."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Keep the source author-work predicate, \"A stable source-run timestamp or deterministic token can keep the required ID shape,\" as the direct request. State the counterpart, \"`retrieved_timestamp` records retrieval time,\" separately as a no-change boundary."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3725747245",
    "source_context": "**RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt\n\n`LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.",
    "source_requested_work": "The sound aggregate conversion can remain intact if `llm_scoring` is emitted only when the real template is available.",
    "current_rendered_body": "**RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt.\n\n`LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.\n\nPlease emit `llm_scoring` only when the real template is available. The sound aggregate conversion can remain intact.",
    "auditor_failures": [
      {
        "auditor": "sol",
        "id": "AUDIT:3725747245",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [],
        "fact_losses": [
          "The source conditions the no-change boundary, \"The sound aggregate conversion can remain intact,\" on \"`llm_scoring` is emitted only when the real template is available.\" The rendered counterpart, \"The sound aggregate conversion can remain intact,\" omits that condition and therefore presents the boundary as unconditional."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Preserve the direct request, \"Please emit `llm_scoring` only when the real template is available,\" and explicitly retain that predicate as the condition governing the no-change boundary for the sound aggregate conversion."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3725853155",
    "source_context": "**RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.",
    "source_requested_work": "Numeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.",
    "current_rendered_body": "**RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling.\n\nThey can omit the headline metric or abort strict JSON publication.\n\nPlease validate numeric fields as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.",
    "auditor_failures": [
      {
        "auditor": "sol",
        "id": "AUDIT:3725853155",
        "status": "fail",
        "missing_author_work": [
          "Source predicate \"Invalid rows can enter `SourceConversionResult`.\" is author work, but its rendered counterpart \"Invalid rows can enter `SourceConversionResult`.\" remains modal prose rather than a direct request."
        ],
        "false_actions": [],
        "fact_losses": [],
        "invented_predicates": [],
        "repair_instructions": [
          "Make entry of invalid rows into `SourceConversionResult` a direct request while preserving the exact target and scope."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3725853159",
    "source_context": "**RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.",
    "source_requested_work": "New snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.",
    "current_rendered_body": "**RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content.\n\nOffline records cannot reconstruct the generation prompt.\n\nPlease store pinned prompt content in new snapshots. Legacy snapshots can leave this typed value unset and mark the missing content.",
    "auditor_failures": [
      {
        "auditor": "sol",
        "id": "AUDIT:3725853159",
        "status": "fail",
        "missing_author_work": [
          "Source predicate \"Legacy snapshots can leave this typed value unset\" is author work, but its rendered counterpart in \"Legacy snapshots can leave this typed value unset and mark the missing content.\" remains modal prose rather than a direct request.",
          "Source predicate \"Legacy snapshots can ... mark the missing content\" is author work, but its rendered counterpart in \"Legacy snapshots can leave this typed value unset and mark the missing content.\" remains modal prose rather than a direct request."
        ],
        "false_actions": [],
        "fact_losses": [],
        "invented_predicates": [],
        "repair_instructions": [
          "Make leaving the typed value unset for legacy snapshots a direct request.",
          "Make marking the missing prompt content for legacy snapshots a direct request."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3725853168",
    "source_context": "**RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.",
    "source_requested_work": "Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.",
    "current_rendered_body": "**RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nPlease make exact canonical IDs win first. Normalized spellings can resolve only when one organization owns them.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3725853168",
        "status": "fail",
        "missing_author_work": [
          "Source predicate \"Normalized spellings can resolve only when one organization owns them.\" is target behavior, not a no-change boundary: the diagnosis states \"Normalized organization collisions can rewrite an exact canonical ID to another canonical organization,\" so normalized spellings currently resolve even when more than one organization owns them. The rendered_body leaves this predicate only as modal prose (\"Normalized spellings can resolve only when one organization owns them.\") alongside the direct request \"Please make exact canonical IDs win first.\", so the required restriction on normalized resolution never appears as a direct request to the author."
        ],
        "false_actions": [],
        "fact_losses": [],
        "invented_predicates": [],
        "repair_instructions": [
          "Render the source predicate \"Normalized spellings can resolve only when one organization owns them.\" as a direct request to the author, alongside the existing direct request derived from \"Exact canonical IDs can win first.\", preserving the exact scope (normalized spellings), the ordering relative to exact canonical ID matching, and the \"only when one organization owns them\" condition without strengthening or weakening it."
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3725853168",
        "status": "fail",
        "missing_author_work": [
          "Source predicate \"Normalized spellings can resolve only when one organization owns them.\" is author work and a required safety condition, but its identical rendered counterpart remains modal prose rather than a direct request."
        ],
        "false_actions": [],
        "fact_losses": [],
        "invented_predicates": [],
        "repair_instructions": [
          "Make the single-owning-organization restriction on normalized spelling resolution a direct request, preserving the exact condition."
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3725913004",
    "source_context": "**RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.",
    "source_requested_work": "Complete output can stage before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.",
    "current_rendered_body": "**RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path.\n\nConstruction fails after aggregate and sidecar files are written.\n\nPlease stage complete output before publication. Reject existing logical output until replacement is atomic, while sidecar validation stays streaming.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3725913004",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [
          "Rendered direct request \"Reject existing logical output until replacement is atomic, while sidecar validation stays streaming.\" is author work, but its only source counterpart is the no-change boundary \"Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.\" That source predicate preserves two allowed boundaries (permitted rejection of existing logical output until replacement is atomic, and sidecar validation kept streaming); neither may be rendered as a requested action."
        ],
        "fact_losses": [],
        "invented_predicates": [],
        "repair_instructions": [
          "Keep the direct request derived from the author-work predicate \"Complete output can stage before publication\" (rendered as \"Please stage complete output before publication.\").",
          "Remove the imperative form of the boundary predicate and restore it as an allowance, preserving both clauses exactly: existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming."
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3725913004",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [],
        "fact_losses": [
          "Source no-change boundary “Existing logical output can be rejected until replacement is atomic” is changed by rendered direct request “Reject existing logical output until replacement is atomic” into author work.",
          "Source no-change boundary “with sidecar validation kept streaming” is changed by rendered requested condition “while sidecar validation stays streaming” into author work."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Keep “Please stage complete output before publication” as the direct request, but restore the exact no-change boundary: “Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.”"
        ]
      }
    ]
  },
  {
    "id": "AUDIT:3726043665",
    "source_context": "**RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.",
    "source_requested_work": "New or empty targets can use the batch publisher. Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.",
    "current_rendered_body": "**RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication.\n\nEmpty batches and later write failures can destroy prior or unrelated data.\n\n**Requested actions**\n\n- Use the batch publisher for new or empty targets.\n- Fail by default for symlinks, roots, and populated targets until replacement has an explicit ownership manifest.",
    "auditor_failures": [
      {
        "auditor": "claude",
        "id": "AUDIT:3726043665",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [],
        "fact_losses": [
          "Source no-change boundary \"Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.\" is changed in modality: the draft renders it as the direct request \"- Fail by default for symlinks, roots, and populated targets until replacement has an explicit ownership manifest.\" The source permits failing these targets until replacement carries an explicit ownership manifest; it does not request that failure as author work. The only author-work predicate here is \"New or empty targets can use the batch publisher\", correctly rendered as \"- Use the batch publisher for new or empty targets.\""
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Remove the action bullet \"Fail by default for symlinks, roots, and populated targets until replacement has an explicit ownership manifest.\" from the requested-actions list and state it as the permitted boundary it is in the source, preserving the condition \"until replacement has an explicit ownership manifest\" exactly.",
          "Keep \"Use the batch publisher for new or empty targets.\" as the only direct request."
        ]
      },
      {
        "auditor": "sol",
        "id": "AUDIT:3726043665",
        "status": "fail",
        "missing_author_work": [],
        "false_actions": [
          "Rendered direct request \"Fail by default for symlinks, roots, and populated targets until replacement has an explicit ownership manifest\" incorrectly turns the source no-change boundary \"Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest\" into author work."
        ],
        "fact_losses": [
          "The source predicate \"Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest\" is an allowed implementation boundary, but its rendered counterpart \"Fail by default for symlinks, roots, and populated targets until replacement has an explicit ownership manifest\" changes its obligation status to required author work."
        ],
        "invented_predicates": [],
        "repair_instructions": [
          "Remove the direct request derived from the symlink, root, and populated-target no-change boundary. Preserve that predicate only as an allowed boundary; keep \"Use the batch publisher for new or empty targets\" as the requested author work."
        ]
      }
    ]
  }
]
