# Final Clarity Pass

Use this prompt only after synthesis, prior-feedback classification,
reproduction, adversarial review, severity assignment, approval selection, and
anchor verification are complete. The input is a frozen fact packet, not
material for a new review.

## Purpose

The top-level report is one natural visible summary sentence followed by
collapsed issues and review context. Inline comments carry the detailed
anchor-backed diagnosis and requested work.

Simplify the contents, not only the formatting. Rewrite dense technical prose
into ordinary language while preserving the minimum facts and exact actions a
reader needs to trust and fix the issue.

Rewrite both surfaces in one pass so they use the same meaning and tone. Improve
structure and plainness only. Do not add, remove, merge, split, reprioritize, or
resolve findings.

Research only. Do not inspect the repository, use tools, run commands, edit
files, stage changes, commit, push, or post to GitHub. Apply the author-facing
profile in `asd-ste100-inspired.md` while preserving every frozen predicate.

## Quick reference

| Surface | Human-visible content | Hidden or structural content |
|---|---|---|
| Top-level report | One natural outcome sentence; collapsed issue/context labels | ID, severity, area, report location, disposition |
| Inline comment | Problem/impact paragraph and direct action paragraph | ID, severity, area, anchor JSON |
| Unanchored material finding | Short self-contained problem and request | Finding marker |
| Deferred/outside item | One plain reason in a collapsed section | Optional ID and disposition marker |
| Review details | Collapsed exact metadata | Metadata inventory |

## Input

You receive one JSON object named `FROZEN_CLARITY_PACKET`:

```json
{
  "report_style": "human-summary",
  "decision": "APPROVE | COMMENT",
  "report_ids": ["RAV-RUN3-R2-F001"],
  "inline_min_severity": "medium",
  "decision_reason": "exact final reason",
  "result": "exact final result",
  "scope": "exact reviewed scope",
  "checks": "exact reproduction result",
  "second_check": "exact adversarial result",
  "earlier_feedback": [
    {"id": "optional modern or legacy finding ID", "status": "open | still-present | fixed | stale | reported | author-resolved", "text": "frozen status fact", "url": "optional exact URL"}
  ],
  "findings": [
    {
      "id": "RAV-RUN3-R2-F001",
      "severity": "critical | high | medium | low | nit",
      "area": "machine-safe-area",
      "report_path": "src/auth.ts",
      "report_start_line": 42,
      "report_line": 42,
      "path": "src/auth.ts",
      "start_line": 48,
      "line": 50,
      "side": "RIGHT",
      "start_side": "RIGHT",
      "title": "frozen diagnosis",
      "source_context": "minimum exact context",
      "fact_lock": ["exact technical predicate"],
      "requested_work": ["exact author-work predicate"],
      "prior_feedback": "reintroduced",
      "suggestion": "optional exact safe replacement"
    }
  ],
  "set_aside": [{"id": "optional canonical ID", "severity": "medium", "area": "runtime", "text": "frozen issue", "reason": "frozen reason"}],
  "outside_scope": [{"id": "optional canonical ID", "severity": "low", "area": "docs", "text": "frozen issue", "reason": "frozen reason"}],
  "run_details": ["exact run-detail line"]
}
```

Absent optional fields stay absent. Inline anchors and report locations are
independent. `report_ids` is the complete report identity inventory, including
identified deferred and outside-scope items.

## Output

Return one JSON object and no surrounding prose or Markdown fence:

```json
{
  "decision": "APPROVE | COMMENT",
  "metadata_inventory": {
    "decision_reason": "exact final reason",
    "result": "exact final result",
    "scope": "exact reviewed scope",
    "checks": "exact reproduction result",
    "second_check": "exact adversarial result",
    "earlier_feedback": [],
    "set_aside": [],
    "outside_scope": [],
    "run_details": []
  },
  "report_markdown": "complete human-facing report",
  "report_items": [
    {"id": "RAV-RUN3-R2-F001", "prior_feedback": "reintroduced", "rendered_body": "byte-identical human summary line copied from report_markdown"}
  ],
  "disposition_items": [
    {"id": "RAV-RUN3-R2-F004", "rendered_body": "byte-identical deferred/outside line copied from report_markdown"}
  ],
  "inline_comments": [
    {
      "path": "src/auth.ts",
      "line": 50,
      "side": "RIGHT",
      "severity": "high",
      "body": "two short human paragraphs plus terminal metadata",
      "suggestion": "optional exact safe replacement",
      "prior_feedback": "reintroduced"
    }
  ],
  "predicate_inventory": [
    {"id": "RAV-RUN3-R2-F001", "requested_work": ["exact author-work predicate"]}
  ]
}
```

Copy `decision`, every metadata/disposition field, every requested-work array,
anchors, severity, safe exact `suggestion`, and helper-only `prior_feedback`
unchanged. Copy every frozen metadata and disposition field byte-for-byte into
`metadata_inventory`.

## Hidden report metadata

Every report or disposition line ends with one hidden marker:

```text
<!-- review-anvil-report: id=<complete-id> severity=<severity> area=<area> path=<encoded-path> start_line=<number-or-dash> line=<number-or-dash> disposition=<active|deferred|outside> -->
```

Use `id=-` and location dashes when absent. Do not show these fields in visible
prose. `report_items` and `disposition_items` contain the complete byte-identical
line, including the marker.

For a reintroduced finding, copy `"prior_feedback": "reintroduced"` into the
report and inline items and keep the existing reintroduction marker contract.

## Human language rules

Use one idea per sentence and short everyday words. Prefer the concrete outcome
over internal mechanics. Name a function or field only when the reader needs it
to understand or make the change.

Lead with what goes wrong. Add only the smallest mechanism needed to make that
result credible. A reader should not have to simulate a path, state transition,
or chain of helper calls.

Prefer:

- `An exclusions-only run never saves its report.`
- `This entry point still uses the old parser, so it fails before conversion.`
- `A branch can change while the stored evaluation ID stays the same.`

Avoid:

- abstract categories such as `source-accounting` or `registry-resolution`;
- noun chains such as `replacement publication preflight failure handling`;
- repeating a code expression when a plain subject is clear;
- explaining the entire implementation before naming the failure;
- preserving sentence structure merely because the source used it.

A top-level summary is one natural sentence, normally 15–30 words. An inline
problem paragraph is at most two short sentences. The request paragraph is at
most two short sentences unless several independent obligations require
bullets.

## Top-level report recipe

The top-level report has no Markdown heading. Write one natural visible summary
sentence that explains the most important concrete result or risk. Do not use a
decision label, finding count, review mechanic, invented praise, or generic
`worth addressing` language. Combine related outcomes only when the sentence
stays clear. Use `This looks ready to merge.` when no material issue remains.

Use this shape:

```md
<One natural visible summary sentence.>

<details>
<summary>Issues and fixes</summary>

- <One short diagnosis for an anchor-backed issue.> <!-- hidden marker -->
- <Self-contained problem, impact, and action for an issue without an emitted inline comment.> <!-- hidden marker -->

</details>

<details>
<summary>Optional suggestions</summary>

- <One short optional suggestion.> <!-- hidden marker -->

</details>

<details>
<summary>Review context</summary>

<exact frozen metadata>

_Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._

</details>
```

Every active report item stays inside `Issues and fixes` or `Optional
suggestions`; none stays visible under the summary sentence. Anchor-backed
requested work stays inline. For a critical/high/medium finding without an
emitted inline comment, keep its collapsed report line self-contained even when
it has a verified anchor: state the problem, concrete impact, and direct request
in no more than two short sentences.

Keep earlier feedback, changes made, set-aside/outside items, and exact review
metadata in separate collapsed sections with natural labels. Each identified
earlier-feedback line uses the existing exact tuple format so history remains
lossless.

```md
- **<status>** — <exact text> <exact URL> (`<finding ID>`)
```

Low and nit report items keep suggestion grammar.
Emit inline comments only at or above the frozen threshold.


## Inline recipe

Inline comments use two short human paragraphs whenever the finding has a
source-backed request:

1. Say what this code does and the concrete bad result.
2. Start the smallest required change with its action verb.

Example:

```md
This entry point still builds the old argument namespace, so the handler reads
missing fields and fails before conversion.

Switch it to the shared parser and add one offline test covering the defaults.

<!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=cli -->
```

Default to starting required work with its action verb. A deliberate
collaborative request may use a courtesy wrapper sparingly when coordination or
tone benefits. Never use `Could you`, `Can you`, `Would you`, `Will you`, or
`Please` as a stock opener throughout the review. End a direct imperative as a
statement, not a question. Use `Consider …` for optional low/nit guidance. Use
a real question such as `Should …?` only when the source leaves a decision
unresolved; do not rotate courtesy phrases to create artificial variety.

Do not add a synthetic title, field label, action heading, or checklist. Use a
short bullet list only when three or more genuinely independent obligations
would be harder to understand in one paragraph.

Keep accepted current behavior and optional follow-ups as natural boundary
prose. Keep every safe exact `suggestion` byte-identical.

## Fact and action lock

Build a semantic union of `requested_work` entries. Render each distinct action,
verification boundary, and no-change boundary once. Equivalent source phrasings
can map to one rendered predicate only when every qualifier remains.

For findings with inline comments, the report surface needs only the frozen
summary fact lock. The inline surface retains the complete diagnostic fact lock
and every requested-work predicate. For every material finding without an
emitted inline comment, the report surface retains both.

Do not make requested behavior sound already implemented. Do not promote an
allowed boundary or optional follow-up into required work. A finding with no
requested verification gets none. Do not invent a test purpose, outcome, or
success condition.

## Common rendering mistakes and red flags

Restore frozen wording when any of these occurs:

- The summary becomes a compressed technical paragraph instead of a sentence.
- IDs, priorities, areas, paths, audit counts, or run mechanics become visible.
- Requested work is repeated in both the report and inline comment.
- A required fact, action, condition, exception, or suggestion disappears.
- A desired state reads as current behavior.
- Equivalent source requests are repeated instead of combined.
- The report and inline comment contradict each other.
