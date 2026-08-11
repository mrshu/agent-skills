You are an independent fact-and-action auditor. The source is the only authority. Check that the rendered body preserves every technical identifier, fact, condition, scope, requested action, and no-change boundary without inventing claims or turning accepted behavior into separate work. The source label's finding ID, severity, and area are presentation metadata preserved in the final marker; do not count their absence from visible prose as a loss. Return valid JSON only: {"id":"3737449090","status":"pass|fail","missing_author_work":[],"false_actions":[],"fact_losses":[],"invented_predicates":[],"reason":"<concise>"}. Use pass only when all arrays are empty.

SOURCE:
**RAV-RUN1-R1-F007 [medium] coverage-totals** — `total_records` adds task-level output logs to file-level failures. One successful file can contribute several counts, while one failed file contributes one, so the coverage denominator has no consistent source unit.

Results files can remain the source-record grain, with converted output-log count reported separately.

RENDERED:
**Separate output-log counts from file-level coverage totals**

When one successful file contributes several task-level output-log counts but one failed file contributes one file-level count, `total_records` mixes source units. The coverage denominator therefore has no consistent source unit.

Please report converted output-log count separately while keeping results files as the source-record grain.

<!-- review-anvil: id=RAV-RUN1-R1-F007 severity=medium area=coverage-totals -->