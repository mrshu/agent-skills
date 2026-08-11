# Review-Anvil Maximum-Human Inline Comments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace visible review-anvil IDs, severity tags, and area labels in GitHub inline comments with natural titles while preserving exact machine identity in a hidden HTML comment.

**Architecture:** Overall review reports keep their visible finding rows. Each eligible `.inline.json` body starts with `**<finding title>**` and ends with one `<!-- review-anvil: id=<complete-id> severity=<severity> area=<area> -->` line. `pr-helper.sh` treats that marker as authoritative metadata, preserves it as the final line when it inserts suggestions or reintroduction state, and continues to read legacy visible labels.

**Tech Stack:** Markdown skill contracts, Bash, embedded Python 3, `jq`, fake-`gh` end-to-end shell tests, clean `omp` generation and judging.

## Global Constraints

- Keep `<!-- review-anvil-marker: UUID -->` unchanged; it identifies a run rather than a finding.
- Keep `<!-- review-anvil: prior_feedback=reintroduced -->` unchanged and before the final finding-metadata marker.
- The finding marker is presentation hiding, not secrecy; it contains no sensitive data.
- Overall report rows, reproduction targets, and adversarial targets keep complete visible IDs.
- Legacy inline bodies beginning with `**<complete-id> [<severity>] <area>**` remain readable.
- Suggestions and helper-only JSON fields keep their current safety and stripping behavior.
- Do not push, post, or otherwise write to GitHub.

---

### Task 1: Hidden Metadata Runtime Contract

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh`
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh`

**Interfaces:**
- Consumes: `.inline.json` bodies ending in `<!-- review-anvil: id=<complete-id> severity=<severity> area=<machine-token> -->`.
- Produces: GitHub comment payloads with the same marker as the final line; history entries with the marker's ID and severity; legacy-label compatibility.

- [ ] **Step 1: Add a failing inline-processing test**

Add `test_process_inline_preserves_terminal_finding_metadata`. Its fixture contains a natural title, a suggestion, helper-only `prior_feedback`, and a final high-severity marker. Add a low-severity natural body whose severity exists only in its marker. Assert that processing:

```text
- filters the low item at the default medium threshold;
- strips helper-only fields;
- inserts the suggestion and reintroduced marker before the finding marker;
- leaves exactly one finding marker as the final body line.
```

- [ ] **Step 2: Add a failing history test**

Add `test_history_parses_hidden_inline_metadata`. Feed the real `history` command a fake GraphQL review thread whose root body is:

```md
**`--replace-existing` can remove the only good copy before replacement is ready**

The old files are deleted before the replacement is validated.

Please keep the old files recoverable until the replacement completes.

<!-- review-anvil: id=RAV-RUN5-R1-F001 severity=high area=publication -->
```

Assert the output contains the `high` severity, `publication` area, natural title, and `id=RAV-RUN5-R1-F001`. Add a mixed-history case proving that the same hidden ID matches despite rewritten prose, while identical prose with two different valid IDs stays distinct.

- [ ] **Step 3: Run the focused test and confirm RED**

Run:

```bash
bash skills/review-anvil-pr/scripts/test-pr-helper.sh
```

Expected: failure because the current processor appends helper additions after the marker and neither severity nor identity parsers understand the marker.

- [ ] **Step 4: Implement marker-aware processing**

In `process_inline_comments_for_github`, add a strict finding-marker regex for the complete ID grammar, five severity names, and a machine-safe area token. Make marker severity the first fallback after helper-only `severity`. Add one insertion helper that splits a valid terminal marker from visible prose, inserts a suggestion or reintroduction marker, then restores the finding marker as the final line. Keep old behavior when no valid terminal marker exists.

- [ ] **Step 5: Implement marker-aware history parsing**

In the history engine's embedded Python, add unfenced finding-marker parsing and natural bold-title parsing. Consult hidden metadata before legacy visible labels in `severity_from_body` and `finding_id_from_body`. Use marker area plus natural title in `signature` and `summary`, while retaining all existing report/table/legacy fallbacks. Attach parsed identity to inline and visible-report delivery candidates. When both candidates have valid IDs, make exact identity authoritative before fuzzy prose matching; use fuzzy matching only for legacy/mixed bodies where one side has no comparable ID.

- [ ] **Step 6: Run the focused test and confirm GREEN**

Run:

```bash
bash skills/review-anvil-pr/scripts/test-pr-helper.sh
```

Expected: `test-pr-helper: all e2e checks passed`.

### Task 2: Generator and Artifact Contract Cutover

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil/SKILL.md`
- Modify: `plugins/review-anvil/skills/review-anvil/references/report-artifacts.md`
- Modify: `plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh`
- Modify: `plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh`

**Interfaces:**
- Consumes: finalized finding title, complete ID, severity, area, evidence, and exact requested-work predicates.
- Produces: natural inline bodies with the machine marker last; unchanged visible report identity.

- [ ] **Step 1: Change contract tests first**

Update the identifier and language contract checks so they require this body shape:

```md
**<finding>**

<problem and consequence>

<request when source-backed work exists>

<!-- review-anvil: id=<complete-id> severity=<severity> area=<area> -->
```

Require that the UUID run marker remains distinct, that the finding marker is final, and that `prior_feedback=reintroduced` precedes it.

- [ ] **Step 2: Run contract tests and confirm RED**

Run:

```bash
bash skills/review-anvil/scripts/test-identifiers.sh
bash skills/review-anvil/scripts/test-report-language.sh
```

Expected: failure because the current skill requires the visible parser label.

- [ ] **Step 3: Update the engine output contract**

Change the `.inline.json` examples and rules in `SKILL.md`: the complete finding ID remains visible in the report/reproduction/adversarial artifacts, but the inline title is only the exact failure title and the final HTML marker carries ID, severity, and area. State that no prose or suggestion may follow that marker.

- [ ] **Step 4: Update the author-facing rendering reference**

Change `report-artifacts.md` to define the natural title and terminal marker, update complete examples, and remove wording that relies on a visible severity tag. Keep the existing fact-lock and action-lock rules unchanged.

- [ ] **Step 5: Run contract tests and confirm GREEN**

Run the two commands from Step 2. Expected: both scripts report all contract checks passed.

### Task 3: Clean-Agent Generation and Blind Evaluation

**Files:**
- Create evaluation artifacts only under: `plugins/review-anvil/skills/review-anvil/evaluations/2026-08-08/`

**Interfaces:**
- Consumes: frozen findings from today's `evaleval/every_eval_ever` corpus and the changed skill contract.
- Produces: generated inline JSON, parser/action audit results, old-versus-new comparisons, and a selection assessment.

- [ ] **Step 1: Generate with a clean `omp` agent**

Give a no-session clean agent frozen finding inputs and only the revised skill/reference sections needed to render them. Require JSON bodies with the natural title and terminal metadata marker. Do not allow repository, network, skill, or rule access.

- [ ] **Step 2: Validate every generated body**

Check JSON shape, exact input IDs, one terminal marker per body, marker/body severity agreement, no visible RAV ID or severity/area label, exact requested-work predicate coverage, and preservation of exact source suggestions.

- [ ] **Step 3: Blind-compare against the exact iteration-14 baseline**

Randomize labels and ask at least two clean judges to score defect clarity, action recall, scanability, naturalness, and cognitive ease. Require fact/action correctness as a hard gate. Record ties and every baseline win rather than reporting only aggregate preference.

- [ ] **Step 4: Repair only demonstrated regressions**

If an audit finds fact loss or invented work, restore exact source prose through the existing action-lock fallback. If judges identify repeated readability failures, tighten only the corresponding positive rendering rule and rerun the affected cases.

- [ ] **Step 5: Run final verification**

Run:

```bash
bash skills/review-anvil/scripts/test-report-language.sh
bash skills/review-anvil/scripts/test-identifiers.sh
bash skills/review-anvil/scripts/test-run-reviewer.sh
bash skills/review-anvil/scripts/test-reproduction-policy.sh
bash skills/review-anvil-pr/scripts/test-pr-helper.sh
```

Then run a fake-`gh` post smoke test and inspect the captured JSON payload: visible body starts with a natural title, all requested work remains visible, any suggestion and reintroduction marker precede the metadata, and the metadata marker is the final line.

- [ ] **Step 6: Commit the branch**

Stage only the maximum-human contract, helper, tests, plan, and evaluation evidence. Use a Conventional Commit with a body that describes the staged diff exactly. Verify the resulting author, committer, and full message; confirm the main worktree remains unchanged.
