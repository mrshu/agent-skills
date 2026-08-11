Blindly compare two randomized versions of each GitHub inline code-review comment. Labels A and B do not identify chronology, model, or original. A separate audit has already checked technical facts, so judge human readability only. Assume a busy pull-request author reads each comment once in a narrow GitHub inline pane and must understand both what breaks and what to do.

For every row, score each version from 1 to 5 on:
- defect_clarity: the failure and trigger are immediately clear;
- action_recall: every requested action is visible and easy to remember;
- scanability: structure and idea-at-a-time flow support quick scanning;
- naturalness: respectful technical prose sounds human rather than templated or stilted;
- cognitive_ease: the reader need not untangle clauses, infer referents, or simulate hidden relationships.

Do not reward brevity by itself. Necessary identifiers and technical terms are not jargon when their role is clear. Bullets help only when they expose independently checkable work; penalize bullets that promote permissions or acceptable unchanged behavior into work. Prefer a winner only when the difference would matter to a busy author. Otherwise return tie.

Return valid pretty-printed JSON only:
{
  "per_comment": [
    {"id": 123, "scores": {"A": {"defect_clarity": 1, "action_recall": 1, "scanability": 1, "naturalness": 1, "cognitive_ease": 1}, "B": {"defect_clarity": 1, "action_recall": 1, "scanability": 1, "naturalness": 1, "cognitive_ease": 1}}, "winner": "A|B|tie", "reason": "one or two sentences naming the decisive wording or structure"}
  ],
  "winner_counts": {"A": 0, "B": 0, "tie": 0},
  "mean_scores": {"A": {"defect_clarity": 0, "action_recall": 0, "scanability": 0, "naturalness": 0, "cognitive_ease": 0}, "B": {"defect_clarity": 0, "action_recall": 0, "scanability": 0, "naturalness": 0, "cognitive_ease": 0}},
  "overall_ranking": ["A|B"],
  "recommended_version": "A|B|tie",
  "summary": "two or three sentences"
}

Return every input ID exactly once in input order. Do not include Markdown fences, rewrites, fact judgments, or text outside JSON.

COMPARISON ROWS:
[
  {
    "id": 3525225568,
    "A": "I personally think it would make more sense to make it a specific option for this command and execute it after this handle command?",
    "B": "Please make this a specific option for this command and execute it after this handle command; I personally think that would make more sense."
  },
  {
    "id": 2614980077,
    "A": "The error message \"No new files to add, keeping existing X file(s)\" uses \"file(s)\" which is ambiguous in this context. Since this is counting rows in the parquet file (each row represents a JSON file), consider clarifying the message to say \"No new rows to add, keeping existing X row(s)\" or \"No new entries to add\" to better reflect what's being counted.\n```suggestion\n        print(f\"No new rows to add, keeping existing {len(existing_df)} row(s)\")\n```",
    "B": "The error message `No new files to add, keeping existing X file(s)` uses `file(s)`, which is ambiguous here because this counts rows in the parquet file, with each row representing a JSON file. Please clarify the message to say `No new rows to add, keeping existing X row(s)` or `No new entries to add`."
  },
  {
    "id": 2614980178,
    "A": "The manifest is created even when `modified` is empty. The upload script handles this correctly, but the reason for keeping an empty manifest is not documented. Please add a comment explaining why the empty manifest is still written, including that it gives downstream scripts a consistent file to read and likely aids debugging or workflow clarity.",
    "B": "The manifest is created even when there are no changes (empty \"modified\" list). While this is handled correctly by the upload script, consider adding a comment explaining why an empty manifest is still created (likely for debugging or workflow clarity purposes).\n```suggestion\n        print(\"No changes detected, nothing to upload\")\n        # Always create and write an (empty) manifest file, even when there are no changes.\n        # This ensures downstream scripts have a consistent file to read, and aids in debugging/workflow clarity.\n```"
  },
  {
    "id": 2952666730,
    "A": "The README now states validation uses generated Pydantic models, but the repo’s pre-commit hook still runs `utils/validate_data.py` with `jsonschema` against `eval.schema.json` (see `.pre-commit-config.yaml`). This makes the documentation misleading about what runs automatically on commit/CI. Either update the pre-commit hook to call `validate.py` (and handle JSONL) or clarify in this section that `validate.py` is an optional/manual (or separate CI) validator while pre-commit remains JSON Schema-based.",
    "B": "The README now states validation uses generated Pydantic models, but the repo’s pre-commit hook still runs `utils/validate_data.py` with `jsonschema` against `eval.schema.json` (see `.pre-commit-config.yaml`). This makes the documentation misleading about what runs automatically on commit/CI. Either update the pre-commit hook to call `validate.py` (and handle JSONL) or clarify in this section that `validate.py` is an optional/manual (or separate CI) validator while pre-commit remains JSON Schema-based."
  },
  {
    "id": 2952666872,
    "A": "`apply_discriminator_patch()` treats the file as \"already patched\" if the substring `\"Discriminator\"` appears anywhere in the file. That check is overly broad and could skip patching when `Discriminator` is present for unrelated reasons, leaving `source_data` unpatched. Check for the specific patched field signature (or for `target_line` absence/presence) instead of a global substring match.\n",
    "B": "`apply_discriminator_patch()` treats the file as already patched if the substring `\"Discriminator\"` appears anywhere in the file. This check is overly broad and could skip patching when `Discriminator` is present for unrelated reasons, leaving `source_data` unpatched. Please check for the specific patched field signature or for `target_line` absence/presence instead of using a global substring match."
  },
  {
    "id": 3088978085,
    "A": "The metrics table markup has extra leading pipes (\"|| Metric\"), which breaks Markdown table rendering. Also, in the sample argument list the --output_dir option is missing its argument placeholder (it should show something like \"--output_dir OUTPUT_DIR\"). Please fix the table and the argument list snippet so the rendered docs match actual CLI usage.\n```suggestion\n  --version {v1,v2}            Which leaderboard to convert. Omit to convert both (default).\n  --output_dir OUTPUT_DIR      Base output directory (default: data).\n```",
    "B": "The metrics table markup has extra leading pipes (\"|| Metric\"), which breaks Markdown table rendering. Also, in the sample argument list the --output_dir option is missing its argument placeholder (it should show something like \"--output_dir OUTPUT_DIR\"). Please fix the table and the argument list snippet so the rendered docs match actual CLI usage.\n```suggestion\n  --version {v1,v2}            Which leaderboard to convert. Omit to convert both (default).\n  --output_dir OUTPUT_DIR      Base output directory (default: data).\n```"
  },
  {
    "id": 3096650221,
    "A": "**N+1 loading.** For each URL you run a `DESCRIBE` then an `INSERT ... SELECT`. DuckDB's `read_parquet(urls, union_by_name=true, filename=true)` handles missing columns across a heterogeneous list in one call — you already rely on this a few lines up for schemas. If the strict `NOT NULL` typing on `{table}_instances` is the reason you can't use the fast path, a one-line comment explaining that would help future readers. Otherwise replace the loop with a single `INSERT ... SELECT ... FROM read_parquet(?, union_by_name=true, filename=true)` passing the full `instance_urls` list.",
    "B": "**N+1 loading.** For each URL you run a `DESCRIBE` then an `INSERT ... SELECT`. DuckDB's `read_parquet(urls, union_by_name=true, filename=true)` handles missing columns across a heterogeneous list in one call — you already rely on this a few lines up for schemas. If the strict `NOT NULL` typing on `{table}_instances` is the reason you can't use the fast path, a one-line comment explaining that would help future readers. Otherwise replace the loop with a single `INSERT ... SELECT ... FROM read_parquet(?, union_by_name=true, filename=true)` passing the full `instance_urls` list."
  },
  {
    "id": 3102848524,
    "A": "For the `.txt` path case, the test matches the same 'Could not find file or directory' message used for missing paths. That message is a bit misleading for an existing-but-unsupported file, and matching on it makes the intent (unsupported extension rejection) less clear. Consider either asserting only that an exception is raised for non-JSON files, or (longer-term) updating `expand_paths` to raise a distinct exception/message for unsupported extensions.\n```suggestion\n\n    with pytest.raises(Exception):\n```",
    "B": "For the existing `.txt` path, the test matches the same \"Could not find file or directory\" message used for missing paths. That message is a bit misleading for an existing but unsupported file, and matching it obscures that the test covers unsupported-extension rejection. Please either assert only that non-JSON files raise an exception, or, as a longer-term change, make `expand_paths` raise a distinct exception or message for unsupported extensions."
  },
  {
    "id": 3134292915,
    "A": "`MODEL_DEVELOPER_MAP` maps `qwen` → `alibaba`, while other adapters use `qwen` as the developer slug, including `utils/arc_agi/adapter.py` and `utils/sciarena/adapter.py`. This will make HAL exports inconsistent with the rest of the dataset and may split Qwen models across two developer directories depending on whether `MODEL_ID_OVERRIDES` fires. Please use `qwen` here, or otherwise align the mapping and overrides so the developer slug is consistent.",
    "B": "`MODEL_DEVELOPER_MAP` maps `qwen` → `alibaba`, but other adapters in this repo use `qwen` as the developer slug (e.g. `utils/arc_agi/adapter.py` and `utils/sciarena/adapter.py`). This will make HAL exports inconsistent with the rest of the dataset and may split Qwen models across two developer directories depending on whether `MODEL_ID_OVERRIDES` fires. Consider using `qwen` here (or otherwise aligning the mapping + overrides so the developer slug is consistent).\n```suggestion\n    # Qwen\n    \"qwen\": \"qwen\",\n```"
  },
  {
    "id": 3153765816,
    "A": "The constructor parameter is misspelled as `evaulation_id`, which is easy to miss and prevents using this adapter with keyword arguments such as `evaluation_id=...`. Please rename it to `evaluation_id` throughout the signature and assignments, and update all call sites accordingly.",
    "B": "The constructor parameter is misspelled as `evaulation_id`. This is easy to miss and prevents using this adapter with keyword arguments (e.g. `evaluation_id=...`). Rename it to `evaluation_id` throughout the signature/assignments and update any call sites accordingly."
  },
  {
    "id": 3161743720,
    "A": "nit: could we build this title and filename (line 448) from `top_n`, e.g. `f'Top {top_n} Benchmarks by Number of Models'` and `f'top{top_n}_benchmarks_by_models.png'`? That way the plot stays accurate when someone runs the CLI with `--top-n 3` or another value, instead of hardcoding `Top 10`.\n",
    "B": "Nit: The plot title and filename are hardcoded to `Top 10`, including the filename on line 448. This makes the plot inaccurate when the CLI runs with `--top-n 3` or another value. Please build the title and filename from `top_n`, for example `f'Top {top_n} Benchmarks by Number of Models'` and `f'top{top_n}_benchmarks_by_models.png'`."
  },
  {
    "id": 3161807141,
    "A": "`create_visualisations()` currently depends on `main()` setting `viz_dir` and `top_n` first, so importing the module and calling the function directly would crash. Please pass `viz_dir` and `top_n` directly into `create_visualisations()` if this file is not meant to run only as a CLI script; if it is CLI-only, no change is needed.",
    "B": "Is this file meant to be run only as a CLI script? If yes, ignore this comment. If not, we should pass `viz_dir` and `top_n` directly into `create_visualisations()`, because the function currently depends on `main()` setting those values first and would crash if someone imports and calls it directly.\n"
  },
  {
    "id": 3493867085,
    "A": "This might end up being a bottleneck. It may be worth it to abstract the specific json reader / writer so the stdlib json is always an option, but you can opt-in to something like `orjson` or `ujson`. (Note: orjson is a bit opinionated. It's fast, but it also means you can't serialize generic floats like nans or infs, which technically isn't json, but the stdlib and ujson aren't so strict about it).\n\nI've handled this in a few ways in the past: simple wrappers: https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391\n\nAnd module level globals: https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117",
    "B": "This might end up being a bottleneck. It may be worth it to abstract the specific json reader / writer so the stdlib json is always an option, but you can opt-in to something like `orjson` or `ujson`. (Note: orjson is a bit opinionated. It's fast, but it also means you can't serialize generic floats like nans or infs, which technically isn't json, but the stdlib and ujson aren't so strict about it).\n\nI've handled this in a few ways in the past: simple wrappers: https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391\n\nAnd module level globals: https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117"
  },
  {
    "id": 3520340907,
    "A": "The file is written as `data/adapter_stats.json` below, but this code reads `adapter_stats.json` from the repository root. It also reads from the default branch while the upload creates a PR, so the state from one run may not be available to the next. Please confirm whether this path and branch behavior is intentional.",
    "B": "Is this path intentional? We write the file as `data/adapter_stats.json` below, but read `adapter_stats.json` from the repository root here. Also, this reads from the default branch while the upload creates a PR, so I’m not sure the state from one run will be available to the next one."
  },
  {
    "id": 3652735574,
    "A": "Was this rename a workaround for `check_integer_counts()` rejecting stringified `samples_number` in `additional_details`? If the walk is fixed to skip `additional_details` (see my comment on `validation_core.py`), this could keep the conventional key name.",
    "B": "Was this rename a workaround for `check_integer_counts()` rejecting stringified `samples_number` in `additional_details`? If the walk is fixed to skip `additional_details` as discussed for `validation_core.py`, the conventional key name could be kept."
  },
  {
    "id": 3653129512,
    "A": "On hosting platforms, the organization is the account that owns the content rather than the platform. Editorial and paper URLs carry no account, so they should infer nothing. Please infer the organization from `urls[0]` using these host and path rules.\n\n```suggestion\n    parsed = urlparse(urls[0])\n    host = (parsed.hostname or '').removeprefix('www.')\n    path_parts = [part for part in parsed.path.split('/') if part]\n    if host in {'x.com', 'twitter.com'} and path_parts:\n        return normalize_slug(path_parts[0])\n\n    # On hosting platforms the organization is the account that owns the\n    # content, not the platform, so read it from the URL instead of the\n    # domain. Editorial and paper URLs carry no account, so infer nothing.\n    if host in {'github.com', 'gist.github.com', 'raw.githubusercontent.com'}:\n        return normalize_slug(path_parts[0]) if path_parts else None\n    if host == 'huggingface.co':\n        if not path_parts or path_parts[0] in {\n            'blog',\n            'papers',\n            'posts',\n            'collections',\n            'docs',\n        }:\n            return None\n        if path_parts[0] in {'datasets', 'spaces'}:\n            if len(path_parts) > 1:\n                return normalize_slug(path_parts[1])\n            return None\n        return normalize_slug(path_parts[0])\n    if host.endswith('.github.io'):\n        owner = host.removesuffix('.github.io')\n        return normalize_slug(owner) if owner else None\n    if host == 'arxiv.org':\n        return None\n```",
    "B": "```suggestion\n    parsed = urlparse(urls[0])\n    host = (parsed.hostname or '').removeprefix('www.')\n    path_parts = [part for part in parsed.path.split('/') if part]\n    if host in {'x.com', 'twitter.com'} and path_parts:\n        return normalize_slug(path_parts[0])\n\n    # On hosting platforms the organization is the account that owns the\n    # content, not the platform, so read it from the URL instead of the\n    # domain. Editorial and paper URLs carry no account, so infer nothing.\n    if host in {'github.com', 'gist.github.com', 'raw.githubusercontent.com'}:\n        return normalize_slug(path_parts[0]) if path_parts else None\n    if host == 'huggingface.co':\n        if not path_parts or path_parts[0] in {\n            'blog',\n            'papers',\n            'posts',\n            'collections',\n            'docs',\n        }:\n            return None\n        if path_parts[0] in {'datasets', 'spaces'}:\n            if len(path_parts) > 1:\n                return normalize_slug(path_parts[1])\n            return None\n        return normalize_slug(path_parts[0])\n    if host.endswith('.github.io'):\n        owner = host.removesuffix('.github.io')\n        return normalize_slug(owner) if owner else None\n    if host == 'arxiv.org':\n        return None\n```"
  },
  {
    "id": 3677101235,
    "A": "**[medium] repeat runs** — Reusing an output directory creates duplicate logical evaluations\n\n`save_evaluation_log()` creates a new UUID filename on every call. Instance mode also creates another full sidecar. Stable `evaluation_id` values therefore do not make the filesystem output idempotent.\n\nAn adapter-owned aggregate and sidecar can be replaced as one set. The sidecar needs a fresh write because its current append mode would otherwise duplicate rows.",
    "B": "**[medium] repeat runs** — `save_evaluation_log()` creates a new UUID filename on every call, and instance mode also creates another full sidecar. Stable `evaluation_id` values therefore do not make filesystem output idempotent, so reusing an output directory creates duplicate logical evaluations. Please replace the adapter-owned aggregate and sidecar as one set, writing the sidecar afresh because its current append mode would otherwise duplicate rows."
  },
  {
    "id": 3677104436,
    "A": "**[medium] duplicate variants** — Explicit-file validation cannot see compressed siblings\n\n`expand_paths()` returns only the named file, and this call checks only that limited list. When the caller names only `abc.json`, `abc.json.gz` can therefore escape the one-variant rule. Please make collision discovery inspect same-parent, same-stem variants while keeping payload validation limited to the requested files.",
    "B": "**[medium] duplicate variants** — Explicit-file validation cannot see compressed siblings\n\n`expand_paths()` returns only the named file, and this call checks that limited list. `abc.json.gz` can therefore escape the one-variant rule when the caller names only `abc.json`.\n\nCollision discovery can inspect same-parent, same-stem variants while payload validation stays limited to requested files."
  },
  {
    "id": 3677218975,
    "A": "**[high] schema versioning** — New instance records keep `instance_level_eval_0.2.2`, although the existing 0.2.2 model rejects `modality` and null `is_correct`. The old aggregate model also discards the new modality under its unchanged identifier.\n\nThe extension is well scoped; its schema copies, emitters, models, fixtures, tests, and current-version docs can move to new identifiers together.",
    "B": "**[high] schema versioning** — New instance records keep `instance_level_eval_0.2.2`, although the existing 0.2.2 model rejects `modality` and null `is_correct`. The old aggregate model also discards the new modality under its unchanged identifier. The extension is well scoped. Please move its schema copies, emitters, models, fixtures, tests, and current-version docs to new identifiers together."
  },
  {
    "id": 3677354603,
    "A": "**[medium] error handling** — A handled fetch, conversion, or write failure reaches the final `Done!` message and exits with status 0. Automation can therefore treat a partial dataset as complete. Please feed both outcomes into a final status that `__main__` propagates if this entry point keeps independent work. Delegation may remove this duplicate path.",
    "B": "**[medium] error handling** — A handled fetch, conversion, or write failure reaches the final `Done!` message and exits with status 0. Automation can treat a partial dataset as complete.\n\nIf this entry point keeps independent work, both outcomes can feed a final status that `__main__` propagates. Delegation may remove this duplicate path."
  },
  {
    "id": 3677461204,
    "A": "**[medium] error isolation** — Pydantic `ValidationError` is outside this catch tuple. One malformed benchmark can stop all later targets instead of joining the final partial-run report.\n\nThat error can stay inside the per-benchmark boundary while the adapter continues with later work.",
    "B": "**[medium] error isolation** — Pydantic `ValidationError` is outside this catch tuple. One malformed benchmark can stop all later targets instead of joining the final partial-run report. Please keep that error inside the per-benchmark boundary so the adapter continues with later work."
  },
  {
    "id": 3677564751,
    "A": "**[medium] score validation** — Supported replay input can emit values outside the source contract\n\n`float()` accepts booleans, NaN, infinity, Pass^k values outside 0–100, and negative costs. Current official submissions are valid, but local replay and custom sources can reach this path.\n\nPass metrics can use finite inclusive 0–100 checks. Cost can use a finite non-negative check, with booleans rejected before numeric conversion.",
    "B": "**[medium] score validation** — Supported replay input can emit values outside the source contract. `float()` accepts booleans, NaN, infinity, Pass^k values outside 0–100, and negative costs. Current official submissions are valid, but local replay and custom sources can reach this path. Please validate pass metrics as finite values in the inclusive 0–100 range and cost as finite and non-negative, rejecting booleans before numeric conversion."
  },
  {
    "id": 3677669726,
    "A": "**[medium] Pydantic schema** — The serialization schema excludes emitted sentinel strings. This serializer has no declared output union, so Pydantic describes the bound as number or null even though `model_dump_json()` can emit `\"Infinity\"` or `\"-Infinity\"`. Please expose an accurate serialization contract for each bound covering finite numbers, null, and its field-valid sentinel.",
    "B": "**[medium] Pydantic schema** — The serialization schema excludes emitted sentinel strings\n\nThis serializer has no declared output union. Pydantic therefore describes the bound as number or null, although `model_dump_json()` can emit `\"Infinity\"` or `\"-Infinity\"`.\n\nEach bound can expose an accurate serialization contract for finite numbers, null, and its field-valid sentinel."
  },
  {
    "id": 3677713059,
    "A": "**[medium] snapshot provenance** — One export can combine files from different revisions\n\nMetadata and the three CSVs are separate reads from mutable `main`. Metadata errors become an empty object, after which the adapter uses the current time and omits its promised version anchor.\n\nResolving one Hugging Face dataset revision can pin every live read. The dataset revision and manifest `source_git_commit` can remain separate provenance fields.",
    "B": "**[medium] snapshot provenance** — One export can combine files from different revisions because metadata and the three CSVs are separate reads from mutable `main`. Metadata errors become an empty object; the adapter then uses the current time and omits its promised version anchor. Please resolve one Hugging Face dataset revision and use it to pin every live read. The dataset revision and manifest `source_git_commit` can remain separate provenance fields."
  },
  {
    "id": 3699205371,
    "A": "`re.IGNORECASE` here is wider than the pairing logic, which is case-sensitive: `_aggregate_repo_path_for_samples` uses `endswith('_samples.jsonl')`, and the sibling probe builds a lowercase path. A file named `<uuid>_Samples.jsonl` therefore passes path validation but skips every companion rule: it needs no sibling aggregate, and no aggregate has to declare it. Verified: `check_path_structure` accepts the mixed-case path and `check_instance_companion` returns no errors for it. Please drop `re.IGNORECASE` to close this hole with no loss; publishers only emit lowercase names, and a mixed-case `.JSON` suffix is already handled safely because it fails later with an `unsupported_extension` error, so lowercasing the rule set makes the two paths consistent.",
    "B": "`re.IGNORECASE` here is wider than the pairing logic, which is case-sensitive (`endswith('_samples.jsonl')` in `_aggregate_repo_path_for_samples`, and the sibling probe builds a lowercase path). A file named `<uuid>_Samples.jsonl` passes path validation but skips every companion rule: it needs no sibling aggregate, and no aggregate has to declare it. Verified: `check_path_structure` accepts the mixed-case path and `check_instance_companion` returns no errors for it.\n\nPublishers only emit lowercase names, so dropping `re.IGNORECASE` closes the hole with no loss. (A mixed-case `.JSON` suffix is already handled safely — it fails later with an `unsupported_extension` error — but lowercasing the rule set makes the two paths consistent.)\n\n---\n_Generated by [Claude Code](https://claude.ai/code)_"
  }
]
