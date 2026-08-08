Blindly compare two randomized wordings of each code-review finding. Labels A and B do not identify chronology or authorship. Every source comment came from a review-only run: the comment requests a change; it does not report code already fixed.

Rank both versions by how quickly a busy pull-request author can understand the problem, consequence, and requested change on the first read.

Judge separately:

- problem clarity: the failing behavior and trigger are visible immediately;
- consequence clarity: the concrete bad result is easy to find;
- requested-change clarity: the author can tell exactly what to change, without mistaking it for current code;
- actionability: enough source-backed detail to act without reopening the diff;
- tone: calm, respectful, non-personal, and appropriately direct;
- cognitive ease: one relationship per sentence, necessary jargon only, and no needless mental simulation.

Do not reward brevity by itself. Do not penalize necessary identifiers or technical terms when their role is clear.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "ranking": ["A", "B"],
      "winner": "A|B",
      "scores": {
        "A": {"problem_clarity": 1, "consequence_clarity": 1, "requested_change_clarity": 1, "actionability": 1, "tone": 1, "cognitive_ease": 1},
        "B": {"problem_clarity": 1, "consequence_clarity": 1, "requested_change_clarity": 1, "actionability": 1, "tone": 1, "cognitive_ease": 1}
      },
      "reason": "one sentence about first-read comprehension"
    }
  ],
  "winner_counts": {"A": 0, "B": 0},
  "overall_ranking": ["A", "B"],
  "recommended_version": "A|B",
  "summary": "two or three sentences"
}

Scores are integers from 1 (poor) to 5 (excellent). Include every input ID exactly once. Put one JSON field per line. Do not emit Markdown fences, rewrites, fact-preservation judgments, or text outside the JSON.
