Adjudicate disputed technical fact-safety judgments in code-review rewrites. Each row contains a review-only `source`, one `candidate`, and a disputed `claimed_judgment`.

Judge only whether the candidate preserves the source's material facts and requested behavior: diagnostic certainty, trigger, condition, actor-action-target relationship, technical verb, quantifier, concrete result, valid-behavior boundary, necessary identifier, requested change, and test boundary. The source describes current code followed by proposed remediation. A direct imperative sentence is a request to the PR author, not a claim that the change already exists. A declarative sentence such as “the fix uses” falsely claims implementation unless the source explicitly says that patch exists.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "verdict": "fact_safe|fact_loss",
      "reason": "one or two precise sentences"
    }
  ],
  "fact_safe_count": 0,
  "fact_loss_count": 0,
  "summary": "one or two sentences"
}

Include every input ID exactly once. Do not judge style or brevity. Do not emit Markdown fences, rewrites, or text outside the JSON.
