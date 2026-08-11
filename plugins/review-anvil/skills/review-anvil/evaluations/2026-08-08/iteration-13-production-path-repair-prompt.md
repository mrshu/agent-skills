Repair only the five production Luna draft comments that failed either post-render action-lock auditor. Apply the union of instructions. Preserve the title/diagnosis, evidence, source facts, severity, identifiers, qualifiers, conditions, and already-correct request predicates. Do not invent actions or omit source work. After repair, apply the production form: one concise `Please` sentence for one obligation or `**Requested actions**` with one bullet per obligation for two or more; keep permissions and accepted behavior in modal prose.

Return valid JSON only:
{"comments":[{"id":123,"body":"complete repaired comment","rendered_requested_work":"exact request and boundary prose copied from body"}]}
Return every ID exactly once in input order. No Markdown fences or text outside JSON.

ROWS:
[
  {
    "id": 2614980178,
    "source": "The manifest is created even when there are no changes (empty \"modified\" list). While this is handled correctly by the upload script, consider adding a comment explaining why an empty manifest is still created (likely for debugging or workflow clarity purposes).\n```suggestion\n        print(\"No changes detected, nothing to upload\")\n        # Always create and write an (empty) manifest file, even when there are no changes.\n        # This ensures downstream scripts have a consistent file to read, and aids in debugging/workflow clarity.\n```",
    "candidate": "The manifest is created even when there are no changes (an empty `modified` list), and the upload script handles this correctly. The reason for always creating the empty manifest is not documented for downstream readers, debugging, or workflow clarity.\n\n**Requested actions**\n\n- Add `print(\"No changes detected, nothing to upload\")`.\n- Add a comment explaining why an empty manifest is still created so downstream scripts have a consistent file to read and this aids debugging and workflow clarity.",
    "repair_instructions": [
      "claude: Delete the bullet requesting `print(\"No changes detected, nothing to upload\")`; it is not derived from any source predicate.",
      "claude: Restore the accepted-current-behavior clause \"this is handled correctly by the upload script\" attached to the comment request.",
      "claude: Restore the source hedge on the purpose (\"likely for debugging or workflow clarity purposes\") rather than asserting the purpose outright.",
      "sol: Remove the unsourced `print(\"No changes detected, nothing to upload\")` action; retain only the direct request for the explanatory comment."
    ]
  },
  {
    "id": 3161743720,
    "source": "nit: could we build this title and filename (line 448) from `top_n`, e.g. `f'Top {top_n} Benchmarks by Number of Models'` and `f'top{top_n}_benchmarks_by_models.png'`? That way the plot stays accurate when someone runs the CLI with `--top-n 3` or another value, instead of hardcoding `Top 10`.\n",
    "candidate": "The plot title and filename are hardcoded to `Top 10`, including the filename on line 448. This makes the plot inaccurate when the CLI runs with `--top-n 3` or another value. Please build the title and filename from `top_n`, for example `f'Top {top_n} Benchmarks by Number of Models'` and `f'top{top_n}_benchmarks_by_models.png'`.",
    "repair_instructions": [
      "claude: Restore the \"(line 448)\" locator on the filename target so the request reads as building the title and the filename at line 448 from `top_n`."
    ]
  },
  {
    "id": 3493867085,
    "source": "This might end up being a bottleneck. It may be worth it to abstract the specific json reader / writer so the stdlib json is always an option, but you can opt-in to something like `orjson` or `ujson`. (Note: orjson is a bit opinionated. It's fast, but it also means you can't serialize generic floats like nans or infs, which technically isn't json, but the stdlib and ujson aren't so strict about it).\n\nI've handled this in a few ways in the past: simple wrappers: https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391\n\nAnd module level globals: https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117",
    "candidate": "This might end up being a bottleneck. An optional follow-up is to abstract the specific JSON reader/writer so stdlib `json` is always an option while callers can opt in to `orjson` or `ujson`. `orjson` is fast but opinionated: it cannot serialize generic floats such as nans or infs, which technically are not JSON, while the stdlib and `ujson` are less strict. Similar approaches include simple wrappers in https://gitlab.kitware.com/computer-vision/kwutil/-/blob/main/kwutil/util_json.py?blame=1&ref_type=heads#L391 and module-level globals in https://gitlab.kitware.com/computer-vision/kwcoco/-/blob/main/kwcoco/coco_dataset.py?blame=1&ref_type=heads#L117.",
    "repair_instructions": [
      "claude: Render the abstraction predicate as a direct request (abstract the JSON reader/writer so stdlib `json` remains an option while callers can opt in to `orjson` or `ujson`).",
      "claude: Remove the \"An optional follow-up is to\" framing, which is not present in the source.",
      "claude: Keep the `orjson` caveat about non-serializable nans/infs and both reference links as supporting prose attached to the request.",
      "sol: Express the JSON reader/writer abstraction as a direct request, preserving that stdlib `json` remains available and `orjson` or `ujson` are opt-in choices."
    ]
  },
  {
    "id": 3520340907,
    "source": "Is this path intentional? We write the file as `data/adapter_stats.json` below, but read `adapter_stats.json` from the repository root here. Also, this reads from the default branch while the upload creates a PR, so I’m not sure the state from one run will be available to the next one.",
    "candidate": "The file is written as `data/adapter_stats.json` below, but this code reads `adapter_stats.json` from the repository root. It also reads from the default branch while the upload creates a PR, so the state from one run may not be available to the next. Please confirm whether this path and branch behavior is intentional.",
    "repair_instructions": [
      "sol: Restrict the direct confirmation request to whether the path is intentional; do not turn the branch-state diagnosis into an additional action."
    ]
  },
  {
    "id": 3652735574,
    "source": "Was this rename a workaround for `check_integer_counts()` rejecting stringified `samples_number` in `additional_details`? If the walk is fixed to skip `additional_details` (see my comment on `validation_core.py`), this could keep the conventional key name.",
    "candidate": "Was this rename a workaround for `check_integer_counts()` rejecting stringified `samples_number` in `additional_details`? If the walk is fixed to skip `additional_details` as discussed for `validation_core.py`, the conventional key name could be kept.",
    "repair_instructions": [
      "sol: Make keeping the conventional key name a direct request conditioned exactly on fixing the walk to skip `additional_details`, while retaining the workaround question."
    ]
  }
]
