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


## Final clarity pass

After synthesis freezes the decision, dispositions, facts, requested work,
anchors, and safe suggestions, render both external surfaces through the final
clarity pass.
The top-level report is a short human summary: one or two natural detection
sentences followed by collapsed sections. Every active finding becomes a
four-column row inside `Issues and fixes` or `Optional suggestions`:
`| Severity | Location | Issue | Suggested change |`. The optional table uses
`Suggestion` for the third column. Each collapsed row keeps the full diagnosis,
impact, and requested or suggested change; inline comments retain the same
anchor-backed detail in GitHub's native UI.

Do not narrate the review pipeline in the visible summary. Translate internal
review outcomes into observations about the changed code. Do not require a fixed
replacement phrase. Choose a natural statement about affected behavior,
detected issue areas, optional suggestions, or unreproduced uncertainty.

The pass rewrites the language as well as the layout. Prefer short ordinary
sentences and concrete outcomes over internal mechanics. It cannot change the
finding inventory, decision, priority, disposition, technical relationships,
requested work, anchors, or suggestions. Validate its complete JSON bundle with
`scripts/validate-clarity-output.py` before action-lock auditing or emission.

Each top-level finding or disposition line ends with:
`<!-- review-anvil-report: id=<complete-id> severity=<severity> area=<area> path=<encoded-path> start_line=<number-or-dash> line=<number-or-dash> disposition=<active|deferred|outside> -->`.
The marker hides machine metadata from the rendered report.
The hidden report marker, inline marker, reproduction target, and adversarial
target use the same complete finding ID unchanged.
Each table row stays on one source line and ends with its hidden report marker
in the final cell. Escape every literal `|` inside a cell as `\|`. Parse the
fixed columns and terminal marker; never use generic `split('|')` parsing.
Place the review-anvil footer exactly once as the absolute final nonblank line.
Every collapsed block and helper-only idempotency marker comes before it.

## ASD-STE100-Inspired Language

Apply `asd-ste100-inspired.md` to generated reports and comments. Use the
author-facing profile. Preserve evidence tokens verbatim.

## Inline-comment voice (bodies in `.inline.json`)

The voice rules below do not replace the mandatory two-auditor action-lock gate
in `action-lock-audit.md`; every rewritten draft body must pass that gate before
it enters `.inline.json`. The exact-source fallback is exempt and
forces COMMENT.

Write each inline comment in plain language about the code at that line. Emit
comments at or above the configured inline threshold; lower-priority findings
remain in the summary.

Do not add a synthetic title or visible metadata. Use two short human paragraphs
when requested work exists:

1. State what goes wrong and the concrete result.
2. Start the smallest required change with its action verb.

Default to starting required work with its action verb. A deliberate
collaborative request may use a courtesy wrapper sparingly when coordination or
tone benefits. Never use `Could you`, `Can you`, `Would you`, `Will you`, or
`Please` as a stock opener throughout the review. End a direct imperative as a
statement, not a question. Optional low/nit work starts with `Consider …`. Ask
a real question only when the source leaves a decision unresolved. Do not
mechanically rotate equivalent request openers.

Use a short list only for three or more independent obligations. End each body
with exactly one
`<!-- review-anvil: id=<complete-id> severity=<severity> area=<area> -->`.
The marker remains the final line. Put a safe suggestion fence and the
`prior_feedback=reintroduced` marker before it. Do not put prose after it.
ID reuse produces an inline body only when the finding is otherwise eligible;
ordinary prior-feedback carry-forwards do not create a new inline thread.

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
Preserve a verified exact source suggestion only when it satisfies every
safety exclusion in the engine `SKILL.md`; otherwise omit it.
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
Classify each source predicate before rendering it:

1. Identify whether it describes accepted current behavior, target behavior
   needed to resolve the finding, required verification or documentation, an
   allowed implementation boundary, or an explicitly optional follow-up.
2. Classify target behavior and required verification or documentation as
   author work. Classify accepted current behavior, allowed implementation
   boundaries, and explicitly optional follow-ups as no-change boundaries.
3. Apply the omission counterfactual only after that classification. If leaving
   the current code without the target behavior, test, or documentation would
   leave the defect, safety boundary, or reviewer-required verification
   unresolved, it is author work.
4. Split every source sentence that mixes author work with a no-change boundary
   into predicates for classification; do not preserve an unsplit fallback.

Source intent outranks modal grammar. `Please`, a direct request, or source
words such as `must`, `need`, and `required` identify author work. A
source-backed check, test, document change, or example stated to cover,
demonstrate, clarify, or make a required boundary clear is author work unless
the source explicitly calls it optional or additional. Words such as `can`,
`could`, and `would` do not make that work optional.

A permission is not author work only when it describes acceptable unchanged
behavior, an allowed implementation boundary, or an explicitly optional
follow-up. Words such as `remain`, `keep`, `leave`, `unchanged`, and `still`
identify preservation only when the source says the current behavior is
already acceptable.

An obligation is one cohesive change that can be implemented and verified
independently. Extract its smallest actor-action-target change without
detaching a purpose, result, or safety clause that constrains that change.
Create a separate obligation only when the source requires another
independently implementable action. If a new mechanism is needed to resolve
the failure, request that mechanism and keep only its permitted behavior as modal prose.
Do not split a list of values governed by one rule into repeated actions.
Two verbs that establish one invariant on the same record or output remain one obligation.

A no-change boundary is not a separate obligation. Keep it in the request
sentence with `without changing …` or `while keeping … unchanged`. If that is
too dense, state the accepted behavior in one short sentence after the request.
Keep optional follow-ups as optional prose.

For example: `Reject directory symlinks while keeping file symlinks
unchanged.`

Make a distinct path separate only when the source requires another independent
change. A required source-backed test remains author work when it has its own
boundary. Reuse exact source wording for scope and collection phrases.

Before writing, map every source predicate to author work or a no-change
boundary. Every author-work predicate must remain an explicit request. Combine
actions that implement one invariant; do not split values governed by one rule.

Use one short direct-action paragraph for one or two obligations. Start with
the action verb. Use a real question such as `Should …?` only when the source
leaves a choice unresolved. Use a short bullet list only for three or more
independently implementable obligations.

Order required behavior before required tests. Keep suggestion grammar for low
and nit guidance. Never write `the fix`, `in the fix`, or `the corrected path`
unless the source discusses an existing patch. If no source-backed request
exists, stop after the consequence. Do not invent why a test exists.

Write the visible body in this order:

1. One or two short sentences stating the failure and concrete result.
2. One short direct-action paragraph when author work exists.
3. Optional accepted behavior only when it constrains the request.

After the visible body, append the exact finding-metadata marker as the final
nonblank line.

Use one idea per sentence. Name a function, field, or command only when the
reader needs it to understand or make the change. Prefer the concrete result
over a chain of internal calls. Use one minimal example only when it prevents
the reader from having to simulate a path, count, or state change.

Before emitting the body, run this author check:

- The first sentence says what breaks and when.
- The concrete bad result appears before internal implementation detail.
- Every required action and verification boundary appears in the request.
- Accepted behavior remains a boundary, not a separate action.
- No sentence repeats a fact without adding a condition, result, or boundary.
- A reader does not need to simulate a path or helper chain.

For an explicitly reintroduced author-resolved finding, put
`<!-- review-anvil: prior_feedback=reintroduced -->` before the final inline
metadata marker. Its inline item carries helper-only
`"prior_feedback": "reintroduced"`.

Use short everyday words. Prefer one clear sentence over a dense explanation.

```md
This entry point still builds the old argument namespace, so the handler reads
missing fields and fails before conversion.

Switch it to the shared parser and add one offline test covering the defaults.

<!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=cli -->
```

When one change has an accepted boundary, keep it in natural prose:

```md
Invalid populated cells currently disappear, and invalid denominators fall
back to 805.

Validate uncertainty, counts, and positive denominators separately while
keeping empty optional cells allowed.

<!-- review-anvil: id=RAV-RUN3-R1-F002 severity=medium area=input-validation -->
```

Keep only evidence that helps the author trust or fix the finding. Do not
narrate the investigation or list code terms without saying what they do here.
Use a short code sketch or exact replacement only when it removes doubt.

Voice rules:

- Address the code, never the author.
- Keep requested work calm, direct, and conversational.
- Do not use stock openers, review jargon, field labels, or compliment
  sandwiches.
- Severity determines placement; prose needs no alarm words or bold warnings.
- Keep the comment as short as the finding allows.
- Use a suggestion only for a safe, exact replacement; still explain the
  problem.

The same voice applies to visible top-level summaries and disposition prose.

## Checking uncertain findings

When a finding needs another check, keep reviewer counts, rounds, and
dispositions out of the visible summary. Describe only the code-facing outcome:
the affected behavior when confirmed, or the remaining runtime concern and
missing proof when uncertainty matters to the author.

Put exact check results and disposition accounting in collapsed
`Review context`. Confirmed findings appear in `Issues and fixes`; ruled-out
findings disappear; uncertain or outside-scope findings remain context rather
than active findings.

## Second check

When a second review runs, show only the final code-facing result. Do not expose
reviewer votes, rejected candidates, or kept/clarified/removed counts in the
visible summary. Fold confirmed corrections into the issue tables, omit removed
findings, and keep any useful explanation of changed or set-aside dispositions
inside collapsed `Review context`.

Keep reviewer counts, rounds, and dispositions out of the visible summary.
Inline comments contain only the final wording. Omit GitHub suggestion blocks
when the exact replacement is not safe.

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
