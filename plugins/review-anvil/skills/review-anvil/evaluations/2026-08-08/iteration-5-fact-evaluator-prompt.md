Blindly evaluate technical fact and requested-obligation preservation in three randomized rewrites of each code-review comment. Each row contains the original `source` plus candidates A, B, and C. Every source came from a review-only run: proposed remediation was not implemented unless the source explicitly says otherwise.

For every candidate, preserve every material source fact needed to trust or safely act on the finding:

- complete ID, severity, and area;
- actor, action, target, operation order, trigger, condition, and scope;
- technical verbs, identifiers, numbers, quantifiers, and diagnostic certainty;
- concrete bad result and whether it is file-, directory-, row-, target-, or run-level;
- handled and unhandled error classes;
- valid behavior, preservation constraints, and exceptions;
- every requested implementation action;
- every source-backed test and its exact boundary.

A title may move the consequence ahead of the mechanism only when it preserves scope, diagnostic modality, ownership, and the shortest necessary trigger. Mark `fact_loss` if it invents an actor or destination, attributes an aggregate result to one file, strengthens `can` to certainty, drops `all`, `only`, or `every`, broadens an error class, converts a preservation constraint into a broader action, or weakens a precise test boundary to generic testing.

A candidate also has `fact_loss` if it omits a requested obligation or presents requested work as already implemented. Direct requests and `Requested actions` bullets are fact-safe when their action, target, condition, exception, and test boundary match the source. Do not judge style, length, formatting preference, or politeness.

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