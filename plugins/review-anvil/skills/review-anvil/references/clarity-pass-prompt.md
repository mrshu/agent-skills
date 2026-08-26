# Final Clarity Pass

Use this prompt only after normal synthesis, prior-feedback classification,
reproduction, adversarial review, severity assignment, approval selection, and
anchor verification are complete. The input is a frozen fact packet, not
material for a new review.

## Purpose

Turn the final facts into one review that a busy author can scan and act on.
Rewrite both the top-level report and eligible inline comments in one pass so
they use the same wording and priorities. Improve structure and plainness only.
Do not add, remove, merge, split, reprioritize, or resolve findings.

Research only. Do not inspect the repository, use tools, run commands, edit
files, stage changes, commit, push, or post to GitHub. Do not infer facts from
paths, identifiers, titles, or requested work. Apply the author-facing profile
in `asd-ste100-inspired.md` to generated prose while preserving every evidence
token and frozen predicate.

## Quick reference

| Surface | Required shape |
|---|---|
| Top-level report | Decision, result, each finding once with impact and requested change, collapsed support detail |
| Inline comment | Natural title, problem and impact, exact requested work, terminal metadata marker |
| Validation ledger | Byte-identical report items, exact predicate inventory, unchanged anchors and suggestions |
| Audit | Independent report/inline rows with severity-derived request mode |
| Failure | Exact-source or pre-clarity fallback and `COMMENT` |

## Input

You receive one JSON object named `FROZEN_CLARITY_PACKET`:

```json
{
  "decision": "APPROVE | COMMENT",
  "report_ids": ["RAV-RUN3-R2-F001", "RAV-RUN1-R1-F004"],
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
      "source_context": "minimum exact context needed to render the finding",
      "fact_lock": ["exact actor/action/target, condition, certainty, impact, or preservation predicate"],
      "requested_work": ["exact author-work predicate"],
      "prior_feedback": "reintroduced",
      "suggestion": "optional exact safe replacement"
    }
  ],
  "set_aside": ["frozen one-line disposition"],
  "outside_scope": ["frozen one-line follow-up"],
  "run_details": ["exact run-detail line"]
}
```

Absent optional anchor fields stay absent. `requested_work` can be empty. The
packet contains the complete final inventory. Raw reviewer transcripts, failed
candidate findings, and superseded wording are intentionally absent.

Inline anchors and report locations are independent. Use `path`, `start_line`,
and `line` only for `.inline.json`. Use `report_path`, `report_start_line`, and
`report_line` only for the top-level finding. Either surface can be unanchored.

`report_ids` is the complete report identity inventory. It contains every
current finding ID and each identified earlier-feedback ID that must remain in
the report. Put every listed ID exactly once in `report_markdown`. Create
`report_items` and `predicate_inventory` rows only for current `findings`;
earlier-feedback IDs stay in their status lines.

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
  "report_markdown": "complete external report",
  "report_items": [
    {"id": "RAV-RUN3-R2-F001", "prior_feedback": "reintroduced", "rendered_body": "byte-identical complete finding bullet copied from report_markdown"}
  ],
  "inline_comments": [
    {
      "path": "src/auth.ts",
      "start_line": 48,
      "line": 50,
      "side": "RIGHT",
      "start_side": "RIGHT",
      "severity": "high",
      "body": "complete inline body ending in the finding marker",
      "suggestion": "optional exact safe replacement",
      "prior_feedback": "reintroduced"
    }
  ],
  "predicate_inventory": [
    {"id": "RAV-RUN3-R2-F001", "requested_work": ["exact author-work predicate"]}
  ]
}
```


Copy every frozen metadata and disposition field byte-for-byte into
`metadata_inventory`. Keep each nonempty value verbatim in `report_markdown`;
structure and collapse it without paraphrasing. The validator compares both the
ledger and visible report.
Copy `decision` unchanged. Copy every `requested_work` array byte-for-byte and
in order into `predicate_inventory`; this is a validation ledger, not visible
report prose. Copy anchor fields, severity, area, every safe exact `suggestion`,
and helper-only `prior_feedback` unchanged. Do not emit an inline item for an
unanchored low or nit finding.

## Top-Level Report Recipe

Write a decision summary followed by the active findings. Show each active
finding once, with its impact and requested change together. Do not repeat
findings in a separate action-plan section. Each finding body in `report_items`
must occur byte-identically once in `report_markdown` and contain its canonical
finding ID exactly once, at the end in parentheses.
After the visible ID, append
`<!-- review-anvil-report: severity=<severity> area=<area> -->` on the same
line. Copy severity and area from the frozen finding. This hidden presentation
metadata lets history parsing retain priority and topic without adding visible
labels. It contains no ID.
Copy the exact report `path:line` or `path:start-line` for every finding with
`report_path` and `report_line`, and place it in backticks immediately after the
bold title. Omit the location only when the report location is absent.

For a reintroduced finding, copy `"prior_feedback": "reintroduced"` into its
report item and inline item. Put
`<!-- review-anvil: prior_feedback=reintroduced -->` on the line immediately
after the byte-identical report item. Keep the existing inline-marker insertion
contract unchanged.

Each active bullet has exactly four visible parts:

1. The bold text is only the natural failure title.
2. The exact code location follows in backticks when the finding is anchored.
3. After the dash, plain prose gives the trigger or mechanism, concrete impact,
   requested behavior, and supplied verification, when any.
4. The final parenthesis contains only the stable finding ID.

Do not add field labels such as `Finding`, `Trigger`, `Impact`, `Requested change`, or `Finding ID`.
A finding with no requested verification gets none. Do not add a test purpose, outcome, or success condition that is absent from `requested_work`.

Use this shape:

```md
# Review result

**COMMENT** — <decision reason>

<one short result sentence>

## Needs attention

- **<natural failure title>** `<path:line>` — <trigger/mechanism and concrete impact> <requested behavior and required verification, when any>. (`RAV-RUN3-R2-F001`) <!-- review-anvil-report: severity=high area=auth -->

<details>
<summary>Earlier review comments (N)</summary>

- **<status>** — <exact text> <exact URL> (`<finding ID>`)

</details>

Each identified earlier-feedback line uses the exact shape above. Copy status,
text, URL, and ID without paraphrasing. Omit the final ID parenthesis only when
the frozen entry has no `id`.

<details>
<summary>Run details</summary>

<exact run details>

</details>
```

Use `## Findings` instead of `## Needs attention` when the decision is
`APPROVE` and only non-blocking items remain. Put critical, high, and medium
items in the visible section. Low and nit report items keep suggestion grammar.
They must not become mandatory author work. Collapse low/nit items when there
are any. Omit empty sections. Collapse earlier feedback,
set-aside/outside-scope items, and run details. A critical/high blocker must
never exist only inside a collapsed section.

Keep the summary concrete. Do not repeat decision, counts, scope, check counts,
or the same issue in adjacent prose. Put scope in Run details unless it is
needed to understand the decision. Do not include the ID legend; IDs are stable
references, not reading instructions.

## Inline Recipe

For each anchored finding at or above `inline_min_severity`, follow the
inline-comment voice in `report-artifacts.md`:

1. Natural bold failure title without visible ID, severity, or area.
2. The smallest problem and impact explanation not already stated by the title.
3. Every required author action. Use one `Please` sentence for one obligation;
   use `**What to change**` bullets for two or more obligations.
4. Accepted current behavior and optional follow-ups remain modal prose, never
   action bullets.
5. The exact terminal finding marker as the final line.

Findings below `inline_min_severity` remain summary-only. Emit anchored inline
comments at or above the frozen threshold. Keep every safe exact `suggestion`
byte-identical. Do not convert prose into a GitHub suggestion or alter a
suggestion during copy editing.

## Fact and Action Lock

For each report item and inline body, map every sentence to the supplied
`fact_lock`, `source_context`, or `requested_work` entry. Preserve technical
verbs, actors, targets, conditions, quantifiers, scope, certainty, concrete
results, and no-change boundaries. A shorter sentence is not clearer when it
changes one of those facts.

Build a semantic union of `requested_work` entries. Render each distinct action,
verification boundary, and no-change boundary once. Equivalent source phrasings
can map to one rendered predicate when that predicate preserves every actor,
target, condition, scope word, and result from both. Keep the original arrays
unchanged in `predicate_inventory`; do not repeat synonymous prose to mirror
the ledger's row count.

Every requested-work predicate must remain visible on both surfaces as
required or suggested work according to its request mode. Do not make requested
behavior sound already implemented. Do not promote an allowed boundary or
optional follow-up into author work. Do not invent a rationale for a test.

## Common rendering mistakes and red flags

Stop and restore the frozen wording for the affected sentence when any of these
occurs:

- A finding, action, condition, exception, identifier, or suggestion disappears.
- A finding appears twice in the report.
- The decision, priority, disposition, anchor, or certainty changes.
- A desired state reads as current code behavior.
- A report action contradicts its inline action.
- A sentence needs repository knowledge that is absent from the packet.
- Removing words makes the actor, trigger, target, or result ambiguous.

## Complete Example

Input finding: `RAV-RUN2-R1-F003`, medium `cli`, anchored at
`every_eval_ever/cli.py:383`; the module entry point builds the old namespace,
the changed handler reads missing fields and fails before conversion; requested
work is exactly “Use the shared top-level parser in the module entry point.” and
“Add one offline entry-point test.”

```json
{
  "decision": "COMMENT",
  "report_markdown": "# Review result\n\n**COMMENT** — One conversion blocker remains.\n\n## Needs attention\n\n- **The module entry point builds the old argument namespace** `every_eval_ever/cli.py:383` — The changed handler reads missing fields and fails before conversion. Use the shared top-level parser in the module entry point and add one offline entry-point test. (`RAV-RUN2-R1-F003`) <!-- review-anvil-report: severity=medium area=cli -->",
  "report_items": [
    {
      "id": "RAV-RUN2-R1-F003",
      "rendered_body": "- **The module entry point builds the old argument namespace** `every_eval_ever/cli.py:383` — The changed handler reads missing fields and fails before conversion. Use the shared top-level parser in the module entry point and add one offline entry-point test. (`RAV-RUN2-R1-F003`) <!-- review-anvil-report: severity=medium area=cli -->"
    }
  ],
  "inline_comments": [
    {
      "path": "every_eval_ever/cli.py",
      "line": 383,
      "side": "RIGHT",
      "severity": "medium",
      "body": "**The module entry point builds the old argument namespace**\n\nThe changed handler reads missing fields and fails before conversion.\n\n**What to change**\n\n- Use the shared top-level parser in the module entry point.\n- Add one offline entry-point test.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=cli -->"
    }
  ],
  "predicate_inventory": [
    {
      "id": "RAV-RUN2-R1-F003",
      "requested_work": [
        "Use the shared top-level parser in the module entry point.",
        "Add one offline entry-point test."
      ]
    }
  ]
}
```
