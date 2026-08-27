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

## Size reduction

| Review | Current report | Human report | Report reduction | Current inline | Human inline | Inline reduction |
|---|---:|---:|---:|---:|---:|---:|
| PR #190 | 591 words | 432 words | 26.9% | 280 words | 254 words | 9.3% |
| PR #204 | 569 words | 428 words | 24.8% | 200 words | 151 words | 24.5% |
| PR #230 | 423 words | 370 words | 12.5% | 116 words | 82 words | 29.3% |

Raw Markdown retains lossless collapsed rows for history and fallback delivery.
The default visible prose is one sentence: PR #190 uses 21 words, PR #204 uses
26, and PR #230 uses 17. Issue rows, IDs, severity, areas, paths, and repeated
inline actions stay collapsed.

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

## Blind readability result

Three clean judges evaluated 15 randomized pairs: 3 complete reviews and 12
individual inline comments. Complete-review pairs contained the report and all
of its inline comments, so action completeness was judged across the artifact
rather than against the summary alone.

| Surface | Human wins | Current wins | Ties |
|---|---:|---:|---:|
| Complete reviews | 9 | 0 | 0 |
| Inline comments | 35 | 1 | 0 |
| **Total** | **44** | **1** | **0** |

No final human output received a hard fact/action failure.

Mean scores across all 45 judgments:

| Dimension | Current | Human | Delta |
|---|---:|---:|---:|
| Defect clarity | 5.000 | 5.000 | 0.000 |
| Action recall | 5.000 | 4.978 | -0.022 |
| Scanability | 4.867 | 4.733 | -0.134 |
| Naturalness | 3.867 | 4.933 | +1.066 |
| Cognitive ease | 3.822 | 4.867 | +1.045 |
| Plain language | 4.044 | 4.867 | +0.823 |

All nine complete-review judgments preferred the compact human report and
marked it fact-safe. The blind text extraction expands collapsed content, so
its 4.000 scanability score does not model GitHub's default one-sentence view;
the expanded current baseline scored 4.333.

## Safety gates

The deterministic validator checks:

- exact decision and metadata/disposition inventories;
- complete modern and legacy report-ID inventory;
- hidden ID, priority, area, encoded report location, and disposition markers;
- active and deferred/outside item counts;
- configured inline-severity eligibility and exact inline anchors;
- one headingless visible summary line, canonical count-free collapsed labels,
  full envelope consumption, footer placement, and report-item section
  placement;
- post-time history refresh fails closed when it would stale the compact
  summary;
- count-free fallback details and delivery metadata stay collapsed, including
  improve-PR success edits;
- suggestions, reintroduction state, and requested-work ledgers.

It does not judge prose semantics. Two bidirectional auditors check each
surface with an explicit mode:

- `summary` for report lines backed by emitted inline comments;
- `required` for inline comments and material report lines without one;
- `suggested` for low/nit guidance;
- `boundary` for deferred and outside-scope items.

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
