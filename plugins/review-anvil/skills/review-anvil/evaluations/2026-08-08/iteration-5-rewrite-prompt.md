Rewrite the `body` of every item in `inline_comments` from the attached corpus. Apply the attached inline-comment language contract.

Every source comment came from a review-only run. Proposed remediation has not been implemented unless the source explicitly says otherwise.

The source comment is the technical ground truth. Preserve every material fact, including:

- the complete RAV ID, severity, and area label;
- actor, action, target, operation order, trigger, and scope;
- the concrete bad result and its diagnostic certainty;
- every identifier, number, quantifier, and scope word needed to distinguish the behavior;
- handled and unhandled error classes;
- valid behavior, preservation constraints, and exceptions;
- every requested code change and every source-backed test boundary.

Before writing, privately make a fact lock and an obligation lock. Map every source fact to an exact supporting phrase in the draft. Map every draft relationship and boundary back to one source fact. Restore source wording if any fact is missing. Delete unsupported draft claims. Never strengthen `can` to certainty, drop `all`, `only`, or `every`, broaden an error class, invent an actor or destination, attribute an aggregate result to one file, or reduce a precise test boundary to generic testing.

Improve presentation in this order:

1. Write a consequence-focused title: concrete bad result plus only the shortest trigger needed to keep the claim exact. Put operation order and other mechanism details in the body. Rewrite the title only when all source title facts remain; otherwise copy the source title verbatim.
2. Separate mechanism from result. Each sentence expresses one relationship. Use a pronoun only when its antecedent is the immediately preceding subject and cannot be confused with another identifier.
3. Prefer direct verbs with concrete targets, conditions, and source-backed destinations. Prefer `Keep X as Y`, `Record X in Y`, and `Leave X visible` over abstract state phrases such as `X can stay Y`. Do not invent a container or destination merely to make a sentence concrete.
4. Remove a sentence that only repeats the title. Keep necessary local technical terms and explain their role instead of replacing them with vague words.

Count independently verifiable requested obligations. A behavior change, preservation or exception, error class that must remain visible, or source-backed test with its own boundary is an obligation. A condition that only limits another action stays with that action.

For exactly one critical, high, or medium obligation, use one short sentence beginning with `Please` and a direct action verb. For two or more, use exactly:

**Requested actions**

- <Direct verb, target, and necessary condition or destination.>
- <Direct verb and preserved behavior, exception, or exact test boundary.>

Order behavior change, preservation or exception, then test. Do not repeat `Please` in bullets. Preserve suggestion grammar for low and nit guidance. Never write `the fix`, `in the fix`, or `the corrected path` unless the source explicitly discusses an existing patch under review. Do not add visible Problem, Impact, or Requested change headings. Do not address the author.

Return valid JSON only. The top-level value must be an array with one object per source inline comment in the original order. Each object must contain exactly:

- `id`: original numeric GitHub comment ID;
- `pr`: original PR number;
- `body`: rewritten Markdown body.

Do not include the top-level report, analysis, or Markdown fences.