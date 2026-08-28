# Human-summary clarity assessment

## Decision

Keep the human-summary revision. It simplifies the actual language as well as
the Markdown: the top-level report becomes a short issue map, and the full
reasoning and requested work move to conversational inline comments.

Machine IDs, priority, area, report coordinates, and disposition now live in
hidden markers. The validator checks those fields structurally. Surface-specific
fact/action auditors still protect the visible prose.

## Comparison corpus

The frozen sample contains the same three prior `evaleval/every_eval_ever`
reviews used by the first clarity experiment:

- PR #190 review `4870915628`: 11 findings and 7 inline comments;
- PR #204 review `4884442134`: 5 findings and 3 inline comments;
- PR #230 review `4870883842`: 6 findings and 2 inline comments.

`clarity-v1-bundles.json` is the before side. `rendered-bundles.json` is the new
human-summary side. `before-after.md` renders both complete outputs.

`source-snapshot.json` contains the verbatim historical reports and comments
with per-body SHA-256 checksums. `extract-corpus.py` verifies those checksums
before regenerating `corpus.json`.

## Artifact size and default view

| Review | Current report | Human report | Raw report change | Current inline | Human inline | Inline reduction |
|---|---:|---:|---:|---:|---:|---:|
| PR #190 | 591 words | 665 words | +12.5% | 280 words | 261 words | 6.8% |
| PR #204 | 569 words | 576 words | +1.2% | 200 words | 159 words | 20.5% |
| PR #230 | 423 words | 493 words | +16.5% | 116 words | 83 words | 28.4% |

Raw Markdown is larger where the collapsed tables now retain complete issue and
action detail. The default visible prose remains short: PR #190 uses 21 words,
PR #204 uses 20, and PR #230 uses 28. IDs and areas remain hidden; severity,
location, issue, and suggested change appear only after expansion.

## Full-detail tables

`Issues and fixes` and `Optional suggestions` use fixed four-column tables.
Every row stays on one source line, ends with its hidden identity marker, and
escapes literal pipes as `\|`. The validator checks exact headers, severity,
location, row inventory, marker metadata, and section placement. The history
helper parses the fixed columns and marker instead of generic pipe splitting.

## Direct request voice

The first human-summary draft opened all 12 inline action paragraphs with
`Could you`. The final draft opens none that way. A deliberate collaborative
request may still use a courtesy wrapper sparingly; the rule targets stock
repetition, not the phrase itself. Required work defaults to its action verb,
optional low/nit work uses `Consider …`, and only a genuinely unresolved choice
uses question grammar.

This is renderer guidance, not a runtime English-grammar gate. The deterministic
validator intentionally does not parse prose style. Semantic auditors protect
facts, requiredness, optionality, and boundaries; blind judges evaluate voice.

## Reader-facing summary voice

Visible summaries describe the changed code rather than the review process.
Reviewer counts, rounds, candidates, confirmation mechanics, “survived review,”
and internal disposition vocabulary stay in collapsed context or disappear.
The renderer translates those outcomes into affected behavior, detected issue
areas, optional suggestions, or unreproduced uncertainty. It has no fixed
replacement phrase and no English phrase regex; semantic judges evaluate the
result.

The contract now treats review lifecycle as context rather than visible process
metadata. First reviews stay focused on the current code; follow-ups mention
earlier concerns only when a fixed, still-present, reintroduced, or new concern
creates a meaningful author-facing delta. Otherwise the same history-neutral
summary rules apply.

## Blind readability result

Three clean judges evaluated 15 randomized pairs: 3 complete reviews and 12
individual inline comments. Complete-review pairs contained the report and all
of its inline comments, so action completeness was judged across the artifact
rather than against the summary alone.

| Surface | Human wins | Current wins | Ties |
|---|---:|---:|---:|
| Complete reviews | 6 | 3 | 0 |
| Inline comments | 30 | 5 | 1 |
| **Total** | **36** | **8** | **1** |

No final human output received a hard fact/action failure.

Mean scores across all 45 judgments:

| Dimension | Current | Human | Delta |
|---|---:|---:|---:|
| Defect clarity | 4.978 | 4.933 | -0.045 |
| Action recall | 5.000 | 4.911 | -0.089 |
| Scanability | 4.911 | 4.000 | -0.911 |
| Naturalness | 3.889 | 4.933 | +1.044 |
| Cognitive ease | 4.067 | 4.822 | +0.755 |
| Plain language | 4.044 | 4.844 | +0.800 |

Six of nine complete-review judgments preferred the table-based human report;
all nine marked it fact-safe. The blind text extraction expands collapsed
tables, so its scanability score does not model GitHub's default compact view.
The aggregate also includes separately judged inline comments.

## Safety gates

The deterministic validator checks:

- exact decision and metadata/disposition inventories;
- complete modern and legacy report-ID inventory;
- hidden ID, priority, area, encoded report location, and disposition markers;
- active and deferred/outside item counts;
- configured inline-severity eligibility and exact inline anchors;
- one headingless visible summary line, canonical count-free collapsed labels,
  fixed full-detail table headers and columns, escaped single-line cells,
  terminal marker identity, complete envelope consumption, and the footer as
  the absolute final nonblank line after every helper marker;
- post-time history refresh fails closed when it would stale the compact
  summary;
- count-free fallback details and delivery metadata stay collapsed, including
  improve-PR success edits;
- suggestions, reintroduction state, and requested-work ledgers.

It does not judge prose style. Two bidirectional semantic auditors check each
surface with an explicit mode:

- `required` for critical/high/medium report-table and inline rows;
- `suggested` for low/nit report-table rows;
- `boundary` for deferred and outside-scope rows.

`fact-lock-audit-1.json` and `fact-lock-audit-2.json` each contain all 34
`(id, surface)` verdicts for the exact retained `action-audit-corpus.json` and
`action-audit-prompt.md`; both pass every row. The focused re-audit files retain
the categorical exact-miss check. The blind run uses that same final output.

## Limits

- The sample contains three historical reviews from one repository.
- The judges are clean model sessions, not a human PR-author timing study.
- Natural paragraph-style inline comments scored lower on narrow scanability
  than checklists, although the complete review became easier to scan.
- Prompt-following remains probabilistic; structural validation and the
  two-auditor fallback remain mandatory.
