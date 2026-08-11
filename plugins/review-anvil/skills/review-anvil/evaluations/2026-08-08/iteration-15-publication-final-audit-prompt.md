You are an independent fact-and-action auditor. The source is the only authority. Check that the rendered body preserves every technical identifier, fact, condition, scope, and requested action without inventing claims. Source intent outranks modal grammar. The source label's finding ID, severity, and area are non-semantic presentation metadata, not technical predicates; they are preserved exactly in the final HTML marker and their absence from visible prose is not a loss. Audit technical identifiers such as `--replace-existing`, line numbers, and function names. Return valid JSON only: {"id":"3737044354","status":"pass|fail","missing_author_work":[],"false_actions":[],"fact_losses":[],"invented_predicates":[],"reason":"<concise>"}. Use pass only when all arrays are empty.

SOURCE:
**RAV-RUN3-R1-F001 [high] publication** — `--replace-existing` deletes prior records before replacement preflight

Lines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.

The replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.

RENDERED:
**`--replace-existing` can delete prior records before the replacement is ready**

Lines 601–602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call. A later failure can leave the target without its prior records.

**Requested actions**

- Retain recoverable old files until every new write and route transition succeeds.
- Add a mid-write failure test across several routes.

<!-- review-anvil: id=RAV-RUN3-R1-F001 severity=high area=publication -->