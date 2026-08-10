Evaluate technical preservation and action locking in three randomized rewrites of each code-review inline comment. Each row contains the original `source` plus candidates A, B, and C. The source came from a review-only run: proposed remediation was not implemented unless the source explicitly says otherwise.

For each source, first split all requested prose after the diagnosis into the smallest meaningful post-change predicates. Classify every predicate with this counterfactual:

- `author_work`: omitting this behavior leaves the reported defect or a required safety/correctness boundary unresolved. Modal verbs such as `can`, `could`, or `may` do not make it optional.
- `constraint`: the source identifies behavior as already acceptable and permits it to remain allowed, preserved, unchanged, conditional, or outside the error boundary.
- `permission`: an optional follow-up whose omission still leaves every reported defect and required boundary resolved.

Classify each predicate independently. A sentence can mix classes. Example: `Legacy snapshots can leave this typed value unset and mark the missing content` contains a constraint (`leave ... unset`) and author work (`mark the missing content`).

Then judge every candidate on two independent gates:

1. `fact_status`: `fact_safe` only if it preserves every material source fact, including complete ID, severity, area, title, mechanism, consequence, values, identifiers, conditions, quantifiers, modality, scope, actor, destination, exact test boundary, and error class. It must add no unsupported technical claim.
2. `action_lock_status`: `locked` only if every `author_work` predicate is visibly governed by an explicit request (`Please` plus an action verb, or a `**Requested actions**` bullet). Merely retaining the words as modal prose is not locked. Every constraint and permission must remain visible without becoming a mandatory action.

Do not judge style, length, formatting preference, or politeness. Preserve a candidate as safe only when both gates can be verified from the text. When uncertain, name the exact predicate and why it is uncertain rather than silently passing it.

Return valid, pretty-printed JSON only:

{
  "per_comment": [
    {
      "id": 123,
      "source_units": [
        {"text": "...", "class": "author_work|constraint|permission"}
      ],
      "candidates": {
        "A": {
          "fact_status": "fact_safe|fact_loss",
          "action_lock_status": "locked|unlocked|false_action",
          "fact_losses": ["..."],
          "missing_explicit_actions": ["..."],
          "false_actions": ["..."]
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

Include each input ID exactly once. Put one JSON field per line. Do not include Markdown fences.
