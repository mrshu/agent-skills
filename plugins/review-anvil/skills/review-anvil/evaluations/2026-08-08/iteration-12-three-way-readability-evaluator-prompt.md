Blindly compare three randomized versions of each GitHub inline code-review comment. Labels A, B, and C do not identify chronology, model, or the original. Do not infer which is newer. A separate evaluator checks technical facts.

Judge human readability only. A busy pull-request author should understand after one read:

1. the failure and its trigger;
2. the concrete consequence;
3. the exact requested outcome, including every action or preserved boundary.

Prefer direct, calm, natural language; short sentences; necessary technical terms; and scan-friendly structure. Do not reward brevity that drops information. Do not penalize identifiers or code terms whose role is clear. Do not reward headings or bullets unless they reduce cognitive load.

For every ID, rank all three versions from best to worst and give one concise reason tied to wording or structure. Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "ranking": ["A", "B", "C"],
      "winner": "A",
      "reason": "one sentence"
    }
  ],
  "winner_counts": {"A": 0, "B": 0, "C": 0},
  "overall_ranking": ["A", "B", "C"],
  "recommended_version": "A",
  "summary": "two or three sentences"
}

Include every input ID exactly once. Do not emit Markdown fences, rewrites, fact-preservation judgments, or text outside the JSON.
