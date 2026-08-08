You are selecting the clearest technically safe wording for code-review comments. Each input row has a `source` technical reference and four randomized candidate labels. The labels do not identify chronology or authorship.

Use `source` only as the fact boundary. A candidate can be clearer than the source, but it must preserve every trigger, condition, technical relationship, quantifier, certainty level, concrete result, valid-behavior boundary, and necessary identifier.

For each row:

1. Mark every candidate `fact_safe` or `fact_loss`.
2. Rank all candidates. Put every fact-safe candidate before any fact-loss candidate, then rank by clarity.
3. Choose one readability winner. A fact-loss candidate cannot win.
4. Give one concise reason focused on first-read comprehension and cognitive load.

Judge problem visibility, concrete consequence, required outcome, evidence, jargon load, sentence structure, tone, and scanability. Do not reward brevity that drops a fact. Do not reward length that repeats facts or narrates investigation.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "fact_status": {"A": "fact_safe|fact_loss", "B": "fact_safe|fact_loss", "C": "fact_safe|fact_loss", "D": "fact_safe|fact_loss"},
      "ranking": ["A", "B", "C", "D"],
      "winner": "A|B|C|D",
      "reason": "one sentence",
      "fact_losses": ["candidate label: exact lost or changed fact"]
    }
  ],
  "winner_counts": {"A": 0, "B": 0, "C": 0, "D": 0},
  "fact_safe_counts": {"A": 0, "B": 0, "C": 0, "D": 0},
  "overall_ranking": ["A", "B", "C", "D"],
  "dimension_winners": {
    "immediate_comprehension": "A|B|C|D",
    "consequence_clarity": "A|B|C|D",
    "actionability": "A|B|C|D",
    "evidence_preservation": "A|B|C|D",
    "jargon_load": "A|B|C|D",
    "sentence_clarity": "A|B|C|D",
    "tone": "A|B|C|D",
    "scanability": "A|B|C|D"
  },
  "recommended_version": "A|B|C|D",
  "summary": "two or three sentences"
}

Include all IDs exactly once. Put one JSON field per line. Do not emit Markdown fences, rewrites, or analysis outside the JSON.