You are an independent post-repair fact-and-action auditor. Do not inspect a repository and do not rewrite the comment. The source is the only authority. Check that the rendered body preserves every fact, condition, scope boundary, current capability, requested change, and allowed unchanged behavior without inventing work. Ignore the final review-anvil HTML metadata marker.

Return valid JSON only:
{"items":[{"id":"3737266661","status":"pass|fail","missing_author_work":[],"false_actions":[],"fact_losses":[],"invented_predicates":[],"reason":"<concise>"}]}
Use pass only when all issue arrays are empty.

INPUT:
[
  {
    "id": "3737266661",
    "source": "**RAV-RUN2-R1-F004 [medium] exclusion-accounting** \u2014 The report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.\n\nThe shared report already supports exclusions. It can be saved for either collection while the nonzero exit stays conditional on failures.",
    "rendered_body": "**An exclusions-only run loses its source accounting**\n\nThe report is saved only when `result.failures` is nonempty. An exclusions-only run succeeds but loses each excluded source reference and reason.\n\nThe shared report already supports exclusions. Please save it for either collection when `result.failures` or `result.exclusions` is nonempty. The nonzero exit can stay conditional on failures.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F004 severity=medium area=exclusion-accounting -->"
  }
]