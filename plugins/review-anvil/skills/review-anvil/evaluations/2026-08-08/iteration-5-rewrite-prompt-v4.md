Rewrite the `body` of every item in `inline_comments` from the attached corpus. The attached comments are the selected fact-safe baseline. This pass targets only requested-work readability.

Every source comment came from a review-only run. Treat the source body as technical ground truth. Preserve the complete RAV label, title, and every diagnostic sentence before requested work verbatim. Do not rewrite or reorder the title, mechanism, consequence, identifiers, numbers, conditions, quantifiers, modals, error classes, aggregate scope, actor, or destination.

Privately lock all requested work. Preserve every action, target, condition, exception, and exact test boundary. Reuse exact source wording for scope and collection phrases such as `for either collection`; do not replace them with inferred member names. Add no work.

Group requested work by implementation obligation, not by grammar:

- One obligation is a cohesive code or test change that can be implemented and verified independently.
- A list of values under one rule is one obligation. Do not split `uncertainty, counts, and positive denominators` into three repeated actions.
- Two verbs that establish one invariant on the same record or output may remain one obligation.
- A condition, preservation rule, error class, or exception stays with the action it limits. Make it a separate obligation only when it governs a distinct input or code path that can be verified independently.
- A source-backed test with its own boundary is a separate obligation from the code change.

Prefer a direct verb with a concrete target and source-backed condition or destination. Prefer `Keep X as Y`, `Record X in Y`, and `Leave X visible` over abstract state phrases such as `X can stay Y`. Avoid repeating a long shared phrase across bullets; state the shared context once when the distinction remains clear.

For exactly one obligation, write one short sentence beginning with `Please` and a direct action verb. Attach its constraint or exception in the same sentence when practical.

For two or more independently implementable obligations, use exactly:

**Requested actions**

- <Direct verb, target, and necessary condition or destination.>
- <Direct verb and distinct preserved behavior, path, or exact test boundary.>

Order behavior change, distinct preservation path, then test. Do not repeat `Please` in bullets. Do not combine a distinct source-backed test with the code action. Do not create multiple bullets by repeating one verb for values governed by the same rule.

Never write `the fix`, `in the fix`, or `the corrected path`. Do not address the author.

Return valid JSON only. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly `id`, `pr`, and `body`. Do not include analysis or Markdown fences.