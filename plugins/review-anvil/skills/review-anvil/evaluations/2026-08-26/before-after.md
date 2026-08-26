# Historical review clarity comparison

The before side is verbatim GitHub output from prior `evaleval/every_eval_ever` review-anvil runs. The after side is a clean final clarity pass over frozen facts; it did not inspect the reviewed repositories.

## PR #190 — review 4870915628

Source: https://github.com/evaleval/every_eval_ever/pull/190#pullrequestreview-4870915628

### Before — top-level report

> <!-- review-anvil-marker: 0e04290a-39be-4dd6-9df2-145f6768b3c3 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — Seven confirmed medium concerns remain in the consolidated adapter.
> **Result:** The nine earlier concerns are fixed. This head has seven medium concerns and four low suggestions.
> **Scope:** This PR consolidates AlpacaEval conversion with registry resolution, provenance, and publication.
> **Checks:** 11 concerns checked; 10 confirmed and 1 narrowed.
> **Second check:** targeted, 2 reviewers; 11 kept, 9 clarified or lowered, 0 set aside, 0 removed.
>
> ## Earlier review comments
>
> - All nine earlier comments are fixed or stale. The duplicate adapter is gone, `NullModel` is excluded, and incomplete conversion exits nonzero.
>
> ## What I noticed
>
> - **RAV-RUN2-R1-F001 [medium] model-identity** `every_eval_ever/converters/alpaca_eval/adapter.py:602` — Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect the join key. (inline)
> - **RAV-RUN2-R1-F002 [medium] reproducibility** `every_eval_ever/converters/alpaca_eval/adapter.py:838` — Explicit branch or tag refs are not resolved before use in stable IDs and provenance URLs. Two network runs can fetch different input under the same identity. (inline)
> - **RAV-RUN2-R1-F003 [medium] cli** `every_eval_ever/cli.py:383` — The module entry point builds the old argument namespace. The changed handler reads missing fields and fails before conversion. (inline)
> - **RAV-RUN2-R1-F005 [medium] input-validation** `every_eval_ever/converters/alpaca_eval/adapter.py:302` — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication. (inline)
> - **RAV-RUN2-R1-F007 [medium] generation-provenance** `every_eval_ever/converters/alpaca_eval/adapter.py:643` — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt. (inline)
> - **RAV-RUN2-R1-F009 [medium] registry-resolution** `every_eval_ever/helpers/eval_card_registry.py:245` — Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes. (inline)
> - **RAV-RUN2-R1-F011 [medium] registry-identity** `every_eval_ever/tools/refresh_eval_card_registry.py:151` — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization. (inline)
>
> ID legend: `RUN` is the observed PR review run, `R` is the immutable origin round, `F` is a finding, and `P` is a plan.
>
> <details>
> <summary>Non-blocking low findings (4 items)</summary>
>
> - **RAV-RUN2-R1-F004 [low] output-lifecycle** `every_eval_ever/cli.py:624` — The fixed default smoke directory keeps UUID-named output from earlier runs.
> - **RAV-RUN2-R1-F006 [low] metric-semantics** `every_eval_ever/converters/alpaca_eval/adapter.py:438` — The primary description always says 805 judged instructions, even when `n_total` is smaller.
> - **RAV-RUN2-R1-F008 [low] source-metadata** `every_eval_ever/converters/alpaca_eval/adapter.py:893` — Every row is marked third-party, including a model developed by the evaluating organization.
> - **RAV-RUN2-R1-F010 [low] registry-provenance** `every_eval_ever/helpers/eval_card_registry.py:267` — A prior live error causes later successful exact misses to report `registry_unavailable`.
>
> </details>
>
> <details>
> <summary>Things to try (11 items)</summary>
>
> - **[medium] model-identity** — Only model IDs emitted by this pinned snapshot can receive vendored registry resolution. The source ID can remain a marked fallback. (`RAV-RUN2-R1-P001`; covers `RAV-RUN2-R1-F001`)
> - **[medium] reproducibility** — Network-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access. (`RAV-RUN2-R1-P002`; covers `RAV-RUN2-R1-F002`)
> - **[medium] cli** — The module entry point can use the shared top-level parser and one offline entry-point test. (`RAV-RUN2-R1-P003`; covers `RAV-RUN2-R1-F003`)
> - **[low] output-lifecycle** — A temporary-directory context can own and remove default smoke output while preserving explicit output paths. (`RAV-RUN2-R1-P004`; covers `RAV-RUN2-R1-F004`)
> - **[medium] input-validation** — Populated numeric cells can validate as finite values within their metric rules before result construction. Invalid rows can enter `SourceConversionResult`. (`RAV-RUN2-R1-P005`; covers `RAV-RUN2-R1-F005`)
> - **[low] metric-semantics** — The primary description can use the validated row denominator. (`RAV-RUN2-R1-P006`; covers `RAV-RUN2-R1-F006`)
> - **[medium] generation-provenance** — New snapshots can store pinned prompt content. Legacy snapshots can leave the typed value unset and mark missing content. (`RAV-RUN2-R1-P007`; covers `RAV-RUN2-R1-F007`)
> - **[low] source-metadata** — Canonical evaluator and model-developer organizations can determine the relationship. (`RAV-RUN2-R1-P008`; covers `RAV-RUN2-R1-F008`)
> - **[medium] registry-resolution** — Live mode can query present-null entries while offline behavior stays unchanged. (`RAV-RUN2-R1-P009`; covers `RAV-RUN2-R1-F009`)
> - **[low] registry-provenance** — Each cached live lookup can carry a hit, miss, or error result. Aggregate errors can remain separate. (`RAV-RUN2-R1-P010`; covers `RAV-RUN2-R1-F010`)
> - **[medium] registry-identity** — Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them. (`RAV-RUN2-R1-P011`; covers `RAV-RUN2-R1-F011`)
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #190 at `d081d835d21d582a0e056e0e0fcbd77344fc8abb` (15 files, +6557/-459)
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off; material findings remain
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 9 comments; all fixed or stale
> - Finding counts: 0 critical, 0 high, 7 medium, 4 low, 0 nit
> - Checks: concerns=11; confirmed=10/ruled-out=0/set-aside=0/narrowed=1
> - Second check: targeted; reviewers=2; kept=11/clarified-or-lowered=9/set-aside=0/removed=0; approval changed no
> - Fixes applied: 0 (review-only)
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level report

> # Review result
>
> **COMMENT** — Seven confirmed medium concerns remain in the consolidated adapter.
>
> The nine earlier concerns are fixed. This head has seven medium concerns and four low suggestions.
>
> ## Needs attention
>
> - **Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder** `every_eval_ever/converters/alpaca_eval/adapter.py:602` — Canonical model aliases cannot affect this join key. Limit vendored registry resolution to model IDs emitted by this pinned snapshot while keeping the source-derived ID as a marked fallback. (`RAV-RUN2-R1-F001`) <!-- review-anvil-report: severity=medium area=model-identity -->
> - **Explicit branch or tag refs are not resolved before use in stable IDs and provenance URLs** `every_eval_ever/converters/alpaca_eval/adapter.py:838` — Two network runs can fetch different input under the same identity. Resolve network-mode refs once to a commit SHA while keeping offline replay on the stored immutable ref without network access. (`RAV-RUN2-R1-F002`) <!-- review-anvil-report: severity=medium area=reproducibility -->
> - **The module entry point builds the old argument namespace** `every_eval_ever/cli.py:383` — The changed handler reads missing fields and fails before conversion. Use the shared top-level parser in the module entry point. Add one offline entry-point test that covers its defaults. (`RAV-RUN2-R1-F003`) <!-- review-anvil-report: severity=medium area=cli -->
> - **Populated invalid `win_rate` values bypass row-level failure handling** `every_eval_ever/converters/alpaca_eval/adapter.py:302` — They can omit the headline metric or abort strict JSON publication. Validate populated numeric cells as finite values within their metric rules before result construction. Send invalid rows into `SourceConversionResult`. (`RAV-RUN2-R1-F005`) <!-- review-anvil-report: severity=medium area=input-validation -->
> - **`GenerationArgs.prompt_template` contains an upstream path instead of prompt content** `every_eval_ever/converters/alpaca_eval/adapter.py:643` — Offline records cannot reconstruct the generation prompt. Store pinned prompt content for new snapshots. For legacy snapshots, leave the typed value unset and mark the missing content. (`RAV-RUN2-R1-F007`) <!-- review-anvil-report: severity=medium area=generation-provenance -->
> - **Live mode skips keys whose vendored value is null** `every_eval_ever/helpers/eval_card_registry.py:245` — A known gap cannot discover a new registry entry until the snapshot refreshes. Query present-null entries in live mode while keeping offline behavior unchanged. (`RAV-RUN2-R1-F009`) <!-- review-anvil-report: severity=medium area=registry-resolution -->
> - **Normalized organization collisions can rewrite an exact canonical ID to another canonical organization** `every_eval_ever/tools/refresh_eval_card_registry.py:151` — Exact canonical IDs must win first. Resolve normalized spellings only when one organization owns them. (`RAV-RUN2-R1-F011`) <!-- review-anvil-report: severity=medium area=registry-identity -->
>
> <details>
> <summary>Suggestions (4)</summary>
>
> - **The fixed default smoke directory keeps UUID-named output from earlier runs** `every_eval_ever/cli.py:624` — A temporary-directory context can own and remove default smoke output while preserving explicit output paths. (`RAV-RUN2-R1-F004`) <!-- review-anvil-report: severity=low area=output-lifecycle -->
> - **The primary description always says 805 judged instructions, even when `n_total` is smaller** `every_eval_ever/converters/alpaca_eval/adapter.py:438` — The primary description can use the validated row denominator. (`RAV-RUN2-R1-F006`) <!-- review-anvil-report: severity=low area=metric-semantics -->
> - **Every row is marked third-party, including a model developed by the evaluating organization** `every_eval_ever/converters/alpaca_eval/adapter.py:893` — Canonical evaluator and model-developer organizations can determine the relationship. (`RAV-RUN2-R1-F008`) <!-- review-anvil-report: severity=low area=source-metadata -->
> - **A prior live error causes later successful exact misses to report `registry_unavailable`** `every_eval_ever/helpers/eval_card_registry.py:267` — Each cached live lookup can carry a hit, miss, or error result. Aggregate errors can remain separate. (`RAV-RUN2-R1-F010`) <!-- review-anvil-report: severity=low area=registry-provenance -->
>
> </details>
>
> <details>
> <summary>Earlier review comments (9)</summary>
>
> Reported:
>
> - **reported** — All nine earlier comments are fixed or stale. The duplicate adapter is gone, `NullModel` is excluded, and incomplete conversion exits nonzero.
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> Scope: This PR consolidates AlpacaEval conversion with registry resolution, provenance, and publication.
>
> Checks: 11 concerns checked; 10 confirmed and 1 narrowed.
>
> Second check: targeted, 2 reviewers; 11 kept, 9 clarified or lowered, 0 set aside, 0 removed.
>
> - Target: PR #190 at `d081d835d21d582a0e056e0e0fcbd77344fc8abb` (15 files, +6557/-459)
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off; material findings remain
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 9 comments; all fixed or stale
> - Finding counts: 0 critical, 0 high, 7 medium, 4 low, 0 nit
> - Checks: concerns=11; confirmed=10/ruled-out=0/set-aside=0/narrowed=1
> - Second check: targeted; reviewers=2; kept=11/clarified-or-lowered=9/set-aside=0/removed=0; approval changed no
> - Fixes applied: 0 (review-only)
>
> </details>

### Inline comments

#### RAV-RUN2-R1-F001 — `every_eval_ever/converters/alpaca_eval/adapter.py:687`

**Before**

> **RAV-RUN2-R1-F001 [medium] model-identity** — Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect this join key.
>
> Only model IDs emitted by the pinned snapshot need vendored resolution. The source-derived ID can remain a marked fallback.

**After**

> **Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder**
>
> Canonical model aliases cannot affect this join key.
>
> Please limit vendored registry resolution to model IDs emitted by this pinned snapshot while keeping the source-derived ID as a marked fallback.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=model-identity -->

#### RAV-RUN2-R1-F002 — `every_eval_ever/converters/alpaca_eval/adapter.py:976`

**Before**

> **RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.
>
> Network-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access.

**After**

> **Explicit branch or tag refs are not resolved before use in stable IDs and provenance URLs**
>
> Two network runs can fetch different input under the same identity.
>
> Please resolve network-mode refs once to a commit SHA while keeping offline replay on the stored immutable ref without network access.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F002 severity=medium area=reproducibility -->

#### RAV-RUN2-R1-F003 — `every_eval_ever/cli.py:392`

**Before**

> **RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.
>
> The module entry point can use the shared parser, with one offline entry-point test covering its defaults.

**After**

> **The module entry point builds the old argument namespace**
>
> The changed handler reads missing fields and fails before conversion.
>
> **What to change**
>
> - Use the shared top-level parser in the module entry point.
> - Add one offline entry-point test that covers its defaults.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=cli -->

#### RAV-RUN2-R1-F005 — `every_eval_ever/converters/alpaca_eval/adapter.py:307`

**Before**

> **RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.
>
> Numeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.

**After**

> **Populated invalid `win_rate` values bypass row-level failure handling**
>
> They can omit the headline metric or abort strict JSON publication.
>
> **What to change**
>
> - Validate populated numeric cells as finite values within their metric rules before result construction.
> - Send invalid rows into `SourceConversionResult`.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F005 severity=medium area=input-validation -->

#### RAV-RUN2-R1-F007 — `every_eval_ever/converters/alpaca_eval/adapter.py:643`

**Before**

> **RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.
>
> New snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.

**After**

> **`GenerationArgs.prompt_template` contains an upstream path instead of prompt content**
>
> Offline records cannot reconstruct the generation prompt.
>
> **What to change**
>
> - Store pinned prompt content for new snapshots.
> - For legacy snapshots, leave the typed value unset and mark the missing content.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F007 severity=medium area=generation-provenance -->

#### RAV-RUN2-R1-F009 — `every_eval_ever/helpers/eval_card_registry.py:251`

**Before**

> **RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.
>
> Live mode can query present-null entries while offline behavior remains unchanged.

**After**

> **Live mode skips keys whose vendored value is null**
>
> A known gap cannot discover a new registry entry until the snapshot refreshes.
>
> Please query present-null entries in live mode while keeping offline behavior unchanged.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F009 severity=medium area=registry-resolution -->

#### RAV-RUN2-R1-F011 — `every_eval_ever/tools/refresh_eval_card_registry.py:151`

**Before**

> **RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.
>
> Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.

**After**

> **Normalized organization collisions can rewrite an exact canonical ID to another canonical organization**
>
> Please make exact canonical IDs win first. Resolve normalized spellings only when one organization owns them.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity -->

## PR #204 — review 4884442134

Source: https://github.com/evaleval/every_eval_ever/pull/204#pullrequestreview-4884442134

### Before — top-level report

> <!-- review-anvil-marker: ce1ee5f5-4de0-430a-8978-eb17d765a615 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — The new adapter is well structured, and five focused suggestions can make identity and publication safer.
> **Result:** Two high-priority and two medium-priority concerns remain. One CLI edge case is a low-priority suggestion.
> **Scope:** Add the Open Medical-LLM adapter with stable identities, complete source accounting, isolated failures, and safe publication.
> **Checks:** 5 concerns checked; 4 confirmed and 1 narrowed.
> **Second check:** 2 reviewers checked 5 findings; 4 kept, 1 lowered in priority, and 3 fix paths clarified.
>
> ## Earlier review comments
>
> <details>
> <summary>Earlier review comments (22 ledger entries, grouped into 10 topics)</summary>
>
> - The model-attribution mismatch is fixed. Alias reconciliation now rejects unresolved conflicts. The stable evaluation identity concern below is a separate edge of that approach.
> - Partial-failure exit handling, repository placement, schema compatibility, metric identity, pagination, and timestamp precision are fixed.
> - Duplicate detection and empty-result accounting are fixed. The replacement and exclusions-only paths below are separate follow-up suggestions.
> - Record isolation is still incomplete for non-finite numbers. The current path now fails during batch serialization instead of per-source conversion.
>
> </details>
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN3-R1-F001 | high | publication | `every_eval_ever/adapters/open_medical_llm/adapter.py:601` | `--replace-existing` deletes prior records before replacement preflight. A later validation or write failure can leave the target without its prior records. |
> | RAV-RUN3-R1-F002 | high | evaluation identity | `every_eval_ever/adapters/open_medical_llm/adapter.py:397` | Alias reconciliation uses the current Hugging Face canonical repository in `evaluation_id`. The same source file can receive a different identity after alias metadata changes. |
> | RAV-RUN3-R1-F003 | medium | record isolation | `every_eval_ever/adapters/open_medical_llm/adapter.py:301` | Non-finite scores pass conversion but fail strict batch serialization after worker accounting. One malformed record can block all valid records. |
> | RAV-RUN3-R1-F004 | medium | source accounting | `every_eval_ever/adapters/open_medical_llm/adapter.py:585` | A run with exclusions but no failures does not persist its accounting report. A report from an earlier failed run also remains unchanged. |
>
> <details>
> <summary>Non-blocking low-priority suggestion (1 item)</summary>
>
> - **RAV-RUN3-R1-F005 [low] CLI** `every_eval_ever/adapters/open_medical_llm/adapter.py:568` — `--limit 0` processes all models. Negative limits use Python negative slicing.
>
> </details>
>
> ## Things to try
>
> <details>
> <summary>Suggested changes (5 items)</summary>
>
> - **[high] publication** — The replacement path could preflight all new records and retain recoverable old files until every new write succeeds. Failure tests across several model routes would cover the rollback. (`RAV-RUN3-R1-P001`; covers `RAV-RUN3-R1-F001`)
> - **[high] evaluation identity** — The original dataset model path can remain the evaluation identity input. The reconciled repository can continue to drive model metadata and routing. (`RAV-RUN3-R1-P002`; covers `RAV-RUN3-R1-F002`)
> - **[medium] record isolation** — The existing `require_finite_number` helper can validate accuracy and uncertainty inside `make_result`. The worker boundary will then account for the selected source file. (`RAV-RUN3-R1-P003`; covers `RAV-RUN3-R1-F003`)
> - **[medium] source accounting** — An atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger. (`RAV-RUN3-R1-P004`; covers `RAV-RUN3-R1-F004`)
> - **[low] CLI** — Negative limits can be rejected, and slicing can run whenever the value is not `None`. (`RAV-RUN3-R1-P005`; covers `RAV-RUN3-R1-F005`)
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #204 at `d6e7288a56d1976a255b70c42269a48f804508f7` (5 files, +949/-0)
> - Run ordinal: 3
> - Rounds: 1/1 completed; adaptive off; material findings
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 22 ledger entries grouped into 10 topics; 1 still present and 9 fixed or replaced by distinct concerns
> - Finding counts: 0 critical, 2 high, 2 medium, 1 low, 0 nit
> - Checks: concerns=5; confirmed=4; narrowed=1; set-aside=0
> - Second check: targeted; reviewers=2; kept=5; clarified=3 plans; lowered=1; removed=0; approval unchanged
> - Set aside: 0 items
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level report

> # Review result
>
> **COMMENT** — The new adapter is well structured, and five focused suggestions can make identity and publication safer.
>
> Two high-priority and two medium-priority concerns remain. One CLI edge case is a low-priority suggestion.
>
> ## Needs attention
>
> - **`--replace-existing` deletes prior records before replacement preflight** `every_eval_ever/adapters/open_medical_llm/adapter.py:601` — Lines 601–602 remove old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files that call creates, so a later failure can leave the target without its prior records. Preflight all new records. Retain recoverable old files until every new write and route transition succeeds. Add mid-write failure tests across several model routes to cover the rollback path. (`RAV-RUN3-R1-F001`) <!-- review-anvil-report: severity=high area=publication -->
> - **Alias reconciliation uses the current Hugging Face canonical repository in `evaluation_id`** `every_eval_ever/adapters/open_medical_llm/adapter.py:397` — `evaluated_model_repo()` returns the current repository, and `make_log()` includes it in `evaluation_id`. A later redirect can give the same source result a second identity. Use the raw dataset model path—the original source value—as the evaluation identity input while keeping the reconciled repository unchanged for model metadata and routing. (`RAV-RUN3-R1-F002`) <!-- review-anvil-report: severity=high area=evaluation-identity -->
> - **Non-finite scores pass conversion but fail strict batch serialization after worker accounting** `every_eval_ever/adapters/open_medical_llm/adapter.py:301` — One malformed record can block all valid records. Use the existing `require_finite_number` helper to validate accuracy and uncertainty inside `make_result`. The worker boundary will then account for the selected source file. (`RAV-RUN3-R1-F003`) <!-- review-anvil-report: severity=medium area=record-isolation -->
> - **A run with exclusions but no failures does not persist its accounting report** `every_eval_ever/adapters/open_medical_llm/adapter.py:585` — `failure_report()` already includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current. Atomically replace the report after successful publication to record failures, exclusions, and fully clean runs without losing the last complete ledger. (`RAV-RUN3-R1-F004`) <!-- review-anvil-report: severity=medium area=source-accounting -->
>
> <details>
> <summary>Suggestions (1)</summary>
>
> - **`--limit 0` processes all models** `every_eval_ever/adapters/open_medical_llm/adapter.py:568` — Negative limits use Python negative slicing. Negative limits can be rejected, and slicing can run whenever the value is not `None`. (`RAV-RUN3-R1-F005`) <!-- review-anvil-report: severity=low area=CLI -->
>
> </details>
>
> <details>
> <summary>Earlier review comments (22 ledger entries, grouped into 10 topics)</summary>
>
> - **reported** — The model-attribution mismatch is fixed. Alias reconciliation now rejects unresolved conflicts. The stable evaluation identity concern below is a separate edge of that approach.
> - **reported** — Partial-failure exit handling, repository placement, schema compatibility, metric identity, pagination, and timestamp precision are fixed.
> - **reported** — Duplicate detection and empty-result accounting are fixed. The replacement and exclusions-only paths below are separate follow-up suggestions.
> - **reported** — Record isolation is still incomplete for non-finite numbers. The current path now fails during batch serialization instead of per-source conversion.
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Scope: Add the Open Medical-LLM adapter with stable identities, complete source accounting, isolated failures, and safe publication.
> - Checks: 5 concerns checked; 4 confirmed and 1 narrowed.
> - Second check: 2 reviewers checked 5 findings; 4 kept, 1 lowered in priority, and 3 fix paths clarified.
> - Target: PR #204 at `d6e7288a56d1976a255b70c42269a48f804508f7` (5 files, +949/-0)
> - Run ordinal: 3
> - Rounds: 1/1 completed; adaptive off; material findings
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 22 ledger entries grouped into 10 topics; 1 still present and 9 fixed or replaced by distinct concerns
> - Finding counts: 0 critical, 2 high, 2 medium, 1 low, 0 nit
> - Checks: concerns=5; confirmed=4; narrowed=1; set-aside=0
> - Second check: targeted; reviewers=2; kept=5; clarified=3 plans; lowered=1; removed=0; approval unchanged
> - Set aside: 0 items
>
> </details>

### Inline comments

#### RAV-RUN3-R1-F001 — `every_eval_ever/adapters/open_medical_llm/adapter.py:601`

**Before**

> **RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight
>
> Lines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.
>
> The replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.

**After**

> **`--replace-existing` deletes prior records before replacement preflight**
>
> Lines 601–602 remove old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files that call creates, so a later failure can leave the target without its prior records.
>
> **What to change**
>
> - Preflight all new records.
> - Retain recoverable old files until every new write and route transition succeeds.
> - Add mid-write failure tests across several model routes to cover the rollback path.
>
> <!-- review-anvil: id=RAV-RUN3-R1-F001 severity=high area=publication -->

#### RAV-RUN3-R1-F002 — `every_eval_ever/adapters/open_medical_llm/adapter.py:397`

**Before**

> **RAV-RUN3-R1-F002 [high] evaluation-identity** — Alias metadata can change the identity of the same source file
>
> `evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.
>
> The raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing.

**After**

> **Alias reconciliation uses the current Hugging Face canonical repository in `evaluation_id`**
>
> `evaluated_model_repo()` returns the current repository, and `make_log()` includes it in `evaluation_id`. A later redirect can give the same source result a second identity.
>
> Please use the raw dataset model path—the original source value—as the evaluation identity input while keeping the reconciled repository unchanged for model metadata and routing.
>
> <!-- review-anvil: id=RAV-RUN3-R1-F002 severity=high area=evaluation-identity -->

#### RAV-RUN3-R1-F004 — `every_eval_ever/adapters/open_medical_llm/adapter.py:585`

**Before**

> **RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report
>
> `failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.
>
> An atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger.

**After**

> **A run with exclusions but no failures does not persist its accounting report**
>
> `failure_report()` already includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.
>
> Please atomically replace the report after successful publication to record failures, exclusions, and fully clean runs without losing the last complete ledger.
>
> <!-- review-anvil: id=RAV-RUN3-R1-F004 severity=medium area=source-accounting -->

## PR #230 — review 4870883842

Source: https://github.com/evaleval/every_eval_ever/pull/230#pullrequestreview-4870883842

### Before — top-level report

> <!-- review-anvil-marker: 70e25c99-9cdd-45c1-ad9a-40916e660ed1 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — This run is comment-only and found two focused merge-readiness items.
> **Result:** The offline registry design is thoughtful. The warning needs visible default output and its required contributor guidance before merge.
> **Scope:** This PR adds an offline organization vocabulary, a refresh tool, and a warning-only publisher-alias validator.
> **Checks:** 3 concerns checked; 1 confirmed and 2 narrowed.
> **Second check:** 2 reviewers checked 6 findings and plans; 2 lowered in priority and 4 kept with clearer fix paths.
>
> ## Earlier review comments
>
> None.
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN1-R1-F003 | medium | warning visibility | `every_eval_ever/validator/validation_core.py:832` | The new warning stays hidden in the default rich output until PR #221 is included. The current renderer returns after `PASS` for valid reports. (inline) |
> | RAV-RUN1-R1-F004 | medium | contributor guidance | `every_eval_ever/validator/validation_core.py:835` | This adds a registered validator rule, but the required `datastore-gate.md` contributor guidance does not describe it. (inline) |
>
> <details>
> <summary>Non-blocking low-priority findings (4 items)</summary>
>
> - **RAV-RUN1-R1-F001 [low] refresh safety** — The maintainer refresh tool replaces the tracked snapshot with a direct truncating write. An interrupted refresh can leave invalid JSON for later semantic validation.
> - **RAV-RUN1-R1-F002 [low] diagnostic scope** — The check proves a registry alias mismatch from one record. It cannot prove that the collection currently uses two directory spellings.
> - **RAV-RUN1-R1-F005 [low] refresh errors** — Malformed endpoint records can raise `AttributeError` or `KeyError` outside the tool's concise error path.
> - **RAV-RUN1-R1-F006 [low] refresh provenance** — A custom `--base-url` fetch still records the production URL in `_source`.
>
> </details>
>
> <details>
> <summary>Things to try (6 items)</summary>
>
> - **[low] refresh safety** — A same-directory temporary file can preserve the live snapshot until replacement. Cleanup and file-mode preservation keep that path tidy. (`RAV-RUN1-R1-P001`; covers `RAV-RUN1-R1-F001`)
> - **[low] diagnostic scope** — The warning can name the observed alias relation. Directory splitting can stay a conditional result when both spellings are published. (`RAV-RUN1-R1-P002`; covers `RAV-RUN1-R1-F002`)
> - **[medium] warning visibility** — PR #221 can remain the merge prerequisite. After rebase, this warning needs one check through the default rich CLI path. (`RAV-RUN1-R1-P003`; covers `RAV-RUN1-R1-F003`)
> - **[medium] contributor guidance** — `datastore-gate.md` can state the alias trigger, warning-only result, and single-record evidence limit. (`RAV-RUN1-R1-P004`; covers `RAV-RUN1-R1-F004`)
> - **[low] refresh errors** — Small checks for consumed fields can report the endpoint and record index without adding a schema layer. (`RAV-RUN1-R1-P005`; covers `RAV-RUN1-R1-F005`)
> - **[low] refresh provenance** — `_source` can use the effective URL after removing user information, query parameters, and fragments. (`RAV-RUN1-R1-P006`; covers `RAV-RUN1-R1-F006`)
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #230 (`validator-developer-slug-drift`, 8 files, +2073/-0)
> - Run ordinal: 1
> - Rounds: 1/1 completed; adaptive off; material findings
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: none
> - Finding counts: 0 critical, 0 high, 2 medium, 4 low, 0 nit
> - Checks: concerns=3; confirmed=1; narrowed=2; ruled-out=0; set-aside=0
> - Second check: targeted; reviewers=2; kept=4; lowered=2; clarified=6; set-aside=0; removed=0; approval changed=no
> - Set aside: 0 items
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level report

> # Review result
>
> **COMMENT** — This run is comment-only and found two focused merge-readiness items.
>
> The offline registry design is thoughtful. The warning needs visible default output and its required contributor guidance before merge.
>
> ## Needs attention
>
> - **The new warning stays hidden in the default rich output until PR #221 is included** `every_eval_ever/validator/validation_core.py:832` — Warning severity leaves the report valid, so the current rich renderer prints `PASS` and returns before its warning loop. PR #221 is already listed and can remain the merge prerequisite. After rebase, add one default-rich CLI check for this warning to confirm the complete path. (`RAV-RUN1-R1-F003`) <!-- review-anvil-report: severity=medium area=warning-visibility -->
> - **This adds a registered validator rule, but the required datastore gate guide does not describe it** `every_eval_ever/validator/validation_core.py:835` — The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. Add a short section there that states the alias trigger, warning-only result, and single-record evidence limit. (`RAV-RUN1-R1-F004`) <!-- review-anvil-report: severity=medium area=contributor-guidance -->
>
> <details>
> <summary>Suggestions (4)</summary>
>
> - **The maintainer refresh tool replaces the tracked snapshot with a direct truncating write** — An interrupted refresh can leave invalid JSON for later semantic validation. A same-directory temporary file can preserve the live snapshot until replacement. Cleanup and file-mode preservation keep that path tidy. (`RAV-RUN1-R1-F001`) <!-- review-anvil-report: severity=low area=refresh-safety -->
> - **The check proves a registry alias mismatch from one record** — It cannot prove that the collection currently uses two directory spellings. The warning can name the observed alias relation. Directory splitting can stay a conditional result when both spellings are published. (`RAV-RUN1-R1-F002`) <!-- review-anvil-report: severity=low area=diagnostic-scope -->
> - **Malformed endpoint records can raise `AttributeError` or `KeyError` outside the tool's concise error path** — Small checks for consumed fields can report the endpoint and record index without adding a schema layer. (`RAV-RUN1-R1-F005`) <!-- review-anvil-report: severity=low area=refresh-errors -->
> - **A custom `--base-url` fetch still records the production URL in `_source`** — `_source` can use the effective URL after removing user information, query parameters, and fragments. (`RAV-RUN1-R1-F006`) <!-- review-anvil-report: severity=low area=refresh-provenance -->
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - 3 concerns checked; 1 confirmed and 2 narrowed.
> - 2 reviewers checked 6 findings and plans; 2 lowered in priority and 4 kept with clearer fix paths.
>
> This PR adds an offline organization vocabulary, a refresh tool, and a warning-only publisher-alias validator.
>
> Target: PR #230 (`validator-developer-slug-drift`, 8 files, +2073/-0)
> Run ordinal: 1
> Rounds: 1/1 completed; adaptive off; material findings
> Mix: 3 codex-exec
> Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> Earlier review comments: none
> Finding counts: 0 critical, 0 high, 2 medium, 4 low, 0 nit
> Checks: concerns=3; confirmed=1; narrowed=2; ruled-out=0; set-aside=0
> Second check: targeted; reviewers=2; kept=4; lowered=2; clarified=6; set-aside=0; removed=0; approval changed=no
> Set aside: 0 items
>
> </details>

### Inline comments

#### RAV-RUN1-R1-F003 — `every_eval_ever/validator/validation_core.py:792`

**Before**

> **RAV-RUN1-R1-F003 [medium] warning-visibility** — The new warning stays hidden in the default rich output without PR #221
>
> Warning severity leaves the report valid. The current rich renderer prints `PASS` and returns before its warning loop.
>
> PR #221 is already listed as a prerequisite. After rebase, one default-rich CLI check for this warning would confirm the complete path.

**After**

> **The new warning stays hidden in the default rich output until PR #221 is included**
>
> Warning severity leaves the report valid, so the current rich renderer prints `PASS` and returns before its warning loop.
>
> PR #221 is already listed and can remain the merge prerequisite.
>
> After rebase, please add one default-rich CLI check for this warning to confirm the complete path.
>
> <!-- review-anvil: id=RAV-RUN1-R1-F003 severity=medium area=warning-visibility -->

#### RAV-RUN1-R1-F004 — `every_eval_ever/validator/validation_core.py:795`

**Before**

> **RAV-RUN1-R1-F004 [medium] contributor-guidance** — The new registered warning is missing from the required datastore gate guide
>
> The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.
>
> A short section can state the alias trigger, warning-only result, and single-record evidence limit.

**After**

> **The registered warning is missing from the required datastore gate guide**
>
> The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.
>
> Please add a short section there that states the alias trigger, warning-only result, and single-record evidence limit.
>
> <!-- review-anvil: id=RAV-RUN1-R1-F004 severity=medium area=contributor-guidance -->

