# review-anvil provenance identifiers

## Problem

review-anvil currently assigns report-local finding IDs such as `RAVF001` and
would-apply IDs such as `RAVW001`. The IDs distinguish items inside one report,
but they do not show which review-anvil run or reviewer round first produced an
item. Repeated reviews on one PR are therefore harder to discuss and trace.

## Goals

- Encode the PR-wide review-anvil run and the item's origin round in each new
  PR-backed identifier.
- Keep identifiers stable after assignment.
- Make identifiers readable in GitHub tables, inline comments, prompts, logs,
  and copied references.
- Share one PR run sequence across read-only and improve modes.
- Avoid claiming a PR run number when no reliable PR history is available.
- Continue reading historical identifier forms without emitting them in new
  reports.

## Non-goals

- A globally unique identifier independent of the PR and its review-anvil UUID
  marker.
- An exact distributed counter for concurrent review-anvil runs.
- A persistent cross-run counter for local, non-PR reviews.
- Retrospective reconstruction of unknown run or round data for legacy IDs.

## Canonical format

PR-backed items use:

```text
RAV-RUN<run>-R<origin-round>-F<ordinal>
RAV-RUN<run>-R<origin-round>-P<ordinal>
```

Examples:

```text
RAV-RUN3-R2-F001
RAV-RUN3-R2-P001
```

Local items, and PR items for which the run ordinal cannot be established,
omit the `RUN` segment:

```text
RAV-R2-F001
RAV-R2-P001
```

The segments mean:

- `RAV`: review-anvil namespace.
- `RUN3`: the third finalized review-anvil report observed on this PR.
- `R2`: the normal reviewer round in which the item first received an ID.
- `F` or `P`: finding or plan.
- `001`: the item's type-specific, run-wide ordinal.

Run and round numbers are positive, unpadded decimal integers. Item ordinals are
positive decimal integers emitted with a minimum width of three digits. They
continue from `999` to `1000` without a format change.

The canonical grammar is:

```regex
RAV-(?:RUN([1-9][0-9]*)-)?R([1-9][0-9]*)-([FP])([0-9]{3,})
```

Parsing also validates that the item ordinal is at least one. Parsers compare
and sort the numeric captures as integers rather than sorting complete IDs as
raw strings.

Author-facing reports include one short legend near the first identifier:

```text
RUN = review-anvil report number on this PR; R = origin round;
F = finding; P = plan.
```

## PR run numbering

The PR presets derive the next run ordinal from the finalized review-anvil
reports already visible in the PR's reviews and issue comments:

```text
next run = count of distinct finalized review-anvil reports + 1
```

The count follows these rules:

- Read-only and improve reports share one sequence.
- Successful and published failure reports both count.
- A starting comment that was never replaced by a final or failure report does
  not count.
- Duplicate representations of one report are coalesced by their review-anvil
  UUID marker when possible.
- Legacy finalized review-anvil reports count even when their item IDs do not
  contain a run segment.
- If complete PR history cannot be read, the run segment is omitted instead of
  emitting an invented value.

This is a best-effort ordinal, not a distributed lock. Two runs that inspect the
same PR history concurrently can receive the same run number. The existing UUID
marker remains the canonical collision-resistant run identity. Exact concurrent
allocation would require a server-backed reservation and is outside this
change.

## Origin and stability

A normal requested or adaptive reviewer wave is a round. Reproduction and
adversarial passes are synthesis gates, not rounds.

An item receives its ID after same-round synthesis, semantic deduplication,
prior-feedback classification, and scope filtering, but before reproduction or
adversarial dispatch. Assignment follows these invariants:

- A finding raised by multiple reviewers in one round receives one finding ID.
- A finding re-raised in a later round of the same run retains its original ID.
- A known finding carried from a modern earlier PR report retains its original
  ID; the `RUN` and `R` segments identify where it originated, not where it was
  mentioned most recently.
- Confirmation, refutation, narrowing, priority changes, deferral, fixes, and
  verification outcomes do not renumber an item.
- Dropped or superseded items leave permanent gaps. Ordinals are never reused.
- Findings and plans have independent monotonic counters that span the entire
  run and do not reset each round.
- A plan's origin round is the round in which that concrete fix group was first
  assembled. It can cover findings from different rounds or earlier runs.
- Adding a covered finding does not change a plan ID when the intended fix group
  remains the same. A material split or merge creates new plan IDs and leaves
  the prior plans as superseded records.

Assignment order must not depend on reviewer completion timing. After synthesis,
findings use stable report order: priority, normalized path, line, then topic.
Plans use the highest priority of their covered findings, then normalized area
and proposed subject.

## Reports and data flow

The PR preset resolves the run ordinal while it gathers the target and review
history. It supplies the optional run ordinal to the engine with the target
context. The engine owns round and item assignment.

The same complete identifier is used in:

- reproduction candidates and verdicts;
- adversarial findings and plan verdicts;
- final report tables and bullets;
- inline GitHub comments;
- plan-to-finding references;
- follow-up artifacts and prior-feedback parsing.

Report metadata states whether the run ordinal was available. Local reports use
the canonical local form and do not maintain a machine-local counter.

## Migration

New reports emit only the new `F` and `P` forms. Historical parsing remains a
read boundary and accepts:

- `RAVF001` and `RAVW001`;
- `F-001` and `W-001`;
- the new PR-backed and local forms.

Legacy identifiers are never rewritten in existing PR content. A legacy finding
whose origin is unknown is not assigned invented run or round values. If the
same concern becomes an actionable item in a new run, it receives a new
canonical ID and records the legacy report URL or ID as its source alias.

The parser must match complete identifier tokens. The new grammar begins with
`RAV-`, so it cannot be accidentally consumed by the old `RAVF[0-9]+` or
`RAVW[0-9]+` forms.

## Failure and edge cases

- Missing or degraded PR history: omit `RUN`; state that the PR run ordinal was
  unavailable.
- Concurrent PR runs: duplicate best-effort run ordinals are allowed; UUID
  markers disambiguate the reports.
- Published failure report: counts as a finalized run and preserves every ID
  already assigned in that run.
- Failure before a report exists: does not count as a finalized run.
- Refuted candidate: its ID is not reused.
- Regressed fixed finding: retain the original finding ID and record the new
  observation separately.
- Distinct root cause at the same code location: assign a new finding ID.
- File or line movement: does not by itself change identity.
- More than 999 items: continue with `F1000` or `P1000`.

## Verification strategy

Deterministic contract tests cover:

- parsing and rejecting canonical and malformed new identifiers;
- reading historical identifiers without emitting them;
- PR and local formatting;
- run counting across read-only, improve, success, failure, legacy, duplicate,
  and incomplete starting comments;
- omission of `RUN` when history is unavailable;
- stable IDs across reproduction, adversarial review, later rounds, and status
  changes;
- deterministic assignment independent of reviewer completion order;
- independent run-wide finding and plan sequences;
- helper parsing of report tables, bullets, and inline comments containing the
  new IDs;
- the documented best-effort collision behavior for concurrent snapshots.
