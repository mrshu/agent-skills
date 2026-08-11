# Exact previous-skill versus final-contract inline output

Previous side: verbatim observed review-anvil output from 16 GitHub reviews. The exact producing skill commit was not recorded.

New side: generated and audited from review-anvil contract `b3f2ad2c4c5e872a6e059d8e64c056ad615ab2ca` using the same 47 accepted findings.

Pipeline result: 33 first-pass bodies, 13 repaired bodies, 1 exact-source fallback; 46/47 outputs changed. Because a fallback was used, `approval_allowed` is `false` and the review event must be `COMMENT`.

The clean generator and auditors saw only frozen source prose and contract rules. They did not inspect repositories. Audits were scoped to each of the original 16 reviews, matching production review boundaries.

## PR #227 — review 4884439849

### Comment 3737042592 — first-pass

`every_eval_ever/converters/common/publication.py` line 61 — https://github.com/evaleval/every_eval_ever/pull/227#discussion_r3737042592

#### Previous skill output

> **RAV-RUN2-R1-F001 [medium] publisher-validation** — The new guard accepts a collection directory when its name differs from the selected collection.
>
> For `base_output_dir=data/foo` and a selected collection of `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.
>
> A small follow-up could reject every publisher base that is an immediate child of canonical `data`. Mismatched source and `collection_override` tests would cover this path.

#### New final-contract output

> **RAV-RUN2-R1-F001 [medium] publisher-validation** — The new guard accepts a collection directory when its name differs from the selected collection.
>
> For `base_output_dir=data/foo` and a selected collection of `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.
>
> **Requested actions**
>
> - Reject every publisher base that is an immediate child of canonical `data`.
> - Add mismatched source and `collection_override` tests for this path.

#### Unified diff

```diff
--- previous
+++ new
@@ -2,4 +2,7 @@
 
 For `base_output_dir=data/foo` and a selected collection of `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.
 
-A small follow-up could reject every publisher base that is an immediate child of canonical `data`. Mismatched source and `collection_override` tests would cover this path.
+**Requested actions**
+
+- Reject every publisher base that is an immediate child of canonical `data`.
+- Add mismatched source and `collection_override` tests for this path.
```

## PR #204 — review 4884442134

### Comment 3737044354 — first-pass

`every_eval_ever/adapters/open_medical_llm/adapter.py` line 601 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3737044354

#### Previous skill output

> **RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight
>
> Lines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.
>
> The replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.

#### New final-contract output

> **RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight.
>
> Lines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.
>
> **Requested actions**
>
> - Retain recoverable old files until every new write and route transition succeeds.
> - Add a mid-write failure test across several routes.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,8 @@
-**RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight
+**RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight.
 
 Lines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.
 
-The replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.
+**Requested actions**
+
+- Retain recoverable old files until every new write and route transition succeeds.
+- Add a mid-write failure test across several routes.
```

### Comment 3737044361 — first-pass

`every_eval_ever/adapters/open_medical_llm/adapter.py` line 397 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3737044361

#### Previous skill output

> **RAV-RUN3-R1-F002 [high] evaluation-identity** — Alias metadata can change the identity of the same source file
>
> `evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.
>
> The raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing.

#### New final-contract output

> **RAV-RUN3-R1-F002 [high] evaluation-identity** — Alias metadata can change the identity of the same source file.
>
> `evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.
>
> Please use the raw dataset model path as the evaluation identity input. The reconciled repository can still drive model metadata and routing.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,5 @@
-**RAV-RUN3-R1-F002 [high] evaluation-identity** — Alias metadata can change the identity of the same source file
+**RAV-RUN3-R1-F002 [high] evaluation-identity** — Alias metadata can change the identity of the same source file.
 
 `evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.
 
-The raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing.
+Please use the raw dataset model path as the evaluation identity input. The reconciled repository can still drive model metadata and routing.
```

### Comment 3737044371 — repaired

`every_eval_ever/adapters/open_medical_llm/adapter.py` line 585 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3737044371

#### Previous skill output

> **RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report
>
> `failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.
>
> An atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger.

#### New final-contract output

> **RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report.
>
> `failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.
>
> Please replace the report atomically after successful publication, including failures, exclusions, and fully clean runs, without losing the last complete ledger.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,5 @@
-**RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report
+**RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report.
 
 `failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.
 
-An atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger.
+Please replace the report atomically after successful publication, including failures, exclusions, and fully clean runs, without losing the last complete ledger.
```

## PR #190 — review 4884452884

### Comment 3737053181 — first-pass

`every_eval_ever/converters/alpaca_eval/adapter.py` line 525 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3737053181

#### Previous skill output

> **RAV-RUN3-R1-F001 [medium] metric-semantics** — `avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.
>
> The adapter approach is consistent with the current schema; the remaining gap is a shared representation for neutral measures.

#### New final-contract output

> **RAV-RUN3-R1-F001 [medium] metric-semantics** — `avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.
>
> The adapter approach is consistent with the current schema.
>
> Please provide a shared representation for neutral measures.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
 **RAV-RUN3-R1-F001 [medium] metric-semantics** — `avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.
 
-The adapter approach is consistent with the current schema; the remaining gap is a shared representation for neutral measures.
+The adapter approach is consistent with the current schema.
+
+Please provide a shared representation for neutral measures.
```

### Comment 3737053197 — first-pass

`every_eval_ever/converters/alpaca_eval/adapter.py` line 557 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3737053197

#### Previous skill output

> **RAV-RUN3-R1-F002 [medium] input-validation** — Populated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.
>
> Separate rules for uncertainty, counts, and positive denominators would keep bad rows in the failure report. Empty optional cells can remain allowed.

#### New final-contract output

> **RAV-RUN3-R1-F002 [medium] input-validation** — Populated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.
>
> Please use separate rules for uncertainty, counts, and positive denominators so bad rows stay in the failure report. Empty optional cells can remain allowed.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,3 @@
 **RAV-RUN3-R1-F002 [medium] input-validation** — Populated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.
 
-Separate rules for uncertainty, counts, and positive denominators would keep bad rows in the failure report. Empty optional cells can remain allowed.
+Please use separate rules for uncertainty, counts, and positive denominators so bad rows stay in the failure report. Empty optional cells can remain allowed.
```

### Comment 3737053204 — first-pass

`every_eval_ever/converters/alpaca_eval/refresh_hf_canonical_ids.py` line 115 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3737053204

#### Previous skill output

> **RAV-RUN3-R1-F005 [medium] registry-refresh** — Every non-200 response drops the current ID from the rebuilt map. A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.
>
> An incomplete sweep can leave the existing output unchanged and return a nonzero result. Expected 401 responses can keep their current handling.

#### New final-contract output

> **RAV-RUN3-R1-F005 [medium] registry-refresh** — Every non-200 response drops the current ID from the rebuilt map.
>
> A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.
>
> Please leave the existing output unchanged and return a nonzero result when a sweep is incomplete. Expected 401 responses can keep their current handling.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN3-R1-F005 [medium] registry-refresh** — Every non-200 response drops the current ID from the rebuilt map. A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.
+**RAV-RUN3-R1-F005 [medium] registry-refresh** — Every non-200 response drops the current ID from the rebuilt map.
 
-An incomplete sweep can leave the existing output unchanged and return a nonzero result. Expected 401 responses can keep their current handling.
+A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.
+
+Please leave the existing output unchanged and return a nonzero result when a sweep is incomplete. Expected 401 responses can keep their current handling.
```

## PR #223 — review 4884614217

### Comment 3737181823 — first-pass

`every_eval_ever/validator/validation_core.py` line 631 — https://github.com/evaleval/every_eval_ever/pull/223#discussion_r3737181823

#### Previous skill output

> **RAV-RUN2-R1-F001 [medium] schema-deferral** — A schema-invalid developer also produces an identity-path warning
>
> Semantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.
>
> For flat IDs, the check can defer when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path.

#### New final-contract output

> **RAV-RUN2-R1-F001 [medium] schema-deferral** — A schema-invalid developer also produces an identity-path warning.
>
> Semantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.
>
> Please defer the check for flat IDs when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,5 @@
-**RAV-RUN2-R1-F001 [medium] schema-deferral** — A schema-invalid developer also produces an identity-path warning
+**RAV-RUN2-R1-F001 [medium] schema-deferral** — A schema-invalid developer also produces an identity-path warning.
 
 Semantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.
 
-For flat IDs, the check can defer when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path.
+Please defer the check for flat IDs when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path.
```

## PR #197 — review 4884743173

### Comment 3737266652 — first-pass

`every_eval_ever/adapters/benchpress/adapter.py` line 245 — https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3737266652

#### Previous skill output

> **RAV-RUN2-R1-F001 [high] failure-accounting** — Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary. One malformed source value can stop every valid row without a source-row failure record.
>
> A narrow boundary can catch expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible.

#### New final-contract output

> **RAV-RUN2-R1-F001 [high] failure-accounting** — Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary.
>
> One malformed source value can stop every valid row without a source-row failure record.
>
> Please add a narrow boundary for expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F001 [high] failure-accounting** — Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary. One malformed source value can stop every valid row without a source-row failure record.
+**RAV-RUN2-R1-F001 [high] failure-accounting** — Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary.
 
-A narrow boundary can catch expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible.
+One malformed source value can stop every valid row without a source-row failure record.
+
+Please add a narrow boundary for expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible.
```

### Comment 3737266656 — first-pass

`every_eval_ever/adapters/benchpress/adapter.py` line 253 — https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3737266656

#### Previous skill output

> **RAV-RUN2-R1-F002 [medium] snapshot-provenance** — The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step. A moving branch can resolve differently across four requests, while metadata records only the symbol.
>
> Resolving every supplied reference once would keep branch and tag support while making all file URLs reproducible.

#### New final-contract output

> **RAV-RUN2-R1-F002 [medium] snapshot-provenance** — The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step.
>
> A moving branch can resolve differently across four requests, while metadata records only the symbol.
>
> Please resolve every supplied reference once so branch and tag support remain available and all file URLs are reproducible.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F002 [medium] snapshot-provenance** — The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step. A moving branch can resolve differently across four requests, while metadata records only the symbol.
+**RAV-RUN2-R1-F002 [medium] snapshot-provenance** — The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step.
 
-Resolving every supplied reference once would keep branch and tag support while making all file URLs reproducible.
+A moving branch can resolve differently across four requests, while metadata records only the symbol.
+
+Please resolve every supplied reference once so branch and tag support remain available and all file URLs are reproducible.
```

### Comment 3737266661 — repaired

`every_eval_ever/adapters/benchpress/adapter.py` line 641 — https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3737266661

#### Previous skill output

> **RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.
>
> The shared report already supports exclusions. It can be saved for either collection while the nonzero exit stays conditional on failures.

#### New final-contract output

> **RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty.
>
> An exclusions-only run succeeds but loses each excluded source reference and reason.
>
> Please save the shared report for either collection. The shared report already supports exclusions. The nonzero exit can stay conditional on failures.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.
+**RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty.
 
-The shared report already supports exclusions. It can be saved for either collection while the nonzero exit stays conditional on failures.
+An exclusions-only run succeeds but loses each excluded source reference and reason.
+
+Please save the shared report for either collection. The shared report already supports exclusions. The nonzero exit can stay conditional on failures.
```

## PR #226 — review 4884776714

### Comment 3737291965 — first-pass

`every_eval_ever/validator/validate.py` line 175 — https://github.com/evaleval/every_eval_ever/pull/226#discussion_r3737291965

#### Previous skill output

> **RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target
>
> `Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.
>
> The expansion can reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged. Tests for both directory-symlink inputs and an accepted file symlink would cover the boundary.

#### New final-contract output

> **RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target.
>
> `Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.
>
> **Requested actions**
>
> - Reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged.
> - Add tests for both directory-symlink inputs and an accepted file symlink.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,8 @@
-**RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target
+**RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target.
 
 `Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.
 
-The expansion can reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged. Tests for both directory-symlink inputs and an accepted file symlink would cover the boundary.
+**Requested actions**
+
+- Reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged.
+- Add tests for both directory-symlink inputs and an accepted file symlink.
```

## PR #203 — review 4884885250

### Comment 3737383919 — repaired

`every_eval_ever/adapters/wild/adapter.py` line 678 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3737383919

#### Previous skill output

> **RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.
>
> Requiring one or more values would block the first path. A no-match check can stop before existing-output discovery or publication.

#### New final-contract output

> **RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run.
>
> A nonempty filter with no matches instead exits successfully with zero logs.
>
> **Requested actions**
>
> - Require one or more values for `--models` to block the bare `--models` full-source-run path.
> - Add a no-match check.
>
> The no-match check can stop before existing-output discovery or publication.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,10 @@
-**RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.
+**RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run.
 
-Requiring one or more values would block the first path. A no-match check can stop before existing-output discovery or publication.
+A nonempty filter with no matches instead exits successfully with zero logs.
+
+**Requested actions**
+
+- Require one or more values for `--models` to block the bare `--models` full-source-run path.
+- Add a no-match check.
+
+The no-match check can stop before existing-output discovery or publication.
```

### Comment 3737383922 — first-pass

`every_eval_ever/adapters/wild/adapter.py` line 608 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3737383922

#### Previous skill output

> **RAV-RUN3-R1-F002 [medium] output-path** — The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it. An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.
>
> Early validation of the documented `data/wild` shape would keep lookup, replacement, and status output on one destination.

#### New final-contract output

> **RAV-RUN3-R1-F002 [medium] output-path** — The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it.
>
> An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.
>
> Please validate the documented `data/wild` shape early so lookup, replacement, and status output use one destination.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN3-R1-F002 [medium] output-path** — The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it. An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.
+**RAV-RUN3-R1-F002 [medium] output-path** — The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it.
 
-Early validation of the documented `data/wild` shape would keep lookup, replacement, and status output on one destination.
+An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.
+
+Please validate the documented `data/wild` shape early so lookup, replacement, and status output use one destination.
```

## PR #235 — review 4884964333

### Comment 3737449039 — first-pass

`every_eval_ever/converters/lighteval/adapter.py` line 375 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449039

#### Previous skill output

> **RAV-RUN1-R1-F001 [high] evaluation-identity** — `evaluation_id` includes the current retrieval time. The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.
>
> A stable ID can use the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`.

#### New final-contract output

> **RAV-RUN1-R1-F001 [high] evaluation-identity** — `evaluation_id` includes the current retrieval time.
>
> The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.
>
> Please build a stable ID from the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN1-R1-F001 [high] evaluation-identity** — `evaluation_id` includes the current retrieval time. The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.
+**RAV-RUN1-R1-F001 [high] evaluation-identity** — `evaluation_id` includes the current retrieval time.
 
-A stable ID can use the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`.
+The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.
+
+Please build a stable ID from the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`.
```

### Comment 3737449052 — first-pass

`every_eval_ever/converters/lighteval/adapter.py` line 524 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449052

#### Previous skill output

> **RAV-RUN1-R1-F002 [high] source-accounting** — An input file whose measured tasks all lack finite scores returns an empty list without a failure. A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.
>
> A file with measured but unconvertible tasks can enter the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.

#### New final-contract output

> **RAV-RUN1-R1-F002 [high] source-accounting** — An input file whose measured tasks all lack finite scores returns an empty list without a failure.
>
> A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.
>
> Please add a file with measured but unconvertible tasks to the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN1-R1-F002 [high] source-accounting** — An input file whose measured tasks all lack finite scores returns an empty list without a failure. A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.
+**RAV-RUN1-R1-F002 [high] source-accounting** — An input file whose measured tasks all lack finite scores returns an empty list without a failure.
 
-A file with measured but unconvertible tasks can enter the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.
+A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.
+
+Please add a file with measured but unconvertible tasks to the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.
```

### Comment 3737449059 — first-pass

`every_eval_ever/converters/lighteval/adapter.py` line 201 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449059

#### Previous skill output

> **RAV-RUN1-R1-F004 [medium] score-coverage** — Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`. The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.
>
> Both counts can remain visible, with the effective count identified as score coverage and the original count retained as dataset provenance.

#### New final-contract output

> **RAV-RUN1-R1-F004 [medium] score-coverage** — Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`.
>
> The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.
>
> Please keep both counts visible, identify the effective count as score coverage, and retain the original count as dataset provenance.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN1-R1-F004 [medium] score-coverage** — Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`. The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.
+**RAV-RUN1-R1-F004 [medium] score-coverage** — Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`.
 
-Both counts can remain visible, with the effective count identified as score coverage and the original count retained as dataset provenance.
+The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.
+
+Please keep both counts visible, identify the effective count as score coverage, and retain the original count as dataset provenance.
```

### Comment 3737449070 — repaired

`every_eval_ever/converters/lighteval/adapter.py` line 287 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449070

#### Previous skill output

> **RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.
>
> Source metric specs or an operator-supplied definition can establish the semantics. Unresolved keys can be reported after the valid metrics are preserved.

#### New final-contract output

> **RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds.
>
> A finite custom key does not prove that direction.
>
> **Requested actions**
>
> - Use source metric specs or an operator-supplied definition to establish the semantics.
> - Preserve the valid metrics.
>
> Unresolved keys can be reported after the valid metrics are preserved.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,10 @@
-**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.
+**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds.
 
-Source metric specs or an operator-supplied definition can establish the semantics. Unresolved keys can be reported after the valid metrics are preserved.
+A finite custom key does not prove that direction.
+
+**Requested actions**
+
+- Use source metric specs or an operator-supplied definition to establish the semantics.
+- Preserve the valid metrics.
+
+Unresolved keys can be reported after the valid metrics are preserved.
```

### Comment 3737449081 — repaired

`every_eval_ever/converters/lighteval/adapter.py` line 337 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449081

#### Previous skill output

> **RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.
>
> The same metric-definition mapping used for direction and bounds can supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.

#### New final-contract output

> **RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy.
>
> `metric_name` keeps the source label but does not provide the cross-source join key.
>
> Please use the same metric-definition mapping used for direction and bounds to supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.
+**RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy.
 
-The same metric-definition mapping used for direction and bounds can supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.
+`metric_name` keeps the source label but does not provide the cross-source join key.
+
+Please use the same metric-definition mapping used for direction and bounds to supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.
```

### Comment 3737449090 — first-pass

`every_eval_ever/converters/lighteval/adapter.py` line 538 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449090

#### Previous skill output

> **RAV-RUN1-R1-F007 [medium] coverage-totals** — `total_records` adds task-level output logs to file-level failures. One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.
>
> Results files can remain the source-record grain, with converted output-log count reported separately.

#### New final-contract output

> **RAV-RUN1-R1-F007 [medium] coverage-totals** — `total_records` adds task-level output logs to file-level failures.
>
> One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.
>
> Please keep results files as the source-record grain and report converted output-log count separately.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN1-R1-F007 [medium] coverage-totals** — `total_records` adds task-level output logs to file-level failures. One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.
+**RAV-RUN1-R1-F007 [medium] coverage-totals** — `total_records` adds task-level output logs to file-level failures.
 
-Results files can remain the source-record grain, with converted output-log count reported separately.
+One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.
+
+Please keep results files as the source-record grain and report converted output-log count separately.
```

### Comment 3737449098 — repaired

`every_eval_ever/cli.py` line 234 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449098

#### Previous skill output

> **RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved; directory input reports the same failure class correctly.
>
> A small lighteval-local file-result path can give both entry modes the same report-before-raise behavior.

#### New final-contract output

> **RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`.
>
> Parse or conversion errors exit non-zero, but the structured failure report is never saved. Directory input reports the same failure class correctly.
>
> Please add a small lighteval-local file-result path so both entry modes report before raising.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved; directory input reports the same failure class correctly.
+**RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`.
 
-A small lighteval-local file-result path can give both entry modes the same report-before-raise behavior.
+Parse or conversion errors exit non-zero, but the structured failure report is never saved. Directory input reports the same failure class correctly.
+
+Please add a small lighteval-local file-result path so both entry modes report before raising.
```

### Comment 3737449101 — repaired

`every_eval_ever/converters/lighteval/utils.py` line 284 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449101

#### Previous skill output

> **RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.
>
> One recursive sanitizer for mappings and lists can protect these values before serialization. Tests with provider-prefixed key names would cover the reachable path without recording secret values.

#### New final-contract output

> **RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized.
>
> Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.
>
> **Requested actions**
>
> - Apply one recursive sanitizer to mappings and lists before serialization to protect these values.
> - Add tests with provider-prefixed key names that cover the reachable path without recording secret values.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,8 @@
-**RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.
+**RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized.
 
-One recursive sanitizer for mappings and lists can protect these values before serialization. Tests with provider-prefixed key names would cover the reachable path without recording secret values.
+Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.
+
+**Requested actions**
+
+- Apply one recursive sanitizer to mappings and lists before serialization to protect these values.
+- Add tests with provider-prefixed key names that cover the reachable path without recording secret values.
```

## PR #220 — review 4870784346

### Comment 3725747243 — fallback

`every_eval_ever/converters/sayf_eval/adapter.py` line 364 — https://github.com/evaleval/every_eval_ever/pull/220#discussion_r3725747243

#### Previous skill output

> **RAV-RUN1-R1-F003 [high] record-identity** — `evaluation_id` changes every time the same record is converted
>
> The current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.
>
> A stable source-run timestamp or deterministic token can keep the required ID shape while `retrieved_timestamp` records retrieval time.

#### New final-contract output

> **RAV-RUN1-R1-F003 [high] record-identity** — `evaluation_id` changes every time the same record is converted
>
> The current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.
>
> A stable source-run timestamp or deterministic token can keep the required ID shape while `retrieved_timestamp` records retrieval time.

#### Unified diff

```diff
# Identical: exact-source fallback or no rendering change.
```

### Comment 3725747244 — first-pass

`every_eval_ever/converters/sayf_eval/adapter.py` line 422 — https://github.com/evaleval/every_eval_ever/pull/220#discussion_r3725747244

#### Previous skill output

> **RAV-RUN1-R1-F005 [high] partial-conversion** — One invalid task discards valid sibling task logs
>
> This loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.
>
> A task-level error boundary can preserve valid logs and account for each rejected task.

#### New final-contract output

> **RAV-RUN1-R1-F005 [high] partial-conversion** — One invalid task discards valid sibling task logs.
>
> This loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.
>
> Please add a task-level error boundary that preserves valid logs and accounts for each rejected task.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,5 @@
-**RAV-RUN1-R1-F005 [high] partial-conversion** — One invalid task discards valid sibling task logs
+**RAV-RUN1-R1-F005 [high] partial-conversion** — One invalid task discards valid sibling task logs.
 
 This loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.
 
-A task-level error boundary can preserve valid logs and account for each rejected task.
+Please add a task-level error boundary that preserves valid logs and accounts for each rejected task.
```

### Comment 3725747245 — repaired

`every_eval_ever/converters/sayf_eval/adapter.py` line 164 — https://github.com/evaleval/every_eval_ever/pull/220#discussion_r3725747245

#### Previous skill output

> **RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt
>
> `LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.
>
> The sound aggregate conversion can remain intact if `llm_scoring` is emitted only when the real template is available.

#### New final-contract output

> **RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt.
>
> `LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.
>
> Please emit `llm_scoring` only when the real template is available. The sound aggregate conversion can remain intact when `llm_scoring` is emitted only when the real template is available.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,5 @@
-**RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt
+**RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt.
 
 `LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.
 
-The sound aggregate conversion can remain intact if `llm_scoring` is emitted only when the real template is available.
+Please emit `llm_scoring` only when the real template is available. The sound aggregate conversion can remain intact when `llm_scoring` is emitted only when the real template is available.
```

## PR #227 — review 4870817417

### Comment 3725776269 — first-pass

`every_eval_ever/helpers/io.py` line 413 — https://github.com/evaleval/every_eval_ever/pull/227#discussion_r3725776269

#### Previous skill output

> **RAV-RUN1-R1-F002 [medium] report-placement** — A nested `data` component can keep the report inside an outer datastore tree
>
> The helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.
>
> A note that the nearest `data` ancestor wins, plus this repeated-`data` example, would make the placement limit clear.

#### New final-contract output

> **RAV-RUN1-R1-F002 [medium] report-placement** — A nested `data` component can keep the report inside an outer datastore tree.
>
> The helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.
>
> Please document that the nearest `data` ancestor wins, using the repeated-`data` example to make the placement limit clear.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,5 @@
-**RAV-RUN1-R1-F002 [medium] report-placement** — A nested `data` component can keep the report inside an outer datastore tree
+**RAV-RUN1-R1-F002 [medium] report-placement** — A nested `data` component can keep the report inside an outer datastore tree.
 
 The helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.
 
-A note that the nearest `data` ancestor wins, plus this repeated-`data` example, would make the placement limit clear.
+Please document that the nearest `data` ancestor wins, using the repeated-`data` example to make the placement limit clear.
```

## PR #223 — review 4870878941

### Comment 3725827216 — first-pass

`every_eval_ever/validator/validation_core.py` line 615 — https://github.com/evaleval/every_eval_ever/pull/223#discussion_r3725827216

#### Previous skill output

> **RAV-RUN1-R1-F003 [medium] path-check-ownership** — Other malformed paths can receive both a path error and an identity warning
>
> This guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.
>
> Identity comparison can stop whenever `check_path_structure` already owns a path error.

#### New final-contract output

> **RAV-RUN1-R1-F003 [medium] path-check-ownership** — Other malformed paths can receive both a path error and an identity warning.
>
> This guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.
>
> Please stop identity comparison whenever `check_path_structure` already owns a path error.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,5 @@
-**RAV-RUN1-R1-F003 [medium] path-check-ownership** — Other malformed paths can receive both a path error and an identity warning
+**RAV-RUN1-R1-F003 [medium] path-check-ownership** — Other malformed paths can receive both a path error and an identity warning.
 
 This guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.
 
-Identity comparison can stop whenever `check_path_structure` already owns a path error.
+Please stop identity comparison whenever `check_path_structure` already owns a path error.
```

## PR #230 — review 4870883842

### Comment 3725830951 — first-pass

`every_eval_ever/validator/validation_core.py` line 795 — https://github.com/evaleval/every_eval_ever/pull/230#discussion_r3725830951

#### Previous skill output

> **RAV-RUN1-R1-F004 [medium] contributor-guidance** — The new registered warning is missing from the required datastore gate guide
>
> The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.
>
> A short section can state the alias trigger, warning-only result, and single-record evidence limit.

#### New final-contract output

> **RAV-RUN1-R1-F004 [medium] contributor-guidance** — The new registered warning is missing from the required datastore gate guide.
>
> The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.
>
> Please add a short section that states the alias trigger, warning-only result, and single-record evidence limit.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,5 +1,5 @@
-**RAV-RUN1-R1-F004 [medium] contributor-guidance** — The new registered warning is missing from the required datastore gate guide
+**RAV-RUN1-R1-F004 [medium] contributor-guidance** — The new registered warning is missing from the required datastore gate guide.
 
 The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.
 
-A short section can state the alias trigger, warning-only result, and single-record evidence limit.
+Please add a short section that states the alias trigger, warning-only result, and single-record evidence limit.
```

## PR #190 — review 4870915628

### Comment 3725853148 — first-pass

`every_eval_ever/converters/alpaca_eval/adapter.py` line 976 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853148

#### Previous skill output

> **RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.
>
> Network-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access.

#### New final-contract output

> **RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution.
>
> Two network runs can fetch different input under the same identity.
>
> Please resolve network-mode refs once to a commit SHA. Offline replay can keep the stored immutable ref without network access.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.
+**RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution.
 
-Network-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access.
+Two network runs can fetch different input under the same identity.
+
+Please resolve network-mode refs once to a commit SHA. Offline replay can keep the stored immutable ref without network access.
```

### Comment 3725853152 — first-pass

`every_eval_ever/cli.py` line 392 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853152

#### Previous skill output

> **RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.
>
> The module entry point can use the shared parser, with one offline entry-point test covering its defaults.

#### New final-contract output

> **RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace.
>
> This handler now reads missing fields and fails before conversion.
>
> **Requested actions**
>
> - Use the shared parser in the module entry point.
> - Add one offline entry-point test covering its defaults.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,8 @@
-**RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.
+**RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace.
 
-The module entry point can use the shared parser, with one offline entry-point test covering its defaults.
+This handler now reads missing fields and fails before conversion.
+
+**Requested actions**
+
+- Use the shared parser in the module entry point.
+- Add one offline entry-point test covering its defaults.
```

### Comment 3725853155 — repaired

`every_eval_ever/converters/alpaca_eval/adapter.py` line 307 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853155

#### Previous skill output

> **RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.
>
> Numeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.

#### New final-contract output

> **RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling.
>
> They can omit the headline metric or abort strict JSON publication.
>
> **Requested actions**
>
> - Validate numeric fields as finite values under their metric rules before result construction.
> - Enter invalid rows into `SourceConversionResult`.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,8 @@
-**RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.
+**RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling.
 
-Numeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.
+They can omit the headline metric or abort strict JSON publication.
+
+**Requested actions**
+
+- Validate numeric fields as finite values under their metric rules before result construction.
+- Enter invalid rows into `SourceConversionResult`.
```

### Comment 3725853159 — repaired

`every_eval_ever/converters/alpaca_eval/adapter.py` line 643 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853159

#### Previous skill output

> **RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.
>
> New snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.

#### New final-contract output

> **RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content.
>
> Offline records cannot reconstruct the generation prompt.
>
> **Requested actions**
>
> - Store pinned prompt content in new snapshots.
> - Leave this typed value unset for legacy snapshots.
> - Mark the missing content for legacy snapshots.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,9 @@
-**RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.
+**RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content.
 
-New snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.
+Offline records cannot reconstruct the generation prompt.
+
+**Requested actions**
+
+- Store pinned prompt content in new snapshots.
+- Leave this typed value unset for legacy snapshots.
+- Mark the missing content for legacy snapshots.
```

### Comment 3725853163 — first-pass

`every_eval_ever/helpers/eval_card_registry.py` line 251 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853163

#### Previous skill output

> **RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.
>
> Live mode can query present-null entries while offline behavior remains unchanged.

#### New final-contract output

> **RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null.
>
> A known gap cannot discover a new registry entry until the snapshot refreshes.
>
> Please make live mode query present-null entries. Offline behavior can remain unchanged.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.
+**RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null.
 
-Live mode can query present-null entries while offline behavior remains unchanged.
+A known gap cannot discover a new registry entry until the snapshot refreshes.
+
+Please make live mode query present-null entries. Offline behavior can remain unchanged.
```

### Comment 3725853168 — repaired

`every_eval_ever/tools/refresh_eval_card_registry.py` line 151 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853168

#### Previous skill output

> **RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.
>
> Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.

#### New final-contract output

> **RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.
>
> **Requested actions**
>
> - Make exact canonical IDs win first.
> - Resolve normalized spellings only when one organization owns them.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,6 @@
 **RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.
 
-Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.
+**Requested actions**
+
+- Make exact canonical IDs win first.
+- Resolve normalized spellings only when one organization owns them.
```

## PR #203 — review 4871030385

### Comment 3725913004 — repaired

`utils/wild/adapter.py` line 528 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913004

#### Previous skill output

> **RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.
>
> Complete output can stage before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.

#### New final-contract output

> **RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path.
>
> Construction fails after aggregate and sidecar files are written.
>
> Please stage complete output before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.
+**RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path.
 
-Complete output can stage before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.
+Construction fails after aggregate and sidecar files are written.
+
+Please stage complete output before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.
```

### Comment 3725913007 — first-pass

`utils/wild/README.md` line 32 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913007

#### Previous skill output

> **RAV-RUN2-R1-F002 [medium] documentation** — This smoke command passes a directory to a file-only validator. Its output root also cannot satisfy datastore path checks.
>
> Smoke output can use the required `data/<collection>` path, and validation can receive a quoted fixed-depth file glob.

#### New final-contract output

> **RAV-RUN2-R1-F002 [medium] documentation** — This smoke command passes a directory to a file-only validator.
>
> Its output root also cannot satisfy datastore path checks.
>
> **Requested actions**
>
> - Use the required `data/<collection>` path for smoke output.
> - Pass a quoted fixed-depth file glob to validation.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,8 @@
-**RAV-RUN2-R1-F002 [medium] documentation** — This smoke command passes a directory to a file-only validator. Its output root also cannot satisfy datastore path checks.
+**RAV-RUN2-R1-F002 [medium] documentation** — This smoke command passes a directory to a file-only validator.
 
-Smoke output can use the required `data/<collection>` path, and validation can receive a quoted fixed-depth file glob.
+Its output root also cannot satisfy datastore path checks.
+
+**Requested actions**
+
+- Use the required `data/<collection>` path for smoke output.
+- Pass a quoted fixed-depth file glob to validation.
```

### Comment 3725913013 — first-pass

`utils/wild/adapter.py` line 157 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913013

#### Previous skill output

> **RAV-RUN2-R1-F004 [medium] data-validation** — Missing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted.
>
> Invalid scores can enter the failure report. Incomplete token usage can be omitted, with token means based only on complete values.

#### New final-contract output

> **RAV-RUN2-R1-F004 [medium] data-validation** — Missing scores become incorrect answers and stay in aggregate denominators.
>
> Missing token data becomes measured zero instead of being omitted.
>
> **Requested actions**
>
> - Put invalid scores in the failure report.
> - Omit incomplete token usage and base token means only on complete values.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,8 @@
-**RAV-RUN2-R1-F004 [medium] data-validation** — Missing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted.
+**RAV-RUN2-R1-F004 [medium] data-validation** — Missing scores become incorrect answers and stay in aggregate denominators.
 
-Invalid scores can enter the failure report. Incomplete token usage can be omitted, with token means based only on complete values.
+Missing token data becomes measured zero instead of being omitted.
+
+**Requested actions**
+
+- Put invalid scores in the failure report.
+- Omit incomplete token usage and base token means only on complete values.
```

### Comment 3725913015 — first-pass

`utils/wild/adapter.py` line 210 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913015

#### Previous skill output

> **RAV-RUN2-R1-F005 [medium] metric-identity** — Each task receives a different metric ID even though every result is canonical accuracy. Cross-source joins by metric ID become fragmented.
>
> `accuracy` can remain the metric ID while `evaluation_name` distinguishes tasks.

#### New final-contract output

> **RAV-RUN2-R1-F005 [medium] metric-identity** — Each task receives a different metric ID even though every result is canonical accuracy.
>
> Cross-source joins by metric ID become fragmented.
>
> Please keep `accuracy` as the metric ID and use `evaluation_name` to distinguish tasks.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F005 [medium] metric-identity** — Each task receives a different metric ID even though every result is canonical accuracy. Cross-source joins by metric ID become fragmented.
+**RAV-RUN2-R1-F005 [medium] metric-identity** — Each task receives a different metric ID even though every result is canonical accuracy.
 
-`accuracy` can remain the metric ID while `evaluation_name` distinguishes tasks.
+Cross-source joins by metric ID become fragmented.
+
+Please keep `accuracy` as the metric ID and use `evaluation_name` to distinguish tasks.
```

### Comment 3725913021 — first-pass

`utils/wild/adapter.py` line 546 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913021

#### Previous skill output

> **RAV-RUN2-R1-F011 [medium] cli** — A bare `--parquet` flag yields an empty list. The adapter treats that as no local input and silently starts the full remote 15-shard conversion.
>
> The option can require at least one path.

#### New final-contract output

> **RAV-RUN2-R1-F011 [medium] cli** — A bare `--parquet` flag yields an empty list.
>
> The adapter treats that as no local input and silently starts the full remote 15-shard conversion.
>
> Please require at least one path for the option.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F011 [medium] cli** — A bare `--parquet` flag yields an empty list. The adapter treats that as no local input and silently starts the full remote 15-shard conversion.
+**RAV-RUN2-R1-F011 [medium] cli** — A bare `--parquet` flag yields an empty list.
 
-The option can require at least one path.
+The adapter treats that as no local input and silently starts the full remote 15-shard conversion.
+
+Please require at least one path for the option.
```

## PR #204 — review 4871126847

### Comment 3725972277 — first-pass

`utils/open_medical_llm/adapter.py` line 12 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3725972277

#### Previous skill output

> **RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.
>
> Current main can be integrated before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`.

#### New final-contract output

> **RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout.
>
> Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.
>
> Please integrate current main before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.
+**RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout.
 
-Current main can be integrated before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`.
+Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.
+
+Please integrate current main before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`.
```

### Comment 3725972282 — first-pass

`tests/test_open_medical_llm_adapter.py` line 26 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3725972282

#### Previous skill output

> **RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.
>
> The expected value can come from the imported schema version.

#### New final-contract output

> **RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`.
>
> The test fails after integration.
>
> Please take the expected value from the imported schema version.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.
+**RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`.
 
-The expected value can come from the imported schema version.
+The test fails after integration.
+
+Please take the expected value from the imported schema version.
```

### Comment 3725972285 — first-pass

`utils/open_medical_llm/adapter.py` line 274 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3725972285

#### Previous skill output

> **RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.
>
> `accuracy` can remain the metric ID while task-specific evaluation names preserve benchmark identity.

#### New final-contract output

> **RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs.
>
> This fragments the global accuracy join key.
>
> Please keep `accuracy` as the metric ID and use task-specific evaluation names to preserve benchmark identity.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.
+**RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs.
 
-`accuracy` can remain the metric ID while task-specific evaluation names preserve benchmark identity.
+This fragments the global accuracy join key.
+
+Please keep `accuracy` as the metric ID and use task-specific evaluation names to preserve benchmark identity.
```

### Comment 3725972287 — first-pass

`utils/open_medical_llm/adapter.py` line 444 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3725972287

#### Previous skill output

> **RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.
>
> The collection target can reject existing output JSON before UUID generation or batch publication.

#### New final-contract output

> **RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID.
>
> A populated target can hold duplicate logical records.
>
> Please reject existing output JSON in the collection target before UUID generation or batch publication.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.
+**RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID.
 
-The collection target can reject existing output JSON before UUID generation or batch publication.
+A populated target can hold duplicate logical records.
+
+Please reject existing output JSON in the collection target before UUID generation or batch publication.
```

## PR #209 — review 4871239031

### Comment 3726043665 — repaired

`utils/paperswithcode/adapter.py` line 1693 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043665

#### Previous skill output

> **RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.
>
> New or empty targets can use the batch publisher. Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.

#### New final-contract output

> **RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication.
>
> Empty batches and later write failures can destroy prior or unrelated data.
>
> Please use the batch publisher for new or empty targets. Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.
+**RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication.
 
-New or empty targets can use the batch publisher. Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.
+Empty batches and later write failures can destroy prior or unrelated data.
+
+Please use the batch publisher for new or empty targets. Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.
```

### Comment 3726043671 — first-pass

`every_eval_ever/adapters/paperswithcode/adapter.py` line 925 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043671

#### Previous skill output

> **RAV-RUN2-R1-F002 [high] conversion-accounting** — Malformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output.
>
> Metric cells can be the source unit. Each attempted or rejected cell can count once, while malformed objects and missing datasets retain row references.

#### New final-contract output

> **RAV-RUN2-R1-F002 [high] conversion-accounting** — Malformed metrics, missing dataset references, and resultless rows are silently omitted.
>
> The command can exit successfully with incomplete output.
>
> Please use metric cells as the source unit. Count each attempted or rejected cell once, and retain row references for malformed objects and missing datasets.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F002 [high] conversion-accounting** — Malformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output.
+**RAV-RUN2-R1-F002 [high] conversion-accounting** — Malformed metrics, missing dataset references, and resultless rows are silently omitted.
 
-Metric cells can be the source unit. Each attempted or rejected cell can count once, while malformed objects and missing datasets retain row references.
+The command can exit successfully with incomplete output.
+
+Please use metric cells as the source unit. Count each attempted or rejected cell once, and retain row references for malformed objects and missing datasets.
```

### Comment 3726043679 — first-pass

`every_eval_ever/adapters/paperswithcode/adapter.py` line 356 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043679

#### Previous skill output

> **RAV-RUN2-R1-F004 [medium] score-bounds** — Scale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores.
>
> Tolerance can support scale classification only. A strict pre-publication check can reject unproven overruns.

#### New final-contract output

> **RAV-RUN2-R1-F004 [medium] score-bounds** — Scale tolerance accepts small boundary overruns but emits them unchanged.
>
> Current semantic validation rejects those scores.
>
> Please use tolerance only for scale classification and add a strict pre-publication check that rejects unproven overruns.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F004 [medium] score-bounds** — Scale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores.
+**RAV-RUN2-R1-F004 [medium] score-bounds** — Scale tolerance accepts small boundary overruns but emits them unchanged.
 
-Tolerance can support scale classification only. A strict pre-publication check can reject unproven overruns.
+Current semantic validation rejects those scores.
+
+Please use tolerance only for scale classification and add a strict pre-publication check that rejects unproven overruns.
```

### Comment 3726043682 — first-pass

`utils/paperswithcode/adapter.py` line 830 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043682

#### Previous skill output

> **RAV-RUN2-R1-F005 [medium] metric-metadata** — `metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds.
>
> A unit can be set only when the canonical contract or an explicit conversion proves it. Otherwise it can stay unset while `pwc_scale` remains in details.

#### New final-contract output

> **RAV-RUN2-R1-F005 [medium] metric-metadata** — `metric_unit` stays tied to the PwC source scale after score conversion.
>
> It can conflict with the emitted score and canonical bounds.
>
> Please set a unit only when the canonical contract or an explicit conversion proves it. Otherwise, leave it unset while `pwc_scale` remains in details.

#### Unified diff

```diff
--- previous
+++ new
@@ -1,3 +1,5 @@
-**RAV-RUN2-R1-F005 [medium] metric-metadata** — `metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds.
+**RAV-RUN2-R1-F005 [medium] metric-metadata** — `metric_unit` stays tied to the PwC source scale after score conversion.
 
-A unit can be set only when the canonical contract or an explicit conversion proves it. Otherwise it can stay unset while `pwc_scale` remains in details.
+It can conflict with the emitted score and canonical bounds.
+
+Please set a unit only when the canonical contract or an explicit conversion proves it. Otherwise, leave it unset while `pwc_scale` remains in details.
```
