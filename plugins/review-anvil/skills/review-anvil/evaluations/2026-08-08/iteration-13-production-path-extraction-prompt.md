Prepare exact action-lock audit rows for one production renderer draft. Do not judge, repair, or rewrite. For each item:
- `source_context`: copy only the minimum exact source diagnosis needed to resolve identifiers, pronouns, and current-versus-target behavior.
- `source_requested_work`: copy verbatim every source phrase that expresses target behavior, a required test or documentation change, an allowed implementation boundary, accepted current behavior, an exception, a purpose/safety clause, or an explicitly optional follow-up. Include question or modal wording verbatim. Exclude unchanged lines from suggestion blocks when the prose does not request them. Use an empty string only when the source contains no requested or boundary prose.
- `rendered_requested_work`: copy verbatim every request and boundary phrase from the rendered draft. Exclude diagnosis and consequence prose.
Never paraphrase, classify, or infer. Preserve exact punctuation, identifiers, qualifiers, and line breaks.

Return valid JSON only:
{"rows":[{"id":123,"source_context":"exact source","source_requested_work":"exact source","rendered_requested_work":"exact rendered"}]}
Return every ID exactly once in input order. No Markdown fences or text outside JSON.

ITEMS:
[
  {
    "id": 3525225568,
    "source": "I personally think it would make more sense to make it a specific option for this command and execute it after this handle command?",
    "rendered": "Please make this a specific option for this command and execute it after this handle command."
  },
  {
    "id": 2614980077,
    "source": "The error message \"No new files to add, keeping existing X file(s)\" uses \"file(s)\" which is ambiguous in this context. Since this is counting rows in the parquet file (each row represents a JSON file), consider clarifying the message to say \"No new rows to add, keeping existing X row(s)\" or \"No new entries to add\" to better reflect what's being counted.\n```suggestion\n        print(f\"No new rows to add, keeping existing {len(existing_df)} row(s)\")\n```",
    "rendered": "The error message `No new files to add, keeping existing X file(s)` uses `file(s)`, which is ambiguous here because this counts rows in the parquet file, with each row representing a JSON file. Please clarify the message to say `No new rows to add, keeping existing X row(s)` or `No new entries to add`."
  },
  {
    "id": 2614980178,
    "source": "The manifest is created even when there are no changes (empty \"modified\" list). While this is handled correctly by the upload script, consider adding a comment explaining why an empty manifest is still created (likely for debugging or workflow clarity purposes).\n```suggestion\n        print(\"No changes detected, nothing to upload\")\n        # Always create and write an (empty) manifest file, even when there are no changes.\n        # This ensures downstream scripts have a consistent file to read, and aids in debugging/workflow clarity.\n```",
    "rendered": "The manifest is created even when there are no changes (an empty `modified` list), and the upload script handles this correctly. The reason for always creating the empty manifest is not documented for downstream readers, debugging, or workflow clarity.\n\n**Requested actions**\n\n- Add `print(\"No changes detected, nothing to upload\")`.\n- Add a comment explaining why an empty manifest is still created so downstream scripts have a consistent file to read and this aids debugging and workflow clarity."
  },
  {
    "id": 2952666730,
    "source": "The README now states validation uses generated Pydantic models, but the repo’s pre-commit hook still runs `utils/validate_data.py` with `jsonschema` against `eval.schema.json` (see `.pre-commit-config.yaml`). This makes the documentation misleading about what runs automatically on commit/CI. Either update the pre-commit hook to call `validate.py` (and handle JSONL) or clarify in this section that `validate.py` is an optional/manual (or separate CI) validator while pre-commit remains JSON Schema-based.",
    "rendered": "The README now states that validation uses generated Pydantic models, but the repository's pre-commit hook still runs `utils/validate_data.py` with `jsonschema` against `eval.schema.json`. This makes the documentation misleading about what runs automatically on commit/CI. Please either update the pre-commit hook to call `validate.py` and handle JSONL, or clarify in this section that `validate.py` is an optional/manual (or separate CI) validator while pre-commit remains JSON Schema-based."
  },
  {
    "id": 2952666872,
    "source": "`apply_discriminator_patch()` treats the file as \"already patched\" if the substring `\"Discriminator\"` appears anywhere in the file. That check is overly broad and could skip patching when `Discriminator` is present for unrelated reasons, leaving `source_data` unpatched. Check for the specific patched field signature (or for `target_line` absence/presence) instead of a global substring match.\n",
    "rendered": "`apply_discriminator_patch()` treats the file as already patched if the substring `\"Discriminator\"` appears anywhere in the file. This check is overly broad and could skip patching when `Discriminator` is present for unrelated reasons, leaving `source_data` unpatched. Please check for the specific patched field signature or for `target_line` absence/presence instead of using a global substring match."
  },
  {
    "id": 3088978085,
    "source": "The metrics table markup has extra leading pipes (\"|| Metric\"), which breaks Markdown table rendering. Also, in the sample argument list the --output_dir option is missing its argument placeholder (it should show something like \"--output_dir OUTPUT_DIR\"). Please fix the table and the argument list snippet so the rendered docs match actual CLI usage.\n```suggestion\n  --version {v1,v2}            Which leaderboard to convert. Omit to convert both (default).\n  --output_dir OUTPUT_DIR      Base output directory (default: data).\n```",
    "rendered": "The metrics table markup has extra leading pipes (`|| Metric`), which breaks Markdown table rendering. The sample argument list also omits the argument placeholder for `--output_dir`, so the rendered docs do not match actual CLI usage.\n\n**Requested actions**\n\n- Fix the metrics table markup by removing the extra leading pipe.\n- Update the sample argument list to show `--output_dir OUTPUT_DIR`."
  },
  {
    "id": 3096650221,
    "source": "**N+1 loading.** For each URL you run a `DESCRIBE` then an `INSERT ... SELECT`. DuckDB's `read_parquet(urls, union_by_name=true, filename=true)` handles missing columns across a heterogeneous list in one call — you already rely on this a few lines up for schemas. If the strict `NOT NULL` typing on `{table}_instances` is the reason you can't use the fast path, a one-line comment explaining that would help future readers. Otherwise replace the loop with a single `INSERT ... SELECT ... FROM read_parquet(?, union_by_name=true, filename=true)` passing the full `instance_urls` list.",
    "rendered": "**N+1 loading.** Each URL runs a `DESCRIBE` followed by an `INSERT ... SELECT`, creating the N+1 loading path and a possible bottleneck. DuckDB's `read_parquet(urls, union_by_name=true, filename=true)` handles missing columns across a heterogeneous list in one call, and you already rely on it a few lines up for schemas. Please replace the loop with a single `INSERT ... SELECT ... FROM read_parquet(?, union_by_name=true, filename=true)` that passes the full `instance_urls` list. If strict `NOT NULL` typing on `{table}_instances` is the reason the fast path cannot be used, add a one-line comment explaining that instead."
  },
  {
    "id": 3102848524,
    "source": "For the `.txt` path case, the test matches the same 'Could not find file or directory' message used for missing paths. That message is a bit misleading for an existing-but-unsupported file, and matching on it makes the intent (unsupported extension rejection) less clear. Consider either asserting only that an exception is raised for non-JSON files, or (longer-term) updating `expand_paths` to raise a distinct exception/message for unsupported extensions.\n```suggestion\n\n    with pytest.raises(Exception):\n```",
    "rendered": "For the `.txt` path case, the test matches the same `Could not find file or directory` message used for missing paths. That message is misleading for an existing-but-unsupported file and makes the intent—unsupported-extension rejection—less clear. Please either assert only that an exception is raised for non-JSON files, using `with pytest.raises(Exception):`, or update `expand_paths` to raise a distinct exception/message for unsupported extensions."
  },
  {
    "id": 3134292915,
    "source": "`MODEL_DEVELOPER_MAP` maps `qwen` → `alibaba`, but other adapters in this repo use `qwen` as the developer slug (e.g. `utils/arc_agi/adapter.py` and `utils/sciarena/adapter.py`). This will make HAL exports inconsistent with the rest of the dataset and may split Qwen models across two developer directories depending on whether `MODEL_ID_OVERRIDES` fires. Consider using `qwen` here (or otherwise aligning the mapping + overrides so the developer slug is consistent).\n```suggestion\n    # Qwen\n    \"qwen\": \"qwen\",\n```",
    "rendered": "`MODEL_DEVELOPER_MAP` maps `qwen` → `alibaba`, while other adapters use `qwen` as the developer slug, including `utils/arc_agi/adapter.py` and `utils/sciarena/adapter.py`. This will make HAL exports inconsistent with the rest of the dataset and may split Qwen models across two developer directories depending on whether `MODEL_ID_OVERRIDES` fires. Please use `qwen` here, or otherwise align the mapping and overrides so the developer slug is consistent."
  },
  {
    "id": 3153765816,
    "source": "The constructor parameter is misspelled as `evaulation_id`. This is easy to miss and prevents using this adapter with keyword arguments (e.g. `evaluation_id=...`). Rename it to `evaluation_id` throughout the signature/assignments and update any call sites accordingly.",
    "rendered": "The constructor parameter is misspelled as `evaulation_id`, which is easy to miss and prevents using this adapter with keyword arguments such as `evaluation_id=...`. Please rename it to `evaluation_id` throughout the signature and assignments, and update all call sites accordingly."
  },
  {
    "id": 3161743720,
    "source": "nit: could we build this title and filename (line 448) from `top_n`, e.g. `f'Top {top_n} Benchmarks by Number of Models'` and `f'top{top_n}_benchmarks_by_models.png'`? That way the plot stays accurate when someone runs the CLI with `--top-n 3` or another value, instead of hardcoding `Top 10`.\n",
    "rendered": "The plot title and filename are hardcoded to `Top 10`, including the filename on line 448. This makes the plot inaccurate when the CLI runs with `--top-n 3` or another value. Please build the title and filename from `top_n`, for example `f'Top {top_n} Benchmarks by Number of Models'` and `f'top{top_n}_benchmarks_by_models.png'`."
  },
  {
    "id": 3161807141,
    "source": "Is this file meant to be run only as a CLI script? If yes, ignore this comment. If not, we should pass `viz_dir` and `top_n` directly into `create_visualisations()`, because the function currently depends on `main()` setting those values first and would crash if someone imports and calls it directly.\n",
    "rendered": "`create_visualisations()` currently depends on `main()` setting `viz_dir` and `top_n` first, so importing the module and calling the function directly would crash. Please pass `viz_dir` and `top_n` directly into `create_visualisations()` if this file is not meant to run only as a CLI script; if it is CLI-only, no change is needed."
  },
  {
    "id": 3493867085,
    "source": "This might end up being a bottleneck. It may be worth it to abstract the specific json reader / writer so the stdlib json is always an option, but you can opt-in to something like `orjson` or `ujson`. (Note: orjson is a bit opinionated. It's fast, but it also means you can't serialize generic floats like nans or infs, which technically isn't json, but the stdlib and ujson aren't so strict about it).\n\nI've handled this in a few ways in the past: simple wrappers: https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391\n\nAnd module level globals: https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117",
    "rendered": "This might end up being a bottleneck. An optional follow-up is to abstract the specific JSON reader/writer so stdlib `json` is always an option while callers can opt in to `orjson` or `ujson`. `orjson` is fast but opinionated: it cannot serialize generic floats such as nans or infs, which technically are not JSON, while the stdlib and `ujson` are less strict. Similar approaches include simple wrappers in https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391 and module-level globals in https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117."
  },
  {
    "id": 3520340907,
    "source": "Is this path intentional? We write the file as `data/adapter_stats.json` below, but read `adapter_stats.json` from the repository root here. Also, this reads from the default branch while the upload creates a PR, so I’m not sure the state from one run will be available to the next one.",
    "rendered": "The file is written as `data/adapter_stats.json` below, but this code reads `adapter_stats.json` from the repository root. It also reads from the default branch while the upload creates a PR, so the state from one run may not be available to the next. Please confirm whether this path and branch behavior is intentional."
  },
  {
    "id": 3652735574,
    "source": "Was this rename a workaround for `check_integer_counts()` rejecting stringified `samples_number` in `additional_details`? If the walk is fixed to skip `additional_details` (see my comment on `validation_core.py`), this could keep the conventional key name.",
    "rendered": "Was this rename a workaround for `check_integer_counts()` rejecting stringified `samples_number` in `additional_details`? If the walk is fixed to skip `additional_details` as discussed for `validation_core.py`, the conventional key name could be kept."
  },
  {
    "id": 3653129512,
    "source": "```suggestion\n    parsed = urlparse(urls[0])\n    host = (parsed.hostname or '').removeprefix('www.')\n    path_parts = [part for part in parsed.path.split('/') if part]\n    if host in {'x.com', 'twitter.com'} and path_parts:\n        return normalize_slug(path_parts[0])\n\n    # On hosting platforms the organization is the account that owns the\n    # content, not the platform, so read it from the URL instead of the\n    # domain. Editorial and paper URLs carry no account, so infer nothing.\n    if host in {'github.com', 'gist.github.com', 'raw.githubusercontent.com'}:\n        return normalize_slug(path_parts[0]) if path_parts else None\n    if host == 'huggingface.co':\n        if not path_parts or path_parts[0] in {\n            'blog',\n            'papers',\n            'posts',\n            'collections',\n            'docs',\n        }:\n            return None\n        if path_parts[0] in {'datasets', 'spaces'}:\n            if len(path_parts) > 1:\n                return normalize_slug(path_parts[1])\n            return None\n        return normalize_slug(path_parts[0])\n    if host.endswith('.github.io'):\n        owner = host.removesuffix('.github.io')\n        return normalize_slug(owner) if owner else None\n    if host == 'arxiv.org':\n        return None\n```",
    "rendered": "Please update the URL account inference as follows:\n\n```python\nparsed = urlparse(urls[0])\nhost = (parsed.hostname or '').removeprefix('www.')\npath_parts = [part for part in parsed.path.split('/') if part]\nif host in {'x.com', 'twitter.com'} and path_parts:\n    return normalize_slug(path_parts[0])\n\n# On hosting platforms the organization is the account that owns the\n# content, not the platform, so read it from the URL instead of the\n# domain. Editorial and paper URLs carry no account, so infer nothing.\nif host in {'github.com', 'gist.github.com', 'raw.githubusercontent.com'}:\n    return normalize_slug(path_parts[0]) if path_parts else None\nif host == 'huggingface.co':\n    if not path_parts or path_parts[0] in {\n        'blog',\n        'papers',\n        'posts',\n        'collections',\n        'docs',\n    }:\n        return None\n    if path_parts[0] in {'datasets', 'spaces'}:\n        if len(path_parts) > 1:\n            return normalize_slug(path_parts[1])\n        return None\n    return normalize_slug(path_parts[0])\nif host.endswith('.github.io'):\n    owner = host.removesuffix('.github.io')\n    return normalize_slug(owner) if owner else None\nif host == 'arxiv.org':\n    return None\n```"
  },
  {
    "id": 3677101235,
    "source": "**[medium] repeat runs** — Reusing an output directory creates duplicate logical evaluations\n\n`save_evaluation_log()` creates a new UUID filename on every call. Instance mode also creates another full sidecar. Stable `evaluation_id` values therefore do not make the filesystem output idempotent.\n\nAn adapter-owned aggregate and sidecar can be replaced as one set. The sidecar needs a fresh write because its current append mode would otherwise duplicate rows.",
    "rendered": "**[medium] repeat runs** — `save_evaluation_log()` creates a new UUID filename on every call, and instance mode also creates another full sidecar. Stable `evaluation_id` values therefore do not make filesystem output idempotent, so reusing an output directory creates duplicate logical evaluations. Please replace the adapter-owned aggregate and sidecar as one set, writing the sidecar afresh because its current append mode would otherwise duplicate rows."
  },
  {
    "id": 3677104436,
    "source": "**[medium] duplicate variants** — Explicit-file validation cannot see compressed siblings\n\n`expand_paths()` returns only the named file, and this call checks that limited list. `abc.json.gz` can therefore escape the one-variant rule when the caller names only `abc.json`.\n\nCollision discovery can inspect same-parent, same-stem variants while payload validation stays limited to requested files.",
    "rendered": "**[medium] duplicate variants** — `expand_paths()` returns only the named file, and this call checks only that limited list. `abc.json.gz` can therefore escape the one-variant rule when the caller names only `abc.json`. Please inspect same-parent, same-stem variants for collision discovery while keeping payload validation limited to requested files."
  },
  {
    "id": 3677218975,
    "source": "**[high] schema versioning** — New instance records keep `instance_level_eval_0.2.2`, although the existing 0.2.2 model rejects `modality` and null `is_correct`. The old aggregate model also discards the new modality under its unchanged identifier.\n\nThe extension is well scoped; its schema copies, emitters, models, fixtures, tests, and current-version docs can move to new identifiers together.",
    "rendered": "**[high] schema versioning** — New instance records keep `instance_level_eval_0.2.2`, although the existing 0.2.2 model rejects `modality` and null `is_correct`. The old aggregate model also discards the new modality under its unchanged identifier. The extension is well scoped. Please move its schema copies, emitters, models, fixtures, tests, and current-version docs to new identifiers together."
  },
  {
    "id": 3677354603,
    "source": "**[medium] error handling** — A handled fetch, conversion, or write failure reaches the final `Done!` message and exits with status 0. Automation can treat a partial dataset as complete.\n\nIf this entry point keeps independent work, both outcomes can feed a final status that `__main__` propagates. Delegation may remove this duplicate path.",
    "rendered": "**[medium] error handling** — A handled fetch, conversion, or write failure reaches the final `Done!` message and exits with status 0. Automation can therefore treat a partial dataset as complete. Please feed both outcomes into a final status that `__main__` propagates if this entry point keeps independent work. Delegation may remove this duplicate path."
  },
  {
    "id": 3677461204,
    "source": "**[medium] error isolation** — Pydantic `ValidationError` is outside this catch tuple. One malformed benchmark can stop all later targets instead of joining the final partial-run report.\n\nThat error can stay inside the per-benchmark boundary while the adapter continues with later work.",
    "rendered": "**[medium] error isolation** — Pydantic `ValidationError` is outside this catch tuple. One malformed benchmark can stop all later targets instead of joining the final partial-run report. Please keep that error inside the per-benchmark boundary so the adapter continues with later work."
  },
  {
    "id": 3677564751,
    "source": "**[medium] score validation** — Supported replay input can emit values outside the source contract\n\n`float()` accepts booleans, NaN, infinity, Pass^k values outside 0–100, and negative costs. Current official submissions are valid, but local replay and custom sources can reach this path.\n\nPass metrics can use finite inclusive 0–100 checks. Cost can use a finite non-negative check, with booleans rejected before numeric conversion.",
    "rendered": "**[medium] score validation** — Supported replay input can emit values outside the source contract. `float()` accepts booleans, NaN, infinity, Pass^k values outside 0–100, and negative costs. Current official submissions are valid, but local replay and custom sources can reach this path. Please validate pass metrics as finite values in the inclusive 0–100 range and cost as finite and non-negative, rejecting booleans before numeric conversion."
  },
  {
    "id": 3677669726,
    "source": "**[medium] Pydantic schema** — The serialization schema excludes emitted sentinel strings\n\nThis serializer has no declared output union. Pydantic therefore describes the bound as number or null, although `model_dump_json()` can emit `\"Infinity\"` or `\"-Infinity\"`.\n\nEach bound can expose an accurate serialization contract for finite numbers, null, and its field-valid sentinel.",
    "rendered": "**[medium] Pydantic schema** — The serialization schema excludes emitted sentinel strings. This serializer has no declared output union, so Pydantic describes the bound as number or null even though `model_dump_json()` can emit `\"Infinity\"` or `\"-Infinity\"`. Please expose an accurate serialization contract for each bound covering finite numbers, null, and its field-valid sentinel."
  },
  {
    "id": 3677713059,
    "source": "**[medium] snapshot provenance** — One export can combine files from different revisions\n\nMetadata and the three CSVs are separate reads from mutable `main`. Metadata errors become an empty object, after which the adapter uses the current time and omits its promised version anchor.\n\nResolving one Hugging Face dataset revision can pin every live read. The dataset revision and manifest `source_git_commit` can remain separate provenance fields.",
    "rendered": "**[medium] snapshot provenance** — One export can combine files from different revisions because metadata and the three CSVs are separate reads from mutable `main`. Metadata errors become an empty object; the adapter then uses the current time and omits its promised version anchor. Please resolve one Hugging Face dataset revision and use it to pin every live read. The dataset revision and manifest `source_git_commit` can remain separate provenance fields."
  },
  {
    "id": 3699205371,
    "source": "`re.IGNORECASE` here is wider than the pairing logic, which is case-sensitive (`endswith('_samples.jsonl')` in `_aggregate_repo_path_for_samples`, and the sibling probe builds a lowercase path). A file named `<uuid>_Samples.jsonl` passes path validation but skips every companion rule: it needs no sibling aggregate, and no aggregate has to declare it. Verified: `check_path_structure` accepts the mixed-case path and `check_instance_companion` returns no errors for it.\n\nPublishers only emit lowercase names, so dropping `re.IGNORECASE` closes the hole with no loss. (A mixed-case `.JSON` suffix is already handled safely — it fails later with an `unsupported_extension` error — but lowercasing the rule set makes the two paths consistent.)\n\n---\n_Generated by [Claude Code](https://claude.ai/code)_",
    "rendered": "`re.IGNORECASE` here is wider than the pairing logic, which is case-sensitive: `_aggregate_repo_path_for_samples` uses `endswith('_samples.jsonl')`, and the sibling probe builds a lowercase path. A file named `<uuid>_Samples.jsonl` therefore passes path validation but skips every companion rule: it needs no sibling aggregate, and no aggregate has to declare it. Verified: `check_path_structure` accepts the mixed-case path and `check_instance_companion` returns no errors for it. Please drop `re.IGNORECASE` to close this hole with no loss; publishers only emit lowercase names, and a mixed-case `.JSON` suffix is already handled safely because it fails later with an `unsupported_extension` error, so lowercasing the rule set makes the two paths consistent."
  }
]
