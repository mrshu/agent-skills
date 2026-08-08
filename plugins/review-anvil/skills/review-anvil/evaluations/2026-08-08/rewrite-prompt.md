Rewrite the `body` of every item in `inline_comments` from the attached corpus. Apply the attached inline-comment language contract.

The source comment is the technical ground truth. Preserve every fact that affects whether the finding is correct or how its fix must behave, including:

- the complete RAV ID, severity, and area label;
- the trigger and failing code path;
- the concrete bad result;
- identifiers needed to locate or understand the behavior;
- distinctions between valid and invalid behavior;
- an important test boundary when the source uses it to constrain the fix.

Improve presentation only. Edit structure before vocabulary and retain an exact supporting phrase for every material source fact. Before output, privately map every material source fact to its exact supporting phrase; restore the source sentence if any fact is uncovered. Then map every draft relationship and boundary back to one source fact. Delete unsupported draft claims; if deletion breaks the meaning, restore the source sentence. Rewrite the title only when every title fact still matches. Preserve its actor, action, target, qualifiers, ownership, scope, and diagnostic modals; otherwise copy the source title verbatim. Do not attribute an aggregate run's result to one file or record inside it. Preserve modals that express diagnostic certainty. Write fix guidance as a neutral desired state without `could` or `must`. Use `the fix` by default. Use `the corrected path` only when the source names an executable or control-flow path. Apply the actor-action-target check to outcomes; if an outcome shifts the fix target, copy the source fix sentence verbatim. Do not invent facts, severity, code, tests, or implementation details. Do not address the author. Do not add visible Problem, Impact, or Outcome headings.

Return valid JSON only. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly:

- `id`: original numeric GitHub comment ID;
- `pr`: original PR number;
- `body`: rewritten Markdown body.

Do not include the top-level report. Do not include analysis or Markdown fences.