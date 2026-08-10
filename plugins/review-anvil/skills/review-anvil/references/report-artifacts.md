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
- valid behavior that the requested change must preserve.

Do not put the fact lock in the comment. Compare the draft with the fact lock.
Every relationship and boundary must still match.
Clarity does not permit a stronger, broader, or different claim.
If shorter wording changes a fact, restore the fact and simplify a different
part of the sentence.

Edit structure before vocabulary.
Keep an exact supporting phrase for every fact-lock item.
Privately map every fact-lock item to its exact supporting phrase in the draft.
Do not emit until every fact-lock item has a supporting phrase.
Privately map every draft relationship and boundary back to one fact-lock item.
Delete any draft claim that has no source fact.
If deletion would break the meaning, restore the source sentence.
You may reorder clauses and split sentences to show problem, impact, and the
requested change.
You may remove filler and exact repetition.
Do not replace technical verbs, quantifiers, or scope words.
Preserve modals that express diagnostic certainty.
Treat remediation as a requested change, not as observed code.
Prefer a direct verb with a concrete target, condition, or destination.
Use an imperative only for work the author must perform. Use modal prose for
behavior that may remain unchanged.
Do not force an actor or destination that the source does not establish.
Group requested work by implementation obligation, not by grammar.
An obligation is work the author must perform in code or tests.
One obligation is a cohesive change that can be implemented and verified
independently.
Do not split a list of values governed by one rule into repeated actions.
Two verbs that establish one invariant on the same record or output may remain
one obligation.
A preservation constraint, permission, carve-out, exception, or
already-correct behavior is not a separate obligation.
Keep a no-change constraint out of `**Requested actions**`.
Keep it with the action it limits. State it as short modal prose immediately
after the action it limits when combining them would make the request dense.
Make a distinct path separate only when the source requires the author to
change that path independently.
A required source-backed test is author work and is separate when it has its
own exact boundary.
For example: `Files containing only intentionally skipped derived rows can remain explicit exclusions; no change is requested for them.`
Reuse exact source wording for scope and collection phrases; do not replace
them with inferred member names.
For each source-backed obligation in a critical, high, or medium finding, make
its requested status explicit. For exactly one obligation, write one short
request sentence beginning with `Please` and a direct action verb.
For two or more independently implementable obligations, use this form:

```md
**Requested actions**

- <Direct verb, target, and necessary condition or destination.>
- <Direct verb, target, and a distinct implementation or exact test boundary.>
```

Order required behavior changes before required tests. Keep no-change
constraints with the action they limit or in the modal prose immediately after
it.
Do not repeat `Please` in the bullets; the heading establishes request mode.
Avoid repeating a long shared phrase across bullets.
Keep suggestion grammar for low and nit guidance.
Never write `the fix`, `in the fix`, or `the corrected path` unless the source
explicitly discusses an existing patch under review.
Apply the actor-action-target check to requested-change sentences as well as titles.
If a requested change shifts the target, restore the source plan sentence verbatim.
If no source-backed requested change exists, stop after the consequence.
Do not invent why a requested test exists.
Delete a source clause only when another retained clause states the same fact.
If an exact phrase is hard to place, keep the whole source sentence.

Write the body in this order:

1. **Problem:** Name the code behavior and trigger.
2. **Impact:** State the concrete bad result.
3. **Requested change:** State the exact action or decision. Include a test only
   when the source requests it; do not invent what the test proves.

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
- Remove a test sentence unless it defines the failure boundary.
- Remove any sentence that repeats the title without adding a trigger, result,
  constraint, or fix boundary.

For an explicitly reintroduced author-resolved finding, put `<!-- review-anvil: prior_feedback=reintroduced -->` immediately after the visible final-report finding row or bullet. Its matching inline item carries helper-only `"prior_feedback": "reintroduced"`; the posting helper strips that JSON field before the GitHub REST request while preserving the hidden marker in the posted inline body for later PR-history handling.
Use short everyday words. Prefer one clear sentence over a dense explanation.

```
**RAV-RUN2-R1-F003 [medium] cli** — The module entry point builds the old argument namespace

The changed handler reads missing fields and fails before conversion.

**Requested actions**

- Use the shared top-level parser in the module entry point.
- Add one offline entry-point test.
```

When one code change has a no-change constraint, keep the constraint in prose:

```
**RAV-RUN3-R1-F002 [medium] input-validation** — Invalid populated cells become absent values

The fallback also accepts invalid or zero denominators.

Please use separate rules for uncertainty, counts, and positive denominators to keep bad rows in the failure report.
Empty optional cells can remain allowed.
```

Keep only evidence that helps the author trust or fix the finding. Do not
narrate the investigation, repeat the title, or list code terms without saying
what they do here. Use a short code sketch or exact replacement only when it
removes doubt.

Voice rules:

- Address the code, never the author: "the handler swallows the error", not "you swallow the error". No "should have", no "Obviously / Clearly / Simply / Just".
- Keep requested work calm and specific. Use one concise `Please` sentence for one critical/high/medium obligation and `**Requested actions**` bullets for two or more. Do not use context-free commands, rhetorical questions, review jargon, or filler.
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
