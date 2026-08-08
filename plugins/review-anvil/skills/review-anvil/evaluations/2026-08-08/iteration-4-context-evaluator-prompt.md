Evaluate the `selected_branch_comment` in each input row as an author-facing GitHub inline code-review comment.

Context: every row came from a review-only run. The reviewer applied no fix. The comment may request a change or offer remediation, but it must not imply that a proposed correction already exists in the PR. Compare against `original_inline_comment` only to detect lost, changed, or invented technical facts; do not reward either version for being original or rewritten.

For each comment, judge these dimensions independently:

- `problem_clarity`: how quickly the current defect and trigger are understood;
- `consequence_clarity`: how concrete and immediate the bad result is;
- `requested_change_clarity`: whether the author can tell what change, outcome, or decision is requested without mistaking it for current code;
- `actionability`: whether the author can act without guessing at the relevant code relationship;
- `tone`: respectful, code-focused, and proportionate;
- `cognitive_ease`: low jargon, short dependency chains, and little rereading;
- `technical_safety`: whether every identifier, relationship, condition, certainty, boundary, and useful guidance fact from the original remains intact, with no unsupported addition;
- `fix_presupposition`: whether wording such as “the fix” or an unmarked declarative desired state falsely implies that an unimplemented correction already exists.

Use integer scores from 1 (poor) to 5 (excellent). `technical_safety` is `fact_safe` or `fact_loss`. `fix_presupposition` is `none` or `implies_existing_fix`.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "problem_clarity": 1,
      "consequence_clarity": 1,
      "requested_change_clarity": 1,
      "actionability": 1,
      "tone": 1,
      "cognitive_ease": 1,
      "technical_safety": "fact_safe|fact_loss",
      "fix_presupposition": "none|implies_existing_fix",
      "note": "one concrete sentence"
    }
  ],
  "means": {
    "problem_clarity": 0.0,
    "consequence_clarity": 0.0,
    "requested_change_clarity": 0.0,
    "actionability": 0.0,
    "tone": 0.0,
    "cognitive_ease": 0.0
  },
  "fact_safe_count": 0,
  "fix_presupposition_count": 0,
  "summary": "two or three sentences"
}

Include every input ID exactly once. Do not rewrite comments. Do not emit Markdown fences or text outside the JSON.
