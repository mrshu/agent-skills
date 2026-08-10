Rewrite the `body` of every item in `inline_comments` from the attached corpus. The attached comments are the selected fact-safe baseline. This pass targets only requested-work readability.

Every source comment came from a review-only run. Treat the source body as technical ground truth. Preserve the complete RAV label, title, and every diagnostic sentence before requested work verbatim. Do not rewrite or reorder the title, mechanism, consequence, identifiers, numbers, conditions, quantifiers, modals, error classes, aggregate scope, actor, or destination.

Privately lock all requested content. Preserve every action, target, condition, permission, carve-out, exception, already-correct behavior, and exact test boundary. Reuse exact source wording for scope and collection phrases such as `for either collection`; do not replace them with inferred member names. Add no work.

Before drafting, split requested source prose into the smallest meaningful post-change predicates. Classify each predicate by meaning, not by its modal verb or sentence boundary:

- **AUTHOR WORK**: a post-change behavior or required test the PR author must implement. Apply an omission counterfactual: if omitting the predicate leaves the reported defect or a required boundary unresolved, it is AUTHOR WORK even when the source uses `can`, `could`, or `may`. Extract its smallest actor-action-target request. A source-backed test with its own exact boundary is separate author work.
- **MODAL BOUNDARY**: permitted behavior that limits where or how an explicit author obligation may operate. It is a boundary only when omitting the permitted behavior would not leave the reported defect unresolved. Example: request `Add a no-match check.` Then retain `It can stop before existing-output discovery or publication.`
- **NO-CHANGE CONSTRAINT**: behavior the source identifies as already acceptable and permits to remain allowed, preserved, unchanged, conditional, or outside the requested error boundary. Words such as `remain`, `keep`, `leave`, `unchanged`, or `still` are preservation cues only when the source says the behavior is already acceptable.
- **STANDALONE PERMISSION**: an optional follow-up or outcome after the primary change. It is optional only when all reported defects and required boundaries remain resolved if the author omits it. Example: `Unresolved keys can be reported after the valid metrics are preserved.`

A compound modal sentence can mix classes. Classify each predicate independently. For example, `Legacy snapshots can leave this typed value unset and mark the missing content` contains a NO-CHANGE CONSTRAINT (`leave ... unset`) and AUTHOR WORK (`mark the missing content`).

Privately map every requested source predicate to one class. Do not emit until every AUTHOR WORK predicate appears as an explicit request and every other predicate remains visible with its original modality.

Group AUTHOR WORK by cohesive independently implementable change, not by grammar. A list of values under one rule is one obligation. Two verbs that establish one invariant on the same record or output may remain one obligation.

Never put a MODAL BOUNDARY, NO-CHANGE CONSTRAINT, or STANDALONE PERMISSION in its own action bullet. Keep a short boundary with the action it limits. If that would make the request dense, preserve it as one short modal sentence immediately after the request or action list. Do not start that sentence with an imperative. Do not convert `can`, `could`, or `may` into mandatory language.

For exactly one AUTHOR WORK obligation, write one short sentence beginning with `Please` and a direct action verb. Add any modal boundary or no-change constraint as prose in the next sentence.

For two or more AUTHOR WORK obligations, use exactly:

**Requested actions**

- <Direct verb, target, and necessary condition or destination.>
- <Direct verb, target, and a distinct implementation or exact test boundary.>

Order required behavior changes before required tests. Do not repeat `Please` in bullets. Do not combine a distinct source-backed test with the code action. Do not create multiple bullets by repeating one verb for values governed by the same rule. Place modal boundaries, constraints, and permissions in prose immediately after the list; never add a bullet for them.

Prefer direct verbs with concrete targets for AUTHOR WORK. Preserve the source's diagnostic, boundary, and permission modality exactly. Avoid noun stacks, semicolons after long recipes, and repeated shared phrases.

Never write `the fix`, `in the fix`, or `the corrected path`. Do not address the author.

Return valid JSON only. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly `id`, `pr`, and `body`. Do not include analysis or Markdown fences.
