# review-anvil — Report Artifact Details

Read at final-report time when `report_path` is set (Loop Mechanics §6 of the engine SKILL.md).

## Progressive disclosure for external reports

Keep the decision, result, scope, and actionable critical/high/medium findings
visible without an extra click. Preserve supporting evidence and auditability
without filling the destination's conversation surface: use the destination's
native collapsed/expandable sections for run metadata and longer supporting
sections. On GitHub, wrap Run details in `<details>` for every external report,
and collapse prior-feedback, would-apply, deferred/out-of-scope, and low/nit
sections when they exceed the thresholds in the engine's Output Format. Use a
specific summary with an item count when available, leave a blank line after
`<summary>`, and place `</details>` on its own line.

If a destination has no disclosure control, send a concise decision summary
and preserve the full report in an attached artifact or stable link. Never put
a blocker only in collapsed or linked detail.

## ASD-STE100-Inspired Language

Apply `asd-ste100-inspired.md` to generated reports and comments. Use the
author-facing profile. Preserve evidence tokens verbatim.

## Inline-comment voice (bodies in `.inline.json`)

Write each inline comment in plain language about the code at that line. Use
comments for `critical`, `high`, and `medium` problems; put `low` and `nit`
items in the summary.

Start every identified inline finding with the parser-supported bold label
`**<complete-id> [<severity>] <area>**` followed by `— <finding>`.
The title states the failure, not only its technical category.
The report row, inline body, reproduction target, and adversarial target use the same complete finding ID unchanged.
ID reuse produces an inline body only when the finding is otherwise eligible
for a new inline; ordinary prior-feedback carry-forwards do not create a new inline thread.

Before rewriting, make a private fact lock from the final synthesized finding.
Record only:

- code identifiers, numbers, and quoted diagnostics;
- technical verbs and actor-action-target relationships;
- triggers and conditions;
- quantifiers, scope words, and certainty such as `all`, `only`, `can`, and
  `must`;
- the concrete bad result;
- valid behavior that the fix must preserve.

Do not put the fact lock in the comment. Compare the draft with the fact lock.
Every relationship and boundary must still match.
Clarity does not permit a stronger, broader, or different claim.
If shorter wording changes a fact, restore the fact and simplify a different
part of the sentence.

Write the body in this order:

1. **Problem:** Name the code behavior and trigger.
2. **Impact:** State the concrete bad result.
3. **Outcome:** State the corrected behavior. Add a test only when it explains
   an important boundary.

Each sentence explains one relationship between code concepts. Name the
function, field, command, or request that acts. Tie each necessary identifier
to its role in the failure. Use one minimal example only when it makes a path,
count, or state change easier to see. Do not show the Problem, Impact, or
Outcome labels in the final comment.

Before emitting the body, run this author check:

- The title and first sentence answer: what breaks, and when?
- Replace an abstract label with the code actor and a direct verb.
- When a path, count, or state change is hard to picture, give one minimal example instead of making the reader simulate it.
- Remove a test sentence unless it defines the failure boundary.
- Remove any sentence that repeats the title without adding a trigger, result,
  constraint, or fix boundary.

For an explicitly reintroduced author-resolved finding, put `<!-- review-anvil: prior_feedback=reintroduced -->` immediately after the visible final-report finding row or bullet. Its matching inline item carries helper-only `"prior_feedback": "reintroduced"`; the posting helper strips that JSON field before the GitHub REST request while preserving the hidden marker in the posted inline body for later PR-history handling.
Use short everyday words. Prefer one clear sentence over a dense explanation.

```
**RAV-RUN3-R2-F001 [medium] error-handling** — `save_user` reports success after the database write fails

`save_user` catches the database error and returns `True`. `signup_flow` then
reports success, but no user row exists.

Non-retryable write errors must reach `signup_flow` so it returns failure. An
INSERT failure test covers this boundary.
```

Keep only evidence that helps the author trust or fix the finding. Do not
narrate the investigation, repeat the title, or list code terms without saying
what they do here. Use a short code sketch or exact replacement only when it
removes doubt. A concise finding can omit the Outcome sentence when the problem
and impact already make the correction unambiguous.

Voice rules:

- Address the code, never the author: "the handler swallows the error", not "you swallow the error". No "should have", no "Obviously / Clearly / Simply / Just".
- Keep the outcome calm and specific. Do not use commands, rhetorical questions, review jargon, or filler.
- Do not add a stock opener or rotate through canned alternatives. Let the problem determine the sentence.
- Calm and specific beats emphatic. The severity tag carries the urgency; the prose needs no alarm words, bold warnings, exclamation marks, or rhetorical/scolding questions.
- When the PR's approach is sound and that fact changes the fix, say so in one honest clause. Do not add a compliment sandwich.
- Keep the comment as short as the finding allows. Add detail only when needed to explain the failure or safe outcome.
- Use a suggestion only for a safe, exact replacement. The comment must still explain the problem. For cross-file or multi-step fixes, describe the behavior to change instead.

The same voice applies to the report body's Things to try, Set aside, and Outside this change prose.

## Checking uncertain findings

When a finding needs a second check, tell the reader only what was checked and
what remains. Do not paste the investigation.

Use one line near the top of the report:

```md
**Checks:** 4 concerns checked; 2 confirmed, 1 lowered in priority, 1 set aside because it could not be confirmed.
```

Then use plain language in the normal sections:

- Confirmed findings appear in `## Findings`.
- Ruled-out findings disappear unless a short note helps explain the result.
- Unclear findings move to `## Set aside / Outside this change` with what proof
  is missing.
- Lower-priority findings follow the normal priority rules.

## Second check

When a second review runs, show only its result. Do not paste reviewer
disagreement or rejected-finding essays into the PR timeline.

Use one line near the top of the report:

```md
**Second check:** 2 reviewers checked 7 findings; 5 kept, 1 clarified, 1 set aside, 1 removed.
```

Then fold the result into the normal sections:

- Removed findings disappear unless a short note helps explain the result.
- Fixes that are too large or unsafe move to `## Set aside / Outside this change`
  with one short reason.
- Clearer fixes replace the old wording.
- Inline comments contain only the final wording.
- Omit GitHub suggestion blocks when the exact replacement is not safe.

## `.followups.json` schema

When `report_path` is set, write a sibling `<report_path>.followups.json` with any follow-ups:

```json
[
  {
    "approval": "auto_approved | needs_triage",
    "severity": "high",
    "area": "entity-resolution",
    "title": "Canonicalize merged co-mentions before seeding annotation prompts",
    "why": "Confirmed pre-existing bug; stale merged IDs can re-enter prompts.",
    "evidence": {"file": "apps/api/src/pipeline/seeder.rs", "line": 359},
    "separate_pr_reason": "Not introduced by this performance PR; should be fixed independently.",
    "dedupe_key": "entity-resolution merged co-mentions seeding"
  }
]
```

Downstream automation may file GitHub issues only for `auto_approved` entries after duplicate search; `needs_triage` stays in the PR report only.
