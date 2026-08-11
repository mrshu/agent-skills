You rewrite GitHub inline code-review comments for a busy pull-request author. Human readability is the goal, but technical and action correctness are hard gates. The source is a review-only finding: proposed remediation was not implemented unless the source explicitly says otherwise.

For each input comment:
1. Keep its entire first line verbatim, including complete RAV ID, severity, area, punctuation, and title.
2. Preserve every material source fact: identifiers, numbers, technical verbs and actor-action-target relationships, triggers, conditions, quantifiers, diagnostic certainty, concrete results, valid behavior, and fix boundaries. Do not add or infer facts. If a shorter rewrite changes a fact, retain the source wording.
3. After the title, put the current code behavior first, the consequence second, and the requested change last. Use short sentences and plain words. Do not show Problem/Impact labels.
4. Classify every source predicate by behavior, not by modal grammar. Target behavior and source-backed required verification or documentation are author work. Accepted current behavior, allowed implementation boundaries, and explicitly optional follow-ups are no-change boundaries. Words such as can, could, or would do not make target behavior optional.
5. If omitting a target behavior, test, or documentation change leaves the source defect or required verification unresolved, make it an explicit author request. A source-backed test stated to cover or demonstrate the requested boundary is required unless the source explicitly calls it optional or additional. Never invent a test.
6. Do not turn a permission, exception, carve-out, optional follow-up, or acceptable unchanged behavior into an action. Keep it as short modal prose after the action it limits.
7. One independently implementable author obligation: one concise sentence beginning with Please and a direct action verb. Two or more: use exactly this structure and one direct-action bullet per obligation:

**Requested actions**

- <action>
- <action>

Keep a purpose, result, safety clause, and exact scope with the action it constrains. Do not split one invariant or a list governed by one rule. Order behavior changes before tests. Do not repeat Please in bullets.
8. If the source has no requested author work, stop after the consequence or preserve its suggestion as optional prose.
9. A reader must be able to act without reopening the diff. Prefer the exact source sentence over a fluent rewrite when uncertain.

Return valid JSON only, with this schema:
{
  "comments": [
    {"id": 123, "body": "complete rewritten comment"}
  ]
}
Return every input ID exactly once in input order. Do not return Markdown fences, explanations, fact locks, or fields other than id and body.

INPUT COMMENTS:
[
  {
    "id": 3725747241,
    "pr": 220,
    "created_at": "2026-08-06T03:45:51Z",
    "path": "every_eval_ever/converters/sayf_eval/adapter.py",
    "line": 184,
    "side": "RIGHT",
    "commit_id": "6bb7909f1e72151651d3136d88d89fc9e9e3eff0",
    "body": "**RAV-RUN1-R1-F001 [high] source-provenance** — The adapter puts the task slug in `source_data.dataset_name`\n\nThe source record already supplies the dataset name, but this line replaces it with a routing slug. Published records then identify task collections instead of datasets such as `CTI-Bench MCQ`.\n\nThe upstream name can stay in `source_data`; an explicit sayf-eval collection override can handle routing.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/220#discussion_r3725747241"
  },
  {
    "id": 3725776266,
    "pr": 227,
    "created_at": "2026-08-06T03:54:03Z",
    "path": "every_eval_ever/helpers/io.py",
    "line": 408,
    "side": "RIGHT",
    "commit_id": "86f4384051ff4a10f028169a522274e366269f8b",
    "body": "**RAV-RUN1-R1-F001 [medium] api-contract** — `output_dir` also supports report-identity paths below `data`\n\nThe CLI passes paths such as `data/lm_eval_samples`, and the tests require `adapter_reports/lm_eval_samples_failures.json`. Calling the argument only a collection directory narrows a supported contract.\n\nThe wording can describe a path below the nearest `data` root. Its relative components form the report name, while `data/<collection>` remains the usual adapter case.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/227#discussion_r3725776266"
  },
  {
    "id": 3725827214,
    "pr": 223,
    "created_at": "2026-08-06T04:09:17Z",
    "path": "every_eval_ever/validator/validation_core.py",
    "line": 621,
    "side": "RIGHT",
    "commit_id": "7a847db5c9c8118622d47769b6fd03338acbed63",
    "body": "**RAV-RUN1-R1-F001 [medium] schema-deferral** — Blank model IDs bypass the new identity-path check\n\nThe schema accepts blank strings, but this guard returns before `datastore_path_components` can reject them. Such a record can pass without any warning that its identity names no directory.\n\nMissing or non-string IDs can stay with schema validation, while blank strings can use the helper's focused error path.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/223#discussion_r3725827214"
  },
  {
    "id": 3725830949,
    "pr": 230,
    "created_at": "2026-08-06T04:10:25Z",
    "path": "every_eval_ever/validator/validation_core.py",
    "line": 792,
    "side": "RIGHT",
    "commit_id": "abf080913d7ede5886fb0f2259056850320325e4",
    "body": "**RAV-RUN1-R1-F003 [medium] warning-visibility** — The new warning stays hidden in the default rich output without PR #221\n\nWarning severity leaves the report valid. The current rich renderer prints `PASS` and returns before its warning loop.\n\nPR #221 is already listed as a prerequisite. After rebase, one default-rich CLI check for this warning would confirm the complete path.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/230#discussion_r3725830949"
  },
  {
    "id": 3725853144,
    "pr": 190,
    "created_at": "2026-08-06T04:17:11Z",
    "path": "every_eval_ever/converters/alpaca_eval/adapter.py",
    "line": 687,
    "side": "RIGHT",
    "commit_id": "1983a5f858a9111576dfcd10bd0bc65bd93028c0",
    "body": "**RAV-RUN2-R1-F001 [medium] model-identity** — Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect this join key.\n\nOnly model IDs emitted by the pinned snapshot need vendored resolution. The source-derived ID can remain a marked fallback.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853144"
  },
  {
    "id": 3725913011,
    "pr": 203,
    "created_at": "2026-08-06T04:33:46Z",
    "path": "utils/wild/adapter.py",
    "line": 142,
    "side": "RIGHT",
    "commit_id": "6c8e3b20a4fbff2d332cab3ccbe544bac618f87a",
    "body": "**RAV-RUN2-R1-F003 [medium] memory-use** — Capped instance runs still materialize all selected columns for a complete row group before the cap is checked. The cap does not bound this allocation.\n\nBounded record batches can flush and hash incrementally.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913011"
  },
  {
    "id": 3726043677,
    "pr": 209,
    "created_at": "2026-08-06T05:08:35Z",
    "path": "every_eval_ever/adapters/paperswithcode/adapter.py",
    "line": 471,
    "side": "RIGHT",
    "commit_id": "c1fb2bcc214dd2c201b03c1d174bf53630e87ed8",
    "body": "**RAV-RUN2-R1-F003 [high] score-scaling** — The adapter divides a group by 100 when its median is out of range and 90 percent then fit. This decision ignores source scale evidence.\n\nRescaling can require an explicit recognized marker and compatible canonical definition. Other out-of-range cells can stay out of publication and retain raw provenance in the failure report.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043677"
  },
  {
    "id": 3726043685,
    "pr": 209,
    "created_at": "2026-08-06T05:08:35Z",
    "path": "every_eval_ever/adapters/paperswithcode/adapter.py",
    "line": 1415,
    "side": "RIGHT",
    "commit_id": "c1fb2bcc214dd2c201b03c1d174bf53630e87ed8",
    "body": "**RAV-RUN2-R1-F006 [medium] runtime-dependencies** — The default download path needs `huggingface_hub` 1.x, but the project requires a version below 1.0. The declared environment exits before download.\n\n`--dump` can be required in the current environment until the declared client supports bucket access.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043685"
  }
]
