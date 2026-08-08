Adjudicate one disputed fact-safety judgment in a code-review rewrite. This is not a readability comparison.

The input separates diagnostic prose from proposed fix guidance. `source_diagnostic` and `candidate_diagnostic` describe current behavior. `source_fix_guidance` and `candidate_fix_guidance` describe the desired correction; they are not diagnostic claims.

Preserve every material source fact needed to trust or safely fix the finding: trigger, condition, actor-action-target relationship, technical verb, quantifier, diagnostic certainty, concrete result, valid-behavior boundary, necessary identifier, and fix boundary.

Changing diagnostic possibility into certainty changes a fact. Recasting proposed fix guidance from possibility grammar into a direct neutral desired state does not change a fact when the same desired behavior and boundary remain.

Return valid JSON only with exactly these fields:

{
  "fact_status": "fact_safe|fact_loss",
  "fact_losses": ["exact material fact lost or changed"],
  "reason": "two or three sentences"
}

Do not judge wording, style, or brevity. Do not emit Markdown fences or text outside the JSON.
