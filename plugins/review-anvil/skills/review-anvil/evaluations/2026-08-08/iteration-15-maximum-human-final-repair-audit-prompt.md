You are an independent post-repair fact-and-action auditor. Do not inspect a repository and do not rewrite comments. The source body is the only authority. For every row, check that the rendered body preserves every exact identifier, fact, condition, scope boundary, current capability, requested change, and allowed unchanged behavior. Reject invented fields, predicates, or work. Source can/could/would still describes required work when unchanged behavior leaves the stated defect unresolved. Ignore the final review-anvil HTML metadata marker.

Return valid JSON only:
{"items":[{"id":"<exact id>","status":"pass|fail","missing_author_work":[],"false_actions":[],"fact_losses":[],"invented_predicates":[],"reason":"<concise>"}]}
Return each ID exactly once. Use pass only when all issue arrays are empty. Do not emit Markdown fences or extra text.

INPUT:
[
  {
    "id": "3737266661",
    "source": "**RAV-RUN2-R1-F004 [medium] exclusion-accounting** \u2014 The report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.\n\nThe shared report already supports exclusions. It can be saved for either collection while the nonzero exit stays conditional on failures.",
    "rendered_body": "**An exclusions-only run loses its source accounting**\n\nThe report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.\n\nThe shared report already supports exclusions. Please save it whenever either collection has entries. The nonzero exit can stay conditional on failures.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F004 severity=medium area=exclusion-accounting -->"
  },
  {
    "id": "3737044354",
    "source": "**RAV-RUN3-R1-F001 [high] publication** \u2014 `--replace-existing` deletes prior records before replacement preflight\n\nLines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.\n\nThe replacement path could retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.",
    "rendered_body": "**`--replace-existing` can remove the only good copy before replacement is ready**\n\nLines 601\u2013602 remove the old files before `save_evaluation_logs()` validates and writes the new batch. Its rollback covers only files created by that call. A later failure can leave the target without its prior records.\n\n**Requested actions**\n\n- Retain recoverable old files until every new write and route transition succeeds.\n- Add a mid-write failure test across several routes.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F001 severity=high area=publication -->"
  },
  {
    "id": "3725853168",
    "source": "**RAV-RUN2-R1-F011 [medium] registry-identity** \u2014 Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.\n\nExact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.",
    "rendered_body": "**Normalized organization collisions can rewrite exact canonical IDs**\n\nPlease let exact canonical IDs win first. Normalized spellings can resolve only when one organization owns them.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity -->"
  },
  {
    "id": "3737383919",
    "source": "**RAV-RUN3-R1-F001 [medium] cli** \u2014 A bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.\n\nRequiring one or more values would block the first path. A no-match check can stop before existing-output discovery or publication.",
    "rendered_body": "**A bare `--models` starts the full source run**\n\nA bare `--models` parses as an empty list, which disables filtering and starts the full source run. A nonempty filter with no matches instead exits successfully with zero logs.\n\n**Requested actions**\n\n- Require one or more values for `--models`.\n- Stop a no-match run before existing-output discovery or publication.\n\n<!-- review-anvil: id=RAV-RUN3-R1-F001 severity=medium area=cli -->"
  }
]