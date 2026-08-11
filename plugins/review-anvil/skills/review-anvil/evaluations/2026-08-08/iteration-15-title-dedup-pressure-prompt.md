Render one GitHub inline review comment under the contract below. Return valid JSON only: {"body":"<complete body>"}. Do not inspect a repository, add facts, or omit facts. The visible title must be natural and must not expose the ID, severity, or area. End with the exact hidden marker derived from the source label.
The marker must be `<!-- review-anvil: id=RAV-RUN2-R1-F011 severity=medium area=registry-identity -->` on the final line.

CONTRACT:
Write the visible body in this order:

1. **Problem:** Name the code behavior and trigger.
2. **Impact:** State the concrete bad result.
3. **Requested change:** State the exact action or decision. Include a test only
   when the source requests it; do not invent what the test proves.
The first visible sentence adds a trigger, mechanism, result, or fix boundary that the title does not already state. If the title fully states the problem and consequence, begin with the next new fact or the request.

After the visible body, append the exact finding-metadata marker as the final
nonblank line.

Each sentence explains one relationship between code concepts. Name the
function, field, command, or request that acts. Tie each necessary identifier
to its role in the failure. Use a pronoun only when its antecedent is the
immediately preceding subject and cannot be confused with another identifier.
Use one minimal example only when it makes a path, count, or state change easier
to see. Do not show the Problem, Impact, or Requested change labels in the final
comment.

Before emitting the body, run this author check:

- The title and first sentence answer: what breaks, and when?
- Replace an abstract label with the code actor and a direct verb.
- The title names the actor that produces the concrete bad result.
- Do not attribute an aggregate run's result to one file or record inside it.
- Rewrite the title only when every fact-lock item in it still matches.
- Preserve title qualifiers and ownership, including diagnostic modals and scope words.
- If the title changes the actor, action, target, condition, scope, or certainty,
  restore the synthesized finding sentence verbatim.
- When a path, count, or state change is hard to picture, give one minimal example instead of making the reader simulate it.
- Remove a test sentence only when the source does not request it. Keep every source-backed required verification with its exact boundary.
- Remove any sentence that repeats the title without adding a trigger, result,
  constraint, or fix boundary.


SOURCE:
**RAV-RUN2-R1-F011 [medium] registry-identity** — Normalized organization collisions can rewrite an exact canonical ID to another canonical organization.

Exact canonical IDs can win first. Normalized spellings can resolve only when one organization owns them.