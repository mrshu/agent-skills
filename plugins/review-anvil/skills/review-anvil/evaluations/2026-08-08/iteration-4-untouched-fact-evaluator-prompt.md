Evaluate technical fact preservation in three rewritten code-review comments. Each row contains a review-only `source` and randomized candidates A, B, and C.

For every candidate, preserve every material source fact needed to trust or safely act on the finding: ID, severity, trigger, condition, actor-action-target relationship, technical verb, quantifier, diagnostic certainty, concrete result, valid-behavior boundary, necessary identifier, requested change, and test boundary. A `Please` request describes proposed remediation, not code already present. Mark `fact_loss` if a candidate presents a requested change as existing code, or if an omission or change can alter diagnosis, scope, severity, current behavior, or the safe requested change. Do not prefer style or brevity.

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
