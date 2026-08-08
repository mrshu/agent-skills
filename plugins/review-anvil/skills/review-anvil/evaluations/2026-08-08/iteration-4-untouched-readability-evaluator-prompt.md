Blindly compare three randomized wordings of each code-review finding. Labels A, B, and C do not identify model or chronology. Every source comment came from a review-only run: the comment requests a change; it does not report code already fixed.

Rank all versions by how quickly a busy pull-request author can understand the problem, consequence, and requested change on the first read. Judge problem clarity, consequence clarity, requested-change clarity, actionability, calm respectful tone, cognitive ease, and scanability. Do not reward brevity by itself. Do not penalize necessary identifiers or technical terms when their role is clear.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "ranking": ["A", "B", "C"],
      "winner": "A|B|C",
      "reason": "one sentence about first-read comprehension"
    }
  ],
  "winner_counts": {"A": 0, "B": 0, "C": 0},
  "overall_ranking": ["A", "B", "C"],
  "recommended_version": "A|B|C",
  "summary": "two or three sentences"
}

Include every input ID exactly once. Put one JSON field per line. Do not emit Markdown fences, rewrites, fact-preservation judgments, or text outside the JSON.
