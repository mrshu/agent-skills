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

## Inline-comment voice (bodies in `.inline.json`)

Write each inline comment in plain language about the code at that line. Use comments for `critical`, `high`, and `medium` problems; put `low` and `nit` items in the summary. Start with what you saw. State what the code does and what happens because of it. Then offer a friendly next step. Keep the comment as short as the finding allows. Every claim must point to a concrete code, test, config, caller, or runtime fact.
Keep evidence brief. Use separate short sentences when more than one fact is needed. Do not add an evidence heading or code dump unless it is needed.
Use short everyday words. Prefer one clear sentence over a dense explanation.

```
**[medium] error-handling** — `save_user` reports success when the INSERT fails

`save_user` catches every database error and returns `True`. `signup_flow`
then shows success even though no user row was written.

We could avoid that by letting non-retryable write errors reach `signup_flow`
and returning failure. A test where the INSERT fails would cover it.
```

Start with what you saw: the observable problem, the code path, and the result.
Then offer a friendly next step and, when useful, a test. Write ordinary prose;
do not label these parts. Use a short code sketch or exact replacement only when
it removes doubt.

Voice rules:

- Address the code, never the author: "the handler swallows the error", not "you swallow the error". No "should have", no "Obviously / Clearly / Simply / Just".
- Offer a calm next step: "We could ...", "One option is ...", or "It may help to ...". Do not use commands, rhetorical questions, review jargon, or filler.
- Calm and specific beats emphatic. The severity tag carries the urgency; the prose needs no alarm words, bold warnings, exclamation marks, or rhetorical/scolding questions.
- When the PR's approach is sound and the finding is an edge of it, say so in one honest clause ("the retry loop is right; the timeout just needs to cover it") — genuine context, not a compliment sandwich.
- Keep the comment as short as the finding allows. Add detail only when needed to explain the failure or the safe fix.
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
