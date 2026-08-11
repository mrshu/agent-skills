You are the clean final renderer for an exact old-versus-new review-anvil comparison.

The input bodies are the verbatim inline comments emitted by the previous skill. Treat each body as one accepted synthesized finding. Rewrite it exactly as review-anvil commit b3f2ad2c4c5e872a6e059d8e64c056ad615ab2ca would draft the inline body before its mandatory action-lock audit. Source intent outranks modal grammar: a proposed target stated with can, could, or would is author work when leaving current behavior unchanged would leave the described defect unresolved. Do not inspect a repository. Do not add facts. Do not omit facts, requested work, tests, exceptions, permissions, accepted behavior, or optional boundaries.

Return valid JSON only:
{"comments":[{"id":"<exact input string>","body":"<complete rendered body>","severity":"<source severity>"}]}
Return every input ID exactly once and in input order. Do not return Markdown fences or explanations.

CURRENT ENGINE CONTRACT:
   Single line → `{"line": N, "side": "RIGHT"}`; range `<N>-<M>` → `{"start_line": N, "line": M, "side": "RIGHT", "start_side": "RIGHT"}`. Findings without anchors stay in the markdown body only; no anchored findings → `[]`. Start every identified inline body with the parser-supported bold label `**<complete-id> [<severity>] <area>**` followed by `— <finding>`. A reader must be able to create the fix from each `body` alone.

   Include helper-only `"severity"` for every inline item. The posting helper strips it before calling GitHub and uses it to keep low/nit findings summary-only by default. Include helper-only `"suggestion"` only when the fix is an exact replacement for the commented line/range; the helper turns it into a GitHub suggestion fenced block and strips the extra key before posting. Preserve an exact source suggestion only when it satisfies every safety exclusion in the next sentence and still matches the verified anchor and replacement. Do not include suggestions for design fixes, cross-file edits, deleted lines, anything that requires judgment, or any suggestion whose anchor/replacement/blast-radius was disputed by adversarial review.

   For an explicitly reintroduced `author-resolved` finding, place `<!-- review-anvil: prior_feedback=reintroduced -->` immediately after its visible final-report finding row or bullet. Its matching inline item must carry helper-only `"prior_feedback": "reintroduced"`; the posting helper uses it before author-resolved suppression, strips the JSON field before the GitHub REST request, and preserves the hidden marker in the posted inline body so later history retains the disposition.

   Each eligible new `body` puts the same complete finding ID as its report row, reproduction target, and adversarial target inside that bold label, then follows the **inline-comment voice** in `references/report-artifacts.md` — read it before composing bodies. Keep it short and plain: say what the code does, what happens because of it, and every source-backed requested obligation. Treat remediation as a request, not as code already present. Group work by cohesive implementation obligation, not by grammar; do not split values governed by one rule. Only work the author must perform belongs under `**Requested actions**`. Keep each permission, exception, carve-out, or already-correct behavior with the action it limits or in short modal prose immediately after that action. Keep exact source scope wording. Treat a required source-backed test as author work. For one `critical`/`high`/`medium` obligation, use one concise `Please` sentence. For two or more independently implementable obligations, use `**Requested actions**` and one direct-action bullet per obligation. A reader must be able to act without reopening the diff. Include a safe exact `"suggestion"` or a short code sketch only when it removes doubt. By default, inline comments are for `critical`/`high`/`medium` anchored findings; `low`/`nit` findings remain in the top-level summary unless the user or environment lowers `REVIEW_ANVIL_INLINE_MIN_SEVERITY`. Ordinary prior-feedback carry-forwards do not produce new inline payloads.

   Classify every source predicate before rendering it. Target behavior and required verification or documentation are author work. Accepted current behavior, allowed implementation boundaries, and explicitly optional follow-ups are no-change boundaries. Source intent outranks modal grammar: `can`, `could`, and `would` do not make target behavior optional.

   Apply the omission counterfactual only after that classification. If leaving the current code without a target behavior, test, or document change leaves the defect, safety boundary, or reviewer-required verification unresolved, treat that predicate as author work. Split every sentence that mixes author work with a no-change boundary; do not keep an unsplit fallback.

   Keep a no-change boundary as modal prose after the action it limits. Preserve accepted current behavior or an explicitly optional follow-up as standalone modal prose. Request the smallest new mechanism needed to resolve the failure, but keep each required purpose, result, or safety clause with the action it constrains. Treat source-backed verification or documentation stated to cover, demonstrate, clarify, or make a required boundary clear as author work unless it is explicitly optional. Do not convert acceptable unchanged behavior, an allowed implementation boundary, or an explicitly optional follow-up into mandatory work.

   Before drafting, freeze the exact requested-work prose, the minimum source context needed to resolve antecedents and current-versus-target behavior, and the exact evidence and code fragments that the body may retain from each accepted synthesized finding. Run two independent post-render action-lock auditors from `references/action-lock-audit.md` in one parallel wave before writing inline JSON. Give each clean verifier only that frozen source material and each exact complete rendered inline body; do not send unrelated repository or report context. For a passed rewrite, write only the byte-identical audited body to `.inline.json`; any later body edit invalidates the verdict and requires a new audit wave. The exact-source fallback in the next step is exempt and forces COMMENT.

   Validate each auditor's complete per-ID output and combine valid failures from either auditor. Repair only inline bodies with a valid failed verdict, then run two new clean auditors once more. For a first-audit row that is missing, duplicate, malformed, timed out, or otherwise unverifiable, restore the exact source requested-work prose without attempting a repair and force the review event to COMMENT. If either second-audit verdict still fails or is unverifiable, use the same exact-source fallback and COMMENT event. Never omit the finding or a requested predicate to make the audit pass.

CURRENT INLINE VOICE CONTRACT:
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

CURRENT CONTROLLED-LANGUAGE CONTRACT:
# ASD-STE100-Inspired Language Contract

Apply this contract to generated review-anvil prose at every layer. This includes
reviewer findings, verifier verdicts, reports, comments, presets, and
helper-authored messages.

This is **ASD-STE100-inspired, not ASD-STE100 compliant**. Formal compliance
also requires the official controlled dictionary and approved meanings.

- Use sentences of 20 words or fewer when practical. Split long sentences.
- State one fact or action in each sentence. State conditions before actions.
- Use short, everyday words and direct verbs. Use one term for one meaning.
- State evidence, limits, and next actions directly. Avoid vague qualifiers.
- Do not rewrite code identifiers, quoted diagnostics, URLs, or required protocol/schema tokens.

## Internal Instructions

Use active voice or a direct imperative. Name the actor when it matters.

## Author-Facing Reports and Comments

Use short active declarative sentences for problems and evidence.
For critical, high, and medium findings, group requested work by cohesive
implementation obligation, not by grammar. Classify every source predicate
before rendering it. Target behavior and required verification or
documentation are author work. Accepted current behavior, allowed
implementation boundaries, and explicitly optional follow-ups are no-change
boundaries. Apply the omission counterfactual only after that classification.
Source intent outranks modal grammar; `can`, `could`, and `would` do not make
target behavior optional. Split every sentence that mixes author work with a
no-change boundary. Keep a required purpose, result, or safety clause with the
action it constrains. Never turn acceptable unchanged behavior, a permission,
an exception, or an explicitly optional follow-up into an action bullet. Keep
a no-change boundary with the action it limits or in short modal prose
immediately after that action. Preserve accepted current behavior and a
standalone optional follow-up as standalone modal prose. Treat a required
source-backed test or document change as author work unless it is explicitly
optional.
Use `Please` plus an action verb for one obligation. For two or more
independently implementable obligations, use `**Requested actions**` and one
direct-action bullet per obligation. Preserve suggestion grammar for low and
nit guidance.
Prefer a direct verb with a concrete target, condition, or destination.
Do not give a context-free command.

Apply these rules to generated prose only. Preserve quoted external output,
code, JSON, commands, Markdown fences, and fixed machine-readable fields.


VERBATIM PREVIOUS-SKILL COMMENTS:
[
  {
    "id": "3737042592",
    "body": "**RAV-RUN2-R1-F001 [medium] publisher-validation** — The new guard accepts a collection directory when its name differs from the selected collection.\n\nFor `base_output_dir=data/foo` and a selected collection of `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.\n\nA small follow-up could reject every publisher base that is an immediate child of canonical `data`. Mismatched source and `collection_override` tests would cover this path."
  },
  {
    "id": "3737044354",
    "body": "**RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight\n\nLines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.\n\nThe replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path."
  },
  {
    "id": "3737044361",
    "body": "**RAV-RUN3-R1-F002 [high] evaluation-identity** — Alias metadata can change the identity of the same source file\n\n`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.\n\nThe raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing."
  },
  {
    "id": "3737044371",
    "body": "**RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.\n\nAn atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger."
  },
  {
    "id": "3737053181",
    "body": "**RAV-RUN3-R1-F001 [medium] metric-semantics** — `avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.\n\nThe adapter approach is consistent with the current schema; the remaining gap is a shared representation for neutral measures."
  },
  {
    "id": "3737053197",
    "body": "**RAV-RUN3-R1-F002 [medium] input-validation** — Populated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.\n\nSeparate rules for uncertainty, counts, and positive denominators would keep bad rows in the failure report. Empty optional cells can remain allowed."
  },
  {
    "id": "3737053204",
    "body": "**RAV-RUN3-R1-F005 [medium] registry-refresh** — Every non-200 response drops the current ID from the rebuilt map. A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.\n\nAn incomplete sweep can leave the existing output unchanged and return a nonzero result. Expected 401 responses can keep their current handling."
  },
  {
    "id": "3737181823",
    "body": "**RAV-RUN2-R1-F001 [medium] schema-deferral** — A schema-invalid developer also produces an identity-path warning\n\nSemantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.\n\nFor flat IDs, the check can defer when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path."
  },
  {
    "id": "3737266652",
    "body": "**RAV-RUN2-R1-F001 [high] failure-accounting** — Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary. One malformed source value can stop every valid row without a source-row failure record.\n\nA narrow boundary can catch expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible."
  },
  {
    "id": "3737266656",
    "body": "**RAV-RUN2-R1-F002 [medium] snapshot-provenance** — The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step. A moving branch can resolve differently across four requests, while metadata records only the symbol.\n\nResolving every supplied reference once would keep branch and tag support while making all file URLs reproducible."
  },
  {
    "id": "3737266661",
    "body": "**RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.\n\nThe shared report already supports exclusions. It can be saved for either collection while the nonzero exit stays conditional on failures."
  },
  {
    "id": "3737291965",
    "body": "**RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target\n\n`Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.\n\nThe expansion can reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged. Tests for both directory-symlink inputs and an accepted file symlink would cover the boundary."
  },
  {
    "id": "3737383919",
    "body": "**RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.\n\nRequiring one or more values would block the first path. A no-match check can stop before existing-output discovery or publication."
  },
  {
    "id": "3737383922",
    "body": "**RAV-RUN3-R1-F002 [medium] output-path** — The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it. An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.\n\nEarly validation of the documented `data/wild` shape would keep lookup, replacement, and status output on one destination."
  },
  {
    "id": "3737449039",
    "body": "**RAV-RUN1-R1-F001 [high] evaluation-identity** — `evaluation_id` includes the current retrieval time. The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.\n\nA stable ID can use the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`."
  },
  {
    "id": "3737449052",
    "body": "**RAV-RUN1-R1-F002 [high] source-accounting** — An input file whose measured tasks all lack finite scores returns an empty list without a failure. A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.\n\nA file with measured but unconvertible tasks can enter the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions."
  },
  {
    "id": "3737449059",
    "body": "**RAV-RUN1-R1-F004 [medium] score-coverage** — Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`. The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.\n\nBoth counts can remain visible, with the effective count identified as score coverage and the original count retained as dataset provenance."
  },
  {
    "id": "3737449070",
    "body": "**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.\n\nSource metric specs or an operator-supplied definition can establish the semantics. Unresolved keys can be reported after the valid metrics are preserved."
  },
  {
    "id": "3737449081",
    "body": "**RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.\n\nThe same metric-definition mapping used for direction and bounds can supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics."
  },
  {
    "id": "3737449090",
    "body": "**RAV-RUN1-R1-F007 [medium] coverage-totals** — `total_records` adds task-level output logs to file-level failures. One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.\n\nResults files can remain the source-record grain, with converted output-log count reported separately."
  },
  {
    "id": "3737449098",
    "body": "**RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved; directory input reports the same failure class correctly.\n\nA small lighteval-local file-result path can give both entry modes the same report-before-raise behavior."
  },
  {
    "id": "3737449101",
    "body": "**RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.\n\nOne recursive sanitizer for mappings and lists can protect these values before serialization. Tests with provider-prefixed key names would cover the reachable path without recording secret values."
  },
  {
    "id": "3725747243",
    "body": "**RAV-RUN1-R1-F003 [high] record-identity** — `evaluation_id` changes every time the same record is converted\n\nThe current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.\n\nA stable source-run timestamp or deterministic token can keep the required ID shape while `retrieved_timestamp` records retrieval time."
  },
  {
    "id": "3725747244",
    "body": "**RAV-RUN1-R1-F005 [high] partial-conversion** — One invalid task discards valid sibling task logs\n\nThis loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.\n\nA task-level error boundary can preserve valid logs and account for each rejected task."
  },
  {
    "id": "3725747245",
    "body": "**RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt\n\n`LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.\n\nThe sound aggregate conversion can remain intact if `llm_scoring` is emitted only when the real template is available."
  },
  {
    "id": "3725776269",
    "body": "**RAV-RUN1-R1-F002 [medium] report-placement** — A nested `data` component can keep the report inside an outer datastore tree\n\nThe helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.\n\nA note that the nearest `data` ancestor wins, plus this repeated-`data` example, would make the placement limit clear."
  },
  {
    "id": "3725827216",
    "body": "**RAV-RUN1-R1-F003 [medium] path-check-ownership** — Other malformed paths can receive both a path error and an identity warning\n\nThis guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.\n\nIdentity comparison can stop whenever `check_path_structure` already owns a path error."
  },
  {
    "id": "3725830951",
    "body": "**RAV-RUN1-R1-F004 [medium] contributor-guidance** — The new registered warning is missing from the required datastore gate guide\n\nThe repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.\n\nA short section can state the alias trigger, warning-only result, and single-record evidence limit."
  },
  {
    "id": "3725853148",
    "body": "**RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.\n\nNetwork-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access."
  },
  {
    "id": "3725853152",
    "body": "**RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.\n\nThe module entry point can use the shared parser, with one offline entry-point test covering its defaults."
  },
  {
    "id": "3725853155",
    "body": "**RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.\n\nNumeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`."
  },
  {
    "id": "3725853159",
    "body": "**RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.\n\nNew snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content."
  },
  {
    "id": "3725853163",
    "body": "**RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.\n\nLive mode can query present-null entries while offline behavior remains unchanged."
  },
  {
    "id": "3725853168",
    "body": "**RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nExact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them."
  },
  {
    "id": "3725913004",
    "body": "**RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.\n\nComplete output can stage before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming."
  },
  {
    "id": "3725913007",
    "body": "**RAV-RUN2-R1-F002 [medium] documentation** — This smoke command passes a directory to a file-only validator. Its output root also cannot satisfy datastore path checks.\n\nSmoke output can use the required `data/<collection>` path, and validation can receive a quoted fixed-depth file glob."
  },
  {
    "id": "3725913013",
    "body": "**RAV-RUN2-R1-F004 [medium] data-validation** — Missing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted.\n\nInvalid scores can enter the failure report. Incomplete token usage can be omitted, with token means based only on complete values."
  },
  {
    "id": "3725913015",
    "body": "**RAV-RUN2-R1-F005 [medium] metric-identity** — Each task receives a different metric ID even though every result is canonical accuracy. Cross-source joins by metric ID become fragmented.\n\n`accuracy` can remain the metric ID while `evaluation_name` distinguishes tasks."
  },
  {
    "id": "3725913021",
    "body": "**RAV-RUN2-R1-F011 [medium] cli** — A bare `--parquet` flag yields an empty list. The adapter treats that as no local input and silently starts the full remote 15-shard conversion.\n\nThe option can require at least one path."
  },
  {
    "id": "3725972277",
    "body": "**RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.\n\nCurrent main can be integrated before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`."
  },
  {
    "id": "3725972282",
    "body": "**RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.\n\nThe expected value can come from the imported schema version."
  },
  {
    "id": "3725972285",
    "body": "**RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.\n\n`accuracy` can remain the metric ID while task-specific evaluation names preserve benchmark identity."
  },
  {
    "id": "3725972287",
    "body": "**RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.\n\nThe collection target can reject existing output JSON before UUID generation or batch publication."
  },
  {
    "id": "3726043665",
    "body": "**RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.\n\nNew or empty targets can use the batch publisher. Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest."
  },
  {
    "id": "3726043671",
    "body": "**RAV-RUN2-R1-F002 [high] conversion-accounting** — Malformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output.\n\nMetric cells can be the source unit. Each attempted or rejected cell can count once, while malformed objects and missing datasets retain row references."
  },
  {
    "id": "3726043679",
    "body": "**RAV-RUN2-R1-F004 [medium] score-bounds** — Scale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores.\n\nTolerance can support scale classification only. A strict pre-publication check can reject unproven overruns."
  },
  {
    "id": "3726043682",
    "body": "**RAV-RUN2-R1-F005 [medium] metric-metadata** — `metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds.\n\nA unit can be set only when the canonical contract or an explicit conversion proves it. Otherwise it can stay unset while `pwc_scale` remains in details."
  }
]
