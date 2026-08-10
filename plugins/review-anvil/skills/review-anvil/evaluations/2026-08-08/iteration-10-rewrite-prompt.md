Rewrite the `body` of every item in `inline_comments` from the attached corpus. The attached comments are the selected fact-safe baseline. This pass targets only requested-work readability.

Every source comment came from a review-only run. Treat the source body as technical ground truth. Preserve the complete RAV label, title, and every diagnostic sentence before requested work verbatim. Do not rewrite or reorder the title, mechanism, consequence, identifiers, numbers, conditions, quantifiers, modals, error classes, aggregate scope, actor, or destination.

Privately lock all requested content. Preserve every action, target, condition, permission, carve-out, exception, already-correct behavior, and exact test boundary. Reuse exact source wording for scope and collection phrases such as `for either collection`; do not replace them with inferred member names. Add no work.

Before drafting, split requested source prose into predicates. Classify each predicate in this order:

1. Identify whether it describes accepted current behavior, target behavior needed to resolve the finding, required verification or documentation, an allowed implementation boundary, or an explicitly optional follow-up.
2. Classify target behavior and required verification or documentation as AUTHOR WORK. Classify accepted current behavior, allowed implementation boundaries, and explicitly optional follow-ups as NO-CHANGE BOUNDARIES.
3. Apply the omission counterfactual only after that classification. If leaving the current code without the target behavior, test, or documentation would leave the defect, safety boundary, or reviewer-required verification unresolved, it is AUTHOR WORK.
4. Split every sentence that mixes AUTHOR WORK with a NO-CHANGE BOUNDARY. Classify each predicate separately. Do not keep an unsplit fallback.

Source intent outranks modal grammar. `Please`, a direct request, or source words such as `must`, `need`, and `required` identify AUTHOR WORK. A source-backed check, test, document change, or example stated to cover, demonstrate, clarify, or make a required boundary clear is AUTHOR WORK unless the source explicitly calls it optional or additional. Words such as `can`, `could`, and `would` do not make that work optional.

A predicate is a NO-CHANGE BOUNDARY only when it describes acceptable unchanged behavior, an allowed implementation boundary, or an explicitly optional follow-up. Words such as `remain`, `keep`, `leave`, `unchanged`, or `still` identify preservation only when the source says the current behavior is already acceptable.

Examples:
- `A mismatched-source test would cover this path.` is AUTHOR WORK because it is requested verification.
- `Unresolved keys can be reported after valid metrics are preserved.` mixes AUTHOR WORK (`preserve valid metrics`) with a NO-CHANGE BOUNDARY (`unresolved keys can be reported afterward`). Make preservation explicit in the request. Then write, `After valid metrics are preserved, unresolved keys can be reported.`
- `Expected 401 responses can keep their current handling.` is a NO-CHANGE BOUNDARY because the current behavior is acceptable.
- `A note plus this example would make the placement limit clear.` contains two AUTHOR WORK documentation items.
- `Optionally add a benchmark.` is an explicitly optional follow-up.

Privately map every requested source predicate to one class. Do not emit until every AUTHOR WORK predicate appears as an explicit request and every NO-CHANGE BOUNDARY remains visible with its original modality.

Group AUTHOR WORK by cohesive independently implementable change, not by grammar. Extract the smallest actor-action-target change without detaching a purpose, result, or safety clause that constrains it. Create a separate obligation only when the source requires another independently implementable action. A list of values under one rule is one obligation. Two verbs that establish one invariant on the same record or output remain one obligation.

Never put a NO-CHANGE BOUNDARY in its own action bullet. Keep a short boundary with the action it limits. If that would make the request dense, preserve it as one short modal sentence immediately after the request or action list. Preserve accepted current behavior as standalone modal prose. Preserve a standalone optional follow-up as standalone modal prose after the required request, or after the consequence when no request exists. Do not start that sentence with an imperative. Do not convert `can`, `could`, or `may` into mandatory language.

For exactly one AUTHOR WORK obligation, write one short sentence beginning with `Please` and a direct action verb. Add any no-change boundary as prose in the next sentence.

For two or more AUTHOR WORK obligations, use exactly:

**Requested actions**

- <Direct verb, target, and necessary condition or destination.>
- <Direct verb, target, and a distinct implementation or exact test boundary.>

Order required behavior changes before required tests. Do not repeat `Please` in bullets. Do not combine a distinct source-backed test with the code action. Do not create multiple bullets by repeating one verb for values governed by the same rule. Place no-change boundaries in prose immediately after the list; never add a bullet for them.

Prefer direct verbs with concrete targets for AUTHOR WORK. Preserve the source's diagnostic, boundary, and permission modality exactly. Avoid noun stacks, semicolons after long recipes, and repeated shared phrases.

Never write `the fix`, `in the fix`, or `the corrected path`. Do not address the author.

Return valid, pretty-printed JSON only, with one object field per line. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly `id`, `pr`, and `body`. Do not include analysis or Markdown fences.
