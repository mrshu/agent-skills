Compare two randomized wordings of each code-review finding. `source` is the technical reference, not a candidate.

For each candidate, first determine whether it preserves every material source fact needed to trust or safely fix the finding: trigger, condition, technical relationship, quantifier, certainty, result, valid-behavior boundary, and necessary identifier. Small grammar changes are allowed. Mark `fact_loss` only for an omission or change that can alter diagnosis, scope, severity, or the safe fix.

Distinguish diagnostic certainty from recommendation grammar. Changing a
diagnostic claim such as “a failure can leave old files” to “a failure leaves
old files” is a fact change. Recasting fix guidance such as “the path could
retain old files” as the neutral desired state “old files remain recoverable
until replacement succeeds” is not a fact change when the boundary is the same.

A fact-loss candidate cannot win. If both are fact-safe, choose the wording that is easiest for a busy pull-request author to understand and act on during the first read. Judge problem visibility, concrete consequence, required outcome, jargon load, sentence structure, tone, and scanability. Do not reward brevity that drops a material fact or length that repeats facts.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "fact_status": {"A": "fact_safe|fact_loss", "B": "fact_safe|fact_loss"},
      "readability_winner": "A|B|tie",
      "reason": "one sentence",
      "fact_losses": ["candidate label: exact material fact lost or changed"]
    }
  ],
  "fact_safe_counts": {"A": 0, "B": 0},
  "readability_counts": {"A": 0, "B": 0, "tie": 0},
  "dimension_winners": {
    "immediate_comprehension": "A|B|tie",
    "consequence_clarity": "A|B|tie",
    "actionability": "A|B|tie",
    "evidence_preservation": "A|B|tie",
    "jargon_load": "A|B|tie",
    "sentence_clarity": "A|B|tie",
    "tone": "A|B|tie",
    "scanability": "A|B|tie"
  },
  "overall_winner": "A|B|tie",
  "summary": "two or three sentences"
}

Include all IDs exactly once and put one JSON field per line. Do not include Markdown fences, rewrites, or text outside the JSON.