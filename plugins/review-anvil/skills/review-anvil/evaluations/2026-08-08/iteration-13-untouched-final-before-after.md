# Untouched final corpus — before/after inline comments

This 25-comment corpus was frozen after the renderer contract was locked. It contains 24 untouched historical comments from `evaleval/every_eval_ever` selected by a predeclared hash rule and 1 public cross-repository comment from `dotnet/sign`. The earlier 31-comment iteration-13 corpus is tuning evidence, not a holdout, because its title-splitting rule changed after first output inspection.

**Top-level review artifacts:** unavailable for this comment-sampled final gate. The benchmark captured source inline comments only and generated inline rewrites only; no top-level readability claim is made.

After behavior-based readjudication of one evaluator’s modal-grammar failures, 4 comments use the exact-source fail-safe and 21 retain a behavior-audited rewrite.

## dotnet/sign PR #1035 — comment 3525225568 — sol

`src/Sign.Cli/TrustedSigningCommand.cs` line 108 — https://github.com/dotnet/sign/pull/1035#discussion_r3525225568

### Before

> I personally think it would make more sense to make it a specific option for this command and execute it after this handle command?

### After

> Please make this a specific option for this command and execute it after this handle command; I personally think that would make more sense.

## evaleval/every_eval_ever PR #11 — comment 2614980077 — luna

`scripts/json_to_parquet.py` line 157 — https://github.com/evaleval/every_eval_ever/pull/11#discussion_r2614980077

### Before

> The error message "No new files to add, keeping existing X file(s)" uses "file(s)" which is ambiguous in this context. Since this is counting rows in the parquet file (each row represents a JSON file), consider clarifying the message to say "No new rows to add, keeping existing X row(s)" or "No new entries to add" to better reflect what's being counted.
> ```suggestion
>         print(f"No new rows to add, keeping existing {len(existing_df)} row(s)")
> ```

### After

> The error message `No new files to add, keeping existing X file(s)` uses `file(s)`, which is ambiguous here because this counts rows in the parquet file, with each row representing a JSON file. Please clarify the message to say `No new rows to add, keeping existing X row(s)` or `No new entries to add`.

## evaleval/every_eval_ever PR #11 — comment 2614980178 — sol

`scripts/convert_to_parquet.py` line 156 — https://github.com/evaleval/every_eval_ever/pull/11#discussion_r2614980178

### Before

> The manifest is created even when there are no changes (empty "modified" list). While this is handled correctly by the upload script, consider adding a comment explaining why an empty manifest is still created (likely for debugging or workflow clarity purposes).
> ```suggestion
>         print("No changes detected, nothing to upload")
>         # Always create and write an (empty) manifest file, even when there are no changes.
>         # This ensures downstream scripts have a consistent file to read, and aids in debugging/workflow clarity.
> ```

### After

> The manifest is created even when `modified` is empty. The upload script handles this correctly, but the reason for keeping an empty manifest is not documented. Please add a comment explaining why the empty manifest is still written, including that it gives downstream scripts a consistent file to read and likely aids debugging or workflow clarity.

## evaleval/every_eval_ever PR #69 — comment 2952666730 — exact-source fallback

`README.md` line 149 — https://github.com/evaleval/every_eval_ever/pull/69#discussion_r2952666730

### Before

> The README now states validation uses generated Pydantic models, but the repo’s pre-commit hook still runs `utils/validate_data.py` with `jsonschema` against `eval.schema.json` (see `.pre-commit-config.yaml`). This makes the documentation misleading about what runs automatically on commit/CI. Either update the pre-commit hook to call `validate.py` (and handle JSONL) or clarify in this section that `validate.py` is an optional/manual (or separate CI) validator while pre-commit remains JSON Schema-based.

### After

> The README now states validation uses generated Pydantic models, but the repo’s pre-commit hook still runs `utils/validate_data.py` with `jsonschema` against `eval.schema.json` (see `.pre-commit-config.yaml`). This makes the documentation misleading about what runs automatically on commit/CI. Either update the pre-commit hook to call `validate.py` (and handle JSONL) or clarify in this section that `validate.py` is an optional/manual (or separate CI) validator while pre-commit remains JSON Schema-based.

## evaleval/every_eval_ever PR #69 — comment 2952666872 — luna

`post_codegen.py` line 142 — https://github.com/evaleval/every_eval_ever/pull/69#discussion_r2952666872

### Before

> `apply_discriminator_patch()` treats the file as "already patched" if the substring `"Discriminator"` appears anywhere in the file. That check is overly broad and could skip patching when `Discriminator` is present for unrelated reasons, leaving `source_data` unpatched. Check for the specific patched field signature (or for `target_line` absence/presence) instead of a global substring match.

### After

> `apply_discriminator_patch()` treats the file as already patched if the substring `"Discriminator"` appears anywhere in the file. This check is overly broad and could skip patching when `Discriminator` is present for unrelated reasons, leaving `source_data` unpatched. Please check for the specific patched field signature or for `target_line` absence/presence instead of using a global substring match.

## evaleval/every_eval_ever PR #107 — comment 3088978085 — exact-source fallback

`every_eval_ever/converters/README.md` line 271 — https://github.com/evaleval/every_eval_ever/pull/107#discussion_r3088978085

### Before

> The metrics table markup has extra leading pipes ("|| Metric"), which breaks Markdown table rendering. Also, in the sample argument list the --output_dir option is missing its argument placeholder (it should show something like "--output_dir OUTPUT_DIR"). Please fix the table and the argument list snippet so the rendered docs match actual CLI usage.
> ```suggestion
>   --version {v1,v2}            Which leaderboard to convert. Omit to convert both (default).
>   --output_dir OUTPUT_DIR      Base output directory (default: data).
> ```

### After

> The metrics table markup has extra leading pipes ("|| Metric"), which breaks Markdown table rendering. Also, in the sample argument list the --output_dir option is missing its argument placeholder (it should show something like "--output_dir OUTPUT_DIR"). Please fix the table and the argument list snippet so the rendered docs match actual CLI usage.
> ```suggestion
>   --version {v1,v2}            Which leaderboard to convert. Omit to convert both (default).
>   --output_dir OUTPUT_DIR      Base output directory (default: data).
> ```

## evaleval/every_eval_ever PR #109 — comment 3096650221 — exact-source fallback

`every_eval_ever/helpers/eee_stats.py` line 259 — https://github.com/evaleval/every_eval_ever/pull/109#discussion_r3096650221

### Before

> **N+1 loading.** For each URL you run a `DESCRIBE` then an `INSERT ... SELECT`. DuckDB's `read_parquet(urls, union_by_name=true, filename=true)` handles missing columns across a heterogeneous list in one call — you already rely on this a few lines up for schemas. If the strict `NOT NULL` typing on `{table}_instances` is the reason you can't use the fast path, a one-line comment explaining that would help future readers. Otherwise replace the loop with a single `INSERT ... SELECT ... FROM read_parquet(?, union_by_name=true, filename=true)` passing the full `instance_urls` list.

### After

> **N+1 loading.** For each URL you run a `DESCRIBE` then an `INSERT ... SELECT`. DuckDB's `read_parquet(urls, union_by_name=true, filename=true)` handles missing columns across a heterogeneous list in one call — you already rely on this a few lines up for schemas. If the strict `NOT NULL` typing on `{table}_instances` is the reason you can't use the fast path, a one-line comment explaining that would help future readers. Otherwise replace the loop with a single `INSERT ... SELECT ... FROM read_parquet(?, union_by_name=true, filename=true)` passing the full `instance_urls` list.

## evaleval/every_eval_ever PR #103 — comment 3102848524 — repair

`tests/test_check_duplicate_entries.py` line 95 — https://github.com/evaleval/every_eval_ever/pull/103#discussion_r3102848524

### Before

> For the `.txt` path case, the test matches the same 'Could not find file or directory' message used for missing paths. That message is a bit misleading for an existing-but-unsupported file, and matching on it makes the intent (unsupported extension rejection) less clear. Consider either asserting only that an exception is raised for non-JSON files, or (longer-term) updating `expand_paths` to raise a distinct exception/message for unsupported extensions.
> ```suggestion
>
>     with pytest.raises(Exception):
> ```

### After

> For the existing `.txt` path, the test matches the same "Could not find file or directory" message used for missing paths. That message is a bit misleading for an existing but unsupported file, and matching it obscures that the test covers unsupported-extension rejection. Please either assert only that non-JSON files raise an exception, or, as a longer-term change, make `expand_paths` raise a distinct exception or message for unsupported extensions.

## evaleval/every_eval_ever PR #114 — comment 3134292915 — luna

`utils/hal/adapter.py` line 254 — https://github.com/evaleval/every_eval_ever/pull/114#discussion_r3134292915

### Before

> `MODEL_DEVELOPER_MAP` maps `qwen` → `alibaba`, but other adapters in this repo use `qwen` as the developer slug (e.g. `utils/arc_agi/adapter.py` and `utils/sciarena/adapter.py`). This will make HAL exports inconsistent with the rest of the dataset and may split Qwen models across two developer directories depending on whether `MODEL_ID_OVERRIDES` fires. Consider using `qwen` here (or otherwise aligning the mapping + overrides so the developer slug is consistent).
> ```suggestion
>     # Qwen
>     "qwen": "qwen",
> ```

### After

> `MODEL_DEVELOPER_MAP` maps `qwen` → `alibaba`, while other adapters use `qwen` as the developer slug, including `utils/arc_agi/adapter.py` and `utils/sciarena/adapter.py`. This will make HAL exports inconsistent with the rest of the dataset and may split Qwen models across two developer directories depending on whether `MODEL_ID_OVERRIDES` fires. Please use `qwen` here, or otherwise align the mapping and overrides so the developer slug is consistent.

## evaleval/every_eval_ever PR #116 — comment 3153765816 — luna

`every_eval_ever/converters/helm/instance_level_adapter.py` line 52 — https://github.com/evaleval/every_eval_ever/pull/116#discussion_r3153765816

### Before

> The constructor parameter is misspelled as `evaulation_id`. This is easy to miss and prevents using this adapter with keyword arguments (e.g. `evaluation_id=...`). Rename it to `evaluation_id` throughout the signature/assignments and update any call sites accordingly.

### After

> The constructor parameter is misspelled as `evaulation_id`, which is easy to miss and prevents using this adapter with keyword arguments such as `evaluation_id=...`. Please rename it to `evaluation_id` throughout the signature and assignments, and update all call sites accordingly.

## evaleval/every_eval_ever PR #121 — comment 3161743720 — repair

`every_eval_ever/helpers/eee_stats.py` line 442 — https://github.com/evaleval/every_eval_ever/pull/121#discussion_r3161743720

### Before

> nit: could we build this title and filename (line 448) from `top_n`, e.g. `f'Top {top_n} Benchmarks by Number of Models'` and `f'top{top_n}_benchmarks_by_models.png'`? That way the plot stays accurate when someone runs the CLI with `--top-n 3` or another value, instead of hardcoding `Top 10`.

### After

> Nit: The plot title and filename are hardcoded to `Top 10`, including the filename on line 448. This makes the plot inaccurate when the CLI runs with `--top-n 3` or another value. Please build the title and filename from `top_n`, for example `f'Top {top_n} Benchmarks by Number of Models'` and `f'top{top_n}_benchmarks_by_models.png'`.

## evaleval/every_eval_ever PR #121 — comment 3161807141 — luna

`every_eval_ever/helpers/eee_stats.py` line 357 — https://github.com/evaleval/every_eval_ever/pull/121#discussion_r3161807141

### Before

> Is this file meant to be run only as a CLI script? If yes, ignore this comment. If not, we should pass `viz_dir` and `top_n` directly into `create_visualisations()`, because the function currently depends on `main()` setting those values first and would crash if someone imports and calls it directly.

### After

> `create_visualisations()` currently depends on `main()` setting `viz_dir` and `top_n` first, so importing the module and calling the function directly would crash. Please pass `viz_dir` and `top_n` directly into `create_visualisations()` if this file is not meant to run only as a CLI script; if it is CLI-only, no change is needed.

## evaleval/every_eval_ever PR #194 — comment 3493867085 — exact-source fallback

`every_eval_ever/dedup.py` line 155 — https://github.com/evaleval/every_eval_ever/pull/194#discussion_r3493867085

### Before

> This might end up being a bottleneck. It may be worth it to abstract the specific json reader / writer so the stdlib json is always an option, but you can opt-in to something like `orjson` or `ujson`. (Note: orjson is a bit opinionated. It's fast, but it also means you can't serialize generic floats like nans or infs, which technically isn't json, but the stdlib and ujson aren't so strict about it).
>
> I've handled this in a few ways in the past: simple wrappers: https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391
>
> And module level globals: https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117

### After

> This might end up being a bottleneck. It may be worth it to abstract the specific json reader / writer so the stdlib json is always an option, but you can opt-in to something like `orjson` or `ujson`. (Note: orjson is a bit opinionated. It's fast, but it also means you can't serialize generic floats like nans or infs, which technically isn't json, but the stdlib and ujson aren't so strict about it).
>
> I've handled this in a few ways in the past: simple wrappers: https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391
>
> And module level globals: https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117

## evaleval/every_eval_ever PR #184 — comment 3520340907 — luna

`utils/scripts/run_adapters.py` line 99 — https://github.com/evaleval/every_eval_ever/pull/184#discussion_r3520340907

### Before

> Is this path intentional? We write the file as `data/adapter_stats.json` below, but read `adapter_stats.json` from the repository root here. Also, this reads from the default branch while the upload creates a PR, so I’m not sure the state from one run will be available to the next one.

### After

> The file is written as `data/adapter_stats.json` below, but this code reads `adapter_stats.json` from the repository root. It also reads from the default branch while the upload creates a PR, so the state from one run may not be available to the next. Please confirm whether this path and branch behavior is intentional.

## evaleval/every_eval_ever PR #194 — comment 3652735574 — luna

`utils/cocoabench/adapter.py` line 344 — https://github.com/evaleval/every_eval_ever/pull/194#discussion_r3652735574

### Before

> Was this rename a workaround for `check_integer_counts()` rejecting stringified `samples_number` in `additional_details`? If the walk is fixed to skip `additional_details` (see my comment on `validation_core.py`), this could keep the conventional key name.

### After

> Was this rename a workaround for `check_integer_counts()` rejecting stringified `samples_number` in `additional_details`? If the walk is fixed to skip `additional_details` as discussed for `validation_core.py`, the conventional key name could be kept.

## evaleval/every_eval_ever PR #136 — comment 3653129512 — sol

`utils/llm_stats/adapter.py` line 902 — https://github.com/evaleval/every_eval_ever/pull/136#discussion_r3653129512

### Before

> ```suggestion
>     parsed = urlparse(urls[0])
>     host = (parsed.hostname or '').removeprefix('www.')
>     path_parts = [part for part in parsed.path.split('/') if part]
>     if host in {'x.com', 'twitter.com'} and path_parts:
>         return normalize_slug(path_parts[0])
>
>     # On hosting platforms the organization is the account that owns the
>     # content, not the platform, so read it from the URL instead of the
>     # domain. Editorial and paper URLs carry no account, so infer nothing.
>     if host in {'github.com', 'gist.github.com', 'raw.githubusercontent.com'}:
>         return normalize_slug(path_parts[0]) if path_parts else None
>     if host == 'huggingface.co':
>         if not path_parts or path_parts[0] in {
>             'blog',
>             'papers',
>             'posts',
>             'collections',
>             'docs',
>         }:
>             return None
>         if path_parts[0] in {'datasets', 'spaces'}:
>             if len(path_parts) > 1:
>                 return normalize_slug(path_parts[1])
>             return None
>         return normalize_slug(path_parts[0])
>     if host.endswith('.github.io'):
>         owner = host.removesuffix('.github.io')
>         return normalize_slug(owner) if owner else None
>     if host == 'arxiv.org':
>         return None
> ```

### After

> On hosting platforms, the organization is the account that owns the content rather than the platform. Editorial and paper URLs carry no account, so they should infer nothing. Please infer the organization from `urls[0]` using these host and path rules.
>
> ```suggestion
>     parsed = urlparse(urls[0])
>     host = (parsed.hostname or '').removeprefix('www.')
>     path_parts = [part for part in parsed.path.split('/') if part]
>     if host in {'x.com', 'twitter.com'} and path_parts:
>         return normalize_slug(path_parts[0])
>
>     # On hosting platforms the organization is the account that owns the
>     # content, not the platform, so read it from the URL instead of the
>     # domain. Editorial and paper URLs carry no account, so infer nothing.
>     if host in {'github.com', 'gist.github.com', 'raw.githubusercontent.com'}:
>         return normalize_slug(path_parts[0]) if path_parts else None
>     if host == 'huggingface.co':
>         if not path_parts or path_parts[0] in {
>             'blog',
>             'papers',
>             'posts',
>             'collections',
>             'docs',
>         }:
>             return None
>         if path_parts[0] in {'datasets', 'spaces'}:
>             if len(path_parts) > 1:
>                 return normalize_slug(path_parts[1])
>             return None
>         return normalize_slug(path_parts[0])
>     if host.endswith('.github.io'):
>         owner = host.removesuffix('.github.io')
>         return normalize_slug(owner) if owner else None
>     if host == 'arxiv.org':
>         return None
> ```

## evaleval/every_eval_ever PR #203 — comment 3677101235 — luna

`utils/wild/adapter.py` line 473 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3677101235

### Before

> **[medium] repeat runs** — Reusing an output directory creates duplicate logical evaluations
>
> `save_evaluation_log()` creates a new UUID filename on every call. Instance mode also creates another full sidecar. Stable `evaluation_id` values therefore do not make the filesystem output idempotent.
>
> An adapter-owned aggregate and sidecar can be replaced as one set. The sidecar needs a fresh write because its current append mode would otherwise duplicate rows.

### After

> **[medium] repeat runs** — `save_evaluation_log()` creates a new UUID filename on every call, and instance mode also creates another full sidecar. Stable `evaluation_id` values therefore do not make filesystem output idempotent, so reusing an output directory creates duplicate logical evaluations. Please replace the adapter-owned aggregate and sidecar as one set, writing the sidecar afresh because its current append mode would otherwise duplicate rows.

## evaleval/every_eval_ever PR #133 — comment 3677104436 — sol

`every_eval_ever/validate.py` line 437 — https://github.com/evaleval/every_eval_ever/pull/133#discussion_r3677104436

### Before

> **[medium] duplicate variants** — Explicit-file validation cannot see compressed siblings
>
> `expand_paths()` returns only the named file, and this call checks that limited list. `abc.json.gz` can therefore escape the one-variant rule when the caller names only `abc.json`.
>
> Collision discovery can inspect same-parent, same-stem variants while payload validation stays limited to requested files.

### After

> **[medium] duplicate variants** — Explicit-file validation cannot see compressed siblings
>
> `expand_paths()` returns only the named file, and this call checks only that limited list. When the caller names only `abc.json`, `abc.json.gz` can therefore escape the one-variant rule. Please make collision discovery inspect same-parent, same-stem variants while keeping payload validation limited to the requested files.

## evaleval/every_eval_ever PR #137 — comment 3677218975 — luna

`every_eval_ever/schemas/instance_level_eval.schema.json` line 50 — https://github.com/evaleval/every_eval_ever/pull/137#discussion_r3677218975

### Before

> **[high] schema versioning** — New instance records keep `instance_level_eval_0.2.2`, although the existing 0.2.2 model rejects `modality` and null `is_correct`. The old aggregate model also discards the new modality under its unchanged identifier.
>
> The extension is well scoped; its schema copies, emitters, models, fixtures, tests, and current-version docs can move to new identifiers together.

### After

> **[high] schema versioning** — New instance records keep `instance_level_eval_0.2.2`, although the existing 0.2.2 model rejects `modality` and null `is_correct`. The old aggregate model also discards the new modality under its unchanged identifier. The extension is well scoped. Please move its schema copies, emitters, models, fixtures, tests, and current-version docs to new identifiers together.

## evaleval/every_eval_ever PR #190 — comment 3677354603 — luna

`utils/alpaca_eval/adapter.py` line 315 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3677354603

### Before

> **[medium] error handling** — A handled fetch, conversion, or write failure reaches the final `Done!` message and exits with status 0. Automation can treat a partial dataset as complete.
>
> If this entry point keeps independent work, both outcomes can feed a final status that `__main__` propagates. Delegation may remove this duplicate path.

### After

> **[medium] error handling** — A handled fetch, conversion, or write failure reaches the final `Done!` message and exits with status 0. Automation can therefore treat a partial dataset as complete. Please feed both outcomes into a final status that `__main__` propagates if this entry point keeps independent work. Delegation may remove this duplicate path.

## evaleval/every_eval_ever PR #191 — comment 3677461204 — luna

`utils/kaggle/adapter.py` line 496 — https://github.com/evaleval/every_eval_ever/pull/191#discussion_r3677461204

### Before

> **[medium] error isolation** — Pydantic `ValidationError` is outside this catch tuple. One malformed benchmark can stop all later targets instead of joining the final partial-run report.
>
> That error can stay inside the per-benchmark boundary while the adapter continues with later work.

### After

> **[medium] error isolation** — Pydantic `ValidationError` is outside this catch tuple. One malformed benchmark can stop all later targets instead of joining the final partial-run report. Please keep that error inside the per-benchmark boundary so the adapter continues with later work.

## evaleval/every_eval_ever PR #192 — comment 3677564751 — luna

`utils/tau_bench/adapter.py` line 596 — https://github.com/evaleval/every_eval_ever/pull/192#discussion_r3677564751

### Before

> **[medium] score validation** — Supported replay input can emit values outside the source contract
>
> `float()` accepts booleans, NaN, infinity, Pass^k values outside 0–100, and negative costs. Current official submissions are valid, but local replay and custom sources can reach this path.
>
> Pass metrics can use finite inclusive 0–100 checks. Cost can use a finite non-negative check, with booleans rejected before numeric conversion.

### After

> **[medium] score validation** — Supported replay input can emit values outside the source contract. `float()` accepts booleans, NaN, infinity, Pass^k values outside 0–100, and negative costs. Current official submissions are valid, but local replay and custom sources can reach this path. Please validate pass metrics as finite values in the inclusive 0–100 range and cost as finite and non-negative, rejecting booleans before numeric conversion.

## evaleval/every_eval_ever PR #207 — comment 3677669726 — luna

`every_eval_ever/eval_types.py` line 472 — https://github.com/evaleval/every_eval_ever/pull/207#discussion_r3677669726

### Before

> **[medium] Pydantic schema** — The serialization schema excludes emitted sentinel strings
>
> This serializer has no declared output union. Pydantic therefore describes the bound as number or null, although `model_dump_json()` can emit `"Infinity"` or `"-Infinity"`.
>
> Each bound can expose an accurate serialization contract for finite numbers, null, and its field-valid sentinel.

### After

> **[medium] Pydantic schema** — The serialization schema excludes emitted sentinel strings. This serializer has no declared output union, so Pydantic describes the bound as number or null even though `model_dump_json()` can emit `"Infinity"` or `"-Infinity"`. Please expose an accurate serialization contract for each bound covering finite numbers, null, and its field-valid sentinel.

## evaleval/every_eval_ever PR #197 — comment 3677713059 — luna

`utils/benchpress/adapter.py` line 223 — https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3677713059

### Before

> **[medium] snapshot provenance** — One export can combine files from different revisions
>
> Metadata and the three CSVs are separate reads from mutable `main`. Metadata errors become an empty object, after which the adapter uses the current time and omits its promised version anchor.
>
> Resolving one Hugging Face dataset revision can pin every live read. The dataset revision and manifest `source_git_commit` can remain separate provenance fields.

### After

> **[medium] snapshot provenance** — One export can combine files from different revisions because metadata and the three CSVs are separate reads from mutable `main`. Metadata errors become an empty object; the adapter then uses the current time and omits its promised version anchor. Please resolve one Hugging Face dataset revision and use it to pin every live read. The dataset revision and manifest `source_git_commit` can remain separate provenance fields.

## evaleval/every_eval_ever PR #212 — comment 3699205371 — luna

`every_eval_ever/validation_core.py` line 30 — https://github.com/evaleval/every_eval_ever/pull/212#discussion_r3699205371

### Before

> `re.IGNORECASE` here is wider than the pairing logic, which is case-sensitive (`endswith('_samples.jsonl')` in `_aggregate_repo_path_for_samples`, and the sibling probe builds a lowercase path). A file named `<uuid>_Samples.jsonl` passes path validation but skips every companion rule: it needs no sibling aggregate, and no aggregate has to declare it. Verified: `check_path_structure` accepts the mixed-case path and `check_instance_companion` returns no errors for it.
>
> Publishers only emit lowercase names, so dropping `re.IGNORECASE` closes the hole with no loss. (A mixed-case `.JSON` suffix is already handled safely — it fails later with an `unsupported_extension` error — but lowercasing the rule set makes the two paths consistent.)
>
> ---
> _Generated by [Claude Code](https://claude.ai/code)_

### After

> `re.IGNORECASE` here is wider than the pairing logic, which is case-sensitive: `_aggregate_repo_path_for_samples` uses `endswith('_samples.jsonl')`, and the sibling probe builds a lowercase path. A file named `<uuid>_Samples.jsonl` therefore passes path validation but skips every companion rule: it needs no sibling aggregate, and no aggregate has to declare it. Verified: `check_path_structure` accepts the mixed-case path and `check_instance_companion` returns no errors for it. Please drop `re.IGNORECASE` to close this hole with no loss; publishers only emit lowercase names, and a mixed-case `.JSON` suffix is already handled safely because it fails later with an `unsupported_extension` error, so lowercasing the rule set makes the two paths consistent.
