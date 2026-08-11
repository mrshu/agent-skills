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
    "id": 3754142973,
    "pr": 209,
    "created_at": "2026-08-10T23:18:49Z",
    "path": "every_eval_ever/adapters/paperswithcode/adapter.py",
    "line": 95,
    "side": "RIGHT",
    "commit_id": "c1fb2bcc214dd2c201b03c1d174bf53630e87ed8",
    "body": "**RAV-RUN3-R1-F001 [high] model-identity** — A Hugging Face collection URL becomes a model identity\n\nThe expression excludes `datasets/` and `spaces/`, but it accepts `collections/`. `model_identity()` then reads `collections/<owner>` as a model repository. The source snapshot includes one collection URL, so this path is reachable.\n\nLocal URL-shape checks can reject reserved namespaces without adding network dependence. An independent fallback identity can remain available and marked unverified.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3754142973"
  },
  {
    "id": 3754142975,
    "pr": 209,
    "created_at": "2026-08-10T23:18:49Z",
    "path": "every_eval_ever/adapters/paperswithcode/adapter.py",
    "line": 1238,
    "side": "RIGHT",
    "commit_id": "c1fb2bcc214dd2c201b03c1d174bf53630e87ed8",
    "body": "**RAV-RUN3-R1-F002 [high] stable-identity** — Same-day snapshots can share an ID while their bundled content differs\n\n`dump_version_from_path()` discards the filename time. `evaluation_id` then uses only that date and the model ID. Two same-day backups can therefore produce different model bundles with one identity.\n\nAn immutable dump hash or object revision can identify the source. A stable digest of the bundle's included raw evaluation units can distinguish content without depending on selector syntax.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3754142975"
  },
  {
    "id": 3754206009,
    "pr": 188,
    "created_at": "2026-08-10T23:33:27Z",
    "path": "every_eval_ever/adapters/bountybench/adapter.py",
    "line": 97,
    "side": "RIGHT",
    "commit_id": "663e3d5836a819b67bec05ebdfa39e4f37ac55c9",
    "body": "**RAV-RUN2-R1-F004 [medium] workflow-identity** — The fallback maps distinct accepted labels such as `DetectWorkflow` and `Detect` to the same slug. Matching model, config, and timestamp values can then publish one evaluation identity.\n\nThe existing `WORKFLOW_SLUGS` map provides a clear boundary. Unknown names can enter the normal source-failure path until their semantics are mapped.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/188#discussion_r3754206009"
  },
  {
    "id": 3754206017,
    "pr": 188,
    "created_at": "2026-08-10T23:33:27Z",
    "path": "every_eval_ever/adapters/bountybench/adapter.py",
    "line": 316,
    "side": "RIGHT",
    "commit_id": "663e3d5836a819b67bec05ebdfa39e4f37ac55c9",
    "body": "**RAV-RUN2-R1-F005 [medium] attempt-selection** — The shared ranking makes `best` choose the latest final tie. It also makes `latest` prefer an earlier usable attempt over a later startup failure.\n\nPolicy-specific rankings over numeric `start_epoch` would align selection with the README and avoid lexical timestamp ordering.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/188#discussion_r3754206017"
  },
  {
    "id": 3754206021,
    "pr": 188,
    "created_at": "2026-08-10T23:33:27Z",
    "path": "every_eval_ever/adapters/bountybench/adapter.py",
    "line": 727,
    "side": "RIGHT",
    "commit_id": "663e3d5836a819b67bec05ebdfa39e4f37ac55c9",
    "body": "**RAV-RUN2-R1-F006 [medium] source-accounting** — Attempt selection happens before startup exclusions. A startup row can disappear when a retry wins, while an all-startup group also adds a synthetic exclusion and can count one row twice.\n\nA ledger derived once from the original group would preserve one accounting entry per source row.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/188#discussion_r3754206021"
  },
  {
    "id": 3754206025,
    "pr": 188,
    "created_at": "2026-08-10T23:33:27Z",
    "path": "every_eval_ever/adapters/bountybench/adapter.py",
    "line": 822,
    "side": "RIGHT",
    "commit_id": "663e3d5836a819b67bec05ebdfa39e4f37ac55c9",
    "body": "**RAV-RUN2-R1-F008 [medium] output-path** — Publication receives `args.output_dir.parent` and appends `bountybench`. A request such as `/safe/job/chosen` therefore writes to `/safe/job/bountybench`.\n\nEarly validation of the documented collection-directory shape would keep staging, reports, and publication on the requested path.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/188#discussion_r3754206025"
  },
  {
    "id": 3754223961,
    "pr": 197,
    "created_at": "2026-08-10T23:36:57Z",
    "path": "every_eval_ever/adapters/benchpress/adapter.py",
    "line": 557,
    "side": "RIGHT",
    "commit_id": "c3d16fe138396b433a9393ab61a7ad1391b546e0",
    "body": "**RAV-RUN3-R1-F001 [high] data-selection** — A missing `audit_status` column can produce a successful empty run\n\n`_parse_scores()` reads this field with `get()`. This branch then treats every absent value as a normal exclusion. With all rows excluded, no failure reaches `raise_if_incomplete()`.\n\nMissing or blank status values can become row failures before policy filtering. A fresh report and non-zero exit would preserve the incompatible export evidence.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3754223961"
  },
  {
    "id": 3754223973,
    "pr": 197,
    "created_at": "2026-08-10T23:36:57Z",
    "path": "every_eval_ever/adapters/benchpress/adapter.py",
    "line": 628,
    "side": "RIGHT",
    "commit_id": "c3d16fe138396b433a9393ab61a7ad1391b546e0",
    "body": "**RAV-RUN3-R1-F002 [high] stable-identity** — The ID does not include the immutable score-matrix revision\n\nThis timestamp can fall back to conversion time, and the source manifest can lag the pinned CSV revision. Replays can change identity, while distinct revisions can collide.\n\nThe raw model, relationship, and required `dataset_revision` can define the ID. Generated and retrieved times can stay as metadata.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3754223973"
  },
  {
    "id": 3754223975,
    "pr": 197,
    "created_at": "2026-08-10T23:36:57Z",
    "path": "every_eval_ever/adapters/benchpress/adapter.py",
    "line": 352,
    "side": "RIGHT",
    "commit_id": "c3d16fe138396b433a9393ab61a7ad1391b546e0",
    "body": "**RAV-RUN3-R1-F003 [medium] model-metadata** — Typed availability remains unknown despite source evidence\n\nThe source provides `open_weights` values, and this code keeps them only as raw additional detail. `ModelInfo` then fills `model_availability` with `unknown`.\n\nRecognized booleans can map to `open_weights` or `closed_weights`. Unknown tokens can remain typed `unknown`, with their raw text preserved.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3754223975"
  },
  {
    "id": 3754223977,
    "pr": 197,
    "created_at": "2026-08-10T23:36:57Z",
    "path": "every_eval_ever/adapters/benchpress/adapter.py",
    "line": 470,
    "side": "RIGHT",
    "commit_id": "c3d16fe138396b433a9393ab61a7ad1391b546e0",
    "body": "**RAV-RUN3-R1-F004 [medium] metric-semantics** — Known global metrics receive benchmark-specific IDs and source scales\n\nThe AIME fixture declares percent correct, but this path emits `benchpress.aime-2025.score` on a 0–100 scale. That result cannot join canonical accuracy records.\n\nA pinned mapping can canonicalize metrics only when source metadata proves their meaning. Score, bounds, unit, and direction can convert together; ambiguous ratings can remain namespaced.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3754223977"
  },
  {
    "id": 3754223982,
    "pr": 197,
    "created_at": "2026-08-10T23:36:57Z",
    "path": "every_eval_ever/adapters/benchpress/adapter.py",
    "line": 559,
    "side": "RIGHT",
    "commit_id": "c3d16fe138396b433a9393ab61a7ad1391b546e0",
    "body": "**RAV-RUN3-R1-F005 [medium] exclusion-accounting** — Repeated exclusion references lose row-level detail\n\nThis exclusion stores only the model and benchmark reference. The fixture contains repeated references, so the report cannot distinguish their scores, citations, or status values.\n\nEach exclusion can retain its complete score row through the existing `source_record` field.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3754223982"
  },
  {
    "id": 3754223992,
    "pr": 197,
    "created_at": "2026-08-10T23:36:57Z",
    "path": "every_eval_ever/adapters/benchpress/adapter.py",
    "line": 631,
    "side": "RIGHT",
    "commit_id": "c3d16fe138396b433a9393ab61a7ad1391b546e0",
    "body": "**RAV-RUN3-R1-F006 [medium] evaluation-metadata** — The aggregator is recorded as the evaluation harness\n\nBenchPress re-reports scores from varied harnesses, which the results already retain. This log-level value states that BenchPress ran every evaluation in the group.\n\nA common harness can populate this field only when every result agrees. Mixed groups can use `unknown` while keeping each result's source claim.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3754223992"
  },
  {
    "id": 3754223999,
    "pr": 197,
    "created_at": "2026-08-10T23:36:57Z",
    "path": "every_eval_ever/adapters/benchpress/adapter.py",
    "line": 603,
    "side": "RIGHT",
    "commit_id": "c3d16fe138396b433a9393ab61a7ad1391b546e0",
    "body": "**RAV-RUN3-R1-F007 [medium] duplicate-accounting** — Equal duplicate rows disappear from the source ledger\n\nThis branch keeps one result and silently skips the later equal row. `total_records` still includes both, but neither failures nor exclusions identifies the duplicate.\n\nExact source-cell duplicates can remain deduplicated while later rows become exclusions with their complete `source_record`.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3754223999"
  },
  {
    "id": 3754264211,
    "pr": 204,
    "created_at": "2026-08-10T23:44:26Z",
    "path": "every_eval_ever/adapters/open_medical_llm/adapter.py",
    "line": 378,
    "side": "RIGHT",
    "commit_id": "c6cec44a9d0835872578a261aed7fb65fef9014f",
    "body": "**RAV-RUN4-R1-F001 [medium] canonical routing** — Registry resolution updates `model_info.id`, while this route still comes from the reconciled Hugging Face repository. When those identities differ, canonical-ID consumers can miss the published record. The final route can use the shared datastore identity helpers, with both raw identities retained as provenance.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3754264211"
  },
  {
    "id": 3754264213,
    "pr": 204,
    "created_at": "2026-08-10T23:44:26Z",
    "path": "every_eval_ever/adapters/open_medical_llm/adapter.py",
    "line": 383,
    "side": "RIGHT",
    "commit_id": "c6cec44a9d0835872578a261aed7fb65fef9014f",
    "body": "**RAV-RUN4-R1-F002 [medium] benchmark completeness** — This loop skips missing tasks and tasks without `acc,none`, while the record succeeds if any one result remains. A partial source file can therefore publish fewer than the documented nine benchmarks without an accounting entry. Validation at the worker boundary, plus a partial-file fixture, would keep that omission visible.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3754264213"
  },
  {
    "id": 3754357957,
    "pr": 230,
    "created_at": "2026-08-11T00:07:33Z",
    "path": "every_eval_ever/validator/validation_core.py",
    "line": 631,
    "side": "RIGHT",
    "commit_id": "abf080913d7ede5886fb0f2259056850320325e4",
    "body": "**RAV-RUN4-R1-F001 [medium] path-semantics** — An unroutable namespaced ID can enter flat-ID warning behavior\n\nFor `/model`, `_developer_prefix()` returns an empty string. This branch then treats `model_info.developer` as path-defining, while `datastore_path_components()` rejects the same ID because its namespace is empty. A warning-only run can therefore exit `2` for a routing claim the publisher cannot make.\n\nIdentity parsing can distinguish flat, namespaced, and unroutable states before registry lookup. Leading, trailing, and repeated empty components can return no alias warning.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/230#discussion_r3754357957"
  },
  {
    "id": 3754371416,
    "pr": 235,
    "created_at": "2026-08-11T00:11:13Z",
    "path": "every_eval_ever/converters/lighteval/adapter.py",
    "line": 106,
    "side": "RIGHT",
    "commit_id": "deb0b8ddbe69fe9212b8191d7bdfe73a86d4ad0e",
    "body": "**RAV-RUN2-R1-F001 [high] model routing** — A bare `model_name` leaves `developer` unset here. The adapter can build the log, but publication rejects a one-component model ID without a developer route. Shared model helpers, registry resolution, and an explicit identity override can cover known and operator-supplied names; an unresolved unsafe route can remain a structured source failure.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3754371416"
  },
  {
    "id": 3754371417,
    "pr": 235,
    "created_at": "2026-08-11T00:11:13Z",
    "path": "every_eval_ever/converters/lighteval/adapter.py",
    "line": 598,
    "side": "RIGHT",
    "commit_id": "deb0b8ddbe69fe9212b8191d7bdfe73a86d4ad0e",
    "body": "**RAV-RUN2-R1-F002 [medium] task isolation** — These sibling tasks share one file-level exception boundary. If a later task raises, this function never returns the valid logs already accumulated, so the result contains only the file failure. Per-task conversion can retain valid siblings and aggregate failed-task detail into the existing file-grain report.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3754371417"
  },
  {
    "id": 3754371419,
    "pr": 235,
    "created_at": "2026-08-11T00:11:13Z",
    "path": "every_eval_ever/converters/lighteval/__main__.py",
    "line": 25,
    "side": "RIGHT",
    "commit_id": "deb0b8ddbe69fe9212b8191d7bdfe73a86d4ad0e",
    "body": "**RAV-RUN2-R1-F003 [medium] CLI provenance** — This entry point defaults organization to an empty string and evaluator relationship to `first_party`, while the top-level LightEval command uses `unknown` and `third_party`. Sharing one parser/default definition would keep identical inputs from receiving different implicit provenance.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3754371419"
  },
  {
    "id": 3754404625,
    "pr": 243,
    "created_at": "2026-08-11T00:20:00Z",
    "path": "tests/test_helm_generation_args.py",
    "line": 17,
    "side": "RIGHT",
    "commit_id": "d66facf1a24e53e9f84172425c7e1368789ea9a2",
    "body": "**RAV-RUN1-R1-F001 [medium] tests** — Nice improvement over checking only `import helm`: the converter guard is the right signal for these cases. One follow-up worth considering is preserving a failing signal when HELM *is installed* but a guarded converter import is broken. Because this module-wide marker skips for every `_HELM_IMPORT_ERROR`, the full `--all-extras` CI rows can also pass with a skipped HELM suite. Could we move this marker onto the generation-argument tests and add one unmarked sentinel that skips only when the top-level `helm` package is absent, but otherwise calls `_require_helm_dependencies()`? That would keep core installs optional while checking that a full HELM install is actually usable.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/243#discussion_r3754404625"
  },
  {
    "id": 3754410441,
    "pr": 241,
    "created_at": "2026-08-11T00:21:35Z",
    "path": ".agents/skills/eee-datastore-pr-review/assets/collection-review-decision.md",
    "line": 10,
    "side": "RIGHT",
    "commit_id": "5f861a59bc33690e0640fcd538fe031b3c6afcf5",
    "body": "**RAV-RUN1-R1-F001 [medium] audit-closure** — The append-only record can remain at `pending` after validation completes. This entry must exist before upload, while the matching bot run exists only afterward, and the later workflow does not define a closure entry. A receipt-only append linked to this decision and the validated data head would preserve both completeness and append-only history.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/241#discussion_r3754410441"
  },
  {
    "id": 3754410447,
    "pr": 241,
    "created_at": "2026-08-11T00:21:35Z",
    "path": ".agents/skills/eee-datastore-pr-review/assets/collection-review-decision.md",
    "line": 14,
    "side": "RIGHT",
    "commit_id": "5f861a59bc33690e0640fcd538fe031b3c6afcf5",
    "body": "**RAV-RUN1-R1-F002 [medium] evidence-resolution** — These source IDs have no resolver when `Approved proposal` is `n/a`, and the approval field above has no durable event URL or receipt ID. A compact per-entry Sources section plus an approval-receipt field would let future readers trace both the evidence and authorization.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/241#discussion_r3754410447"
  },
  {
    "id": 3754410450,
    "pr": 241,
    "created_at": "2026-08-11T00:21:35Z",
    "path": ".agents/skills/eee-datastore-pr-review/reference/metadata-missingness.md",
    "line": 13,
    "side": "RIGHT",
    "commit_id": "5f861a59bc33690e0640fcd538fe031b3c6afcf5",
    "body": "**RAV-RUN1-R1-F003 [medium] authorization-scope** — This approval requirement also applies to temperature, token limits, and other non-deployment fields, but the skill defines a head-bound artifact only for deployment axes. Stating whether ordinary fix authorization or a lightweight head-bound receipt governs these backfills would keep the mutation boundary unambiguous.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/241#discussion_r3754410450"
  },
  {
    "id": 3754419474,
    "pr": 244,
    "created_at": "2026-08-11T00:24:14Z",
    "path": "tests/test_converter_conversion.py",
    "line": 79,
    "side": "RIGHT",
    "commit_id": "1267c9270c9a98ea29990b0eb69fca792dce6793",
    "body": "**RAV-RUN1-R1-F001 [medium] result assertions** — This dictionary overwrites duplicate evaluation/metric keys. Since the lm-eval case leaves `results` unset, an extra identical result can still pass the score mapping and semantic gate. An explicit `results=2` plus a uniqueness check before dictionary construction would preserve this useful declarative shape while catching duplicates.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/244#discussion_r3754419474"
  },
  {
    "id": 3754419477,
    "pr": 244,
    "created_at": "2026-08-11T00:24:14Z",
    "path": "tests/converter_cases.py",
    "line": 123,
    "side": "RIGHT",
    "commit_id": "1267c9270c9a98ea29990b0eb69fca792dce6793",
    "body": "**RAV-RUN1-R1-F002 [medium] optional dependencies** — Every stored import error becomes an unavailable skip here. Because Inspect and HELM capture broad exceptions, an installed but incompatible release can be skipped even in full CI. Declaring each optional distribution explicitly would let core skip a genuinely absent package while surfacing an installed package's captured import error.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/244#discussion_r3754419477"
  },
  {
    "id": 3754488852,
    "pr": 245,
    "created_at": "2026-08-11T00:40:18Z",
    "path": "every_eval_ever/converters/lm_eval/instance_level_adapter.py",
    "line": 153,
    "side": "RIGHT",
    "commit_id": "c46eec389e3ddb15f1eef37728980f32d35ab0da",
    "body": "**RAV-RUN1-R1-F001 [medium] — suggestion:** It may be helpful to keep boolean metric contributions in this fan-out. The aggregate path accepts `bool` through Python's numeric hierarchy, so excluding it here turns a valid `true` contribution into an unjoined synthetic `0.0` row. Normalizing booleans to `1.0`/`0.0` would preserve the new result-ID join while leaving the fallback for genuinely non-numeric values.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/245#discussion_r3754488852"
  },
  {
    "id": 3754488853,
    "pr": 245,
    "created_at": "2026-08-11T00:40:18Z",
    "path": "every_eval_ever/converters/inspect/utils.py",
    "line": 577,
    "side": "RIGHT",
    "commit_id": "c46eec389e3ddb15f1eef37728980f32d35ab0da",
    "body": "**RAV-RUN1-R1-F002 [medium] — suggestion:** Could entries with an `evaluation_result_id` be excluded from this name index (or could the model reject both selectors together)? As written, one dual-key entry first matches its specific result by ID, then matches sibling results through the shared evaluation name. A small two-result test would make the intended precedence especially clear.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/245#discussion_r3754488853"
  },
  {
    "id": 3754547095,
    "pr": 246,
    "created_at": "2026-08-11T00:57:37Z",
    "path": "every_eval_ever/converters/common/metrics.py",
    "line": 204,
    "side": "RIGHT",
    "commit_id": "f10d4d7aab6df0454a9f957dd82c58b438976f5e",
    "body": "**RAV-RUN1-R1-F001 [medium] — suggestion:** Could unknown direction be marked explicitly here, similarly to dispersion's `not_applicable` marker? For any unrecognized loss/error metric this required `false` reads as an affirmative higher-is-better claim, while the current additional details only qualify the bounds. Keeping the boolean but adding `polarity: unknown` until a harness or supplement supplies direction would make the fallback safer for ranking consumers.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/246#discussion_r3754547095"
  },
  {
    "id": 3754547098,
    "pr": 246,
    "created_at": "2026-08-11T00:57:37Z",
    "path": "every_eval_ever/converters/lm_eval/utils.py",
    "line": 77,
    "side": "RIGHT",
    "commit_id": "f10d4d7aab6df0454a9f957dd82c58b438976f5e",
    "body": "**RAV-RUN1-R1-F002 [medium] — suggestion:** lm-eval applies this 100-resample cap to the aggregation callable, so an aliased metric can use `aggregation: bleu` without being named `bleu`. Keying this check on `aggregation` (as `standard_error_method()` already does) would keep `num_bootstrap_samples` faithful for custom metric names too.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/246#discussion_r3754547098"
  },
  {
    "id": 3754547099,
    "pr": 246,
    "created_at": "2026-08-11T00:57:37Z",
    "path": "every_eval_ever/converters/inspect/utils.py",
    "line": 349,
    "side": "RIGHT",
    "commit_id": "f10d4d7aab6df0454a9f957dd82c58b438976f5e",
    "body": "**RAV-RUN1-R1-F003 [medium] — suggestion:** These four new fields look intentionally overrideable, but the strict `SupplementalMetricConfig` does not declare them, so exact probes reject each as `extra_forbidden` before this allowlist runs. Adding matching model fields and an end-to-end override test would make this useful correction path reachable; a `metric_id` override can also refresh its generated status/revision atomically.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/246#discussion_r3754547099"
  },
  {
    "id": 3754547101,
    "pr": 246,
    "created_at": "2026-08-11T00:57:38Z",
    "path": "every_eval_ever/converters/inspect/adapter.py",
    "line": 234,
    "side": "RIGHT",
    "commit_id": "f10d4d7aab6df0454a9f957dd82c58b438976f5e",
    "body": "**RAV-RUN1-R1-F004 [medium] — suggestion:** If a scorer carries both `stderr` and `bootstrap_stderr`, this `next(...)` makes the published value and method depend on mapping order while both source entries are later removed. Could the collision have deterministic policy (or preserve the alternate in details), and could the chosen metric's params populate bootstrap count/clustering metadata? That would retain the useful uncertainty provenance this PR is adding.",
    "url": "https://github.com/evaleval/every_eval_ever/pull/246#discussion_r3754547101"
  }
]
