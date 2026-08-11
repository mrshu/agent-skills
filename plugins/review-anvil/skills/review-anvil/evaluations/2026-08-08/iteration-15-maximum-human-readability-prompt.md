Blindly compare two rendered GitHub inline code-review comments for a busy pull-request author. A and B are randomized independently for every row. You are seeing what the normal GitHub UI renders; hidden HTML metadata has already been removed. Do not infer chronology, tool identity, or implementation. Judge human readability only, assuming both versions describe the same accepted technical finding.

For every row, choose A, B, or tie. Prefer the version a senior engineer can understand correctly after one read in a narrow inline pane. Judge: (1) defect clarity: failure and trigger are immediately clear; (2) action recall: every requested action is visible and memorable; (3) scanability: structure supports quick scanning; (4) naturalness: concise colleague-to-colleague prose rather than a template; (5) cognitive ease: minimal rereading without losing necessary identifiers, qualifiers, or technical terms. Do not reward brevity by itself. Do not penalize necessary technical detail. Penalize visible machine/provenance metadata when it makes the rendered comment feel generated or delays the actual problem.

Return valid JSON only:
{"items":[{"id":"<exact id>","winner":"A|B|tie","dimension_winners":{"defect_clarity":"A|B|tie","action_recall":"A|B|tie","scanability":"A|B|tie","naturalness":"A|B|tie","cognitive_ease":"A|B|tie"},"reason":"<one sentence>"}],"winner_counts":{"A":0,"B":0,"tie":0},"summary":"<two or three sentences>"}
Return every input ID exactly once. Do not emit Markdown fences or extra text.

INPUT:
[
  {
    "id": "3737042592",
    "A": "**The publisher guard accepts a collection directory with the wrong name**\n\nFor `base_output_dir=data/foo` and selected collection `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.\n\n**Requested actions**\n\n- Reject every publisher base that is an immediate child of canonical `data`.\n- Add mismatched source and `collection_override` tests for this path.",
    "B": "**RAV-RUN2-R1-F001 [medium] publisher-validation** \u2014 The new guard accepts a collection directory when its name differs from the selected collection.\n\nFor `base_output_dir=data/foo` and a selected collection of `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.\n\n**Requested actions**\n\n- Reject every publisher base that is an immediate child of canonical `data`.\n- Add mismatched source and `collection_override` tests for this path."
  },
  {
    "id": "3737044354",
    "A": "**Replacement deletes prior records before preflight validation**\n\nLines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call. A later failure can leave the target without its prior records.\n\n**Requested actions**\n\n- Retain recoverable old files until every new write and route transition succeeds.\n- Add a mid-write failure test across several routes.",
    "B": "**RAV-RUN3-R1-F001 [high] publication** \u2014 `--replace-existing` deletes prior records before replacement preflight.\n\nLines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.\n\n**Requested actions**\n\n- Retain recoverable old files until every new write and route transition succeeds.\n- Add a mid-write failure test across several routes."
  },
  {
    "id": "3737044361",
    "A": "**RAV-RUN3-R1-F002 [high] evaluation-identity** \u2014 Alias metadata can change the identity of the same source file.\n\n`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.\n\nPlease use the raw dataset model path as the evaluation identity input. The reconciled repository can still drive model metadata and routing.",
    "B": "**Alias metadata can change the identity of the same source file**\n\n`evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.\n\nPlease use the raw dataset model path as the evaluation identity input. The reconciled repository can still drive model metadata and routing."
  },
  {
    "id": "3737044371",
    "A": "**Exclusions-only runs do not persist their accounting report**\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.\n\nPlease atomically replace the report after successful publication so it records failures, exclusions, and fully clean runs without losing the last complete ledger.",
    "B": "**RAV-RUN3-R1-F004 [medium] source-accounting** \u2014 Exclusions-only runs do not persist their accounting report.\n\n`failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.\n\nPlease replace the report atomically after successful publication, including failures, exclusions, and fully clean runs."
  },
  {
    "id": "3737053181",
    "A": "**`avg_length` publishes a directional flag for a neutral measure**\n\n`avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.\n\nPlease add a shared representation for neutral measures so `avg_length` does not imply higher-is-better. The adapter approach can remain consistent with the current schema.",
    "B": "**RAV-RUN3-R1-F001 [medium] metric-semantics** \u2014 `avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.\n\nThe adapter approach is consistent with the current schema.\n\nPlease provide a shared representation for neutral measures."
  },
  {
    "id": "3737053197",
    "A": "**Malformed populated cells become absent values**\n\nPopulated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.\n\nPlease apply separate rules for uncertainty, counts, and positive denominators so bad rows remain in the failure report. Empty optional cells can remain allowed.",
    "B": "**RAV-RUN3-R1-F002 [medium] input-validation** \u2014 Populated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.\n\nPlease use separate rules for uncertainty, counts, and positive denominators so bad rows stay in the failure report. Empty optional cells can remain allowed."
  },
  {
    "id": "3737053204",
    "A": "**RAV-RUN3-R1-F005 [medium] registry-refresh** \u2014 Every non-200 response drops the current ID from the rebuilt map.\n\nA transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.\n\nPlease leave the existing output unchanged and return a nonzero result when a sweep is incomplete. Expected 401 responses can keep their current handling.",
    "B": "**A failed registry sweep removes confirmed IDs from the rebuilt map**\n\nEvery non-200 response drops the current ID from the rebuilt map. A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.\n\nPlease leave the existing output unchanged when a sweep is incomplete and return a nonzero result. Expected 401 responses can keep their current handling."
  },
  {
    "id": "3737181823",
    "A": "**A schema-invalid developer also produces an identity-path warning**\n\nSemantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.\n\nPlease defer the flat-ID identity check when `developer` is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path.",
    "B": "**RAV-RUN2-R1-F001 [medium] schema-deferral** \u2014 A schema-invalid developer also produces an identity-path warning.\n\nSemantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.\n\nPlease defer the check for flat IDs when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path."
  },
  {
    "id": "3737266652",
    "A": "**Score parsing can stop every valid row without a source-row failure record**\n\nScore parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary. One malformed source value can stop every valid row without a source-row failure record.\n\nPlease add a narrow boundary around expected parsing and schema errors that records the affected source row in `SourceConversionResult`. Unexpected program or infrastructure errors can remain visible.",
    "B": "**RAV-RUN2-R1-F001 [high] failure-accounting** \u2014 Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary.\n\nOne malformed source value can stop every valid row without a source-row failure record.\n\nPlease add a narrow boundary for expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible."
  },
  {
    "id": "3737266656",
    "A": "**A symbolic revision can resolve differently across one snapshot fetch**\n\nThe default fetch resolves one SHA, but a supplied symbolic revision bypasses that step. A moving branch can resolve differently across four requests, while metadata records only the symbol.\n\nPlease resolve every supplied reference once so branch and tag support remain available while all file URLs are reproducible.",
    "B": "**RAV-RUN2-R1-F002 [medium] snapshot-provenance** \u2014 The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step.\n\nA moving branch can resolve differently across four requests, while metadata records only the symbol.\n\nPlease resolve every supplied reference once so branch and tag support remain available and all file URLs are reproducible."
  },
  {
    "id": "3737266661",
    "A": "**RAV-RUN2-R1-F004 [medium] exclusion-accounting** \u2014 The report is saved only when `result.failures` is nonempty.\n\nAn exclusions-only run succeeds but loses each excluded source reference and reason.\n\nPlease save the shared report for either collection. The nonzero exit can stay conditional on failures.",
    "B": "**An exclusions-only run loses its source accounting**\n\nThe report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.\n\nPlease save the shared report when either `result.failures` or `result.exclusions` is nonempty. The nonzero exit can stay conditional on failures."
  },
  {
    "id": "3737291965",
    "A": "**An explicit directory symlink is followed into its target**\n\n`Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.\n\n**Requested actions**\n\n- Reject directory-target symlinks for direct and glob-expanded matches.\n- Add tests for both directory-symlink inputs and an accepted file symlink.\n\n`followlinks=False` can keep blocking directory symlinks discovered below the root, and file-symlink behavior can remain unchanged.",
    "B": "**RAV-RUN2-R1-F001 [medium] filesystem-traversal** \u2014 An explicit directory symlink is followed into its target.\n\n`Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.\n\n**Requested actions**\n\n- Reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged.\n- Add tests for both directory-symlink inputs and an accepted file symlink."
  },
  {
    "id": "3737383919",
    "A": "**RAV-RUN3-R1-F001 [medium] cli** \u2014 A bare `--models` parses as an empty list, which disables filtering and starts the full source run.\n\nA nonempty filter with no matches instead exits successfully with zero logs.\n\n**Requested actions**\n\n- Require one or more values for `--models`.\n- Stop a no-match run before existing-output discovery or publication.",
    "B": "**A bare `--models` starts the full source run**\n\nA bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.\n\n**Requested actions**\n\n- Require one or more values for `--models`.\n- Add a no-match check before existing-output discovery or publication."
  },
  {
    "id": "3737383922",
    "A": "**RAV-RUN3-R1-F002 [medium] output-path** \u2014 The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it.\n\nAn arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.\n\nPlease validate the documented `data/wild` shape early so lookup, replacement, and status output use one destination.",
    "B": "**The requested output path can target a different directory**\n\nThe code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it. An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.\n\nPlease validate the documented `data/wild` shape early so lookup, replacement, and status output use one destination."
  },
  {
    "id": "3737449039",
    "A": "**`evaluation_id` changes for every conversion of the same source file**\n\n`evaluation_id` includes the current retrieval time. The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.\n\nPlease build a stable ID from the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`.",
    "B": "**RAV-RUN1-R1-F001 [high] evaluation-identity** \u2014 `evaluation_id` includes the current retrieval time.\n\nThe same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.\n\nPlease build a stable ID from the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`."
  },
  {
    "id": "3737449052",
    "A": "**RAV-RUN1-R1-F002 [high] source-accounting** \u2014 An input file whose measured tasks all lack finite scores returns an empty list without a failure.\n\nA directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.\n\nPlease add a file with measured but unconvertible tasks to the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.",
    "B": "**A file with measured but unconvertible tasks disappears without a failure**\n\nAn input file whose measured tasks all lack finite scores returns an empty list without a failure. A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.\n\nPlease enter a file with measured but unconvertible tasks in the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions."
  },
  {
    "id": "3737449059",
    "A": "**Score coverage is hidden by the dataset count**\n\nCapped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`. The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.\n\nPlease keep both counts visible, identify the effective count as score coverage, and retain the original count as dataset provenance.",
    "B": "**RAV-RUN1-R1-F004 [medium] score-coverage** \u2014 Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`.\n\nThe dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.\n\nPlease keep both counts visible, identify the effective count as score coverage, and retain the original count as dataset provenance."
  },
  {
    "id": "3737449070",
    "A": "**An unknown result key receives an unverified direction and scale**\n\nWhen a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.\n\n**Requested actions**\n\n- Use source metric specs or an operator-supplied definition to establish semantics for custom keys.\n- Preserve valid metrics and report unresolved keys.",
    "B": "**RAV-RUN1-R1-F005 [medium] metric-semantics** \u2014 When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds.\n\nA finite custom key does not prove that direction.\n\n**Requested actions**\n\n- Use source metric specs or an operator-supplied definition to establish the semantics.\n- Report unresolved keys after preserving the valid metrics."
  },
  {
    "id": "3737449081",
    "A": "**Metric definitions omit the cross-source join key**\n\nBoth `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.\n\nPlease use the same metric-definition mapping for direction and bounds to supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.",
    "B": "**RAV-RUN1-R1-F006 [medium] metric-identity** \u2014 Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy.\n\n`metric_name` keeps the source label but does not provide the cross-source join key.\n\nPlease use the same metric-definition mapping for direction and bounds, canonical global IDs, and stable namespaced IDs for defined lighteval-specific metrics."
  },
  {
    "id": "3737449090",
    "A": "**`total_records` mixes file-level failures with task-level output logs**\n\n`total_records` adds task-level output logs to file-level failures. One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.\n\nPlease report converted output-log count separately. Results files can remain the source-record grain.",
    "B": "**RAV-RUN1-R1-F007 [medium] coverage-totals** \u2014 `total_records` adds task-level output logs to file-level failures.\n\nOne successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.\n\nPlease keep results files as the source-record grain and report converted output-log count separately."
  },
  {
    "id": "3737449098",
    "A": "**Single-file conversion does not save the structured failure report**\n\nThe single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved. Directory input reports the same failure class correctly.\n\nPlease add a lighteval-local file-result path so both entry modes report failures before raising.",
    "B": "**RAV-RUN1-R1-F008 [medium] failure-reporting** \u2014 The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`.\n\nParse or conversion errors exit non-zero, but the structured failure report is never saved. Directory input reports the same failure class correctly.\n\nPlease add a lighteval-local file-result path so both entry modes report before raising."
  },
  {
    "id": "3737449101",
    "A": "**Nested credential values reach published `additional_details`**\n\nSecret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.\n\n**Requested actions**\n\n- Apply one recursive sanitizer to mappings and lists before serialization.\n- Add tests with provider-prefixed key names without recording secret values.",
    "B": "**RAV-RUN1-R1-F009 [medium] credential-filtering** \u2014 Secret filtering checks only top-level model-config keys before nested values are serialized.\n\nSupported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.\n\n**Requested actions**\n\n- Apply one recursive sanitizer to mappings and lists before serialization.\n- Add tests with provider-prefixed key names without recording secret values."
  },
  {
    "id": "3725747243",
    "A": "**`evaluation_id` changes every time the same record is converted**\n\nThe current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.\n\nPlease use a stable source-run timestamp or deterministic token to keep the required ID shape. `retrieved_timestamp` can record retrieval time.",
    "B": "**RAV-RUN1-R1-F003 [high] record-identity** \u2014 `evaluation_id` changes every time the same record is converted.\n\nThe current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.\n\nPlease use a stable source-run timestamp or deterministic token to keep the required ID shape, while `retrieved_timestamp` records retrieval time."
  },
  {
    "id": "3725747244",
    "A": "**One invalid task discards valid sibling task logs**\n\nThis loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.\n\nPlease add a task-level error boundary that preserves valid logs and accounts for each rejected task.",
    "B": "**RAV-RUN1-R1-F005 [high] partial-conversion** \u2014 One invalid task discards valid sibling task logs.\n\nThis loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.\n\nPlease add a task-level error boundary that preserves valid logs and accounts for each rejected task."
  },
  {
    "id": "3725747245",
    "A": "**`input_prompt` receives a scoring description instead of the judge prompt**\n\n`LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.\n\nPlease emit `llm_scoring` only when the real template is available. The sound aggregate conversion can remain intact.",
    "B": "**RAV-RUN1-R1-F007 [medium] judge-metadata** \u2014 `input_prompt` receives a scoring description instead of the judge prompt.\n\n`LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.\n\nPlease emit `llm_scoring` only when the real template is available. The sound aggregate conversion can remain intact."
  },
  {
    "id": "3725776269",
    "A": "**RAV-RUN1-R1-F002 [medium] report-placement** \u2014 A nested `data` component can keep the report inside an outer datastore tree.\n\nThe helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.\n\nPlease document that the nearest `data` ancestor wins, using the repeated-`data` example to make the placement limit clear.",
    "B": "**A nested `data` component can keep the report inside an outer datastore tree**\n\nThe helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.\n\nPlease document that the nearest `data` ancestor wins, including the repeated-`data` example, so the placement limit is clear."
  },
  {
    "id": "3725827216",
    "A": "**RAV-RUN1-R1-F003 [medium] path-check-ownership** \u2014 Other malformed paths can receive both a path error and an identity warning.\n\nThis guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.\n\nPlease stop identity comparison whenever `check_path_structure` already owns a path error.",
    "B": "**Malformed paths can receive both a path error and an identity warning**\n\nThis guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.\n\nPlease stop identity comparison whenever `check_path_structure` already owns a path error."
  },
  {
    "id": "3725830951",
    "A": "**RAV-RUN1-R1-F004 [medium] contributor-guidance** \u2014 The new registered warning is missing from the required datastore gate guide.\n\nThe repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.\n\nPlease add a short section that states the alias trigger, warning-only result, and single-record evidence limit.",
    "B": "**The registered warning is missing from the datastore gate guide**\n\nThe repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.\n\nPlease add a short section that states the alias trigger, warning-only result, and single-record evidence limit."
  },
  {
    "id": "3725853148",
    "A": "**RAV-RUN2-R1-F002 [medium] reproducibility** \u2014 Branch and tag refs are used in stable IDs and provenance URLs without commit resolution.\n\nTwo network runs can fetch different input under the same identity.\n\nPlease resolve network-mode refs once to a commit SHA. Offline replay can keep the stored immutable ref without network access.",
    "B": "**Branch and tag references can identify different fetched input**\n\nBranch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.\n\nPlease resolve network-mode refs once to a commit SHA. Offline replay can keep the stored immutable ref without network access."
  },
  {
    "id": "3725853152",
    "A": "**RAV-RUN2-R1-F003 [medium] cli** \u2014 The module entry point builds the old argument namespace.\n\nThis handler now reads missing fields and fails before conversion.\n\n**Requested actions**\n\n- Use the shared parser in the module entry point.\n- Add one offline entry-point test covering its defaults.",
    "B": "**The module entry point builds the old argument namespace**\n\nThis handler now reads missing fields and fails before conversion.\n\n**Requested actions**\n\n- Use the shared parser in the module entry point.\n- Add one offline entry-point test covering its defaults."
  },
  {
    "id": "3725853155",
    "A": "**Populated invalid `win_rate` values bypass row-level failure handling**\n\nInvalid values can omit the headline metric or abort strict JSON publication.\n\nPlease validate numeric fields as finite values under their metric rules before result construction, and enter invalid rows into `SourceConversionResult`.",
    "B": "**RAV-RUN2-R1-F005 [medium] input-validation** \u2014 Populated invalid `win_rate` values bypass row-level failure handling.\n\nThey can omit the headline metric or abort strict JSON publication.\n\nPlease validate numeric fields as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`."
  },
  {
    "id": "3725853159",
    "A": "**RAV-RUN2-R1-F007 [medium] generation-provenance** \u2014 `GenerationArgs.prompt_template` contains an upstream path instead of prompt content.\n\nOffline records cannot reconstruct the generation prompt.\n\nPlease store pinned prompt content in new snapshots. Legacy snapshots can leave this typed value unset and mark the missing content.",
    "B": "**`GenerationArgs.prompt_template` stores a path instead of prompt content**\n\n`GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.\n\nPlease store pinned prompt content in new snapshots. Legacy snapshots can leave this typed value unset and mark the missing content."
  },
  {
    "id": "3725853163",
    "A": "**Live mode skips known registry gaps**\n\nLive mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.\n\nPlease query present-null entries in live mode. Offline behavior can remain unchanged.",
    "B": "**RAV-RUN2-R1-F009 [medium] registry-resolution** \u2014 Live mode skips keys whose vendored value is null.\n\nA known gap cannot discover a new registry entry until the snapshot refreshes.\n\nPlease make live mode query present-null entries. Offline behavior can remain unchanged."
  },
  {
    "id": "3725853168",
    "A": "**Normalized organization collisions can rewrite exact canonical IDs**\n\nNormalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nPlease let exact canonical IDs win first. Normalized spellings can resolve only when one organization owns them.",
    "B": "**RAV-RUN2-R1-F011 [medium] registry-identity** \u2014 Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nPlease make exact canonical IDs win first. Normalized spellings can resolve only when one organization owns them."
  },
  {
    "id": "3725913004",
    "A": "**RAV-RUN2-R1-F001 [high] instance-publication** \u2014 Instance mode passes a sidecar basename where the schema requires a canonical datastore path.\n\nConstruction fails after aggregate and sidecar files are written.\n\nPlease stage complete output before publication. Reject existing logical output until replacement is atomic, while sidecar validation stays streaming.",
    "B": "**Instance publication can fail after aggregate and sidecar files are written**\n\nInstance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.\n\n**Requested actions**\n\n- Stage complete output before publication.\n- Reject existing logical output until replacement is atomic; sidecar validation can remain streaming."
  },
  {
    "id": "3725913007",
    "A": "**The smoke command passes a directory to a file-only validator**\n\nIts output root also cannot satisfy datastore path checks.\n\n**Requested actions**\n\n- Use the required `data/<collection>` path for smoke output.\n- Pass a quoted fixed-depth file glob to validation.",
    "B": "**RAV-RUN2-R1-F002 [medium] documentation** \u2014 This smoke command passes a directory to a file-only validator.\n\nIts output root also cannot satisfy datastore path checks.\n\n**Requested actions**\n\n- Use the required `data/<collection>` path for smoke output.\n- Pass a quoted fixed-depth file glob to validation."
  },
  {
    "id": "3725913013",
    "A": "**Missing score and token data are converted into valid measurements**\n\nMissing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted.\n\n**Requested actions**\n\n- Enter invalid scores in the failure report.\n- Omit incomplete token usage and calculate token means only from complete values.",
    "B": "**RAV-RUN2-R1-F004 [medium] data-validation** \u2014 Missing scores become incorrect answers and stay in aggregate denominators.\n\nMissing token data becomes measured zero instead of being omitted.\n\n**Requested actions**\n\n- Put invalid scores in the failure report.\n- Omit incomplete token usage and base token means only on complete values."
  },
  {
    "id": "3725913015",
    "A": "**RAV-RUN2-R1-F005 [medium] metric-identity** \u2014 Each task receives a different metric ID even though every result is canonical accuracy.\n\nCross-source joins by metric ID become fragmented.\n\nPlease keep `accuracy` as the metric ID and use `evaluation_name` to distinguish tasks.",
    "B": "**Each task receives a different metric ID for canonical accuracy**\n\nEvery result is canonical accuracy, but each task receives a different metric ID. Cross-source joins by metric ID become fragmented.\n\nPlease keep `accuracy` as the metric ID and use `evaluation_name` to distinguish tasks."
  },
  {
    "id": "3725913021",
    "A": "**A bare `--parquet` flag starts the full remote conversion**\n\nA bare `--parquet` flag yields an empty list. The adapter treats that as no local input and silently starts the full remote 15-shard conversion.\n\nPlease require at least one path for `--parquet`.",
    "B": "**RAV-RUN2-R1-F011 [medium] cli** \u2014 A bare `--parquet` flag yields an empty list.\n\nThe adapter treats that as no local input and silently starts the full remote 15-shard conversion.\n\nPlease require at least one path for the option."
  },
  {
    "id": "3725972277",
    "A": "**The adapter remains outside the active package**\n\nThis adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.\n\nPlease integrate current main before moving the adapter and its references under `every_eval_ever/adapters/open_medical_llm`.",
    "B": "**RAV-RUN2-R1-F002 [medium] repository-integration** \u2014 This adapter remains under the retired `utils` layout.\n\nInstalled packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.\n\nPlease integrate current main before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`."
  },
  {
    "id": "3725972282",
    "A": "**The schema assertion rejects the version emitted by current main**\n\nThis assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.\n\nPlease derive the expected value from the imported schema version.",
    "B": "**RAV-RUN2-R1-F003 [medium] schema-compatibility** \u2014 This assertion requires schema `0.2.2`, while current main emits `0.3.0`.\n\nThe test fails after integration.\n\nPlease take the expected value from the imported schema version."
  },
  {
    "id": "3725972285",
    "A": "**RAV-RUN2-R1-F004 [medium] metric-identity** \u2014 Ordinary accuracy receives nine benchmark-specific metric IDs.\n\nThis fragments the global accuracy join key.\n\nPlease keep `accuracy` as the metric ID and use task-specific evaluation names to preserve benchmark identity.",
    "B": "**Ordinary accuracy receives benchmark-specific metric IDs**\n\nOrdinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.\n\nPlease keep `accuracy` as the metric ID and use task-specific evaluation names to preserve benchmark identity."
  },
  {
    "id": "3725972287",
    "A": "**Repeat runs publish duplicate files for one logical evaluation**\n\nRepeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.\n\nPlease reject existing output JSON in the collection target before UUID generation or batch publication.",
    "B": "**RAV-RUN2-R1-F006 [medium] publication** \u2014 Repeat runs add a fresh UUID file for each stable evaluation ID.\n\nA populated target can hold duplicate logical records.\n\nPlease reject existing output JSON in the collection target before UUID generation or batch publication."
  },
  {
    "id": "3726043665",
    "A": "**RAV-RUN2-R1-F001 [critical] publication-safety** \u2014 The adapter recursively deletes the selected output tree before publication.\n\nEmpty batches and later write failures can destroy prior or unrelated data.\n\n**Requested actions**\n\n- Use the batch publisher for new or empty targets.\n- Fail by default for symlinks, roots, and populated targets until replacement has an explicit ownership manifest.",
    "B": "**Publication deletes the selected output tree before writing**\n\nThe adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.\n\n**Requested actions**\n\n- Use the batch publisher for new or empty targets.\n- Fail by default for symlinks, roots, and populated targets.\n\nReplacement can remain blocked until it has an explicit ownership manifest."
  },
  {
    "id": "3726043671",
    "A": "**RAV-RUN2-R1-F002 [high] conversion-accounting** \u2014 Malformed metrics, missing dataset references, and resultless rows are silently omitted.\n\nThe command can exit successfully with incomplete output.\n\nPlease use metric cells as the source unit. Count each attempted or rejected cell once, and retain row references for malformed objects and missing datasets.",
    "B": "**Conversion can succeed with incomplete output and no accounting**\n\nMalformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output.\n\nPlease use metric cells as the source unit, count each attempted or rejected cell once, and retain row references for malformed objects and missing datasets."
  },
  {
    "id": "3726043679",
    "A": "**RAV-RUN2-R1-F004 [medium] score-bounds** \u2014 Scale tolerance accepts small boundary overruns but emits them unchanged.\n\nCurrent semantic validation rejects those scores.\n\nPlease use tolerance only for scale classification and add a strict pre-publication check that rejects unproven overruns.",
    "B": "**Scale tolerance allows unproven boundary overruns into publication**\n\nScale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores.\n\n**Requested actions**\n\n- Use tolerance only for scale classification.\n- Add a strict pre-publication check that rejects unproven overruns."
  },
  {
    "id": "3726043682",
    "A": "**`metric_unit` can conflict with the converted score**\n\n`metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds.\n\nPlease set a unit only when the canonical contract or an explicit conversion proves it. Otherwise, it can stay unset while `pwc_scale` remains in details.",
    "B": "**RAV-RUN2-R1-F005 [medium] metric-metadata** \u2014 `metric_unit` stays tied to the PwC source scale after score conversion.\n\nIt can conflict with the emitted score and canonical bounds.\n\nPlease set a unit only when the canonical contract or an explicit conversion proves it. Otherwise, leave it unset while `pwc_scale` remains in details."
  }
]