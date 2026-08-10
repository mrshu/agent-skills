Rewrite the `body` of every item in `inline_comments` from the attached corpus. The attached comments are the selected fact-safe baseline. This pass targets only requested-work readability.

Every source comment came from a review-only run. Treat the source body as technical ground truth. Preserve the complete RAV label, title, and every diagnostic sentence before requested work verbatim. Do not rewrite or reorder the title, mechanism, consequence, identifiers, numbers, conditions, quantifiers, modals, error classes, aggregate scope, actor, or destination.

Privately lock all requested content. Preserve every action, target, condition, permission, carve-out, exception, already-correct behavior, and exact test boundary. Reuse exact source wording for scope and collection phrases such as `for either collection`; do not replace them with inferred member names. Add no work.

Before drafting, classify each source-backed requested unit:

- **AUTHOR WORK**: a code change or required test the PR author must perform. A source-backed test with its own exact boundary is author work separate from the code change.
- **NO-CHANGE CONSTRAINT**: a permission, carve-out, exception, or behavior that may remain unchanged. Phrases such as `can remain`, `can stay`, `can keep`, `remains allowed`, `stay conditional`, `behavior unchanged`, and unhandled error classes normally mark constraints, not work.

Only AUTHOR WORK counts as an implementation obligation. Group it by cohesive independently implementable change, not by grammar. A list of values under one rule is one obligation. Two verbs that establish one invariant on the same record or output may remain one obligation.

Never put a NO-CHANGE CONSTRAINT in its own action bullet. Keep a short constraint in the action it limits. If that would make the request dense, preserve the constraint as one short modal sentence immediately after the request or action list. Do not start that sentence with an imperative. State explicitly that no change is requested when an imperative could otherwise be inferred.

For exactly one AUTHOR WORK obligation, write one short sentence beginning with `Please` and a direct action verb. Add any dense no-change constraint as modal prose in the next sentence.

For two or more AUTHOR WORK obligations, use exactly:

**Requested actions**

- <Direct verb, target, and necessary condition or destination.>
- <Direct verb, target, and a distinct implementation or exact test boundary.>

Order required behavior changes before required tests. Do not repeat `Please` in bullets. Do not combine a distinct source-backed test with the code action. Do not create multiple bullets by repeating one verb for values governed by the same rule. Place a no-change constraint inside the action it limits or as modal prose immediately after the list; never add a bullet for it.

Prefer direct verbs with concrete targets for AUTHOR WORK. Use modal prose for NO-CHANGE CONSTRAINTS. Never convert `can`, `may`, or another diagnostic or permission modal into a required imperative. Avoid noun stacks, semicolons after long recipes, and repeated shared phrases.

Never write `the fix`, `in the fix`, or `the corrected path`. Do not address the author.

Return valid JSON only. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly `id`, `pr`, and `body`. Do not include analysis or Markdown fences.
