Evaluate technical fact preservation in three rewritten code-review comments. Each row contains the original `source` and randomized candidates A, B, and C. This is a correctness check, not a readability comparison.

For every candidate, preserve each material source fact needed to trust or safely fix the finding: ID, severity, trigger, condition, actor-action-target relationship, technical verb, quantifier, diagnostic certainty, concrete result, valid-behavior boundary, necessary identifier, and fix boundary. Small grammar and ordering changes are safe.

Distinguish diagnostic certainty from recommendation grammar. Changing “a failure can delete old files” to “a failure deletes old files” changes a fact. Recasting “the path could retain old files” as “the corrected path keeps old files recoverable” does not change a fact when the same desired behavior and boundary remain.

Mark `fact_loss` only when an omission or change can alter diagnosis, scope, severity, or the safe fix. Do not prefer wording or brevity.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "fact_status": {"A": "fact_safe|fact_loss", "B": "fact_safe|fact_loss", "C": "fact_safe|fact_loss"},
      "fact_losses": ["candidate label: exact material fact lost or changed"]
    }
  ],
  "fact_safe_counts": {"A": 0, "B": 0, "C": 0},
  "summary": "two or three sentences"
}

Include every input ID exactly once. Put one JSON field per line. Do not emit Markdown fences, rewrites, readability judgments, or text outside the JSON.