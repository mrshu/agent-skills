# Complete before/after review artifacts — original benchmark

This renders all 16 GitHub review artifacts associated with the 47-comment selection corpus. It includes all 55 inline comments attached to those reviews: 47 benchmark comments plus 8 out-of-window comments on the same reviews. The 8 supplemental comments are excluded from selection metrics; 2 use the exact-source safety fallback.

For every review, the original top-level body is available from GitHub. A selected top-level rewrite is unavailable because the experiment generated only inline-comment candidates; no top-level readability claim is made.

## PR #190 — review 4870915628

Original review: https://github.com/evaleval/every_eval_ever/pull/190#pullrequestreview-4870915628

### Before — top-level review

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

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3725853152

`every_eval_ever/cli.py` line 392 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853152

**Before**

> **RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.
>
> The module entry point can use the shared parser, with one offline entry-point test covering its defaults.

**After**

> **RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace. This handler now reads missing fields and fails before conversion.
>
> **Requested actions**
>
> - Use the shared parser in the module entry point.
> - Add one offline entry-point test covering its defaults.

#### Comment 3725853155

`every_eval_ever/converters/alpaca_eval/adapter.py` line 307 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853155

**Before**

> **RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.
>
> Numeric fields can validate as finite values under their metric rules before result construction. Invalid rows can enter `SourceConversionResult`.

**After**

> **RAV-RUN2-R1-F005 [medium] input-validation** — Populated invalid `win_rate` values bypass row-level failure handling. They can omit the headline metric or abort strict JSON publication.
>
> **Requested actions**
>
> - Validate numeric fields as finite values under their metric rules before result construction.
> - Add invalid rows to `SourceConversionResult`.

#### Comment 3725853159

`every_eval_ever/converters/alpaca_eval/adapter.py` line 643 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853159

**Before**

> **RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.
>
> New snapshots can store pinned prompt content. Legacy snapshots can leave this typed value unset and mark the missing content.

**After**

> **RAV-RUN2-R1-F007 [medium] generation-provenance** — `GenerationArgs.prompt_template` contains an upstream path instead of prompt content. Offline records cannot reconstruct the generation prompt.
>
> **Requested actions**
>
> - Store pinned prompt content in new snapshots.
> - For legacy snapshots, leave this typed value unset and mark the missing content.

#### Comment 3725853144

`every_eval_ever/converters/alpaca_eval/adapter.py` line 687 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853144

**Before**

> **RAV-RUN2-R1-F001 [medium] model-identity** — Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect this join key.
>
> Only model IDs emitted by the pinned snapshot need vendored resolution. The source-derived ID can remain a marked fallback.

**After**

> **RAV-RUN2-R1-F001 [medium] model-identity** — Developer IDs use the registry, but `model_info.id` uses an adapter-private identity ladder. Canonical model aliases cannot affect this join key.
>
> Only model IDs emitted by the pinned snapshot need vendored resolution.
>
> Please resolve `model_info.id` through the vendored registry for model IDs emitted by the pinned snapshot, retaining the source-derived ID as a marked fallback.

#### Comment 3725853148

`every_eval_ever/converters/alpaca_eval/adapter.py` line 976 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853148

**Before**

> **RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.
>
> Network-mode refs can resolve once to a commit SHA. Offline replay can keep the stored immutable ref without network access.

**After**

> **RAV-RUN2-R1-F002 [medium] reproducibility** — Branch and tag refs are used in stable IDs and provenance URLs without commit resolution. Two network runs can fetch different input under the same identity.
>
> Please resolve network-mode refs once to a commit SHA.
> Offline replay can keep the stored immutable ref without network access.

#### Comment 3725853163

`every_eval_ever/helpers/eval_card_registry.py` line 251 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853163

**Before**

> **RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.
>
> Live mode can query present-null entries while offline behavior remains unchanged.

**After**

> **RAV-RUN2-R1-F009 [medium] registry-resolution** — Live mode skips keys whose vendored value is null. A known gap cannot discover a new registry entry until the snapshot refreshes.
>
> Please query present-null entries in live mode.
> Offline behavior remains unchanged.

#### Comment 3725853168

`every_eval_ever/tools/refresh_eval_card_registry.py` line 151 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3725853168

**Before**

> **RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.
>
> Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.

**After**

> **RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.
>
> **Requested actions**
>
> - Give exact canonical IDs precedence.
> - Resolve normalized spellings only when one organization owns them.

## PR #190 — review 4884452884

Original review: https://github.com/evaleval/every_eval_ever/pull/190#pullrequestreview-4884452884

### Before — top-level review

> <!-- review-anvil-marker: a1238ded-0615-45cf-8ec0-0a6f040dedb3 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — This pass is comment-only; five medium suggestions remain on identity, data semantics, and refresh safety.
> **Result:** The consolidation is much stronger at this head. Most earlier concerns are fixed, and the remaining items have focused fix paths.
> **Scope:** Consolidate AlpacaEval 1.0 and 2.0 conversion, identity, registry resolution, CLI support, and pinned source data.
> **Checks:** 5 concerns checked; 4 confirmed and 1 lowered in priority.
> **Second check:** 2 reviewers checked 8 findings; 5 kept, 2 clarified or lowered, and 1 removed.
>
> <details>
> <summary>Earlier review comments (11 grouped items)</summary>
>
> - **Still open:** `RAV-RUN2-R1-F001` model identity and `RAV-RUN2-R1-F009` live lookup for known registry gaps remain relevant.
> - **Fixed:** moving refs, module CLI parsing, score-cell validation, prompt content, evaluator relationship, temporary output, denominator text, live-error provenance, and organization collisions.
> - **Fixed:** the old duplicate converter, `NullModel` publication, partial-success exit, and conflicting output layout are no longer present.
>
> </details>
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN2-R1-F001 | medium | model identity | `every_eval_ever/converters/alpaca_eval/adapter.py:662` | `model_info.id` still bypasses shared model aliases, so the same model can keep separate join keys across sources. |
> | RAV-RUN2-R1-F009 | medium | registry resolution | `every_eval_ever/helpers/eval_card_registry.py:249` | Live mode still skips present-null snapshot entries, so it cannot discover a new canonical until refresh. |
> | RAV-RUN3-R1-F001 | medium | metric semantics | `every_eval_ever/converters/alpaca_eval/adapter.py:504` | `avg_length` is described as neutral but receives a binary direction value that signals higher is better. (inline) |
> | RAV-RUN3-R1-F002 | medium | input validation | `every_eval_ever/converters/alpaca_eval/adapter.py:535` | Populated invalid uncertainty and count cells can disappear, and invalid denominators can become 805. (inline) |
> | RAV-RUN3-R1-F005 | medium | registry refresh | `every_eval_ever/converters/alpaca_eval/refresh_hf_canonical_ids.py:104` | A transient non-200 response can remove a confirmed rename when the refreshed map replaces the prior file. (inline) |
>
> <details>
> <summary>Non-blocking low findings (2 items)</summary>
>
> - **RAV-RUN3-R1-F003 [low] CLI help** — `--input-json` says it is offline, but `--registry-live` remains an explicit network exception. The help text can name that exception.
> - **RAV-RUN3-R1-F004 [low] registry reporting** — The CLI prints registry status before live lookups. A final status line would show the actual query and error totals.
>
> </details>
>
> ## Things to try
>
> <details>
> <summary>Suggested next steps (6 items)</summary>
>
> - **[medium] model identity** — Exact aliases for model IDs emitted by supported converters can stay small. Source IDs and identity evidence can remain in provenance. (`RAV-RUN3-R1-P001`; covers `RAV-RUN2-R1-F001`)
> - **[medium] metric semantics** — The neutral-metric representation needs a shared contract before this adapter changes its published coverage. (`RAV-RUN3-R1-P002`; covers `RAV-RUN3-R1-F001`)
> - **[medium] input validation** — Populated uncertainty and count cells can use their own numeric rules. Invalid rows can then enter the failure report. (`RAV-RUN3-R1-P003`; covers `RAV-RUN3-R1-F002`)
> - **[medium] registry resolution** — Present-null entries can use the existing cached live lookup while offline behavior stays unchanged. (`RAV-RUN3-R1-P004`; covers `RAV-RUN2-R1-F009`)
> - **[low] registry reporting** — One final status line before publication checks can replace the initial zero-count line. (`RAV-RUN3-R1-P005`; covers `RAV-RUN3-R1-F004`)
> - **[medium] registry refresh** — Transient failures can stop an incomplete destructive refresh. Existing output can stay unchanged when the sweep is incomplete. (`RAV-RUN3-R1-P006`; covers `RAV-RUN3-R1-F005`)
>
> </details>
>
> ## Set aside / Outside this change
>
> - **RAV-RUN3-R1-F001 [medium] metric semantics** — The issue is confirmed, but the specific representation stays open because the current schema has no neutral direction.
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #190 (`add-alpaca-eval-adapter`, 16 files, +8729/-514) at `ed5b7dcbe7a2cd5755338c02431782f03a12be82`
> - Run ordinal: 3
> - Rounds: 1/1 completed; adaptive off in review-only mode
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast radius, and constructive suggestions
> - Earlier review comments: 11 grouped items; 2 still present and 9 fixed or stale
> - Finding counts: 0 critical, 0 high, 5 medium, 2 low, 0 nit
> - Checks: concerns=5; confirmed=4, lowered=1; none set aside by verification
> - Second check: targeted; reviewers=2; kept=5, clarified/lowered=2, removed=1; approval unchanged
> - Set aside: 1 fix choice; reason=shared neutral-metric contract
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3737053181

`every_eval_ever/converters/alpaca_eval/adapter.py` line 525 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3737053181

**Before**

> **RAV-RUN3-R1-F001 [medium] metric-semantics** — `avg_length` is described as neutral but receives `lower_is_better=False`. Consumers can read that Boolean as higher-is-better.
>
> The adapter approach is consistent with the current schema; the remaining gap is a shared representation for neutral measures.

**After**

> **RAV-RUN3-R1-F001 [medium] metric-semantics** — `avg_length` is described as neutral but receives `lower_is_better=False`
>
> Consumers can read that Boolean as higher-is-better. The adapter approach is consistent with the current schema.
>
> Please add a shared representation for neutral measures.

#### Comment 3737053197

`every_eval_ever/converters/alpaca_eval/adapter.py` line 557 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3737053197

**Before**

> **RAV-RUN3-R1-F002 [medium] input-validation** — Populated malformed uncertainty and count cells become absent values here. The later denominator fallback also turns invalid or zero `n_total` into 805.
>
> Separate rules for uncertainty, counts, and positive denominators would keep bad rows in the failure report. Empty optional cells can remain allowed.

**After**

> **RAV-RUN3-R1-F002 [medium] input-validation** — Populated malformed uncertainty and count cells become absent values here
>
> The later denominator fallback also turns invalid or zero `n_total` into 805.
>
> Please use separate rules for uncertainty, counts, and positive denominators to keep bad rows in the failure report.
> Empty optional cells can remain allowed.

#### Comment 3737053204

`every_eval_ever/converters/alpaca_eval/refresh_hf_canonical_ids.py` line 115 — https://github.com/evaleval/every_eval_ever/pull/190#discussion_r3737053204

**Before**

> **RAV-RUN3-R1-F005 [medium] registry-refresh** — Every non-200 response drops the current ID from the rebuilt map. A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.
>
> An incomplete sweep can leave the existing output unchanged and return a nonzero result. Expected 401 responses can keep their current handling.

**After**

> **RAV-RUN3-R1-F005 [medium] registry-refresh** — Every non-200 response drops the current ID from the rebuilt map
>
> A transient 429 or server error can therefore remove a confirmed rename when the file is overwritten.
>
> Please leave the existing output unchanged and return a nonzero result when a sweep is incomplete.
> Expected 401 responses can keep their current handling.

## PR #197 — review 4884743173

Original review: https://github.com/evaleval/every_eval_ever/pull/197#pullrequestreview-4884743173

### Before — top-level review

> <!-- review-anvil-marker: 8f57fc24-75bf-4005-bc6f-a6684ffcc866 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — This pass is comment-only, and one high-priority row-accounting gap remains.
> **Result:** The adapter now handles the earlier selection, JSON, and default snapshot concerns well. Four focused suggestions remain.
> **Scope:** Add a BenchPress score-matrix adapter with snapshot pinning, provenance policy, range checks, and complete source-row accounting.
> **Checks:** 3 concerns checked; all 3 confirmed.
> **Second check:** 2 reviewers checked 4 findings; all 4 stayed, and 3 fix paths were clarified.
>
> ## Earlier review comments
>
> - **Fixed:** accepted audit-status selection and strict JSON publication now follow the intended source and shared writer.
> - **Fixed:** the default fetch resolves one immutable dataset SHA before reading all four files.
> - **Still present:** the earlier evaluator-relationship concern remains because citation breadth does not identify document ownership.
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN2-R1-F001 | high | failure accounting | `every_eval_ever/adapters/benchpress/adapter.py:214` | One malformed score or row-level conversion error can stop the full run before that source row is recorded. (inline) |
> | RAV-RUN2-R1-F002 | medium | snapshot provenance | `every_eval_ever/adapters/benchpress/adapter.py:246` | The default path is pinned, but an explicit symbolic `--revision` can still mix snapshots and records the symbol instead of a SHA. (inline) |
> | RAV-RUN2-R1-F003 | medium | evaluator relationship | `every_eval_ever/adapters/benchpress/adapter.py:299` | A one-provider citation does not prove that the document owner matches the scored model provider. |
> | RAV-RUN2-R1-F004 | medium | exclusion accounting | `every_eval_ever/adapters/benchpress/adapter.py:641` | An exclusions-only run prints a count but does not preserve each excluded row and reason in the report. (inline) |
>
> ## Things to try
>
> <details>
> <summary>Suggested next steps (4 items)</summary>
>
> - **[high] failure accounting** — Expected parsing and schema errors can stay inside a per-row boundary. Unexpected program errors can remain visible. (`RAV-RUN2-R1-P001`; covers `RAV-RUN2-R1-F001`)
> - **[medium] snapshot provenance** — Every supplied reference can resolve once to a SHA, preserving current branch and tag support. (`RAV-RUN2-R1-P002`; covers `RAV-RUN2-R1-F002`)
> - **[medium] evaluator relationship** — Ownership-unknown documents can use `other` until the source exposes comparable publisher evidence. (`RAV-RUN2-R1-P003`; covers `RAV-RUN2-R1-F003`)
> - **[medium] exclusion accounting** — The shared report can be saved for failures or exclusions. The exit remains nonzero only for failures. (`RAV-RUN2-R1-P004`; covers `RAV-RUN2-R1-F004`)
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #197 (`add-benchpress-adapter`, 5 files, +942/-0) at `3d624b536f87ffd74d3f135bf43c7044df673cdc`
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off in review-only mode
> - Mix: 3 codex-exec; 2 completed, 1 failed after DNS transport retries
> - Focus: correctness, maintainability, simplicity, production blast radius, and constructive suggestions
> - Earlier review comments: 4 grouped concerns; 3 fixed and 1 still present
> - Finding counts: 0 critical, 1 high, 3 medium, 0 low, 0 nit
> - Checks: concerns=3; confirmed=3
> - Second check: targeted; reviewers=2; kept=4, clarified=3, removed=0; approval unchanged
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3737266652

`every_eval_ever/adapters/benchpress/adapter.py` line 245 — https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3737266652

**Before**

> **RAV-RUN2-R1-F001 [high] failure-accounting** — Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary. One malformed source value can stop every valid row without a source-row failure record.
>
> A narrow boundary can catch expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible.

**After**

> **RAV-RUN2-R1-F001 [high] failure-accounting** — Score parsing happens before `SourceConversionResult` exists, and later row construction has no row-level error boundary
>
> One malformed source value can stop every valid row without a source-row failure record.
>
> Please add a narrow boundary that catches expected parsing and schema errors.
> Unexpected program or infrastructure errors can remain visible.

#### Comment 3737266656

`every_eval_ever/adapters/benchpress/adapter.py` line 253 — https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3737266656

**Before**

> **RAV-RUN2-R1-F002 [medium] snapshot-provenance** — The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step. A moving branch can resolve differently across four requests, while metadata records only the symbol.
>
> Resolving every supplied reference once would keep branch and tag support while making all file URLs reproducible.

**After**

> **RAV-RUN2-R1-F002 [medium] snapshot-provenance** — The default fetch resolves one SHA, but a supplied symbolic revision bypasses that step
>
> A moving branch can resolve differently across four requests, while metadata records only the symbol.
>
> Please resolve every supplied reference once to keep branch and tag support while making all file URLs reproducible.

#### Comment 3737266661

`every_eval_ever/adapters/benchpress/adapter.py` line 641 — https://github.com/evaleval/every_eval_ever/pull/197#discussion_r3737266661

**Before**

> **RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.
>
> The shared report already supports exclusions. It can be saved for either collection while the nonzero exit stays conditional on failures.

**After**

> **RAV-RUN2-R1-F004 [medium] exclusion-accounting** — The report is saved only when `result.failures` is nonempty
>
> An exclusions-only run succeeds but loses each excluded source reference and reason.
>
> Please save the shared report for either collection.
> The nonzero exit can remain conditional on failures.

## PR #203 — review 4871030385

Original review: https://github.com/evaleval/every_eval_ever/pull/203#pullrequestreview-4871030385

### Before — top-level review

> <!-- review-anvil-marker: 50c4c07c-33d4-441c-853f-c70b30e41203 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — The advertised instance mode still fails after writing partial output.
> **Result:** One high and ten medium concerns remain. Five earlier concerns are fixed.
> **Scope:** This PR adds a WILD-raw aggregate and optional item-level adapter.
> **Checks:** 11 concerns checked; 8 confirmed and 3 narrowed.
> **Second check:** targeted, 2 reviewers; 11 kept, 5 fix paths clarified, 0 set aside, 0 removed.
>
> ## Earlier review comments
>
> <details>
> <summary>Earlier review comments (14 items)</summary>
>
> - The dependency declaration, scorer pairing, standard-error test, and false local `main` label are fixed.
> - Missing-response handling, revision pinning, repeat publication, local identity, and overall-instance linkage remain present.
> - Existing discussions remain the place for those carry-forward items. This review does not create duplicate inline threads.
>
> </details>
>
> ## What I noticed
>
> - **RAV-RUN2-R1-F001 [high] instance-publication** `utils/wild/adapter.py:528` — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written. (inline)
> - **RAV-RUN2-R1-F002 [medium] documentation** `utils/wild/README.md:32` — The smoke command passes a directory to a file-only validator. Its output root also cannot satisfy datastore path checks. (inline)
> - **RAV-RUN2-R1-F003 [medium] memory-use** `utils/wild/adapter.py:142` — Capped instance runs still materialize all selected columns for a complete row group before the cap is checked. (inline)
> - **RAV-RUN2-R1-F004 [medium] data-validation** `utils/wild/adapter.py:157` — Missing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted. (inline)
> - **RAV-RUN2-R1-F005 [medium] metric-identity** `utils/wild/adapter.py:210` — Each task receives a different metric ID even though every result is canonical accuracy. Cross-source joins by metric ID become fragmented. (inline)
> - **RAV-RUN2-R1-F006 [medium] instance-linkage** `utils/wild/adapter.py:367` — Multi-subtask rows contribute to overall and leaf results, but instances link only to leaves. This conflicts with the one-record-per-contributing-result guidance. (earlier comment remains open)
> - **RAV-RUN2-R1-F007 [medium] instance-output** `utils/wild/adapter.py:383` — When no assistant response exists, the adapter substitutes an extracted answer into `output.raw`. Scorer data is then labeled as complete model output. (earlier comment remains open)
> - **RAV-RUN2-R1-F008 [medium] revision-pinning** `utils/wild/adapter.py:471` — When metadata lookup fails without `--revision`, both remote passes continue against mutable `main`. (earlier comment remains open)
> - **RAV-RUN2-R1-F009 [medium] local-provenance** `utils/wild/adapter.py:478` — Local runs without `--evaluation-timestamp` key `evaluation_id` on current time. Identical reruns receive different logical identities. (earlier comment remains open)
> - **RAV-RUN2-R1-F010 [medium] repeatability** `utils/wild/adapter.py:510` — Reruns create fresh UUID files for stable evaluation IDs. Incremental writes also leave partial batches when later work fails. (earlier comment remains open)
> - **RAV-RUN2-R1-F011 [medium] cli** `utils/wild/adapter.py:546` — A bare `--parquet` flag yields an empty list. The adapter silently starts the full remote 15-shard conversion. (inline)
>
> ID legend: `RUN` is the observed PR review run, `R` is the immutable origin round, `F` is a finding, and `P` is a plan.
>
> <details>
> <summary>Things to try (10 items)</summary>
>
> - **[high] publication** — Complete output can stage before publication. Existing logical output can be rejected until replacement is atomic. Sidecar validation and hashing must stay streaming for WILD's size. (`RAV-RUN2-R1-P001`; covers `RAV-RUN2-R1-F001`, `RAV-RUN2-R1-F010`)
> - **[medium] documentation** — Smoke output can use the required `data/<collection>` path. The validator can receive a quoted fixed-depth file glob. (`RAV-RUN2-R1-P002`; covers `RAV-RUN2-R1-F002`)
> - **[medium] memory-use** — Bounded record batches can flush and hash incrementally. (`RAV-RUN2-R1-P003`; covers `RAV-RUN2-R1-F003`)
> - **[medium] data-validation** — Rows with invalid scores can enter the failure report. Incomplete token usage can be omitted, with token means based only on complete values. (`RAV-RUN2-R1-P004`; covers `RAV-RUN2-R1-F004`)
> - **[medium] metric-identity** — `accuracy` can remain the metric ID while `evaluation_name` distinguishes tasks. (`RAV-RUN2-R1-P005`; covers `RAV-RUN2-R1-F005`)
> - **[medium] instance-linkage** — Overall-leaf pairs can emit as one unit. The cap can stop before a pair that does not fit. (`RAV-RUN2-R1-P006`; covers `RAV-RUN2-R1-F006`)
> - **[medium] instance-output** — Missing assistant output can remain empty. Attribution can name the actual answer or scorer source. (`RAV-RUN2-R1-P007`; covers `RAV-RUN2-R1-F007`)
> - **[medium] revision-pinning** — Default remote runs can stop when a concrete revision cannot resolve. Verified immutable overrides can remain usable. (`RAV-RUN2-R1-P008`; covers `RAV-RUN2-R1-F008`)
> - **[medium] local-provenance** — Local parquet runs can require an explicit evaluation timestamp. (`RAV-RUN2-R1-P009`; covers `RAV-RUN2-R1-F009`)
> - **[medium] cli** — `--parquet` can require at least one path. (`RAV-RUN2-R1-P010`; covers `RAV-RUN2-R1-F011`)
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #203 at `6c8e3b20a4fbff2d332cab3ccbe544bac618f87a` (7 files, +855/-1)
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off; material findings remain
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 14 ledger entries; fixed and carry-forward items revalidated
> - Finding counts: 0 critical, 1 high, 10 medium, 0 low, 0 nit
> - Checks: concerns=11; confirmed=8/ruled-out=0/set-aside=0/narrowed=3
> - Second check: targeted; reviewers=2; kept=11/clarified=5/set-aside=0/removed=0; approval changed no
> - Fixes applied: 0 (review-only)
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3725913007

`utils/wild/README.md` line 32 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913007

**Before**

> **RAV-RUN2-R1-F002 [medium] documentation** — This smoke command passes a directory to a file-only validator. Its output root also cannot satisfy datastore path checks.
>
> Smoke output can use the required `data/<collection>` path, and validation can receive a quoted fixed-depth file glob.

**After**

> **RAV-RUN2-R1-F002 [medium] documentation** — This smoke command passes a directory to a file-only validator. Its output root also cannot satisfy datastore path checks.
>
> **Requested actions**
>
> - Use the required `data/<collection>` path for smoke output.
> - Pass a quoted fixed-depth file glob to validation.

#### Comment 3725913011

`utils/wild/adapter.py` line 142 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913011

**Before**

> **RAV-RUN2-R1-F003 [medium] memory-use** — Capped instance runs still materialize all selected columns for a complete row group before the cap is checked. The cap does not bound this allocation.
>
> Bounded record batches can flush and hash incrementally.

**After**

> **RAV-RUN2-R1-F003 [medium] memory-use** — Capped instance runs still materialize all selected columns for a complete row group before the cap is checked. The cap does not bound this allocation.
>
> Please flush and hash bounded record batches incrementally so capped instance runs do not materialize all selected columns for a complete row group before the cap is checked.

#### Comment 3725913013

`utils/wild/adapter.py` line 157 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913013

**Before**

> **RAV-RUN2-R1-F004 [medium] data-validation** — Missing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted.
>
> Invalid scores can enter the failure report. Incomplete token usage can be omitted, with token means based only on complete values.

**After**

> **RAV-RUN2-R1-F004 [medium] data-validation** — Missing scores become incorrect answers and stay in aggregate denominators. Missing token data becomes measured zero instead of being omitted.
>
> **Requested actions**
>
> - Add invalid scores to the failure report.
> - Omit incomplete token usage and base token means only on complete values.

#### Comment 3725913015

`utils/wild/adapter.py` line 210 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913015

**Before**

> **RAV-RUN2-R1-F005 [medium] metric-identity** — Each task receives a different metric ID even though every result is canonical accuracy. Cross-source joins by metric ID become fragmented.
>
> `accuracy` can remain the metric ID while `evaluation_name` distinguishes tasks.

**After**

> **RAV-RUN2-R1-F005 [medium] metric-identity** — Each task receives a different metric ID even though every result is canonical accuracy. Cross-source joins by metric ID become fragmented.
>
> Please keep `accuracy` as the metric ID and use `evaluation_name` to distinguish tasks.

#### Comment 3725913004

`utils/wild/adapter.py` line 528 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913004

**Before**

> **RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.
>
> Complete output can stage before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.

**After**

> **RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.
>
> Please stage complete output before publication. Existing logical output can be rejected until replacement is atomic, and sidecar validation can remain streaming.

#### Comment 3725913021

`utils/wild/adapter.py` line 546 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3725913021

**Before**

> **RAV-RUN2-R1-F011 [medium] cli** — A bare `--parquet` flag yields an empty list. The adapter treats that as no local input and silently starts the full remote 15-shard conversion.
>
> The option can require at least one path.

**After**

> **RAV-RUN2-R1-F011 [medium] cli** — A bare `--parquet` flag yields an empty list. The adapter treats that as no local input and silently starts the full remote 15-shard conversion.
>
> Please require at least one path for `--parquet`.

## PR #203 — review 4884885250

Original review: https://github.com/evaleval/every_eval_ever/pull/203#pullrequestreview-4884885250

### Before — top-level review

> <!-- review-anvil-marker: 585bdc46-7ad8-4ff7-9521-dd313411db50 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — This pass is comment-only, and replacement publication still risks losing valid prior output.
> **Result:** The adapter now resolves most earlier review items well. Four focused suggestions remain for publication, pinning, and CLI safety.
> **Scope:** Add a streaming WILD-raw adapter for aggregate and optional item-level Inspect AI records.
> **Checks:** 4 concerns checked; 3 confirmed and 1 ruled out.
> **Second check:** 2 reviewers checked 4 findings; all 4 stayed, and 3 fix paths were clarified.
>
> <details>
> <summary>Earlier review comments (14 grouped concerns)</summary>
>
> - **Still present:** replacement publication (`RAV-RUN2-R1-F010`) and metadata-failure pinning (`RAV-RUN2-R1-F008`) remain relevant at the moved adapter path.
> - **No longer relevant:** instance linkage (`RAV-RUN2-R1-F006`) was checked against the current schema guidance. The documented leaf-only choice is permitted.
> - **Fixed:** sidecar paths, scorer/output semantics, local provenance, memory bounds, score and token validation, canonical metric identity, `--parquet`, dependency packaging, tests, and README validation commands.
>
> </details>
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN2-R1-F010 | high | publication | `every_eval_ever/adapters/wild/adapter.py:660` | Replacement deletes every prior file for selected model directories before new publication. Partial inputs can remove absent benchmarks, and later failures cannot restore deleted files. |
> | RAV-RUN2-R1-F008 | medium | revision pinning | `every_eval_ever/adapters/wild/adapter.py:516` | After metadata failure, an explicit symbolic revision can reach both remote passes when an evaluation timestamp is also supplied. |
> | RAV-RUN3-R1-F001 | medium | models CLI | `every_eval_ever/adapters/wild/adapter.py:678` | A bare `--models` disables filtering. A fully unmatched filter exits successfully after publishing zero logs. (inline) |
> | RAV-RUN3-R1-F002 | medium | output path | `every_eval_ever/adapters/wild/adapter.py:608` | An arbitrary output path loses its final component, so publication and replacement can target a different `wild` directory. (inline) |
>
> ## Things to try
>
> - **[high] publication** — New output can be staged and checked while prior adapter-owned files remain recoverable. Replacement can use logical evaluation identity and preserve unrelated tasks. (`RAV-RUN3-R1-P001`; covers `RAV-RUN2-R1-F010`)
> - **[medium] revision pinning** — Symbolic refs can resolve once to `info.sha`. A metadata-failure fallback can accept only a full SHA with an explicit timestamp. (`RAV-RUN2-R1-P008`; covers `RAV-RUN2-R1-F008`)
> - **[medium] models CLI** — `--models` can require one value. A selection with no source matches can fail before stale-file discovery or publication. (`RAV-RUN3-R1-P002`; covers `RAV-RUN3-R1-F001`)
> - **[medium] output path** — The documented `data/wild` shape can be validated before metadata lookup, reads, or replacement scans. (`RAV-RUN3-R1-P003`; covers `RAV-RUN3-R1-F002`)
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #203 (`add-wild-adapter`, 7 files, +1137/-1) at `ed99266c74958f79249a2d0ac68618c0b76b7f8b`
> - Run ordinal: 3
> - Rounds: 1/1 completed; adaptive off in review-only mode
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast radius, and constructive suggestions
> - Earlier review comments: 14 grouped concerns; 2 still present, 1 ruled out, and 11 fixed
> - Finding counts: 0 critical, 1 high, 3 medium, 0 low, 0 nit
> - Checks: concerns=4; confirmed=3, ruled-out=1
> - Second check: targeted; reviewers=2; kept=4, clarified=3, removed=0; approval unchanged
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3737383922

`every_eval_ever/adapters/wild/adapter.py` line 608 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3737383922

**Before**

> **RAV-RUN3-R1-F002 [medium] output-path** — The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it. An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.
>
> Early validation of the documented `data/wild` shape would keep lookup, replacement, and status output on one destination.

**After**

> **RAV-RUN3-R1-F002 [medium] output-path** — The code passes only `args.output_dir.parent` to lookup and publication, then derives `wild` below it
>
> An arbitrary path such as `/tmp/intended` therefore targets `/tmp/wild` while messages name the requested path.
>
> Please validate the documented `data/wild` shape early to keep lookup, replacement, and status output on one destination.

#### Comment 3737383919

`every_eval_ever/adapters/wild/adapter.py` line 678 — https://github.com/evaleval/every_eval_ever/pull/203#discussion_r3737383919

**Before**

> **RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.
>
> Requiring one or more values would block the first path. A no-match check can stop before existing-output discovery or publication.

**After**

> **RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run
>
> A nonempty filter with no matches instead exits successfully with zero logs.
>
> **Requested actions**
>
> - Require one or more `--models` values to block the bare-flag full-run path.
> - Add a no-match check; it can stop before existing-output discovery or publication.

## PR #204 — review 4871126847

Original review: https://github.com/evaleval/every_eval_ever/pull/204#pullrequestreview-4871126847

### Before — top-level review

> <!-- review-anvil-marker: f41f4245-474c-459c-a948-c069e908976d -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — A confirmed model-attribution defect remains when registry resolution is unavailable.
> **Result:** One high and five medium concerns remain. Pagination, timestamp precision, and worker isolation are fixed.
> **Scope:** This PR adds an Open Medical-LLM leaderboard adapter.
> **Checks:** 6 concerns checked; 5 confirmed and 1 narrowed.
> **Second check:** targeted, 2 reviewers; 6 kept, 4 fix paths clarified, 0 set aside, 0 removed.
>
> ## Earlier review comments
>
> - **Still present:** model attribution can use the wrong path identity when the registry is unavailable. The existing thread remains open.
> - **Partly fixed:** fetch and conversion failures now affect exit status. Empty results and publication failures remain outside full accounting.
> - **Fixed:** malformed conversion isolation, pagination, and timestamp precision.
>
> ## What I noticed
>
> - **RAV-RUN2-R1-F001 [high] model-identity** `utils/open_medical_llm/adapter.py:429` — When registry resolution is unavailable or disabled, a path/config mismatch makes `model_info.id` use the path identity instead of the evaluated config identity. (earlier comment remains open)
> - **RAV-RUN2-R1-F002 [medium] repository-integration** `utils/open_medical_llm/adapter.py:12` — The adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so this adapter and its documented command are outside the active package. (inline)
> - **RAV-RUN2-R1-F003 [medium] schema-compatibility** `tests/test_open_medical_llm_adapter.py:26` — The test requires schema `0.2.2`, while current main emits `0.3.0`. The integrated test fails. (inline)
> - **RAV-RUN2-R1-F004 [medium] metric-identity** `utils/open_medical_llm/adapter.py:274` — Ordinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key. (inline)
> - **RAV-RUN2-R1-F005 [medium] error-handling** `utils/open_medical_llm/adapter.py:434` — A selected file with no usable score exits as a successful skip. A later publication failure can also bypass the failure report after earlier output exists. (earlier feedback remains partly open)
> - **RAV-RUN2-R1-F006 [medium] publication** `utils/open_medical_llm/adapter.py:444` — Repeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records. (inline)
>
> ID legend: `RUN` is the observed PR review run, `R` is the immutable origin round, `F` is a finding, and `P` is a plan.
>
> <details>
> <summary>Things to try (5 items)</summary>
>
> - **[high] model-identity** — Existing lm-eval parsing rules can select one valid config identity. That value can drive model metadata, evaluation ID, and routing, while the dataset path and mismatches stay in provenance. (`RAV-RUN2-R1-P001`; covers `RAV-RUN2-R1-F001`)
> - **[medium] integration** — Current main can be integrated before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`. Tests can use the imported schema version. (`RAV-RUN2-R1-P002`; covers `RAV-RUN2-R1-F002`, `RAV-RUN2-R1-F003`)
> - **[medium] metric-identity** — `accuracy` can remain the metric ID while task-specific evaluation names preserve benchmark identity. (`RAV-RUN2-R1-P003`; covers `RAV-RUN2-R1-F004`)
> - **[medium] error-handling** — Fetch, conversion, and empty-result failures can be recorded by selected source path. Valid records can publish once as a batch; publication failure can roll back and exit nonzero. (`RAV-RUN2-R1-P004`; covers `RAV-RUN2-R1-F005`)
> - **[medium] publication** — The collection target can reject existing output JSON before UUID generation or batch publication. A repeat-run test can confirm that no file appears. (`RAV-RUN2-R1-P005`; covers `RAV-RUN2-R1-F006`)
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #204 at `8d9be4041f42774a40d733f15c459e8b93f929fd` (5 files, +650/-0)
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off; material findings remain
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 10 ledger entries; fixed and carry-forward items revalidated
> - Finding counts: 0 critical, 1 high, 5 medium, 0 low, 0 nit
> - Checks: concerns=6; confirmed=5/ruled-out=0/set-aside=0/narrowed=1
> - Second check: targeted; reviewers=2; kept=6/clarified=4/set-aside=0/removed=0; approval changed no
> - Fixes applied: 0 (review-only)
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3725972282

`tests/test_open_medical_llm_adapter.py` line 26 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3725972282

**Before**

> **RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.
>
> The expected value can come from the imported schema version.

**After**

> **RAV-RUN2-R1-F003 [medium] schema-compatibility** — This assertion requires schema `0.2.2`, while current main emits `0.3.0`. The test fails after integration.
>
> Please derive the expected value from the imported schema version.

#### Comment 3725972277

`utils/open_medical_llm/adapter.py` line 12 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3725972277

**Before**

> **RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.
>
> Current main can be integrated before moving the adapter and references under `every_eval_ever/adapters/open_medical_llm`.

**After**

> **RAV-RUN2-R1-F002 [medium] repository-integration** — This adapter remains under the retired `utils` layout. Installed packages include `every_eval_ever*`, so the adapter and its documented command are outside the active package.
>
> Please integrate current main before moving the adapter and its references under `every_eval_ever/adapters/open_medical_llm`.

#### Comment 3725972285

`utils/open_medical_llm/adapter.py` line 274 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3725972285

**Before**

> **RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.
>
> `accuracy` can remain the metric ID while task-specific evaluation names preserve benchmark identity.

**After**

> **RAV-RUN2-R1-F004 [medium] metric-identity** — Ordinary accuracy receives nine benchmark-specific metric IDs. This fragments the global accuracy join key.
>
> Please keep `accuracy` as the metric ID while using task-specific evaluation names to preserve benchmark identity.

#### Comment 3725972287

`utils/open_medical_llm/adapter.py` line 444 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3725972287

**Before**

> **RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.
>
> The collection target can reject existing output JSON before UUID generation or batch publication.

**After**

> **RAV-RUN2-R1-F006 [medium] publication** — Repeat runs add a fresh UUID file for each stable evaluation ID. A populated target can hold duplicate logical records.
>
> Please reject existing output JSON in the collection target before UUID generation or batch publication.

## PR #204 — review 4884442134

Original review: https://github.com/evaleval/every_eval_ever/pull/204#pullrequestreview-4884442134

### Before — top-level review

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

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3737044361

`every_eval_ever/adapters/open_medical_llm/adapter.py` line 397 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3737044361

**Before**

> **RAV-RUN3-R1-F002 [high] evaluation-identity** — Alias metadata can change the identity of the same source file
>
> `evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.
>
> The raw dataset model path can remain the evaluation identity input. The reconciled repository can still drive model metadata and routing.

**After**

> **RAV-RUN3-R1-F002 [high] evaluation-identity** — Alias metadata can change the identity of the same source file
>
> `evaluated_model_repo()` returns the current Hugging Face canonical repository. `make_log()` then includes that value in `evaluation_id`. A later redirect change can give the same source result a second logical identity.
>
> Please keep the raw dataset model path as the evaluation identity input.
> The reconciled repository can still drive model metadata and routing.

#### Comment 3737044371

`every_eval_ever/adapters/open_medical_llm/adapter.py` line 585 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3737044371

**Before**

> **RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report
>
> `failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.
>
> An atomic report replacement after successful publication can record failures, exclusions, and fully clean runs without losing the last complete ledger.

**After**

> **RAV-RUN3-R1-F004 [medium] source-accounting** — Exclusions-only runs do not persist their accounting report
>
> `failure_report()` includes exclusions, but this condition writes it only when failures exist. The five documented baseline exclusions therefore have no durable record, and an older failure report can remain current.
>
> Please use an atomic report replacement after successful publication to record failures, exclusions, and fully clean runs without losing the last complete ledger.

#### Comment 3737044354

`every_eval_ever/adapters/open_medical_llm/adapter.py` line 601 — https://github.com/evaleval/every_eval_ever/pull/204#discussion_r3737044354

**Before**

> **RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight
>
> Lines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.
>
> The replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.

**After**

> **RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight
>
> Lines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.
>
> **Requested actions**
>
> - Retain recoverable old files until every new write and route transition succeeds.
> - Add a mid-write failure test across several routes covering this path.

## PR #209 — review 4871239031

Original review: https://github.com/evaleval/every_eval_ever/pull/209#pullrequestreview-4871239031

### Before — top-level review

> <!-- review-anvil-marker: 4c44996e-2766-430a-a5ba-27a3799dde12 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — Recursive output deletion can remove prior or unrelated data before publication succeeds.
> **Result:** One critical, two high, and three medium concerns remain. All 15 earlier feedback entries are fixed.
> **Scope:** This PR adds a Papers with Code adapter with metric resolution, score scaling, and publication.
> **Checks:** 6 concerns checked; all 6 confirmed.
> **Second check:** targeted, 2 reviewers; 6 kept, 6 fix paths clarified, 0 set aside, 0 removed.
>
> ## Earlier review comments
>
> - All 15 earlier feedback entries are fixed. Exact metric matching now fails closed on ambiguity.
> - Source bucket provenance, aggregate dependencies, paper URLs, and explicit zero-match behavior now follow the earlier guidance.
>
> ## What I noticed
>
> - **RAV-RUN2-R1-F001 [critical] publication-safety** `utils/paperswithcode/adapter.py:1693` — The adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data. (inline)
> - **RAV-RUN2-R1-F002 [high] conversion-accounting** `utils/paperswithcode/adapter.py:915` — Malformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output. (inline)
> - **RAV-RUN2-R1-F003 [high] score-scaling** `utils/paperswithcode/adapter.py:469` — The adapter divides a group by 100 when its median is out of range and 90 percent then fit. This decision ignores source scale evidence. (inline)
> - **RAV-RUN2-R1-F004 [medium] score-bounds** `utils/paperswithcode/adapter.py:357` — Scale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores. (inline)
> - **RAV-RUN2-R1-F005 [medium] metric-metadata** `utils/paperswithcode/adapter.py:830` — `metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds. (inline)
> - **RAV-RUN2-R1-F006 [medium] runtime-dependencies** `utils/paperswithcode/adapter.py:1260` — The default download path needs `huggingface_hub` 1.x, but the project requires a version below 1.0. The declared environment exits before download. (inline)
>
> ID legend: `RUN` is the observed PR review run, `R` is the immutable origin round, `F` is a finding, and `P` is a plan.
>
> <details>
> <summary>Things to try (6 items)</summary>
>
> - **[critical] publication-safety** — New or empty targets can use the batch publisher. Symlinks, roots, and populated targets can fail by default. Later replacement can use an explicit ownership manifest and recoverable prior directory. (`RAV-RUN2-R1-P001`; covers `RAV-RUN2-R1-F001`)
> - **[high] conversion-accounting** — Metric cells can be the source unit. Each attempted or rejected cell can count once, while malformed objects and missing datasets retain row references. (`RAV-RUN2-R1-P002`; covers `RAV-RUN2-R1-F002`)
> - **[high] score-scaling** — Rescaling can require an explicit recognized marker and compatible canonical definition. Other out-of-range cells can retain raw provenance in the failure report and stay out of publication. (`RAV-RUN2-R1-P003`; covers `RAV-RUN2-R1-F003`)
> - **[medium] score-bounds** — Tolerance can support scale classification only. A strict pre-publication check can reject unproven overruns; documented rounding can retain raw and adjusted values. (`RAV-RUN2-R1-P004`; covers `RAV-RUN2-R1-F004`)
> - **[medium] metric-metadata** — A unit can be set only when the canonical contract or an explicit conversion proves it. Otherwise it can stay unset while `pwc_scale` remains in details. (`RAV-RUN2-R1-P005`; covers `RAV-RUN2-R1-F005`)
> - **[medium] runtime-dependencies** — `--dump` can be required in the current environment. Help, examples, and tests can avoid the broken default until the declared client supports bucket access. (`RAV-RUN2-R1-P006`; covers `RAV-RUN2-R1-F006`)
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #209 at `eb4e5ef0334432499c97eb33346e1e03f229ff80` (16 files, +8479/-16)
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off; material findings remain
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 15 ledger entries; all fixed
> - Finding counts: 1 critical, 2 high, 3 medium, 0 low, 0 nit
> - Checks: concerns=6; confirmed=6/ruled-out=0/set-aside=0/lowered=0
> - Second check: targeted; reviewers=2; kept=6/clarified=6/set-aside=0/removed=0; approval changed no
> - Fixes applied: 0 (review-only)
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3726043679

`every_eval_ever/adapters/paperswithcode/adapter.py` line 356 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043679

**Before**

> **RAV-RUN2-R1-F004 [medium] score-bounds** — Scale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores.
>
> Tolerance can support scale classification only. A strict pre-publication check can reject unproven overruns.

**After**

> **RAV-RUN2-R1-F004 [medium] score-bounds** — Scale tolerance accepts small boundary overruns but emits them unchanged. Current semantic validation rejects those scores.
>
> **Requested actions**
>
> - Limit tolerance to scale classification only.
> - Add a strict pre-publication check to reject unproven overruns.

#### Comment 3726043677

`every_eval_ever/adapters/paperswithcode/adapter.py` line 471 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043677

**Before**

> **RAV-RUN2-R1-F003 [high] score-scaling** — The adapter divides a group by 100 when its median is out of range and 90 percent then fit. This decision ignores source scale evidence.
>
> Rescaling can require an explicit recognized marker and compatible canonical definition. Other out-of-range cells can stay out of publication and retain raw provenance in the failure report.

**After**

> **RAV-RUN2-R1-F003 [high] score-scaling** — The adapter divides a group by 100 when its median is out of range and 90 percent then fit. This decision ignores source scale evidence.
>
> Please require an explicit recognized marker and compatible canonical definition before rescaling. Other out-of-range cells can stay out of publication and retain raw provenance in the failure report.

#### Comment 3726043671

`every_eval_ever/adapters/paperswithcode/adapter.py` line 925 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043671

**Before**

> **RAV-RUN2-R1-F002 [high] conversion-accounting** — Malformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output.
>
> Metric cells can be the source unit. Each attempted or rejected cell can count once, while malformed objects and missing datasets retain row references.

**After**

> **RAV-RUN2-R1-F002 [high] conversion-accounting** — Malformed metrics, missing dataset references, and resultless rows are silently omitted. The command can exit successfully with incomplete output.
>
> **Requested actions**
>
> - Use metric cells as the source unit and count each attempted or rejected cell once.
> - Retain row references for malformed objects and missing datasets.

#### Comment 3726043685 — exact-source fallback

`every_eval_ever/adapters/paperswithcode/adapter.py` line 1415 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043685

**Before**

> **RAV-RUN2-R1-F006 [medium] runtime-dependencies** — The default download path needs `huggingface_hub` 1.x, but the project requires a version below 1.0. The declared environment exits before download.
>
> `--dump` can be required in the current environment until the declared client supports bucket access.

**After**

> **RAV-RUN2-R1-F006 [medium] runtime-dependencies** — The default download path needs `huggingface_hub` 1.x, but the project requires a version below 1.0. The declared environment exits before download.
>
> `--dump` can be required in the current environment until the declared client supports bucket access.

#### Comment 3726043682

`utils/paperswithcode/adapter.py` line 830 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043682

**Before**

> **RAV-RUN2-R1-F005 [medium] metric-metadata** — `metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds.
>
> A unit can be set only when the canonical contract or an explicit conversion proves it. Otherwise it can stay unset while `pwc_scale` remains in details.

**After**

> **RAV-RUN2-R1-F005 [medium] metric-metadata** — `metric_unit` stays tied to the PwC source scale after score conversion. It can conflict with the emitted score and canonical bounds.
>
> **Requested actions**
>
> - Set `metric_unit` only when the canonical contract or an explicit conversion proves it.
> - Otherwise, leave `metric_unit` unset; `pwc_scale` can remain in details.

#### Comment 3726043665

`utils/paperswithcode/adapter.py` line 1693 — https://github.com/evaleval/every_eval_ever/pull/209#discussion_r3726043665

**Before**

> **RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.
>
> New or empty targets can use the batch publisher. Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.

**After**

> **RAV-RUN2-R1-F001 [critical] publication-safety** — The adapter recursively deletes the selected output tree before publication. Empty batches and later write failures can destroy prior or unrelated data.
>
> **Requested actions**
>
> - Use the batch publisher for new or empty targets.
> - Make symlinks, roots, and populated targets fail by default until replacement has an explicit ownership manifest.

## PR #220 — review 4870784346

Original review: https://github.com/evaleval/every_eval_ever/pull/220#pullrequestreview-4870784346

### Before — top-level review

> <!-- review-anvil-marker: 1624500c-23b2-4e00-b513-69736a052874 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — The converter has four confirmed data-quality and partial-conversion risks.
> **Result:** Four focused changes would make repeated and partial conversions safer while preserving the PR's aggregate-only design.
> **Scope:** This PR adds a sayf-eval aggregate results-record converter, CLI route, documentation, fixtures, and offline tests.
> **Checks:** 8 single-reviewer concerns checked; 0 confirmed, 0 ruled out, 8 set aside because exact-head verification did not complete.
> **Second check:** targeted, 2 reviewers; 3 kept, 1 clarified, 0 set aside, 0 removed.
>
> ## Earlier review comments
>
> No earlier review comments were present.
>
> ## What I noticed
>
> - **RAV-RUN1-R1-F001 [high] source-provenance** `every_eval_ever/converters/sayf_eval/adapter.py:184` — The adapter puts a task slug in `source_data.dataset_name`. This replaces upstream names such as `CTI-Bench MCQ`, while the empty default prefix routes data into bare task collections. (inline)
> - **RAV-RUN1-R1-F003 [high] record-identity** `every_eval_ever/converters/sayf_eval/adapter.py:364` — `evaluation_id` contains the current retrieval time. Re-converting the same source run creates a new logical evaluation each time. (inline)
> - **RAV-RUN1-R1-F005 [high] partial-conversion** `every_eval_ever/converters/sayf_eval/adapter.py:418-422` — One invalid task raises after earlier task logs were built. The file-level failure path then discards those valid sibling logs. (inline)
> - **RAV-RUN1-R1-F007 [medium] judge-metadata** `every_eval_ever/converters/sayf_eval/adapter.py:164` — `LlmScoring.input_prompt` receives scoring prose or an invented fallback sentence. The record therefore presents a description as the actual judge prompt. (inline)
>
> <details>
> <summary>Non-blocking low findings (1 item)</summary>
>
> - **RAV-RUN1-R1-F013 [low] tests** — The publish test checks Pydantic validation but does not run the repository semantic validation gate on final paths.
>
> </details>
>
> <details>
> <summary>Things to try (4 items)</summary>
>
> - **[high] source-provenance** — Upstream dataset names can stay in `source_data`, while an explicit sayf-eval collection override handles routing. (`RAV-RUN1-R1-P001`; covers `RAV-RUN1-R1-F001`)
> - **[high] record-identity** — A stable source-run token can occupy the timestamp segment of `evaluation_id`; retrieval time can remain in `retrieved_timestamp`. (`RAV-RUN1-R1-P002`; covers `RAV-RUN1-R1-F003`)
> - **[high] partial-conversion** — A task-level error boundary can keep valid task logs and record each rejected task in failure accounting. (`RAV-RUN1-R1-P003`; covers `RAV-RUN1-R1-F005`)
> - **[medium] judge-metadata** — `llm_scoring` can be present only when the source supplies the real prompt template. Otherwise, supported score data can remain without invented prompt text. (`RAV-RUN1-R1-P004`; covers `RAV-RUN1-R1-F007`)
>
> </details>
>
> <details>
> <summary>Set aside / Outside this change (8 items)</summary>
>
> - **RAV-RUN1-R1-F002 [high] score-validation** — We set this aside because the verification run could not inspect the exact PR head.
> - **RAV-RUN1-R1-F004 [high] empty-record-accounting** — We set this aside because the zero-output CLI path was not reproduced.
> - **RAV-RUN1-R1-F006 [medium] model-metadata** — We set this aside because the model classification path was not reproduced at the exact PR head.
> - **RAV-RUN1-R1-F008 [medium] source-provenance** — We set this aside because malformed provenance behavior was not reproduced.
> - **RAV-RUN1-R1-F009 [medium] timestamp-handling** — We set this aside because malformed timestamp behavior was not reproduced.
> - **RAV-RUN1-R1-F010 [medium] source-type** — We set this aside because the source artifact classification was not confirmed against the exact PR head.
> - **RAV-RUN1-R1-F011 [medium] failure-accounting** — We set this aside because the source-record unit used by `total_records` was not confirmed.
> - **RAV-RUN1-R1-F012 [medium] failure-reporting** — We set this aside because publication failure behavior was not reproduced.
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #220 (`feat/sayf-eval-converter`, 7 files, +928/-1)
> - Run ordinal: 1
> - Rounds: 1/1 completed; adaptive off; material findings remain
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive positive review language
> - Earlier review comments: none
> - Finding counts: 0 critical, 3 high, 1 medium, 1 low, 0 nit
> - Checks: concerns=8; confirmed=0/ruled-out=0/set-aside=8/lowered=0
> - Second check: targeted; reviewers=2; kept=3/clarified=1/set-aside=0/removed=0; approval changed no
> - Set aside: 8 items; reason=verification could not access the exact PR head
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3725747245

`every_eval_ever/converters/sayf_eval/adapter.py` line 164 — https://github.com/evaleval/every_eval_ever/pull/220#discussion_r3725747245

**Before**

> **RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt
>
> `LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.
>
> The sound aggregate conversion can remain intact if `llm_scoring` is emitted only when the real template is available.

**After**

> **RAV-RUN1-R1-F007 [medium] judge-metadata** — `input_prompt` receives a scoring description instead of the judge prompt
>
> `LlmScoring.input_prompt` represents the actual prompt template. The fallback also invents prompt text when the record has none.
>
> Please emit `llm_scoring` only when the real template is available.
> The sound aggregate conversion can remain intact if `llm_scoring` is emitted only when the real template is available.

#### Comment 3725747241 — exact-source fallback

`every_eval_ever/converters/sayf_eval/adapter.py` line 184 — https://github.com/evaleval/every_eval_ever/pull/220#discussion_r3725747241

**Before**

> **RAV-RUN1-R1-F001 [high] source-provenance** — The adapter puts the task slug in `source_data.dataset_name`
>
> The source record already supplies the dataset name, but this line replaces it with a routing slug. Published records then identify task collections instead of datasets such as `CTI-Bench MCQ`.
>
> The upstream name can stay in `source_data`; an explicit sayf-eval collection override can handle routing.

**After**

> **RAV-RUN1-R1-F001 [high] source-provenance** — The adapter puts the task slug in `source_data.dataset_name`
>
> The source record already supplies the dataset name, but this line replaces it with a routing slug. Published records then identify task collections instead of datasets such as `CTI-Bench MCQ`.
>
> The upstream name can stay in `source_data`; an explicit sayf-eval collection override can handle routing.

#### Comment 3725747243

`every_eval_ever/converters/sayf_eval/adapter.py` line 364 — https://github.com/evaleval/every_eval_ever/pull/220#discussion_r3725747243

**Before**

> **RAV-RUN1-R1-F003 [high] record-identity** — `evaluation_id` changes every time the same record is converted
>
> The current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.
>
> A stable source-run timestamp or deterministic token can keep the required ID shape while `retrieved_timestamp` records retrieval time.

**After**

> **RAV-RUN1-R1-F003 [high] record-identity** — `evaluation_id` changes every time the same record is converted
>
> The current clock supplies this ID segment. An unchanged source run therefore becomes a new logical evaluation on each conversion.
>
> Please use a stable source-run timestamp or deterministic token to keep the required ID shape. `retrieved_timestamp` can continue to record retrieval time.

#### Comment 3725747244

`every_eval_ever/converters/sayf_eval/adapter.py` line 422 — https://github.com/evaleval/every_eval_ever/pull/220#discussion_r3725747244

**Before**

> **RAV-RUN1-R1-F005 [high] partial-conversion** — One invalid task discards valid sibling task logs
>
> This loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.
>
> A task-level error boundary can preserve valid logs and account for each rejected task.

**After**

> **RAV-RUN1-R1-F005 [high] partial-conversion** — One invalid task discards valid sibling task logs
>
> This loop builds logs locally, but any later exception exits the whole file conversion. The directory path then records one file failure and loses logs that were already valid.
>
> Please add a task-level error boundary that preserves valid logs and accounts for each rejected task.

## PR #223 — review 4870878941

Original review: https://github.com/evaleval/every_eval_ever/pull/223#pullrequestreview-4870878941

### Before — top-level review

> <!-- review-anvil-marker: a2d01ed2-56bf-401d-a98e-7b7b70224e6c -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — Approval is disabled; two non-blocking path-validation gaps remain.
> **Result:** The publisher-helper reuse is sound, with two focused edge cases worth covering.
> **Scope:** This PR warns when model identity and datastore directory components address different models.
> **Checks:** 1 concern checked; 1 confirmed as a merge-order dependency and removed from actionable findings.
> **Second check:** targeted, 2 reviewers; both could not reach the exact PR head, so the normal synthesis remains.
>
> ## Earlier review comments
>
> No earlier review comments were present.
>
> ## What I noticed
>
> - **RAV-RUN1-R1-F001 [medium] schema-deferral** `every_eval_ever/validator/validation_core.py:620-621` — Blank model IDs return before the publisher helper runs. The schema accepts blank strings, so these records can pass without a warning even though their identity names no datastore directory. (inline)
> - **RAV-RUN1-R1-F003 [medium] path-check-ownership** `every_eval_ever/validator/validation_core.py:613-615` — The check defers only wrong path depth. A five-component path with a nonportable developer or model component can receive both the path error and an identity-drift warning for the same malformed component. (inline)
>
> ## Changes made / Things to try
>
> - **[medium] schema-deferral** — Missing or non-string IDs can stay with schema validation, while blank strings can reach the publisher helper and produce its focused warning. (`RAV-RUN1-R1-P001`; covers `RAV-RUN1-R1-F001`)
> - **[medium] path-check-ownership** — Identity comparison can stop whenever `check_path_structure` already reports a path error. (`RAV-RUN1-R1-P002`; covers `RAV-RUN1-R1-F003`)
>
> ## Set aside / Outside this change
>
> - **RAV-RUN1-R1-F002 [medium] contributor-guidance** — PR #221 must merge before or with this PR for valid-record warnings to appear in default rich output. JSON and GitHub formats already show them.
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #223 (`validator-identity-path-drift`, 3 files, +184/-0)
> - Run ordinal: 1
> - Rounds: 1/1 completed; adaptive off; material findings remain
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive positive review language
> - Earlier review comments: none
> - Finding counts: 0 critical, 0 high, 2 medium, 0 low, 0 nit
> - Checks: concerns=1; confirmed merge dependency=1; actionable=0
> - Second check: targeted; reviewers=2; both failed exact-head access; normal synthesis retained; approval changed no
> - Set aside: 1 item; reason=explicit merge-order dependency on PR #221
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3725827216

`every_eval_ever/validator/validation_core.py` line 615 — https://github.com/evaleval/every_eval_ever/pull/223#discussion_r3725827216

**Before**

> **RAV-RUN1-R1-F003 [medium] path-check-ownership** — Other malformed paths can receive both a path error and an identity warning
>
> This guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.
>
> Identity comparison can stop whenever `check_path_structure` already owns a path error.

**After**

> **RAV-RUN1-R1-F003 [medium] path-check-ownership** — Other malformed paths can receive both a path error and an identity warning
>
> This guard checks only path depth. A five-component path with a nonportable developer or model component continues into the identity comparison, so both checks report the same bad path.
>
> Please stop identity comparison whenever `check_path_structure` already owns a path error.

#### Comment 3725827214

`every_eval_ever/validator/validation_core.py` line 621 — https://github.com/evaleval/every_eval_ever/pull/223#discussion_r3725827214

**Before**

> **RAV-RUN1-R1-F001 [medium] schema-deferral** — Blank model IDs bypass the new identity-path check
>
> The schema accepts blank strings, but this guard returns before `datastore_path_components` can reject them. Such a record can pass without any warning that its identity names no directory.
>
> Missing or non-string IDs can stay with schema validation, while blank strings can use the helper's focused error path.

**After**

> **RAV-RUN1-R1-F001 [medium] schema-deferral** — Blank model IDs bypass the new identity-path check
>
> The schema accepts blank strings, but this guard returns before `datastore_path_components` can reject them. Such a record can pass without any warning that its identity names no directory.
>
> Please route blank strings through `datastore_path_components` so they use the helper's focused error path; missing or non-string IDs can stay with schema validation.

## PR #223 — review 4884614217

Original review: https://github.com/evaleval/every_eval_ever/pull/223#pullrequestreview-4884614217

### Before — top-level review

> <!-- review-anvil-marker: 67555adf-7876-45ea-926b-9ff2e370e612 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — The earlier ownership gaps are fixed, and one focused schema-deferral suggestion remains.
> **Result:** One medium-priority suggestion remains. No high-priority problems were confirmed.
> **Scope:** Add a warning-level validator check for model identity and datastore path disagreement while preserving existing check ownership.
> **Checks:** skipped; two independent reviewers found the same concern.
> **Second check:** targeted review was unavailable because both reviewers lost network access. The confirmed normal-review result remains.
>
> ## Earlier review comments
>
> - `RAV-RUN1-R1-F001` is fixed. Blank IDs now reach the publisher helper and produce the intended warning.
> - `RAV-RUN1-R1-F003` is fixed. The full path-structure result now gates this check.
> - `RAV-RUN1-R1-F002` remains deliberately set aside. PR #221 is still the planned rich-output integration change.
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN2-R1-F001 | medium | schema deferral | `every_eval_ever/validator/validation_core.py:621` | A flat string model ID with a non-string developer produces both a schema error and an identity-path warning. Semantic checks receive the raw dictionary and pass that developer value to the publisher helper. |
>
> ## Things to try
>
> - **[medium] schema deferral** — For a flat ID, the identity check can defer when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe string values can keep the existing warning path. A schema-error-only test would cover the boundary. (`RAV-RUN2-R1-P001`; covers `RAV-RUN2-R1-F001`)
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #223 at `f24bb0778539dd0b65db9a543db27f19d85d0dec` (3 files, +190/-0)
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off; material finding
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 5 ledger entries grouped into 3 topics; 2 fixed and 1 deliberately set aside
> - Finding counts: 0 critical, 0 high, 1 medium, 0 low, 0 nit
> - Checks: skipped because two reviewers agreed on the material finding
> - Second check: targeted; reviewers=2; both failed before verdict because network access was unavailable; approval unchanged
> - Set aside: 1 prior integration item remains deliberately deferred to PR #221
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3737181823

`every_eval_ever/validator/validation_core.py` line 631 — https://github.com/evaleval/every_eval_ever/pull/223#discussion_r3737181823

**Before**

> **RAV-RUN2-R1-F001 [medium] schema-deferral** — A schema-invalid developer also produces an identity-path warning
>
> Semantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.
>
> For flat IDs, the check can defer when the developer is present but is neither a string nor `None`. Schema-valid blank, unknown, or unsafe strings can keep the current warning path.

**After**

> **RAV-RUN2-R1-F001 [medium] schema-deferral** — A schema-invalid developer also produces an identity-path warning
>
> Semantic checks still receive the raw dictionary after model validation fails. With a flat string ID and a non-string developer, this path passes the raw value to `datastore_path_components()`. The result is both the schema error and a warning about the same field.
>
> Please defer the check for flat IDs when the developer is present but is neither a string nor `None`.
> Schema-valid blank, unknown, or unsafe strings can keep the current warning path.

## PR #226 — review 4884776714

Original review: https://github.com/evaleval/every_eval_ever/pull/226#pullrequestreview-4884776714

### Before — top-level review

> <!-- review-anvil-marker: 9eeb0492-20b8-4d41-bde3-78cfb3207103 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — Directory traversal errors are now handled, and one focused symlink edge remains.
> **Result:** One medium-priority suggestion remains. An earlier low-priority help-text suggestion is also still present.
> **Scope:** Accept validator directory arguments while pruning dot-directories, avoiding symlink traversal, preserving structured output, and failing incomplete scans.
> **Checks:** 1 concern checked and confirmed.
> **Second check:** 2 reviewers kept the symlink finding, clarified its fix path, and removed one low-priority output concern.
>
> ## Earlier review comments
>
> - `RAV-RUN1-R1-F001` is fixed. `os.walk` now raises traversal errors through its `onerror` callback, and a focused test covers this path.
> - `RAV-RUN1-R1-F002` was reported earlier and is still present. The installed top-level help still says directory arguments are unsupported.
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN2-R1-F001 | medium | filesystem traversal | `every_eval_ever/validator/validate.py:175` | An explicitly supplied directory symlink is followed into its target. `followlinks=False` blocks discovered child symlinks, but it does not block a symlink used as the walk root. |
>
> <details>
> <summary>Non-blocking low-priority suggestion (1 item)</summary>
>
> - **RAV-RUN1-R1-F002 [low] CLI help** — The top-level `every_eval_ever validate` help still says directory arguments are unsupported. The existing help text can describe recursive directory expansion.
>
> </details>
>
> ## Things to try
>
> - **[medium] filesystem traversal** — The path expansion can reject only symlinks whose targets are directories. This check can apply to direct and glob-expanded matches while keeping file-symlink behavior unchanged. Focused tests can cover direct and globbed directory symlinks plus an accepted file symlink. (`RAV-RUN2-R1-P001`; covers `RAV-RUN2-R1-F001`)
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #226 at `1e405097d79fbe2a960264f2814c534a1ddb35a9` (2 files, +192/-16)
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off; material finding
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: 5 ledger entries grouped into 2 topics; 1 fixed and 1 reported item still present
> - Finding counts: 0 critical, 0 high, 1 medium, 1 low, 0 nit
> - Checks: concerns=1; confirmed=1; set-aside=0
> - Second check: targeted; reviewers=2; kept=1; clarified=1 plan; removed=1 low concern; approval unchanged
> - Set aside: 0 items
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3737291965

`every_eval_ever/validator/validate.py` line 175 — https://github.com/evaleval/every_eval_ever/pull/226#discussion_r3737291965

**Before**

> **RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target
>
> `Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.
>
> The expansion can reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged. Tests for both directory-symlink inputs and an accepted file symlink would cover the boundary.

**After**

> **RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target
>
> `Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.
>
> **Requested actions**
>
> - Reject directory-target symlinks for direct and glob-expanded matches.
> - Add tests for both directory-symlink inputs and an accepted file symlink to cover the boundary.
>
> File-symlink behavior can remain unchanged.

## PR #227 — review 4870817417

Original review: https://github.com/evaleval/every_eval_ever/pull/227#pullrequestreview-4870817417

### Before — top-level review

> <!-- review-anvil-marker: f8e2dcf9-752e-4893-ae62-b1fd13b47f76 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — This run is comment-only and found two documentation contracts that need tighter wording.
> **Result:** The new guidance is useful. Two edge cases need clearer contracts, and one sentence can state its existing validation limit.
> **Scope:** This PR documents the directory roots used by publication and failure-report APIs.
> **Checks:** 2 concerns checked; 2 confirmed.
> **Second check:** 2 reviewers checked 3 findings and their plans; all 3 findings stayed, and 2 fix paths were clarified.
>
> ## Earlier review comments
>
> None.
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN1-R1-F001 | medium | API contract | `every_eval_ever/helpers/io.py:408` | The docstring calls `output_dir` a collection directory, but supported callers also pass report-identity paths such as `data/lm_eval_samples`. (inline) |
> | RAV-RUN1-R1-F002 | medium | report placement | `every_eval_ever/helpers/io.py:413` | The nearest ancestor named `data` controls placement. A nested `data` component can leave `adapter_reports` inside an outer datastore tree. (inline) |
>
> <details>
> <summary>Non-blocking low-priority finding</summary>
>
> - **RAV-RUN1-R1-F003 [low] documentation** — The `EvaluationLogOutput` docstring says any wrong depth except exact `data` is accepted. The leaf still must pass collection-name validation.
>
> </details>
>
> ## Things to try
>
> - **[medium] API contract** — The parameter can be described as a path below the nearest `data` root. Its relative components form the report name; `data/<collection>` is the usual adapter case. (`RAV-RUN1-R1-P001`; covers `RAV-RUN1-R1-F001`)
> - **[medium] report placement** — The docs can state that the nearest `data` ancestor wins. A repeated-`data` example makes the placement limit concrete. (`RAV-RUN1-R1-P002`; covers `RAV-RUN1-R1-F002`)
> - **[low] documentation** — The depth statement can say that parent depth is unchecked when the final component is a valid collection name. (`RAV-RUN1-R1-P003`; covers `RAV-RUN1-R1-F003`)
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #227 (`docs-output-dir-conventions`, 2 files, +35/-3)
> - Run ordinal: 1
> - Rounds: 1/1 completed; adaptive off; material findings
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast-radius, and constructive optional suggestions
> - Earlier review comments: none
> - Finding counts: 0 critical, 0 high, 2 medium, 1 low, 0 nit
> - Checks: concerns=2; confirmed=2; ruled-out=0; set-aside=0; lowered=0
> - Second check: targeted; reviewers=2; kept=3; clarified=2; set-aside=0; removed=0; approval changed=no
> - Set aside: 0 items
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3725776266

`every_eval_ever/helpers/io.py` line 408 — https://github.com/evaleval/every_eval_ever/pull/227#discussion_r3725776266

**Before**

> **RAV-RUN1-R1-F001 [medium] api-contract** — `output_dir` also supports report-identity paths below `data`
>
> The CLI passes paths such as `data/lm_eval_samples`, and the tests require `adapter_reports/lm_eval_samples_failures.json`. Calling the argument only a collection directory narrows a supported contract.
>
> The wording can describe a path below the nearest `data` root. Its relative components form the report name, while `data/<collection>` remains the usual adapter case.

**After**

> **RAV-RUN1-R1-F001 [medium] api-contract** — `output_dir` also supports report-identity paths below `data`
>
> The CLI passes paths such as `data/lm_eval_samples`, and the tests require `adapter_reports/lm_eval_samples_failures.json`. Calling the argument only a collection directory narrows a supported contract.
>
> Please describe `output_dir` as a path below the nearest `data` root so its relative components form the report name; `data/<collection>` remains the usual adapter case.

#### Comment 3725776269

`every_eval_ever/helpers/io.py` line 413 — https://github.com/evaleval/every_eval_ever/pull/227#discussion_r3725776269

**Before**

> **RAV-RUN1-R1-F002 [medium] report-placement** — A nested `data` component can keep the report inside an outer datastore tree
>
> The helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.
>
> A note that the nearest `data` ancestor wins, plus this repeated-`data` example, would make the placement limit clear.

**After**

> **RAV-RUN1-R1-F002 [medium] report-placement** — A nested `data` component can keep the report inside an outer datastore tree
>
> The helper selects the nearest ancestor named `data`. For `data/outer/data/collection`, it writes below `data/outer/adapter_reports`, which conflicts with the stated outside-tree guarantee.
>
> **Requested actions**
>
> - Add a note that the nearest `data` ancestor wins.
> - Add the repeated-`data` example to make the placement limit clear.

## PR #227 — review 4884439849

Original review: https://github.com/evaleval/every_eval_ever/pull/227#pullrequestreview-4884439849

### Before — top-level review

> <!-- review-anvil-marker: 9659580b-3f62-4f15-b6b5-765a6d035881 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — This run is comment-only; one new medium suggestion and three earlier notes remain.
> **Result:** The new path guard is a helpful step. One collection-directory case can still pass when its name differs from the selected collection.
> **Scope:** Clarify output-directory contracts and reject collection directories passed as the publisher root.
> **Checks:** Skipped because the new finding had three-reviewer consensus. All earlier items were revalidated.
> **Second check:** Targeted, 2 reviewers; 4 findings kept and 1 fix path clarified.
>
> ## Earlier review comments
>
> - **RAV-RUN1-R1-F001 [medium] API contract** — Still present. Active callers pass report-identity paths below `data`, although the docstring calls every input a collection directory.
> - **RAV-RUN1-R1-F002 [medium] report placement** — Still present. The nearest `data` ancestor controls placement, so nested `data` paths can keep `adapter_reports` inside an outer datastore tree.
> - **RAV-RUN1-R1-F003 [low] documentation** — Still present. Parent depth is unchecked only when the collection leaf also passes validation.
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN2-R1-F001 | medium | publisher validation | `every_eval_ever/converters/common/publication.py:61` | The new guard accepts `data/foo` when the selected collection is `bar`, then publishes one level too deep. |
>
> ID legend: `RUN` is the observed PR review run, `R` is the origin round, and `F` is a finding.
>
> ## Things to try
>
> - **[medium] publisher validation** — A small follow-up could reject every `base_output_dir` that is an immediate child of canonical `data`. Mismatched source and `collection_override` tests would cover the open path. (`RAV-RUN2-R1-P001`; covers `RAV-RUN2-R1-F001`)
> - **[medium] documentation** — The failure-report docstring could describe paths below the nearest `data` root and how relative components form the report name.
> - **[medium] documentation** — The placement text could name the nearest-ancestor rule and its nested-`data` limit.
> - **[low] documentation** — The depth note could say that the final collection component must still be valid.
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #227 at `854e27fd6bbf357595ca5f2855b7f232d84911ab` (3 files, +71/-3)
> - Run ordinal: 2
> - Rounds: 1/1 completed; adaptive off
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast radius, and constructive suggestions
> - Earlier review comments: 3 root findings; 3 still present
> - Finding counts: 0 critical, 0 high, 3 medium, 1 low
> - Checks: skipped; the new concern had three-reviewer consensus
> - Second check: targeted; reviewers=2; kept=4; clarified=1; set-aside=0; removed=0
> - Fixes applied: 0 (review-only)
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3737042592

`every_eval_ever/converters/common/publication.py` line 61 — https://github.com/evaleval/every_eval_ever/pull/227#discussion_r3737042592

**Before**

> **RAV-RUN2-R1-F001 [medium] publisher-validation** — The new guard accepts a collection directory when its name differs from the selected collection.
>
> For `base_output_dir=data/foo` and a selected collection of `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.
>
> A small follow-up could reject every publisher base that is an immediate child of canonical `data`. Mismatched source and `collection_override` tests would cover this path.

**After**

> **RAV-RUN2-R1-F001 [medium] publisher-validation** — The new guard accepts a collection directory when its name differs from the selected collection
>
> For `base_output_dir=data/foo` and a selected collection of `bar`, the name check is false. Publication then writes `data/foo/bar/<developer>/<model>`, which is still one level too deep.
>
> **Requested actions**
>
> - Reject every publisher base that is an immediate child of canonical `data`.
> - Add mismatched-source and `collection_override` tests covering this path.

## PR #230 — review 4870883842

Original review: https://github.com/evaleval/every_eval_ever/pull/230#pullrequestreview-4870883842

### Before — top-level review

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

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3725830949

`every_eval_ever/validator/validation_core.py` line 792 — https://github.com/evaleval/every_eval_ever/pull/230#discussion_r3725830949

**Before**

> **RAV-RUN1-R1-F003 [medium] warning-visibility** — The new warning stays hidden in the default rich output without PR #221
>
> Warning severity leaves the report valid. The current rich renderer prints `PASS` and returns before its warning loop.
>
> PR #221 is already listed as a prerequisite. After rebase, one default-rich CLI check for this warning would confirm the complete path.

**After**

> **RAV-RUN1-R1-F003 [medium] warning-visibility** — The new warning stays hidden in the default rich output without PR #221
>
> Warning severity leaves the report valid. The current rich renderer prints `PASS` and returns before its warning loop.
>
> PR #221 is already listed as a prerequisite. Please run one default-rich CLI check for this warning after rebasing to confirm the complete path.

#### Comment 3725830951

`every_eval_ever/validator/validation_core.py` line 795 — https://github.com/evaleval/every_eval_ever/pull/230#discussion_r3725830951

**Before**

> **RAV-RUN1-R1-F004 [medium] contributor-guidance** — The new registered warning is missing from the required datastore gate guide
>
> The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.
>
> A short section can state the alias trigger, warning-only result, and single-record evidence limit.

**After**

> **RAV-RUN1-R1-F004 [medium] contributor-guidance** — The new registered warning is missing from the required datastore gate guide
>
> The repository instructions require contributor guidance with validator changes and name `.claude/skills/eee-dataset-conversion/reference/datastore-gate.md` as the rule location. This PR adds the check but does not update that guide.
>
> Please add a short section stating the alias trigger, warning-only result, and single-record evidence limit.

## PR #235 — review 4884964333

Original review: https://github.com/evaleval/every_eval_ever/pull/235#pullrequestreview-4884964333

### Before — top-level review

> <!-- review-anvil-marker: 2f49a4cb-8890-4e2a-86fa-16222766dae3 -->
> # ⚒️ review-anvil report
>
> **Review decision:** COMMENT — This run is comment-only; two high-priority and six medium suggestions remain.
> **Result:** The draft covers several tricky lighteval shapes well. Stable identity and complete source accounting need attention before publication.
> **Scope:** Add a dependency-free lighteval aggregate converter with CLI, docs, fixture, and offline tests.
> **Checks:** 3 single-reviewer concerns checked; 1 confirmed and 2 narrowed.
> **Second check:** Targeted, 2 reviewers; all findings kept, with deployment, count, credential, and test guidance clarified.
>
> ## Earlier review comments
>
> No earlier review comments were found.
>
> ## What I noticed
>
> | ID | Priority | Topic | Code location | What I noticed |
> |---|---|---|---|---|
> | RAV-RUN1-R1-F001 | high | evaluation identity | `every_eval_ever/converters/lighteval/adapter.py:375` | `evaluation_id` includes retrieval time, so identical input gets a new identity on every conversion. |
> | RAV-RUN1-R1-F002 | high | source accounting | `every_eval_ever/converters/lighteval/adapter.py:524` | A directory whose measured tasks all lack finite scores can exit successfully with zero records and no failure ledger. |
> | RAV-RUN1-R1-F004 | medium | score coverage | `every_eval_ever/converters/lighteval/adapter.py:185` | Capped runs expose original dataset size, but do not clearly preserve the smaller population that produced the score. |
> | RAV-RUN1-R1-F005 | medium | metric semantics | `every_eval_ever/converters/lighteval/adapter.py:287` | An undeclared result key is published with an assumed higher-is-better direction and no verified scale. |
> | RAV-RUN1-R1-F006 | medium | metric identity | `every_eval_ever/converters/lighteval/adapter.py:297` | Every metric omits `metric_id`, including global metrics such as accuracy. |
> | RAV-RUN1-R1-F007 | medium | coverage totals | `every_eval_ever/converters/lighteval/adapter.py:538` | `total_records` combines task-level output logs with file-level failures. |
> | RAV-RUN1-R1-F008 | medium | failure reporting | `every_eval_ever/cli.py:234` | Single-file parse or conversion failures exit before a structured failure report is saved. |
> | RAV-RUN1-R1-F009 | medium | credential filtering | `every_eval_ever/converters/lighteval/utils.py:185` | Supported nested model configuration such as `env_vars` is serialized without recursive secret filtering. |
>
> ID legend: `RUN` is the observed PR review run, `R` is the origin round, and `F` is a finding.
>
> <details>
> <summary>Non-blocking low-priority suggestions (2 items)</summary>
>
> - **RAV-RUN1-R1-F003 [low] deployment metadata** — Supported logs normally publish `deployment_type` and `model_availability` as `unknown`, with no CLI override for known facts.
> - **RAV-RUN1-R1-F010 [low] test coverage** — The thorough synthetic fixture is useful. An end-to-end publication assertion would also prove strict output parsing through the real CLI.
>
> </details>
>
> <details>
> <summary>Things to try (10 items)</summary>
>
> - **[high] evaluation identity** — Stable raw model identity, task, source timestamp, and a non-secret run-config digest can form an idempotent ID. (`RAV-RUN1-R1-P001`; covers `RAV-RUN1-R1-F001`)
> - **[high] source accounting** — A file with measured but unconvertible tasks can become a failure; a file containing only intentional derived rows can remain an exclusion. (`RAV-RUN1-R1-P002`; covers `RAV-RUN1-R1-F002`)
> - **[low] deployment metadata** — Validated CLI overrides could follow the existing platform and engine override pattern. (`RAV-RUN1-R1-P003`; covers `RAV-RUN1-R1-F003`)
> - **[medium] score coverage** — Both original and effective document counts can stay visible, with the evaluated count identified as the score population. (`RAV-RUN1-R1-P004`; covers `RAV-RUN1-R1-F004`)
> - **[medium] metric semantics** — Source metric specs or an operator definition can supply direction and scale. Unresolved keys can enter the failure ledger after valid metrics are preserved. (`RAV-RUN1-R1-P005`; covers `RAV-RUN1-R1-F005`)
> - **[medium] metric identity** — One metric-definition resolver can provide ID, direction, type, and bounds without duplicate maps. (`RAV-RUN1-R1-P006`; covers `RAV-RUN1-R1-F006`)
> - **[medium] coverage totals** — Results files can remain the source-record grain, with output-log count reported separately. (`RAV-RUN1-R1-P007`; covers `RAV-RUN1-R1-F007`)
> - **[medium] failure reporting** — A small lighteval-local single-file result path can reuse directory reporting behavior before raising. (`RAV-RUN1-R1-P008`; covers `RAV-RUN1-R1-F008`)
> - **[medium] credential filtering** — One recursive sanitizer can protect nested mappings and lists before model configuration is serialized. (`RAV-RUN1-R1-P009`; covers `RAV-RUN1-R1-F009`)
> - **[low] test coverage** — The existing fixture can drive one CLI publication test that strictly parses and validates each emitted file. (`RAV-RUN1-R1-P010`; covers `RAV-RUN1-R1-F010`)
>
> </details>
>
> <details>
> <summary>Run details</summary>
>
> - Target: PR #235 at `75a03c269eb60dbaf5247ec4a36dc79af18dcbdf` (11 files, +1663/-4)
> - Run ordinal: 1
> - Rounds: 1/1 completed; adaptive off
> - Mix: 3 codex-exec
> - Focus: correctness, maintainability, simplicity, production blast radius, converter content checks, and constructive suggestions
> - Earlier review comments: none
> - Finding counts: 0 critical, 2 high, 6 medium, 2 low, 0 nit
> - Checks: concerns=3; confirmed=1; narrowed=2; set-aside=0; removed=0
> - Second check: targeted; reviewers=2; kept=10; clarified=4; set-aside=0; removed=0
> - Fixes applied: 0 (review-only)
>
> </details>
>
> ---
> _Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

### After — top-level review

> **Unavailable — not generated by the inline-comment benchmark.** The original top-level review is shown only as context.

### Inline comments

#### Comment 3737449098

`every_eval_ever/cli.py` line 234 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449098

**Before**

> **RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`. Parse or conversion errors exit non-zero, but the structured failure report is never saved; directory input reports the same failure class correctly.
>
> A small lighteval-local file-result path can give both entry modes the same report-before-raise behavior.

**After**

> **RAV-RUN1-R1-F008 [medium] failure-reporting** — The single-file branch calls `transform_from_file` before it creates a `SourceConversionResult`
>
> Parse or conversion errors exit non-zero, but the structured failure report is never saved; directory input reports the same failure class correctly.
>
> Please add a small lighteval-local file-result path to give both entry modes the same report-before-raise behavior.

#### Comment 3737449059

`every_eval_ever/converters/lighteval/adapter.py` line 201 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449059

**Before**

> **RAV-RUN1-R1-F004 [medium] score-coverage** — Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`. The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.
>
> Both counts can remain visible, with the effective count identified as score coverage and the original count retained as dataset provenance.

**After**

> **RAV-RUN1-R1-F004 [medium] score-coverage** — Capped or deduplicated runs put `original_num_docs` in `samples_number`, while uncertainty uses `effective_num_docs`
>
> The dataset size is valid source context, but the record does not clearly preserve the smaller population that produced the score.
>
> Please keep both counts visible, with the effective count identified as score coverage and the original count retained as dataset provenance.

#### Comment 3737449070

`every_eval_ever/converters/lighteval/adapter.py` line 287 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449070

**Before**

> **RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds. A finite custom key does not prove that direction.
>
> Source metric specs or an operator-supplied definition can establish the semantics. Unresolved keys can be reported after the valid metrics are preserved.

**After**

> **RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds
>
> A finite custom key does not prove that direction.
>
> **Requested actions**
>
> - Use source metric specs or an operator-supplied definition to establish semantics for result keys without matching metric specs.
> - Preserve valid metrics.
>
> After valid metrics are preserved, unresolved keys can be reported.

#### Comment 3737449081

`every_eval_ever/converters/lighteval/adapter.py` line 337 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449081

**Before**

> **RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy. `metric_name` keeps the source label but does not provide the cross-source join key.
>
> The same metric-definition mapping used for direction and bounds can supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.

**After**

> **RAV-RUN1-R1-F006 [medium] metric-identity** — Both `MetricConfig` branches omit `metric_id`, including common metrics such as accuracy
>
> `metric_name` keeps the source label but does not provide the cross-source join key.
>
> Please use the same metric-definition mapping used for direction and bounds to supply canonical global IDs and stable namespaced IDs for defined lighteval-specific metrics.

#### Comment 3737449039

`every_eval_ever/converters/lighteval/adapter.py` line 375 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449039

**Before**

> **RAV-RUN1-R1-F001 [high] evaluation-identity** — `evaluation_id` includes the current retrieval time. The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.
>
> A stable ID can use the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration. Retrieval time can remain only in `retrieved_timestamp`.

**After**

> **RAV-RUN1-R1-F001 [high] evaluation-identity** — `evaluation_id` includes the current retrieval time
>
> The same source file therefore gets a different logical identity on every conversion, which allows duplicate evaluations on re-ingest.
>
> Please build a stable ID from the raw model identity, task key, source timestamp, and a deterministic digest of non-secret run configuration.
> Retrieval time can remain only in `retrieved_timestamp`.

#### Comment 3737449052

`every_eval_ever/converters/lighteval/adapter.py` line 524 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449052

**Before**

> **RAV-RUN1-R1-F002 [high] source-accounting** — An input file whose measured tasks all lack finite scores returns an empty list without a failure. A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.
>
> A file with measured but unconvertible tasks can enter the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.

**After**

> **RAV-RUN1-R1-F002 [high] source-accounting** — An input file whose measured tasks all lack finite scores returns an empty list without a failure
>
> A directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.
>
> Please put a file with measured but unconvertible tasks in the failure ledger.
> Files containing only intentionally skipped derived rows can stay explicit exclusions.

#### Comment 3737449090

`every_eval_ever/converters/lighteval/adapter.py` line 538 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449090

**Before**

> **RAV-RUN1-R1-F007 [medium] coverage-totals** — `total_records` adds task-level output logs to file-level failures. One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.
>
> Results files can remain the source-record grain, with converted output-log count reported separately.

**After**

> **RAV-RUN1-R1-F007 [medium] coverage-totals** — `total_records` adds task-level output logs to file-level failures
>
> One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.
>
> Please keep results files as the source-record grain and report the converted output-log count separately.

#### Comment 3737449101

`every_eval_ever/converters/lighteval/utils.py` line 284 — https://github.com/evaleval/every_eval_ever/pull/235#discussion_r3737449101

**Before**

> **RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized. Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.
>
> One recursive sanitizer for mappings and lists can protect these values before serialization. Tests with provider-prefixed key names would cover the reachable path without recording secret values.

**After**

> **RAV-RUN1-R1-F009 [medium] credential-filtering** — Secret filtering checks only top-level model-config keys before nested values are serialized
>
> Supported v0.13 configurations can carry unrestricted `env_vars`, so a nested token or API key can reach published `additional_details`.
>
> **Requested actions**
>
> - Use one recursive sanitizer for mappings and lists to protect these values before serialization.
> - Add tests with provider-prefixed key names covering the reachable path without recording secret values.
