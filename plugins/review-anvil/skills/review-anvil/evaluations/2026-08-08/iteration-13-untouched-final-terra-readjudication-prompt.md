Re-adjudicate whether Terra's final action-lock failures applied the frozen behavior-based rubric. Do not rewrite comments and do not judge readability. Source modal grammar is not decisive. In code review prose, `can`, `could`, `would`, `consider`, a question, or a polite suggestion does not make target behavior optional when omitting the change leaves the stated defect unresolved. Classify target behavior, required verification, and required documentation as author work. Classify accepted current behavior, an allowed implementation boundary, and an explicitly optional or longer-term follow-up as no-change/optional. Preserve `nit` and degree qualifiers as facts.

For each row, first identify the defect and apply the omission counterfactual. Then classify Terra's failure:
- `valid_failure`: the candidate really loses a fact, misses author work, invents author work from an explicitly optional/no-change predicate, or changes a boundary.
- `protocol_failure`: Terra rejected a correct direct request solely because the source used modal, question, `consider`, or polite grammar even though behavior makes it target work.

Return JSON only:
{"items":[{"id":123,"terra_status":"valid_failure|protocol_failure","source_classification":"author_work|optional_or_no_change|mixed|fact_only","reason":"two sentences naming the defect/omission counterfactual and exact wording","remaining_candidate_issues":[]}],"counts":{"valid_failure":0,"protocol_failure":0}}
Return every input ID exactly once in input order. Quote exact source and candidate wording for every valid failure. No Markdown fences or text outside JSON.

ROWS:
[
  {
    "id": 3525225568,
    "source": "I personally think it would make more sense to make it a specific option for this command and execute it after this handle command?",
    "candidate": "Please make this a specific option for this command and execute it after this handle command; I personally think that would make more sense.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"I personally think it would make more sense to make it a specific option for this command and execute it after this handle command?\" Candidate: \"Please make this a specific option for this command and execute it after this handle command\". The candidate turns a personal, interrogative suggestion into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 2614980077,
    "source": "The error message \"No new files to add, keeping existing X file(s)\" uses \"file(s)\" which is ambiguous in this context. Since this is counting rows in the parquet file (each row represents a JSON file), consider clarifying the message to say \"No new rows to add, keeping existing X row(s)\" or \"No new entries to add\" to better reflect what's being counted.\n```suggestion\n        print(f\"No new rows to add, keeping existing {len(existing_df)} row(s)\")\n```",
    "candidate": "The error message `No new files to add, keeping existing X file(s)` uses `file(s)`, which is ambiguous here because this counts rows in the parquet file, with each row representing a JSON file. Please clarify the message to say `No new rows to add, keeping existing X row(s)` or `No new entries to add`.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"consider clarifying the message\". Candidate: \"Please clarify the message\". The candidate changes a consideration into required author work."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 2614980178,
    "source": "The manifest is created even when there are no changes (empty \"modified\" list). While this is handled correctly by the upload script, consider adding a comment explaining why an empty manifest is still created (likely for debugging or workflow clarity purposes).\n```suggestion\n        print(\"No changes detected, nothing to upload\")\n        # Always create and write an (empty) manifest file, even when there are no changes.\n        # This ensures downstream scripts have a consistent file to read, and aids in debugging/workflow clarity.\n```",
    "candidate": "The manifest is created even when `modified` is empty. The upload script handles this correctly, but the reason for keeping an empty manifest is not documented. Please add a comment explaining why the empty manifest is still written, including that it gives downstream scripts a consistent file to read and likely aids debugging or workflow clarity.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"consider adding a comment explaining why an empty manifest is still created\". Candidate: \"Please add a comment explaining why the empty manifest is still written\". The candidate changes a consideration into required author work."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3096650221,
    "source": "**N+1 loading.** For each URL you run a `DESCRIBE` then an `INSERT ... SELECT`. DuckDB's `read_parquet(urls, union_by_name=true, filename=true)` handles missing columns across a heterogeneous list in one call — you already rely on this a few lines up for schemas. If the strict `NOT NULL` typing on `{table}_instances` is the reason you can't use the fast path, a one-line comment explaining that would help future readers. Otherwise replace the loop with a single `INSERT ... SELECT ... FROM read_parquet(?, union_by_name=true, filename=true)` passing the full `instance_urls` list.",
    "candidate": "**N+1 loading.** For every URL, this runs a `DESCRIBE` followed by an `INSERT ... SELECT`. DuckDB can handle missing columns across the heterogeneous list in one `read_parquet(urls, union_by_name=true, filename=true)` call, as the schema code a few lines above already does. Please either replace the loop with one `INSERT ... SELECT ... FROM read_parquet(?, union_by_name=true, filename=true)` using the full `instance_urls` list, or add a one-line comment if strict `NOT NULL` typing on `{table}_instances` prevents that fast path.",
    "terra_failure": {
      "fact_losses": [
        "Source: \"a one-line comment explaining that would help future readers\". Candidate: \"add a one-line comment if strict `NOT NULL` typing on `{table}_instances` prevents that fast path\". The candidate omits the stated result that the explanatory comment would help future readers."
      ],
      "missing_author_work": [],
      "false_actions": [],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3102848524,
    "source": "For the `.txt` path case, the test matches the same 'Could not find file or directory' message used for missing paths. That message is a bit misleading for an existing-but-unsupported file, and matching on it makes the intent (unsupported extension rejection) less clear. Consider either asserting only that an exception is raised for non-JSON files, or (longer-term) updating `expand_paths` to raise a distinct exception/message for unsupported extensions.\n```suggestion\n\n    with pytest.raises(Exception):\n```",
    "candidate": "For the existing `.txt` path, the test matches the same \"Could not find file or directory\" message used for missing paths. That message is a bit misleading for an existing but unsupported file, and matching it obscures that the test covers unsupported-extension rejection. Please either assert only that non-JSON files raise an exception, or, as a longer-term change, make `expand_paths` raise a distinct exception or message for unsupported extensions.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"Consider either asserting only that an exception is raised for non-JSON files, or (longer-term) updating `expand_paths`\". Candidate: \"Please either assert only that non-JSON files raise an exception, or, as a longer-term change, make `expand_paths`\". The candidate turns optional alternatives into a direct request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3134292915,
    "source": "`MODEL_DEVELOPER_MAP` maps `qwen` → `alibaba`, but other adapters in this repo use `qwen` as the developer slug (e.g. `utils/arc_agi/adapter.py` and `utils/sciarena/adapter.py`). This will make HAL exports inconsistent with the rest of the dataset and may split Qwen models across two developer directories depending on whether `MODEL_ID_OVERRIDES` fires. Consider using `qwen` here (or otherwise aligning the mapping + overrides so the developer slug is consistent).\n```suggestion\n    # Qwen\n    \"qwen\": \"qwen\",\n```",
    "candidate": "`MODEL_DEVELOPER_MAP` maps `qwen` → `alibaba`, while other adapters use `qwen` as the developer slug, including `utils/arc_agi/adapter.py` and `utils/sciarena/adapter.py`. This will make HAL exports inconsistent with the rest of the dataset and may split Qwen models across two developer directories depending on whether `MODEL_ID_OVERRIDES` fires. Please use `qwen` here, or otherwise align the mapping and overrides so the developer slug is consistent.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"Consider using `qwen` here (or otherwise aligning the mapping + overrides so the developer slug is consistent).\" Candidate: \"Please use `qwen` here, or otherwise align the mapping and overrides\". The candidate turns a consideration and its alternatives into required author work."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3493867085,
    "source": "This might end up being a bottleneck. It may be worth it to abstract the specific json reader / writer so the stdlib json is always an option, but you can opt-in to something like `orjson` or `ujson`. (Note: orjson is a bit opinionated. It's fast, but it also means you can't serialize generic floats like nans or infs, which technically isn't json, but the stdlib and ujson aren't so strict about it).\n\nI've handled this in a few ways in the past: simple wrappers: https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391\n\nAnd module level globals: https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117",
    "candidate": "This might end up being a bottleneck. An optional follow-up is to abstract the specific JSON reader/writer so stdlib `json` is always an option while callers can opt in to `orjson` or `ujson`. `orjson` is fast but opinionated: it cannot serialize generic floats such as nans or infs, which technically are not JSON, while the stdlib and `ujson` are less strict. Similar approaches include simple wrappers in https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391 and module-level globals in https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117.",
    "terra_failure": {
      "fact_losses": [
        "Source: \"I've handled this in a few ways in the past: simple wrappers\" and \"And module level globals\". Candidate: \"Similar approaches include simple wrappers\" and \"module-level globals\". The candidate removes the reviewer's stated prior experience with these approaches."
      ],
      "missing_author_work": [],
      "false_actions": [],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3677101235,
    "source": "**[medium] repeat runs** — Reusing an output directory creates duplicate logical evaluations\n\n`save_evaluation_log()` creates a new UUID filename on every call. Instance mode also creates another full sidecar. Stable `evaluation_id` values therefore do not make the filesystem output idempotent.\n\nAn adapter-owned aggregate and sidecar can be replaced as one set. The sidecar needs a fresh write because its current append mode would otherwise duplicate rows.",
    "candidate": "**[medium] repeat runs** — `save_evaluation_log()` creates a new UUID filename on every call, and instance mode also creates another full sidecar. Stable `evaluation_id` values therefore do not make filesystem output idempotent, so reusing an output directory creates duplicate logical evaluations. Please replace the adapter-owned aggregate and sidecar as one set, writing the sidecar afresh because its current append mode would otherwise duplicate rows.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"An adapter-owned aggregate and sidecar can be replaced as one set.\" Candidate: \"Please replace the adapter-owned aggregate and sidecar as one set\". The candidate converts a possible solution into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3677104436,
    "source": "**[medium] duplicate variants** — Explicit-file validation cannot see compressed siblings\n\n`expand_paths()` returns only the named file, and this call checks that limited list. `abc.json.gz` can therefore escape the one-variant rule when the caller names only `abc.json`.\n\nCollision discovery can inspect same-parent, same-stem variants while payload validation stays limited to requested files.",
    "candidate": "**[medium] duplicate variants** — Explicit-file validation cannot see compressed siblings\n\n`expand_paths()` returns only the named file, and this call checks only that limited list. When the caller names only `abc.json`, `abc.json.gz` can therefore escape the one-variant rule. Please make collision discovery inspect same-parent, same-stem variants while keeping payload validation limited to the requested files.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"Collision discovery can inspect same-parent, same-stem variants while payload validation stays limited to requested files.\" Candidate: \"Please make collision discovery inspect same-parent, same-stem variants while keeping payload validation limited to the requested files.\" The candidate converts a possible solution into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3677218975,
    "source": "**[high] schema versioning** — New instance records keep `instance_level_eval_0.2.2`, although the existing 0.2.2 model rejects `modality` and null `is_correct`. The old aggregate model also discards the new modality under its unchanged identifier.\n\nThe extension is well scoped; its schema copies, emitters, models, fixtures, tests, and current-version docs can move to new identifiers together.",
    "candidate": "**[high] schema versioning** — New instance records keep `instance_level_eval_0.2.2`, although the existing 0.2.2 model rejects `modality` and null `is_correct`. The old aggregate model also discards the new modality under its unchanged identifier. The extension is well scoped. Please move its schema copies, emitters, models, fixtures, tests, and current-version docs to new identifiers together.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"its schema copies, emitters, models, fixtures, tests, and current-version docs can move to new identifiers together.\" Candidate: \"Please move its schema copies, emitters, models, fixtures, tests, and current-version docs to new identifiers together.\" The candidate converts a possible solution into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3677354603,
    "source": "**[medium] error handling** — A handled fetch, conversion, or write failure reaches the final `Done!` message and exits with status 0. Automation can treat a partial dataset as complete.\n\nIf this entry point keeps independent work, both outcomes can feed a final status that `__main__` propagates. Delegation may remove this duplicate path.",
    "candidate": "**[medium] error handling** — A handled fetch, conversion, or write failure reaches the final `Done!` message and exits with status 0. Automation can therefore treat a partial dataset as complete. Please feed both outcomes into a final status that `__main__` propagates if this entry point keeps independent work. Delegation may remove this duplicate path.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"If this entry point keeps independent work, both outcomes can feed a final status that `__main__` propagates.\" Candidate: \"Please feed both outcomes into a final status that `__main__` propagates if this entry point keeps independent work.\" The candidate converts a conditional possible solution into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3677461204,
    "source": "**[medium] error isolation** — Pydantic `ValidationError` is outside this catch tuple. One malformed benchmark can stop all later targets instead of joining the final partial-run report.\n\nThat error can stay inside the per-benchmark boundary while the adapter continues with later work.",
    "candidate": "**[medium] error isolation** — Pydantic `ValidationError` is outside this catch tuple. One malformed benchmark can stop all later targets instead of joining the final partial-run report. Please keep that error inside the per-benchmark boundary so the adapter continues with later work.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"That error can stay inside the per-benchmark boundary while the adapter continues with later work.\" Candidate: \"Please keep that error inside the per-benchmark boundary\". The candidate converts a possible solution into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3677564751,
    "source": "**[medium] score validation** — Supported replay input can emit values outside the source contract\n\n`float()` accepts booleans, NaN, infinity, Pass^k values outside 0–100, and negative costs. Current official submissions are valid, but local replay and custom sources can reach this path.\n\nPass metrics can use finite inclusive 0–100 checks. Cost can use a finite non-negative check, with booleans rejected before numeric conversion.",
    "candidate": "**[medium] score validation** — Supported replay input can emit values outside the source contract. `float()` accepts booleans, NaN, infinity, Pass^k values outside 0–100, and negative costs. Current official submissions are valid, but local replay and custom sources can reach this path. Please validate pass metrics as finite values in the inclusive 0–100 range and cost as finite and non-negative, rejecting booleans before numeric conversion.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"Pass metrics can use finite inclusive 0–100 checks. Cost can use a finite non-negative check, with booleans rejected before numeric conversion.\" Candidate: \"Please validate pass metrics as finite values in the inclusive 0–100 range and cost as finite and non-negative, rejecting booleans before numeric conversion.\" The candidate converts possible validation rules into required author work."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3677669726,
    "source": "**[medium] Pydantic schema** — The serialization schema excludes emitted sentinel strings\n\nThis serializer has no declared output union. Pydantic therefore describes the bound as number or null, although `model_dump_json()` can emit `\"Infinity\"` or `\"-Infinity\"`.\n\nEach bound can expose an accurate serialization contract for finite numbers, null, and its field-valid sentinel.",
    "candidate": "**[medium] Pydantic schema** — The serialization schema excludes emitted sentinel strings. This serializer has no declared output union, so Pydantic describes the bound as number or null even though `model_dump_json()` can emit `\"Infinity\"` or `\"-Infinity\"`. Please expose an accurate serialization contract for each bound covering finite numbers, null, and its field-valid sentinel.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"Each bound can expose an accurate serialization contract for finite numbers, null, and its field-valid sentinel.\" Candidate: \"Please expose an accurate serialization contract for each bound\". The candidate converts a possible solution into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3677713059,
    "source": "**[medium] snapshot provenance** — One export can combine files from different revisions\n\nMetadata and the three CSVs are separate reads from mutable `main`. Metadata errors become an empty object, after which the adapter uses the current time and omits its promised version anchor.\n\nResolving one Hugging Face dataset revision can pin every live read. The dataset revision and manifest `source_git_commit` can remain separate provenance fields.",
    "candidate": "**[medium] snapshot provenance** — One export can combine files from different revisions because metadata and the three CSVs are separate reads from mutable `main`. Metadata errors become an empty object; the adapter then uses the current time and omits its promised version anchor. Please resolve one Hugging Face dataset revision and use it to pin every live read. The dataset revision and manifest `source_git_commit` can remain separate provenance fields.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"Resolving one Hugging Face dataset revision can pin every live read.\" Candidate: \"Please resolve one Hugging Face dataset revision and use it to pin every live read.\" The candidate converts a possible solution into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  },
  {
    "id": 3699205371,
    "source": "`re.IGNORECASE` here is wider than the pairing logic, which is case-sensitive (`endswith('_samples.jsonl')` in `_aggregate_repo_path_for_samples`, and the sibling probe builds a lowercase path). A file named `<uuid>_Samples.jsonl` passes path validation but skips every companion rule: it needs no sibling aggregate, and no aggregate has to declare it. Verified: `check_path_structure` accepts the mixed-case path and `check_instance_companion` returns no errors for it.\n\nPublishers only emit lowercase names, so dropping `re.IGNORECASE` closes the hole with no loss. (A mixed-case `.JSON` suffix is already handled safely — it fails later with an `unsupported_extension` error — but lowercasing the rule set makes the two paths consistent.)\n\n---\n_Generated by [Claude Code](https://claude.ai/code)_",
    "candidate": "`re.IGNORECASE` here is wider than the pairing logic, which is case-sensitive: `_aggregate_repo_path_for_samples` uses `endswith('_samples.jsonl')`, and the sibling probe builds a lowercase path. A file named `<uuid>_Samples.jsonl` therefore passes path validation but skips every companion rule: it needs no sibling aggregate, and no aggregate has to declare it. Verified: `check_path_structure` accepts the mixed-case path and `check_instance_companion` returns no errors for it. Please drop `re.IGNORECASE` to close this hole with no loss; publishers only emit lowercase names, and a mixed-case `.JSON` suffix is already handled safely because it fails later with an `unsupported_extension` error, so lowercasing the rule set makes the two paths consistent.",
    "terra_failure": {
      "fact_losses": [],
      "missing_author_work": [],
      "false_actions": [
        "Source: \"dropping `re.IGNORECASE` closes the hole with no loss.\" Candidate: \"Please drop `re.IGNORECASE` to close this hole with no loss\". The candidate converts a stated possible fix into a direct author request."
      ],
      "changed_action_boundaries": []
    }
  }
]
