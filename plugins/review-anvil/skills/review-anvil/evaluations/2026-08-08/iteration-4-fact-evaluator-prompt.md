Blindly evaluate technical fact preservation in two randomized rewrites of each code-review comment. Each row contains the original `source` plus candidates A and B. Every source comment came from a review-only run: proposed remediation was not implemented unless the source explicitly says otherwise.

For each candidate, preserve every material source fact needed to trust or safely act on the finding: ID, severity, trigger, condition, actor-action-target relationship, technical verb, quantifier, diagnostic certainty, concrete result, valid-behavior boundary, necessary identifier, requested change, and test boundary.

A candidate has `fact_loss` if it presents a requested change as code already present. Phrases such as “the fix uses” or “the corrected path returns” are fact loss in this review-only context unless the source explicitly describes an existing patch. Recasting source-backed remediation as an imperative request is fact-safe. Mark `fact_loss` only when an omission or change can alter diagnosis, scope, severity, current behavior, or the safe requested change. Do not prefer style or brevity.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "fact_status": {"A": "fact_safe|fact_loss", "B": "fact_safe|fact_loss"},
      "fact_losses": ["candidate label: exact material fact lost or changed"]
    }
  ],
  "fact_safe_counts": {"A": 0, "B": 0},
  "summary": "two or three sentences"
}

Include every input ID exactly once. Put one JSON field per line. Do not emit Markdown fences, rewrites, readability judgments, or text outside the JSON.
