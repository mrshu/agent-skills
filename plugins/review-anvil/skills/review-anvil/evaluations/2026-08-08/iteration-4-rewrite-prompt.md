Rewrite the `body` of every item in `inline_comments` from the attached corpus. Apply the attached inline-comment language contract.

Every source comment came from a review-only run. Proposed remediation has not been implemented unless the source explicitly says otherwise.

The source comment is the technical ground truth. Preserve every fact that affects whether the finding is correct or how the requested change must behave, including:

- the complete RAV ID, severity, and area label;
- the trigger and failing code path;
- the concrete bad result;
- identifiers needed to locate or understand the behavior;
- distinctions between valid and invalid behavior;
- an important test boundary when the source uses it to constrain the requested change.

Improve presentation only. Edit structure before vocabulary. Retain an exact supporting phrase for every material source fact. Before output, privately map every material source fact to its exact supporting phrase; restore the source sentence if any fact is uncovered. Then map every draft relationship and boundary back to one source fact. Delete unsupported draft claims; if deletion breaks the meaning, restore the source sentence.

Rewrite the title only when every title fact still matches. Preserve its actor, action, target, qualifiers, ownership, scope, and diagnostic modals; otherwise copy the source title verbatim. Do not attribute an aggregate run's result to one file or record inside it. Preserve modals that express diagnostic certainty.

Treat remediation as a requested change, not as observed code. For each source-backed action in a critical, high, or medium finding, write a separate short request sentence after the problem and consequence. Begin each request sentence with `Please` and a direct action verb. Preserve suggestion grammar for low and nit guidance. Never write `the fix`, `in the fix`, or `the corrected path` unless the source explicitly discusses an existing patch under review. If no source-backed requested change exists, stop after the consequence. Do not invent facts, severity, code, tests, test purposes, or implementation details. Do not address the author. Do not add visible Problem, Impact, or Requested change headings.

Return valid JSON only. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly:

- `id`: original numeric GitHub comment ID;
- `pr`: original PR number;
- `body`: rewritten Markdown body.

Do not include the top-level report. Do not include analysis or Markdown fences.
