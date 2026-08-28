# Human review language comparison

The before side is the current clarity-pass output. The after side uses the same frozen facts with the human-summary language contract.

## PR #190 — review 4870915628

Source: https://github.com/evaleval/every_eval_ever/pull/190#pullrequestreview-4870915628

### Before — top-level report

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

### After — top-level report

> Most findings are around identity stability, reproducible inputs, and validation. There are also registry and provenance issues, plus four optional cleanups.
>
> <details>
> <summary>Issues and fixes</summary>
>
> | Severity | Location | Issue | Suggested change |
> |---|---|---|---|
> | Medium | `every_eval_ever/converters/alpaca_eval/adapter.py:602` | Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases therefore cannot affect the join key. | Apply vendored registry resolution only to model IDs emitted by this pinned snapshot while keeping the source-derived ID as a marked fallback. <!-- review-anvil-report: id=RAV-RUN2-R1-F001 severity=medium area=model-identity path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=602 disposition=active --> |
> | Medium | `every_eval_ever/converters/alpaca_eval/adapter.py:838` | Explicit branch and tag refs remain unresolved when they enter stable IDs and provenance URLs. Two network runs can therefore fetch different input under one identity. | Pin network refs once to a commit SHA while keeping offline replay on its stored immutable ref without network access. <!-- review-anvil-report: id=RAV-RUN2-R1-F002 severity=medium area=reproducibility path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=838 disposition=active --> |
> | Medium | `every_eval_ever/cli.py:383` | This entry point still builds the old arguments. The changed handler reads missing fields and fails before conversion. | Use the shared top-level parser in this module entry point and add one offline entry-point test covering its defaults. <!-- review-anvil-report: id=RAV-RUN2-R1-F003 severity=medium area=cli path=every_eval_ever%2Fcli.py start_line=- line=383 disposition=active --> |
> | Medium | `every_eval_ever/converters/alpaca_eval/adapter.py:302` | Populated invalid `win_rate` values bypass row-level error handling. They can hide the main metric or abort strict JSON publication. | Validate each populated numeric value as finite under its metric rules before building results, and send invalid rows to `SourceConversionResult`. <!-- review-anvil-report: id=RAV-RUN2-R1-F005 severity=medium area=input-validation path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=302 disposition=active --> |
> | Medium | `every_eval_ever/converters/alpaca_eval/adapter.py:643` | `GenerationArgs.prompt_template` stores an upstream path instead of the prompt, so offline records cannot reconstruct it. | Store pinned prompt content for new snapshots. For legacy snapshots, leave this typed value unset and mark the missing content. <!-- review-anvil-report: id=RAV-RUN2-R1-F007 severity=medium area=generation-provenance path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=643 disposition=active --> |
> | Medium | `every_eval_ever/helpers/eval_card_registry.py:245` | Live lookup skips entries already marked missing in the local snapshot, so it cannot discover a new registry value until that snapshot refreshes. | Query those entries in live mode while keeping offline behavior unchanged. <!-- review-anvil-report: id=RAV-RUN2-R1-F009 severity=medium area=registry-resolution path=every_eval_ever%2Fhelpers%2Feval_card_registry.py start_line=- line=245 disposition=active --> |
> | Medium | `every_eval_ever/tools/refresh_eval_card_registry.py:151` | Normalized organization collisions can redirect an exact canonical ID to another canonical organization. | Prefer exact canonical IDs and resolve normalized names only when one organization owns them. <!-- review-anvil-report: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity path=every_eval_ever%2Ftools%2Frefresh_eval_card_registry.py start_line=- line=151 disposition=active --> |
>
> </details>
>
> <details>
> <summary>Optional suggestions</summary>
>
> | Severity | Location | Suggestion | Suggested change |
> |---|---|---|---|
> | Low | `every_eval_ever/cli.py:624` | The fixed default smoke directory keeps UUID-named output from earlier runs. | Consider using a temporary-directory context that cleans it up while preserving explicit output paths. <!-- review-anvil-report: id=RAV-RUN2-R1-F004 severity=low area=output-lifecycle path=every_eval_ever%2Fcli.py start_line=- line=624 disposition=active --> |
> | Low | `every_eval_ever/converters/alpaca_eval/adapter.py:438` | The primary description always says 805 judged instructions even when `n_total` is smaller. | Consider using the validated row denominator. <!-- review-anvil-report: id=RAV-RUN2-R1-F006 severity=low area=metric-semantics path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=438 disposition=active --> |
> | Low | `every_eval_ever/converters/alpaca_eval/adapter.py:893` | Every row is marked third-party, even when the evaluator developed the model. | Consider using the canonical evaluator and developer organizations. <!-- review-anvil-report: id=RAV-RUN2-R1-F008 severity=low area=source-metadata path=every_eval_ever%2Fconverters%2Falpaca_eval%2Fadapter.py start_line=- line=893 disposition=active --> |
> | Low | `every_eval_ever/helpers/eval_card_registry.py:267` | A prior live error causes a later successful exact miss to record `registry_unavailable`. | Consider recording a hit, miss, or error for each cached live lookup while keeping aggregate errors separate. <!-- review-anvil-report: id=RAV-RUN2-R1-F010 severity=low area=registry-provenance path=every_eval_ever%2Fhelpers%2Feval_card_registry.py start_line=- line=267 disposition=active --> |
>
> </details>
>
> <details>
> <summary>Earlier feedback</summary>
>
> - **reported** — All nine earlier comments are fixed or stale. The duplicate adapter is gone, `NullModel` is excluded, and incomplete conversion exits nonzero.
>
>
> </details>
>
> <details>
> <summary>Review context</summary>
>
> **Decision reason:** Seven confirmed medium concerns remain in the consolidated adapter.
>
> **Result:** The nine earlier concerns are fixed. This head has seven medium concerns and four low suggestions.
>
> **Scope:** This PR consolidates AlpacaEval conversion with registry resolution, provenance, and publication.
>
> **Checks:** 11 concerns checked; 10 confirmed and 1 narrowed.
>
> **Second check:** targeted, 2 reviewers; 11 kept, 9 clarified or lowered, 0 set aside, 0 removed.
>
> ### Run details
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
>
>
> </details>
>
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### Inline comments

#### RAV-RUN2-R1-F001 — `every_eval_ever/converters/alpaca_eval/adapter.py:687`

**Before**

> **Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder**
>
> Canonical model aliases cannot affect this join key.
>
> Please limit vendored registry resolution to model IDs emitted by this pinned snapshot while keeping the source-derived ID as a marked fallback.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=model-identity -->

**After**

> Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases therefore cannot affect the join key.
>
> Apply vendored registry resolution only to model IDs emitted by this pinned snapshot while keeping the source-derived ID as a marked fallback.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=model-identity -->

#### RAV-RUN2-R1-F002 — `every_eval_ever/converters/alpaca_eval/adapter.py:976`

**Before**

> **Explicit branch or tag refs are not resolved before use in stable IDs and provenance URLs**
>
> Two network runs can fetch different input under the same identity.
>
> Please resolve network-mode refs once to a commit SHA while keeping offline replay on the stored immutable ref without network access.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F002 severity=medium area=reproducibility -->

**After**

> Explicit branch and tag refs remain unresolved when they enter stable IDs and provenance URLs. Two network runs can therefore fetch different input under one identity.
>
> Pin network refs once to a commit SHA while keeping offline replay on its stored immutable ref without network access.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F002 severity=medium area=reproducibility -->

#### RAV-RUN2-R1-F003 — `every_eval_ever/cli.py:392`

**Before**

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

**After**

> This entry point still builds the old arguments. The changed handler reads missing fields and fails before conversion.
>
> Use the shared top-level parser in this module entry point and add one offline entry-point test covering its defaults.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=cli -->

#### RAV-RUN2-R1-F005 — `every_eval_ever/converters/alpaca_eval/adapter.py:307`

**Before**

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

**After**

> Populated invalid `win_rate` values bypass row-level error handling. They can hide the main metric or abort strict JSON publication.
>
> Validate each populated numeric value as finite under its metric rules before building results, and send invalid rows to `SourceConversionResult`.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F005 severity=medium area=input-validation -->

#### RAV-RUN2-R1-F007 — `every_eval_ever/converters/alpaca_eval/adapter.py:643`

**Before**

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

**After**

> `GenerationArgs.prompt_template` stores an upstream path instead of the prompt, so offline records cannot reconstruct it.
>
> Store pinned prompt content for new snapshots. For legacy snapshots, leave this typed value unset and mark the missing content.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F007 severity=medium area=generation-provenance -->

#### RAV-RUN2-R1-F009 — `every_eval_ever/helpers/eval_card_registry.py:251`

**Before**

> **Live mode skips keys whose vendored value is null**
>
> A known gap cannot discover a new registry entry until the snapshot refreshes.
>
> Please query present-null entries in live mode while keeping offline behavior unchanged.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F009 severity=medium area=registry-resolution -->

**After**

> Live lookup skips entries already marked missing in the local snapshot, so it cannot discover a new registry value until that snapshot refreshes.
>
> Query those entries in live mode while keeping offline behavior unchanged.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F009 severity=medium area=registry-resolution -->

#### RAV-RUN2-R1-F011 — `every_eval_ever/tools/refresh_eval_card_registry.py:151`

**Before**

> **Normalized organization collisions can rewrite an exact canonical ID to another canonical organization**
>
> Please make exact canonical IDs win first. Resolve normalized spellings only when one organization owns them.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity -->

**After**

> Normalized organization collisions can redirect an exact canonical ID to another canonical organization.
>
> Prefer exact canonical IDs and resolve normalized names only when one organization owns them.
>
> <!-- review-anvil: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity -->

## PR #204 — review 4884442134

Source: https://github.com/evaleval/every_eval_ever/pull/204#pullrequestreview-4884442134

### Before — top-level report

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

### After — top-level report

> <!-- review-anvil-marker: ce1ee5f5-4de0-430a-8978-eb17d765a615 -->
>
> The main concerns are replacement safety and evaluation identity. Two reporting issues and one optional CLI cleanup were also detected.
>
> <details>
> <summary>Issues and fixes</summary>
>
> | Severity | Location | Issue | Suggested change |
> |---|---|---|---|
> | High | `every_eval_ever/adapters/open_medical_llm/adapter.py:601` | With `--replace-existing`, lines 601–602 delete the old files before `save_evaluation_logs()` checks or writes the new batch. Its rollback covers only newly created files, so later validation or write failure can leave no old records. | Preflight all new records, retain recoverable old files until every new write and route transition succeeds, and add mid-write failure tests across several model routes to cover the rollback path. <!-- review-anvil-report: id=RAV-RUN3-R1-F001 severity=high area=publication path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=601 disposition=active --> |
> | High | `every_eval_ever/adapters/open_medical_llm/adapter.py:397` | `evaluated_model_repo()` returns the current Hugging Face canonical repository, and `make_log()` puts it in `evaluation_id`. A later alias redirect can give the same source file a second identity. | Use the raw dataset model path for identity while keeping the reconciled repository for metadata and routing. <!-- review-anvil-report: id=RAV-RUN3-R1-F002 severity=high area=evaluation-identity path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=397 disposition=active --> |
> | Medium | `every_eval_ever/adapters/open_medical_llm/adapter.py:301` | Non-finite scores pass conversion but fail strict batch serialization after worker accounting, so one bad record blocks all valid records. | Validate accuracy and uncertainty with `require_finite_number` inside `make_result` so the worker boundary records the selected source file. <!-- review-anvil-report: id=RAV-RUN3-R1-F003 severity=medium area=record-isolation path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=301 disposition=active --> |
> | Medium | `every_eval_ever/adapters/open_medical_llm/adapter.py:585` | `failure_report()` already includes exclusions, but this branch saves it only when failures exist. The five documented baseline exclusions get no durable record, and an older failure report can remain current. | Replace the report atomically after successful publication so failures, exclusions, and clean runs are recorded without losing the last complete report. <!-- review-anvil-report: id=RAV-RUN3-R1-F004 severity=medium area=source-accounting path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=585 disposition=active --> |
>
> </details>
>
> <details>
> <summary>Optional suggestions</summary>
>
> | Severity | Location | Suggestion | Suggested change |
> |---|---|---|---|
> | Low | `every_eval_ever/adapters/open_medical_llm/adapter.py:568` | `--limit 0` processes every model, while negative limits use Python negative slicing. | Consider rejecting negatives and slicing for every non-`None` limit. <!-- review-anvil-report: id=RAV-RUN3-R1-F005 severity=low area=CLI path=every_eval_ever%2Fadapters%2Fopen_medical_llm%2Fadapter.py start_line=- line=568 disposition=active --> |
>
> </details>
>
> <details>
> <summary>Earlier feedback</summary>
>
> - **reported** — The model-attribution mismatch is fixed. Alias reconciliation now rejects unresolved conflicts. The stable evaluation identity concern below is a separate edge of that approach.
> - **reported** — Partial-failure exit handling, repository placement, schema compatibility, metric identity, pagination, and timestamp precision are fixed.
> - **reported** — Duplicate detection and empty-result accounting are fixed. The replacement and exclusions-only paths below are separate follow-up suggestions.
> - **reported** — Record isolation is still incomplete for non-finite numbers. The current path now fails during batch serialization instead of per-source conversion.
>
>
>
> </details>
>
> <details>
> <summary>Review context</summary>
>
> **Decision reason:** The new adapter is well structured, and five focused suggestions can make identity and publication safer.
>
> **Result:** Two high-priority and two medium-priority concerns remain. One CLI edge case is a low-priority suggestion.
>
> **Scope:** Add the Open Medical-LLM adapter with stable identities, complete source accounting, isolated failures, and safe publication.
>
> **Checks:** 5 concerns checked; 4 confirmed and 1 narrowed.
>
> **Second check:** 2 reviewers checked 5 findings; 4 kept, 1 lowered in priority, and 3 fix paths clarified.
>
> **Run details**
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
>
>
> </details>
>
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### Inline comments

#### RAV-RUN3-R1-F001 — `every_eval_ever/adapters/open_medical_llm/adapter.py:601`

**Before**

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

**After**

> With `--replace-existing`, lines 601–602 delete the old files before `save_evaluation_logs()` checks or writes the new batch. Its rollback covers only newly created files, so later validation or write failure can leave no old records.
>
> Preflight all new records, retain recoverable old files until every new write and route transition succeeds, and add mid-write failure tests across several model routes to cover the rollback path.
>
> <!-- review-anvil: id=RAV-RUN3-R1-F001 severity=high area=publication -->

#### RAV-RUN3-R1-F002 — `every_eval_ever/adapters/open_medical_llm/adapter.py:397`

**Before**

> **Alias reconciliation uses the current Hugging Face canonical repository in `evaluation_id`**
>
> `evaluated_model_repo()` returns the current repository, and `make_log()` includes it in `evaluation_id`. A later redirect can give the same source result a second identity.
>
> Please use the raw dataset model path—the original source value—as the evaluation identity input while keeping the reconciled repository unchanged for model metadata and routing.
>
> <!-- review-anvil: id=RAV-RUN3-R1-F002 severity=high area=evaluation-identity -->

**After**

> `evaluated_model_repo()` returns the current Hugging Face canonical repository, and `make_log()` puts it in `evaluation_id`. A later alias redirect can give the same source file a second identity.
>
> Use the raw dataset model path for identity while keeping the reconciled repository for metadata and routing.
>
> <!-- review-anvil: id=RAV-RUN3-R1-F002 severity=high area=evaluation-identity -->

#### RAV-RUN3-R1-F004 — `every_eval_ever/adapters/open_medical_llm/adapter.py:585`

**Before**

> **A run with exclusions but no failures does not persist its accounting report**
>
> `failure_report()` already includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.
>
> Please atomically replace the report after successful publication to record failures, exclusions, and fully clean runs without losing the last complete ledger.
>
> <!-- review-anvil: id=RAV-RUN3-R1-F004 severity=medium area=source-accounting -->

**After**

> `failure_report()` already includes exclusions, but this branch saves it only when failures exist. The five documented baseline exclusions get no durable record, and an older failure report can remain current.
>
> Replace the report atomically after successful publication so failures, exclusions, and clean runs are recorded without losing the last complete report.
>
> <!-- review-anvil: id=RAV-RUN3-R1-F004 severity=medium area=source-accounting -->

## PR #230 — review 4870883842

Source: https://github.com/evaleval/every_eval_ever/pull/230#pullrequestreview-4870883842

### Before — top-level report

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

### After — top-level report

> Two issues showed up: the warning is hidden in the default output, and the contributor guide does not cover the new rule. Four lower-priority suggestions are listed separately.
>
> <details>
> <summary>Issues and fixes</summary>
>
> | Severity | Location | Issue | Suggested change |
> |---|---|---|---|
> | Medium | `every_eval_ever/validator/validation_core.py:832` | Warnings do not make the report invalid, so the rich renderer returns after `PASS` before it prints them. The new warning is hidden until PR #221 is included. | PR #221 can remain the merge prerequisite. After rebasing, add one default-rich CLI check for this warning to confirm the complete path. <!-- review-anvil-report: id=RAV-RUN1-R1-F003 severity=medium area=warning-visibility path=every_eval_ever%2Fvalidator%2Fvalidation_core.py start_line=- line=832 disposition=active --> |
> | Medium | `every_eval_ever/validator/validation_core.py:835` | Repository instructions require validator guidance in `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md`. This PR adds the registered warning but leaves that guide unchanged. | Add a short section there covering the alias trigger, warning-only result, and single-record evidence limit. <!-- review-anvil-report: id=RAV-RUN1-R1-F004 severity=medium area=contributor-guidance path=every_eval_ever%2Fvalidator%2Fvalidation_core.py start_line=- line=835 disposition=active --> |
>
> </details>
>
> <details>
> <summary>Optional suggestions</summary>
>
> | Severity | Location | Suggestion | Suggested change |
> |---|---|---|---|
> | Low | — | The maintainer refresh tool replaces the tracked snapshot with a direct truncating write, so interruption can leave invalid JSON for later semantic validation. | Consider a same-directory temporary file that preserves the live snapshot until replacement and keeps the path tidy through cleanup and file-mode preservation. <!-- review-anvil-report: id=RAV-RUN1-R1-F001 severity=low area=refresh-safety path=- start_line=- line=- disposition=active --> |
> | Low | — | The check proves a registry alias mismatch from one record, but it cannot prove that the collection currently uses two directory spellings. | Consider naming the observed alias and mentioning split directories only when both spellings are published. <!-- review-anvil-report: id=RAV-RUN1-R1-F002 severity=low area=diagnostic-scope path=- start_line=- line=- disposition=active --> |
> | Low | — | Malformed endpoint records can escape the concise error path with `AttributeError` or `KeyError`. | Consider small checks limited to consumed fields that report the endpoint and record index without adding a schema layer. <!-- review-anvil-report: id=RAV-RUN1-R1-F005 severity=low area=refresh-errors path=- start_line=- line=- disposition=active --> |
> | Low | — | A custom `--base-url` still records the production URL in `_source`. | Consider using the effective URL after removing user information, query parameters, and fragments. <!-- review-anvil-report: id=RAV-RUN1-R1-F006 severity=low area=refresh-provenance path=- start_line=- line=- disposition=active --> |
>
> </details>
>
> <details>
> <summary>Review context</summary>
>
> **Decision reason:** This run is comment-only and found two focused merge-readiness items.
>
> **Result:** The offline registry design is thoughtful. The warning needs visible default output and its required contributor guidance before merge.
>
> **Scope:** This PR adds an offline organization vocabulary, a refresh tool, and a warning-only publisher-alias validator.
>
> **Checks:** 3 concerns checked; 1 confirmed and 2 narrowed.
>
> **Second check:** 2 reviewers checked 6 findings and plans; 2 lowered in priority and 4 kept with clearer fix paths.
>
> **Earlier feedback:** None.
>
> **Set aside:** None.
>
> **Outside scope:** None.
>
> **Run details:**
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
>
>
> </details>
>
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### Inline comments

#### RAV-RUN1-R1-F003 — `every_eval_ever/validator/validation_core.py:792`

**Before**

> **The new warning stays hidden in the default rich output until PR #221 is included**
>
> Warning severity leaves the report valid, so the current rich renderer prints `PASS` and returns before its warning loop.
>
> PR #221 is already listed and can remain the merge prerequisite.
>
> After rebase, please add one default-rich CLI check for this warning to confirm the complete path.
>
> <!-- review-anvil: id=RAV-RUN1-R1-F003 severity=medium area=warning-visibility -->

**After**

> Warnings do not make the report invalid, so the rich renderer returns after `PASS` before it prints them. The new warning is hidden until PR #221 is included.
>
> PR #221 can remain the merge prerequisite. After rebasing, add one default-rich CLI check for this warning to confirm the complete path.
>
> <!-- review-anvil: id=RAV-RUN1-R1-F003 severity=medium area=warning-visibility -->

#### RAV-RUN1-R1-F004 — `every_eval_ever/validator/validation_core.py:795`

**Before**

> **The registered warning is missing from the required datastore gate guide**
>
> The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.
>
> Please add a short section there that states the alias trigger, warning-only result, and single-record evidence limit.
>
> <!-- review-anvil: id=RAV-RUN1-R1-F004 severity=medium area=contributor-guidance -->

**After**

> Repository instructions require validator guidance in `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md`. This PR adds the registered warning but leaves that guide unchanged.
>
> Add a short section there covering the alias trigger, warning-only result, and single-record evidence limit.
>
> <!-- review-anvil: id=RAV-RUN1-R1-F004 severity=medium area=contributor-guidance -->

