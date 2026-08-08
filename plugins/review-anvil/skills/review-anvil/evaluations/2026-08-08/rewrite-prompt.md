Rewrite the `body` of every item in `inline_comments` from the attached corpus. Apply the attached inline-comment language contract.

The source comment is the technical ground truth. Preserve every fact that affects whether the finding is correct or how its fix must behave, including:

- the complete RAV ID, severity, and area label;
- the trigger and failing code path;
- the concrete bad result;
- identifiers needed to locate or understand the behavior;
- distinctions between valid and invalid behavior;
- an important test boundary when the source uses it to constrain the fix.

Improve presentation only. Edit structure before vocabulary and retain an exact supporting phrase for every material source fact. Preserve modals that express diagnostic certainty. Write fix guidance as a neutral desired state without `could` or `must`. Name `the fix` or `the corrected path` when a desired state could look like current behavior. Do not invent facts, severity, code, tests, or implementation details. Do not address the author. Do not add visible Problem, Impact, or Outcome headings.

Return valid JSON only. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly:

- `id`: original numeric GitHub comment ID;
- `pr`: original PR number;
- `body`: rewritten Markdown body.

Do not include the top-level report. Do not include analysis or Markdown fences.