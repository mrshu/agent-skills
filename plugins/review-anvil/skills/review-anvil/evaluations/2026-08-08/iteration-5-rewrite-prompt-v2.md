Rewrite the `body` of every item in `inline_comments` from the attached corpus. The attached comments are the selected fact-safe baseline. This pass targets only the readability and visibility of requested work.

Every source comment came from a review-only run. Proposed remediation has not been implemented unless the source explicitly says otherwise.

Treat the source body as technical ground truth. Preserve the complete RAV label, title, and every diagnostic sentence before the requested-work section verbatim. Do not rewrite or reorder the title, mechanism, consequence, identifiers, numbers, conditions, quantifiers, modals, error classes, or aggregate scope. Do not add a destination or actor.

Privately lock every requested obligation. An obligation is independently satisfiable or violable: a behavior change, preservation or exception, error class that must remain visible, or source-backed test with its own boundary. A condition that only limits an action stays with that action. Preserve every action, target, condition, exception, and exact test boundary. Add no work.

Improve only the requested-work section:

- Prefer a direct verb with a concrete target and source-backed condition or destination.
- Prefer `Keep X as Y`, `Record X in Y`, and `Leave X visible` over abstract state phrases such as `X can stay Y`.
- For exactly one obligation, write one short sentence beginning with `Please` and a direct action verb.
- For two or more obligations, use exactly:

**Requested actions**

- <Direct verb, target, and necessary condition or destination.>
- <Direct verb and preserved behavior, exception, or exact test boundary.>

Order behavior change, preservation or exception, then test. Do not repeat `Please` in bullets. Do not combine independently checkable actions in one bullet. Do not split a condition from the action it limits. Never write `the fix`, `in the fix`, or `the corrected path`. Do not address the author.

Return valid JSON only. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly:

- `id`: original numeric GitHub comment ID;
- `pr`: original PR number;
- `body`: rewritten Markdown body.

Do not include analysis or Markdown fences.