Blindly evaluate technical preservation and action locking in three randomized versions of each code-review inline comment. Each row contains the review-only `source` plus candidates A, B, and C. Proposed remediation was not implemented unless the source context explicitly describes current acceptable behavior.

For each source, split requested prose after the diagnosis into the smallest meaningful post-change predicates. Classify by behavior, not modal grammar:

- `author_work`: target behavior needed to resolve the finding, or required verification, documentation, purpose, result, or safety behavior.
- `no_change`: accepted current behavior, an allowed implementation boundary, or an explicitly optional follow-up.

Use the diagnosis to decide current versus target behavior. Split mixed predicates. A predicate that says `can`, `could`, or `may` is still author work when the diagnosis shows the current code violates it. A check, test, document change, or example stated to cover, demonstrate, clarify, or make a required boundary clear is author work unless explicitly optional.

Examples:
- `A no-match check can stop before existing-output discovery or publication` requests the check but permits its stopping point.
- When current IDs use retrieval time, a stable source-run token is author work while an existing `retrieved_timestamp` remains a no-change boundary.
- When the current unit can conflict with canonical bounds, setting it only with proof and leaving it unset otherwise are author work; an existing `pwc_scale` detail can remain a no-change boundary.

Judge each candidate on two independent gates:

1. `fact_status`: `fact_safe` only if it preserves every material source fact: complete ID, severity, area, title, mechanism, consequence, values, identifiers, conditions, quantifiers, modality, scope, actor, destination, purpose, result, safety clause, exact test boundary, and error class. It must add no unsupported technical claim.
2. `action_lock_status`: `locked` only if every `author_work` predicate is visibly governed by an explicit request (`Please` plus an action verb, or a `**Requested actions**` bullet). Modal prose alone is not locked. Every `no_change` predicate must remain visible without becoming mandatory work.

Do not judge style, length, formatting preference, or politeness. Before returning a verdict, internally map every source predicate to its exact rendered phrase and obligation status. When uncertain, mark the specific gate unsafe and state why.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "candidates": {
        "A": {
          "fact_status": "fact_safe|fact_loss",
          "action_lock_status": "locked|unlocked|false_action",
          "fact_losses": [],
          "missing_explicit_actions": [],
          "false_actions": []
        },
        "B": {},
        "C": {}
      }
    }
  ],
  "counts": {
    "A": {"fact_safe": 0, "fact_loss": 0, "locked": 0, "unlocked": 0, "false_action": 0},
    "B": {"fact_safe": 0, "fact_loss": 0, "locked": 0, "unlocked": 0, "false_action": 0},
    "C": {"fact_safe": 0, "fact_loss": 0, "locked": 0, "unlocked": 0, "false_action": 0}
  },
  "summary": "two or three sentences"
}

Include each input ID exactly once. Put one JSON field per line. Do not include Markdown fences, rewrites, readability judgments, or text outside the JSON.
