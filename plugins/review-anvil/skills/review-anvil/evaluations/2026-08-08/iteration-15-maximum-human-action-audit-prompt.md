You are an independent post-render fact-and-action auditor. Do not inspect a repository and do not rewrite comments. The source comment is the only authority. The rendered body may reorder or simplify it, but must preserve every source fact, condition, scope boundary, certainty, accepted behavior, optional boundary, and author-work predicate. It must not invent any fact or requested work. Source intent outranks modal grammar: source text using can/could/would still describes required author work when leaving the behavior unchanged would leave the stated defect unresolved. Ignore the final `<!-- review-anvil: id=... -->` line except to ensure it does not change meaning.

Return valid JSON only:
{"items":[{"id":"<exact input id>","status":"pass|fail","missing_author_work":[],"false_actions":[],"fact_losses":[],"invented_predicates":[],"reason":"<concise>"}]}
Return every ID exactly once. Use pass only when all four issue arrays are empty. Name exact source and rendered predicates in every failure. Do not penalize natural titles, `Please` requests, or Requested actions bullets when they preserve source intent.

INPUT:
[
  {
    "id": "3737042592",
    "source": "**RAV-RUN2-R1-F001 [medium] publisher-validation** \u2014 The new guard accepts a collection directory when its name differs from the selected collection.\n\nFor `base_output_dir=data/foo` and a selected collection of `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.\n\nA small follow-up could reject every publisher base that is an immediate child of canonical `data`. Mismatched source and `collection_override` tests would cover this path.",
    "rendered_body": "**The publisher guard accepts a collection directory with the wrong name**\n\nFor `base_output_dir=data/foo` and selected collection `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.\n\n**Requested actions**\n\n- Reject every publisher base that is an immediate child of canonical `data`.\n- Add mismatched source and `collection_override` tests for this path.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=publisher-validation -->"
  },
  {
    "id": "3737044354",
    "source": "**RAV-RUN3-R1-F001 [high] publication** \u2014 `--replace-existing` deletes prior records before replacement preflight\n\nLines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.\n\nThe replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.",
    "rendered_body": "**Replacement deletes prior records before preflight validation**\n\nLines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call. A later failure can leave the target without its prior records.\n\n**Requested actions**\n\n- Retain recoverable old files until every new write and route transition succeeds.\n- Add a mid-write failure test across several routes.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F001 severity=high area=publication -->"
  },
  {
    "id": "3737044361",
    "source": "**RAV-RUN3-R1-F002 [high] evaluation-identity** \u2014 Alias metadata can change the identity of the same source file\n\n`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.\n\nThe raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing.",
    "rendered_body": "**Alias metadata can change the identity of the same source file**\n\n`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.\n\nPlease use the raw dataset model path as the evaluation identity input. The reconciled repository can still drive model metadata and routing.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F002 severity=high area=evaluation-identity -->"
  },
  {
    "id": "3737044371",
    "source": "**RAV-RUN3-R1-F004 [medium] source-accounting** \u2014 Exclusions-only runs do not persist their accounting report\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.\n\nAn atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger.",
    "rendered_body": "**Exclusions-only runs do not persist their accounting report**\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.\n\nPlease atomically replace the report after successful publication so it records failures, exclusions, and fully clean runs without losing the last complete ledger.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F004 severity=medium area=source-accounting -->"
  },
  {
    "id": "3737053181",
    "source": "**RAV-RUN3-R1-F001 [medium] metric-semantics** \u2014 `avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.\n\nThe adapter approach is consistent with the current schema; the remaining gap is a shared representation for neutral measures.",
    "rendered_body": "**`avg_length` publishes a directional flag for a neutral measure**\n\n`avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.\n\nPlease add a shared representation for neutral measures so `avg_length` does not imply higher-is-better. The adapter approach can remain consistent with the current schema.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F001 severity=medium area=metric-semantics -->"
  },
  {
    "id": "3737053197",
    "source": "**RAV-RUN3-R1-F002 [medium] input-validation** \u2014 Populated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.\n\nSeparate rules for uncertainty, counts, and positive denominators would keep bad rows in the failure report. Empty optional cells can remain allowed.",
    "rendered_body": "**Malformed populated cells become absent values**\n\nPopulated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.\n\nPlease apply separate rules for uncertainty, counts, and positive denominators so bad rows remain in the failure report. Empty optional cells can remain allowed.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F002 severity=medium area=input-validation -->"
  },
  {
    "id": "3737053204",
    "source": "**RAV-RUN3-R1-F005 [medium] registry-refresh** \u2014 Every non-200 response drops the current ID from the rebuilt map. A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.\n\nAn incomplete sweep can leave the existing output unchanged and return a nonzero result. Expected 401 responses can keep their current handling.",
    "rendered_body": "**A failed registry sweep removes confirmed IDs from the rebuilt map**\n\nEvery non-200 response drops the current ID from the rebuilt map. A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.\n\nPlease leave the existing output unchanged when a sweep is incomplete and return a nonzero result. Expected 401 responses can keep their current handling.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F005 severity=medium area=registry-refresh -->"
  },
  {
    "id": "3737181823",
    "source": "**RAV-RUN2-R1-F001 [medium] schema-deferral** \u2014 A schema-invalid developer also produces an identity-path warning\n\nSemantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.\n\nFor flat IDs, the check can defer when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path.",
    "rendered_body": "**A schema-invalid developer also produces an identity-path warning**\n\nSemantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.\n\nPlease defer the flat-ID identity check when `developer` is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=schema-deferral -->"
  },
  {
    "id": "3737266652",
    "source": "**RAV-RUN2-R1-F001 [high] failure-accounting** \u2014 Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary. One malformed source value can stop every valid row without a source-row failure record.\n\nA narrow boundary can catch expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible.",
    "rendered_body": "**Score parsing can stop every valid row without a source-row failure record**\n\nScore parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary. One malformed source value can stop every valid row without a source-row failure record.\n\nPlease add a narrow boundary around expected parsing and schema errors that records the affected source row in `SourceConversionResult`. Unexpected program or infrastructure errors can remain visible.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=high area=failure-accounting -->"
  },
  {
    "id": "3737266656",
    "source": "**RAV-RUN2-R1-F002 [medium] snapshot-provenance** \u2014 The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step. A moving branch can resolve differently across four requests, while metadata records only the symbol.\n\nResolving every supplied reference once would keep branch and tag support while making all file URLs reproducible.",
    "rendered_body": "**A symbolic revision can resolve differently across one snapshot fetch**\n\nThe default fetch resolves one SHA, but a supplied symbolic revision bypasses that step. A moving branch can resolve differently across four requests, while metadata records only the symbol.\n\nPlease resolve every supplied reference once so branch and tag support remain available while all file URLs are reproducible.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F002 severity=medium area=snapshot-provenance -->"
  },
  {
    "id": "3737266661",
    "source": "**RAV-RUN2-R1-F004 [medium] exclusion-accounting** \u2014 The report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.\n\nThe shared report already supports exclusions. It can be saved for either collection while the nonzero exit stays conditional on failures.",
    "rendered_body": "**An exclusions-only run loses its source accounting**\n\nThe report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.\n\nPlease save the shared report when either `result.failures` or `result.exclusions` is nonempty. The nonzero exit can stay conditional on failures.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F004 severity=medium area=exclusion-accounting -->"
  },
  {
    "id": "3737291965",
    "source": "**RAV-RUN2-R1-F001 [medium] filesystem-traversal** \u2014 An explicit directory symlink is followed into its target\n\n`Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.\n\nThe expansion can reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged. Tests for both directory-symlink inputs and an accepted file symlink would cover the boundary.",
    "rendered_body": "**An explicit directory symlink is followed into its target**\n\n`Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.\n\n**Requested actions**\n\n- Reject directory-target symlinks for direct and glob-expanded matches.\n- Add tests for both directory-symlink inputs and an accepted file symlink.\n\n`followlinks=False` can keep blocking directory symlinks discovered below the root, and file-symlink behavior can remain unchanged.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=filesystem-traversal -->"
  },
  {
    "id": "3737383919",
    "source": "**RAV-RUN3-R1-F001 [medium] cli** \u2014 A bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.\n\nRequiring one or more values would block the first path. A no-match check can stop before existing-output discovery or publication.",
    "rendered_body": "**A bare `--models` starts the full source run**\n\nA bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.\n\n**Requested actions**\n\n- Require one or more values for `--models`.\n- Add a no-match check before existing-output discovery or publication.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F001 severity=medium area=cli -->"
  },
  {
    "id": "3737383922",
    "source": "**RAV-RUN3-R1-F002 [medium] output-path** \u2014 The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it. An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.\n\nEarly validation of the documented `data/wild` shape would keep lookup, replacement, and status output on one destination.",
    "rendered_body": "**The requested output path can target a different directory**\n\nThe code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it. An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.\n\nPlease validate the documented `data/wild` shape early so lookup, replacement, and status output use one destination.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F002 severity=medium area=output-path -->"
  },
  {
    "id": "3737449039",
    "source": "**RAV-RUN1-R1-F001 [high] evaluation-identity** \u2014 `evaluation_id` includes the current retrieval time. The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.\n\nA stable ID can use the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`.",
    "rendered_body": "**`evaluation_id` changes for every conversion of the same source file**\n\n`evaluation_id` includes the current retrieval time. The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.\n\nPlease build a stable ID from the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F001 severity=high area=evaluation-identity -->"
  },
  {
    "id": "3737449052",
    "source": "**RAV-RUN1-R1-F002 [high] source-accounting** \u2014 An input file whose measured tasks all lack finite scores returns an empty list without a failure. A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.\n\nA file with measured but unconvertible tasks can enter the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.",
    "rendered_body": "**A file with measured but unconvertible tasks disappears without a failure**\n\nAn input file whose measured tasks all lack finite scores returns an empty list without a failure. A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.\n\nPlease enter a file with measured but unconvertible tasks in the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F002 severity=high area=source-accounting -->"
  },
  {
    "id": "3737449059",
    "source": "**RAV-RUN1-R1-F004 [medium] score-coverage** \u2014 Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`. The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.\n\nBoth counts can remain visible, with the effective count identified as score coverage and the original count retained as dataset provenance.",
    "rendered_body": "**Score coverage is hidden by the dataset count**\n\nCapped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`. The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.\n\nPlease keep both counts visible, identify the effective count as score coverage, and retain the original count as dataset provenance.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F004 severity=medium area=score-coverage -->"
  },
  {
    "id": "3737449070",
    "source": "**RAV-RUN1-R1-F005 [medium] metric-semantics** \u2014 When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.\n\nSource metric specs or an operator-supplied definition can establish the semantics. Unresolved keys can be reported after the valid metrics are preserved.",
    "rendered_body": "**An unknown result key receives an unverified direction and scale**\n\nWhen a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.\n\n**Requested actions**\n\n- Use source metric specs or an operator-supplied definition to establish semantics for custom keys.\n- Preserve valid metrics and report unresolved keys.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F005 severity=medium area=metric-semantics -->"
  },
  {
    "id": "3737449081",
    "source": "**RAV-RUN1-R1-F006 [medium] metric-identity** \u2014 Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.\n\nThe same metric-definition mapping used for direction and bounds can supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.",
    "rendered_body": "**Metric definitions omit the cross-source join key**\n\nBoth `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.\n\nPlease use the same metric-definition mapping for direction and bounds to supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F006 severity=medium area=metric-identity -->"
  },
  {
    "id": "3737449090",
    "source": "**RAV-RUN1-R1-F007 [medium] coverage-totals** \u2014 `total_records` adds task-level output logs to file-level failures. One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.\n\nResults files can remain the source-record grain, with converted output-log count reported separately.",
    "rendered_body": "**`total_records` mixes file-level failures with task-level output logs**\n\n`total_records` adds task-level output logs to file-level failures. One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.\n\nPlease report converted output-log count separately. Results files can remain the source-record grain.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F007 severity=medium area=coverage-totals -->"
  },
  {
    "id": "3737449098",
    "source": "**RAV-RUN1-R1-F008 [medium] failure-reporting** \u2014 The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved; directory input reports the same failure class correctly.\n\nA small lighteval-local file-result path can give both entry modes the same report-before-raise behavior.",
    "rendered_body": "**Single-file conversion does not save the structured failure report**\n\nThe single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved. Directory input reports the same failure class correctly.\n\nPlease add a lighteval-local file-result path so both entry modes report failures before raising.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F008 severity=medium area=failure-reporting -->"
  },
  {
    "id": "3737449101",
    "source": "**RAV-RUN1-R1-F009 [medium] credential-filtering** \u2014 Secret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.\n\nOne recursive sanitizer for mappings and lists can protect these values before serialization. Tests with provider-prefixed key names would cover the reachable path without recording secret values.",
    "rendered_body": "**Nested credential values reach published `additional_details`**\n\nSecret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.\n\n**Requested actions**\n\n- Apply one recursive sanitizer to mappings and lists before serialization.\n- Add tests with provider-prefixed key names without recording secret values.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F009 severity=medium area=credential-filtering -->"
  },
  {
    "id": "3725747243",
    "source": "**RAV-RUN1-R1-F003 [high] record-identity** \u2014 `evaluation_id` changes every time the same record is converted\n\nThe current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.\n\nA stable source-run timestamp or deterministic token can keep the required ID shape while `retrieved_timestamp` records retrieval time.",
    "rendered_body": "**`evaluation_id` changes every time the same record is converted**\n\nThe current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.\n\nPlease use a stable source-run timestamp or deterministic token to keep the required ID shape. `retrieved_timestamp` can record retrieval time.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F003 severity=high area=record-identity -->"
  },
  {
    "id": "3725747244",
    "source": "**RAV-RUN1-R1-F005 [high] partial-conversion** \u2014 One invalid task discards valid sibling task logs\n\nThis loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.\n\nA task-level error boundary can preserve valid logs and account for each rejected task.",
    "rendered_body": "**One invalid task discards valid sibling task logs**\n\nThis loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.\n\nPlease add a task-level error boundary that preserves valid logs and accounts for each rejected task.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F005 severity=high area=partial-conversion -->"
  },
  {
    "id": "3725747245",
    "source": "**RAV-RUN1-R1-F007 [medium] judge-metadata** \u2014 `input_prompt` receives a scoring description instead of the judge prompt\n\n`LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.\n\nThe sound aggregate conversion can remain intact if `llm_scoring` is emitted only when the real template is available.",
    "rendered_body": "**`input_prompt` receives a scoring description instead of the judge prompt**\n\n`LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.\n\nPlease emit `llm_scoring` only when the real template is available. The sound aggregate conversion can remain intact.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F007 severity=medium area=judge-metadata -->"
  },
  {
    "id": "3725776269",
    "source": "**RAV-RUN1-R1-F002 [medium] report-placement** \u2014 A nested `data` component can keep the report inside an outer datastore tree\n\nThe helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.\n\nA note that the nearest `data` ancestor wins, plus this repeated-`data` example, would make the placement limit clear.",
    "rendered_body": "**A nested `data` component can keep the report inside an outer datastore tree**\n\nThe helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.\n\nPlease document that the nearest `data` ancestor wins, including the repeated-`data` example, so the placement limit is clear.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F002 severity=medium area=report-placement -->"
  },
  {
    "id": "3725827216",
    "source": "**RAV-RUN1-R1-F003 [medium] path-check-ownership** \u2014 Other malformed paths can receive both a path error and an identity warning\n\nThis guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.\n\nIdentity comparison can stop whenever `check_path_structure` already owns a path error.",
    "rendered_body": "**Malformed paths can receive both a path error and an identity warning**\n\nThis guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.\n\nPlease stop identity comparison whenever `check_path_structure` already owns a path error.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F003 severity=medium area=path-check-ownership -->"
  },
  {
    "id": "3725830951",
    "source": "**RAV-RUN1-R1-F004 [medium] contributor-guidance** \u2014 The new registered warning is missing from the required datastore gate guide\n\nThe repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.\n\nA short section can state the alias trigger, warning-only result, and single-record evidence limit.",
    "rendered_body": "**The registered warning is missing from the datastore gate guide**\n\nThe repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.\n\nPlease add a short section that states the alias trigger, warning-only result, and single-record evidence limit.\n\n<!-- review-anvil: id=RAV-RUN1-R1-F004 severity=medium area=contributor-guidance -->"
  },
  {
    "id": "3725853148",
    "source": "**RAV-RUN2-R1-F002 [medium] reproducibility** \u2014 Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.\n\nNetwork-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access.",
    "rendered_body": "**Branch and tag references can identify different fetched input**\n\nBranch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.\n\nPlease resolve network-mode refs once to a commit SHA. Offline replay can keep the stored immutable ref without network access.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F002 severity=medium area=reproducibility -->"
  },
  {
    "id": "3725853152",
    "source": "**RAV-RUN2-R1-F003 [medium] cli** \u2014 The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.\n\nThe module entry point can use the shared parser, with one offline entry-point test covering its defaults.",
    "rendered_body": "**The module entry point builds the old argument namespace**\n\nThis handler now reads missing fields and fails before conversion.\n\n**Requested actions**\n\n- Use the shared parser in the module entry point.\n- Add one offline entry-point test covering its defaults.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=cli -->"
  },
  {
    "id": "3725853155",
    "source": "**RAV-RUN2-R1-F005 [medium] input-validation** \u2014 Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.\n\nNumeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.",
    "rendered_body": "**Populated invalid `win_rate` values bypass row-level failure handling**\n\nInvalid values can omit the headline metric or abort strict JSON publication.\n\nPlease validate numeric fields as finite values under their metric rules before result construction, and enter invalid rows into `SourceConversionResult`.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F005 severity=medium area=input-validation -->"
  },
  {
    "id": "3725853159",
    "source": "**RAV-RUN2-R1-F007 [medium] generation-provenance** \u2014 `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.\n\nNew snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.",
    "rendered_body": "**`GenerationArgs.prompt_template` stores a path instead of prompt content**\n\n`GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.\n\nPlease store pinned prompt content in new snapshots. Legacy snapshots can leave this typed value unset and mark the missing content.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F007 severity=medium area=generation-provenance -->"
  },
  {
    "id": "3725853163",
    "source": "**RAV-RUN2-R1-F009 [medium] registry-resolution** \u2014 Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.\n\nLive mode can query present-null entries while offline behavior remains unchanged.",
    "rendered_body": "**Live mode skips known registry gaps**\n\nLive mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.\n\nPlease query present-null entries in live mode. Offline behavior can remain unchanged.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F009 severity=medium area=registry-resolution -->"
  },
  {
    "id": "3725853168",
    "source": "**RAV-RUN2-R1-F011 [medium] registry-identity** \u2014 Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nExact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.",
    "rendered_body": "**Normalized organization collisions can rewrite exact canonical IDs**\n\nNormalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nPlease let exact canonical IDs win first. Normalized spellings can resolve only when one organization owns them.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity -->"
  },
  {
    "id": "3725913004",
    "source": "**RAV-RUN2-R1-F001 [high] instance-publication** \u2014 Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.\n\nComplete output can stage before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.",
    "rendered_body": "**Instance publication can fail after aggregate and sidecar files are written**\n\nInstance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.\n\n**Requested actions**\n\n- Stage complete output before publication.\n- Reject existing logical output until replacement is atomic; sidecar validation can remain streaming.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=high area=instance-publication -->"
  },
  {
    "id": "3725913007",
    "source": "**RAV-RUN2-R1-F002 [medium] documentation** \u2014 This smoke command passes a directory to a file-only validator. Its output root also cannot satisfy datastore path checks.\n\nSmoke output can use the required `data/<collection>` path, and validation can receive a quoted fixed-depth file glob.",
    "rendered_body": "**The smoke command passes a directory to a file-only validator**\n\nIts output root also cannot satisfy datastore path checks.\n\n**Requested actions**\n\n- Use the required `data/<collection>` path for smoke output.\n- Pass a quoted fixed-depth file glob to validation.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F002 severity=medium area=documentation -->"
  },
  {
    "id": "3725913013",
    "source": "**RAV-RUN2-R1-F004 [medium] data-validation** \u2014 Missing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted.\n\nInvalid scores can enter the failure report. Incomplete token usage can be omitted, with token means based only on complete values.",
    "rendered_body": "**Missing score and token data are converted into valid measurements**\n\nMissing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted.\n\n**Requested actions**\n\n- Enter invalid scores in the failure report.\n- Omit incomplete token usage and calculate token means only from complete values.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F004 severity=medium area=data-validation -->"
  },
  {
    "id": "3725913015",
    "source": "**RAV-RUN2-R1-F005 [medium] metric-identity** \u2014 Each task receives a different metric ID even though every result is canonical accuracy. Cross-source joins by metric ID become fragmented.\n\n`accuracy` can remain the metric ID while `evaluation_name` distinguishes tasks.",
    "rendered_body": "**Each task receives a different metric ID for canonical accuracy**\n\nEvery result is canonical accuracy, but each task receives a different metric ID. Cross-source joins by metric ID become fragmented.\n\nPlease keep `accuracy` as the metric ID and use `evaluation_name` to distinguish tasks.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F005 severity=medium area=metric-identity -->"
  },
  {
    "id": "3725913021",
    "source": "**RAV-RUN2-R1-F011 [medium] cli** \u2014 A bare `--parquet` flag yields an empty list. The adapter treats that as no local input and silently starts the full remote 15-shard conversion.\n\nThe option can require at least one path.",
    "rendered_body": "**A bare `--parquet` flag starts the full remote conversion**\n\nA bare `--parquet` flag yields an empty list. The adapter treats that as no local input and silently starts the full remote 15-shard conversion.\n\nPlease require at least one path for `--parquet`.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F011 severity=medium area=cli -->"
  },
  {
    "id": "3725972277",
    "source": "**RAV-RUN2-R1-F002 [medium] repository-integration** \u2014 This adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.\n\nCurrent main can be integrated before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`.",
    "rendered_body": "**The adapter remains outside the active package**\n\nThis adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.\n\nPlease integrate current main before moving the adapter and its references under `every_eval_ever/adapters/open_medical_llm`.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F002 severity=medium area=repository-integration -->"
  },
  {
    "id": "3725972282",
    "source": "**RAV-RUN2-R1-F003 [medium] schema-compatibility** \u2014 This assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.\n\nThe expected value can come from the imported schema version.",
    "rendered_body": "**The schema assertion rejects the version emitted by current main**\n\nThis assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.\n\nPlease derive the expected value from the imported schema version.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=schema-compatibility -->"
  },
  {
    "id": "3725972285",
    "source": "**RAV-RUN2-R1-F004 [medium] metric-identity** \u2014 Ordinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.\n\n`accuracy` can remain the metric ID while task-specific evaluation names preserve benchmark identity.",
    "rendered_body": "**Ordinary accuracy receives benchmark-specific metric IDs**\n\nOrdinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.\n\nPlease keep `accuracy` as the metric ID and use task-specific evaluation names to preserve benchmark identity.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F004 severity=medium area=metric-identity -->"
  },
  {
    "id": "3725972287",
    "source": "**RAV-RUN2-R1-F006 [medium] publication** \u2014 Repeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.\n\nThe collection target can reject existing output JSON before UUID generation or batch publication.",
    "rendered_body": "**Repeat runs publish duplicate files for one logical evaluation**\n\nRepeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.\n\nPlease reject existing output JSON in the collection target before UUID generation or batch publication.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F006 severity=medium area=publication -->"
  },
  {
    "id": "3726043665",
    "source": "**RAV-RUN2-R1-F001 [critical] publication-safety** \u2014 The adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.\n\nNew or empty targets can use the batch publisher. Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.",
    "rendered_body": "**Publication deletes the selected output tree before writing**\n\nThe adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.\n\n**Requested actions**\n\n- Use the batch publisher for new or empty targets.\n- Fail by default for symlinks, roots, and populated targets.\n\nReplacement can remain blocked until it has an explicit ownership manifest.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=critical area=publication-safety -->"
  },
  {
    "id": "3726043671",
    "source": "**RAV-RUN2-R1-F002 [high] conversion-accounting** \u2014 Malformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output.\n\nMetric cells can be the source unit. Each attempted or rejected cell can count once, while malformed objects and missing datasets retain row references.",
    "rendered_body": "**Conversion can succeed with incomplete output and no accounting**\n\nMalformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output.\n\nPlease use metric cells as the source unit, count each attempted or rejected cell once, and retain row references for malformed objects and missing datasets.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F002 severity=high area=conversion-accounting -->"
  },
  {
    "id": "3726043679",
    "source": "**RAV-RUN2-R1-F004 [medium] score-bounds** \u2014 Scale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores.\n\nTolerance can support scale classification only. A strict pre-publication check can reject unproven overruns.",
    "rendered_body": "**Scale tolerance allows unproven boundary overruns into publication**\n\nScale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores.\n\n**Requested actions**\n\n- Use tolerance only for scale classification.\n- Add a strict pre-publication check that rejects unproven overruns.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F004 severity=medium area=score-bounds -->"
  },
  {
    "id": "3726043682",
    "source": "**RAV-RUN2-R1-F005 [medium] metric-metadata** \u2014 `metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds.\n\nA unit can be set only when the canonical contract or an explicit conversion proves it. Otherwise it can stay unset while `pwc_scale` remains in details.",
    "rendered_body": "**`metric_unit` can conflict with the converted score**\n\n`metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds.\n\nPlease set a unit only when the canonical contract or an explicit conversion proves it. Otherwise, it can stay unset while `pwc_scale` remains in details.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F005 severity=medium area=metric-metadata -->"
  }
]