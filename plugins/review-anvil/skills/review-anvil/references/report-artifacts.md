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

Compose each `body` as complete, code-anchored prose. Inline comments are for localized `critical`/`high`/`medium` findings by default; `low`/`nit` findings usually belong only in the top-level summary. For material findings, use three short parts; for simple findings, one or two short paragraphs is enough. Do not rely on the posting helper to shorten or summarize: if a draft is too bulky for a PR reader, rewrite it yourself while preserving the concrete mechanism, consequence, fix path, and test signal.

```
**[medium] error-handling** — `save_user` returns success when the INSERT fails

The `try/except` at line 142 catches `Exception` and logs at debug level, so a
failed write still returns `True`. `signup_flow` (src/auth.py:88) treats that as
a completed signup — the user sees success while no row was written.

Could this handler catch only the driver's retryable `OperationalError`,
re-raise the rest, and log at `error` with the user id? A test that makes the
INSERT raise and asserts `save_user` propagates the error covers this case.
```

1. **Header line** — severity tag, area, one-line statement of the *observable* problem (what goes wrong, not which rule is broken).
2. **Mechanism** — how the code produces the problem and one concrete downstream consequence, anchored to files/lines/functions. Explain the failure; don't cite doctrine — every claim ties to *this* code, never to "best practices" in the abstract.
3. **Fix path** — phrase the change as a polite implementation question when it reads naturally ("Could this handler catch ...?"), then include enough specifics to implement without re-investigation: what to change, where, the intended behavior afterwards, and the most important test or edge case. Include a small code sketch or exact replacement when it materially reduces ambiguity.

Voice rules:

- Address the code, never the author: "the handler swallows the error", not "you swallow the error". No "should have", no "Obviously / Clearly / Simply / Just".
- Calm and specific beats emphatic. The severity tag carries the urgency; the prose needs no alarm words, bold warnings, exclamation marks, or rhetorical/scolding questions.
- When the PR's approach is sound and the finding is an edge of it, say so in one honest clause ("the retry loop is right; the timeout just needs to cover it") — genuine context, not a compliment sandwich.
- Target enough space for the author to implement without re-reading the whole diff; 150-250 words is normal for material findings, and longer is acceptable when the fix needs a code sketch. A one-liner can be fine for low/nit/simple findings; an essay reads as a lecture.
- Use helper-only `.inline.json` `"suggestion"` for exact replacements that GitHub can apply to the commented line/range whenever it makes the fix clearer. The regular `body` must still stand on its own; the suggestion is executable context, not a substitute for the explanation. If the exact replacement is unsafe because the fix is cross-file, multi-step, or requires judgment, include a concise fenced code sketch in the `body` instead of a helper suggestion.

The same voice applies to the report body's Suggestions, Deferred, and Out-of-scope follow-ups prose.

## Reproduction summary

When reproduction runs, the PR-facing report should show only the accounting and
the resulting guidance. Do not paste reproduction transcripts or long rejected
finding analysis into the PR timeline.

Use one accounting line near the top of the report:

```md
**Reproduction:** 4 candidates; 2 confirmed, 1 downgraded, 1 deferred after
failed reproduction.
```

Then fold effects into the normal sections:

- Confirmed and narrowed findings appear in `## Findings` using their survivor
  wording.
- Refuted findings disappear from `## Findings` unless a one-line Deferred note
  helps explain why a likely-looking issue was not posted.
- Unclear findings move to `## Deferred / Out-of-Scope` with
  `failed reproduction: <reason>`.
- Downgraded findings follow the normal severity gates after downgrade.

## Adversarial review summary

When adversarial review is enabled, the PR-facing report should show only the
verdict summary and the resulting final guidance. Do not paste adversarial
transcripts, reviewer disagreement, or rejected-finding essays into the PR
timeline.

Use one accounting line near the top of the report:

```md
**Adversarial review:** targeted, 2 agents; 5 upheld, 1 simplified, 1 deferred as disproportionate, 1 dropped as false positive.
```

Then fold effects into the normal sections:

- Dropped false positives disappear from `## Findings` unless the rejection is
  useful enough to mention in a collapsed deferred note.
- Harmful, bloated, or tech-debt-heavy fix plans move to `## Deferred /
  Out-of-Scope` with a one-line reason.
- Hardened or simplified fix paths replace the original would-apply prose.
- Inline comments contain only the survivor version; no "reviewer A disagreed"
  narration.
- GitHub suggestion blocks are omitted when adversarial review disputes the
  anchor, exact replacement, or blast radius.

Example deferred line:

```md
- **RAVW002 [medium] config** — deferred after adversarial review:
  disproportionate fix; adds a registry for a one-line default.
```

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
