# review-anvil: Cut Complexity & Add Grounding — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cut review-anvil's over-built configuration surface (C1–C10) and then add executable grounding (self-measurement harness, patch-coverage + executable reproduction, static-analyzer lens, confidence/consensus, learnings/config) so findings are *proven*, not argued.

**Architecture:** review-anvil is a prose-driven LLM-orchestrated skill (markdown the orchestrator follows) plus two deterministic shell helpers (`run-reviewer.sh`, `pr-helper.sh`) and shell test harnesses. Phase 1 is pure editing of the prose policy + its test fixtures; no runtime exists to unit-test, so the "tests" for prose tasks are (a) the existing shell harnesses still passing, (b) grep-based invariant checks that removed concepts leave no dangling references, and (c) a structural read-through. Phases 2–5 add real shell/script code with its own fixtures.

**Tech Stack:** Markdown (skill prose), Bash (helpers + test harnesses), `jq`, `uv`/`python3`. No new language runtimes introduced in Phase 1.

## Global Constraints

- **No AI attribution** anywhere (commits, docs, code comments) — verbatim from user CLAUDE.md.
- **Conventional Commits** with a body (diagnosis → what/how → bullets), wrapped at 72 cols; use the `git commit -F - <<'EOF'` heredoc pattern for multi-line/backtick-containing messages.
- **Behavior-preserving cuts:** every Phase 1 cut removes *configuration/duplication*, not review capability. If a cut would change what findings ship, stop and flag it.
- **Trusted-root rule preserved:** never weaken the script-resolution security rules (host-exposed skill path / user-level install roots only; never project-scoped/worktree-local).
- **One source of truth:** after Phase 1, each cross-cutting rule is stated once and pointed to elsewhere.
- **Test harnesses must stay green:** `skills/review-anvil/scripts/test-reproduction-policy.sh` and `skills/review-anvil-pr/scripts/test-pr-helper.sh` pass after every task that touches their subject.
- Plugin root: `plugins/review-anvil/`. Engine: `skills/review-anvil/SKILL.md`. Paths below are relative to the plugin root unless absolute.

---

## Scope & sequencing note

This document fully details **Phase 1 (the cuts)** to step level, because that is what executes first and against the current baseline. **Phases 2–5** are specified at the task/interface/file-target level with their design fixed, but deliberately **not** expanded to exact-edit steps here: each lands on a *different* (post-cut, then post-harness) baseline, so writing exact `old_string`/`new_string` edits for them now would be authored against files that no longer exist by the time they run. Each of Phases 2–5 gets a short detailed-planning pass (re-invoke writing-plans) at its start. This is intentional, not a placeholder gap.

**Phase order (locked):** 1 Cuts → 2 D1 self-measurement harness → 3 A2 patch-coverage then A1 executable reproduction → 4 B1 static-analyzer lens → 5 B2 confidence + B3 cross-family consensus, then D2 learnings + D3 project config.

---

## File Structure (Phase 1)

| File | Responsibility | Phase-1 change |
|---|---|---|
| `skills/review-anvil/SKILL.md` | The engine | Heavy: C1–C10 edits |
| `skills/review-anvil/references/adversarial-prompt.md` | Adversarial gate prompt | C1: collapse modes/roles to one `on` behavior |
| `skills/review-anvil/references/reproduction-prompt.md` | Reproduction verifier prompt | C5: verdict enum → `confirmed\|refuted\|unclear` |
| `skills/review-anvil/references/reproduction-examples.md` | Reproduction fixtures (doc) | C5: update verdict column; C8: move to `scripts/` test fixtures |
| `skills/review-anvil/references/fix-application.md` | Fix-application policy | C8: inline into SKILL.md §4; delete file |
| `skills/review-anvil/references/report-artifacts.md` | Report voice/artifacts | C1/C5: drop adversarial-mode + verdict references |
| `skills/review-anvil/scripts/test-reproduction-policy.sh` | Reproduction policy test | C5/C6: update verdict cases + selection logic |
| `skills/review-anvil-readonly/SKILL.md` | Read-only preset | C1/C3: drop removed params from pass-through list |
| `skills/review-anvil-pr/SKILL.md` | PR preset | C1/C3/C7: drop removed params + legacy-ID mention |
| `skills/review-anvil-pr/scripts/pr-helper.sh` | PR posting helper | C7: remove legacy dashed-ID parsing if present (verify first) |
| `skills/review-anvil-improve-pr/SKILL.md` | Improve-PR preset | C1/C3: drop removed params |

---

## Phase 1 — Cuts (C1–C10)

### Task 1: C1 — Collapse the adversarial gate to `off|on`

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (Parameters table `adversarial`/`adversarial_rounds` rows; "Optional adversarial review" section incl. Modes table, Role mapping, Default policy, `auto` selection ~7 bullets, Apply-verdicts block; §5 round-summary "Adversarial review:" line; §6/Output adversarial references; Edge Cases rows `adversarial` and `adversarial_rounds`)
- Modify: `skills/review-anvil/references/adversarial-prompt.md` (Role Additions section)
- Modify: `skills/review-anvil/references/report-artifacts.md` ("Adversarial review summary" example line — change `targeted, 2 agents` framing to mode-free)

**Interfaces:**
- Produces: `adversarial` is now `off|on` only. `on` ≡ the former `targeted` (two roles: `false-positive-scope-auditor` + `fix-plan-breaker`; force the deletion-skeptic behavior when any would-apply plan removes code). No `auto`, `challenge`, `full`, `strict`. The former `strict` "required-adversary-failure → COMMENT" rule folds into the existing Failure-handling line ("Adversary failure → note in Run Details; if it leaves a `critical`/`high` dispute unresolved, force COMMENT").
- Consumed by: Task 2 (removes `adversarial_rounds`), Task 4 (the `auto` mode-list contradiction disappears here, so C4's contradiction-fix is subsumed — C4 only de-dups what remains).

- [ ] **Step 1: Capture the pre-edit invariant**

Run: `cd plugins/review-anvil && grep -rn 'challenge\|targeted\|strict\|adversarial: auto\|adversarial_rounds' skills/ | wc -l`
Record the count (baseline of references to remove/rewrite).

- [ ] **Step 2: Rewrite the Parameters table rows**

In `SKILL.md`, replace the `adversarial` row with:
`| \`adversarial\` | \`off\` | \`off\` or \`on\` — read-only post-synthesis gate that attacks candidate findings and would-apply fix plans (false-positive/scope audit + fix-plan proportionality, plus a deletion skeptic when a plan removes code) before they become final guidance. `per_fix` ignores it (warns). |`
Delete the `adversarial_rounds` row entirely (it becomes a fixed single pass — see Task 2 owns the param-table cleanup confirmation).

- [ ] **Step 3: Replace the "Optional adversarial review" section body**

Collapse the Modes table, Role-mapping block, Default-policy bullets, and the entire `auto` selection ladder into ~12 lines: when `adversarial: on` and `commit_mode=none`, dispatch the two-role adversary (FP/scope auditor + fix-plan-breaker; add deletion-skeptic when a would-apply plan removes code), one pass, over `medium`+ findings and would-apply plans. Keep the "Apply verdicts conservatively" `drop|defer|modify|uphold` list and the "generic uncertainty does not defer" rule verbatim — those are behavior, not config. Keep the preset defaults rule but reduce to: read-only preset defaults `off`; `review-anvil-pr` defaults `on`; explicit `off` in a PR run forces `.approval.json` COMMENT.

- [ ] **Step 4: Strip mode/round references elsewhere in SKILL.md**

Update §5 round-summary line to `- Adversarial review: off | on, <A> agents, <upheld> upheld, <hardened> hardened, <deferred> deferred, <dropped> dropped`. Update Output-Format final-report `**Adversarial review:**` line the same way (`off | on, ...`). Remove the `adversarial_rounds > 2` and second-pass paragraph; adversarial is exactly one pass. In Edge Cases, delete the `adversarial_rounds > 2` row; keep the `adversarial with per_fix` row.

- [ ] **Step 5: Collapse adversarial-prompt.md roles**

In `references/adversarial-prompt.md`, keep the Core Prompt and the `false-positive-scope-auditor` + `fix-plan-breaker` role additions and the deletion-skeptic note; delete `second-order-bug-hunter` and `report-auditor` (the `full`/`strict`-only roles) and the "Modes" framing. Keep the Output Contract and Orchestrator Rules.

- [ ] **Step 6: Fix report-artifacts.md example**

Change the "Adversarial review summary" sample line from `targeted, 2 agents` to `on, 2 agents`.

- [ ] **Step 7: Verify no dangling mode references**

Run: `cd plugins/review-anvil && grep -rn 'challenge\|: targeted\|: full\|: strict\|adversarial: auto\|adversarial_rounds\|second-order-bug-hunter\|report-auditor' skills/`
Expected: only matches are in unrelated prose (e.g. "challenge" used as an English verb) — review each; zero references to the removed modes/params/roles as configuration.

- [ ] **Step 8: Run the test harnesses**

Run: `cd plugins/review-anvil && bash skills/review-anvil/scripts/test-reproduction-policy.sh && bash skills/review-anvil-pr/scripts/test-pr-helper.sh`
Expected: both print their "all … passed" lines (C1 shouldn't affect either, but confirm no accidental breakage).

- [ ] **Step 9: Commit**

```bash
git add -A skills/review-anvil/SKILL.md skills/review-anvil/references/adversarial-prompt.md skills/review-anvil/references/report-artifacts.md
git commit -F - <<'EOF'
refactor(review-anvil): collapse adversarial gate to off|on

Previously the adversarial gate had five modes (off/auto/challenge/
targeted/full/strict) plus a line-count auto-selection ladder, a
role-mapping table, and a verdict table — more policy text than the
loop it guards, and `full`/`strict` shared identical dispatch. This
collapses it to `off|on`, where `on` is the former `targeted`
(FP/scope auditor + fix-plan-breaker, deletion skeptic on cuts).

- Reduce `adversarial` param to off|on; drop `adversarial_rounds`
- Remove Modes/Role-mapping/auto-selection blocks from SKILL.md §3
- Fold `strict`'s COMMENT-forcing into Failure-handling
- Drop second-order-bug-hunter/report-auditor roles from the prompt
- Single adversarial pass; remove the second-pass arithmetic
EOF
```

---

### Task 2: C3 — Delete speculative params

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (Parameters table; Parsing bullets; §3 disagreement references; Output `.approval.json` `approve` references; Edge Cases)
- Modify: `skills/review-anvil/references/fix-application.md` (add the `allow_new_deps` note before it is inlined in Task 8 — or fold directly if Task 8 runs first; here keep order: edit fix-application.md in place)
- Modify: `skills/review-anvil-readonly/SKILL.md`, `skills/review-anvil-pr/SKILL.md`, `skills/review-anvil-improve-pr/SKILL.md` (pass-through param lists)

**Interfaces:**
- Produces: params `disagreement_policy`, `adversarial_rounds` (already gone in Task 1), and `approve`-as-param are removed. `approve` behavior is now env-only (`REVIEW_ANVIL_NO_APPROVE=1`). Fixed defaults replace `disagreement_policy`: an unresolved `critical`/`high` adversarial/reviewer dispute → COMMENT; unresolved `medium` dispute → move to Deferred (the former `defer` default). `allow_new_deps` survives but as a fix-application.md note, not a headline Parameters row.

- [ ] **Step 1: Remove param rows**

In `SKILL.md` Parameters table delete the `disagreement_policy` and `approve` rows; move `allow_new_deps` out of the table into a one-line note under §4 / fix-application.md. Leave `min_fix_severity`, `reproduction`, `adversarial`, `verify_cmd`, `reviewer_timeout`, `report_path`, `commit_mode`, `rounds`, `max_rounds`, `agents`, `focus`, `target`.

- [ ] **Step 2: Replace disagreement_policy semantics with a fixed rule**

Find every `disagreement_policy` mention (Parsing, §3 adversarial Apply-verdicts, Edge Cases) and replace with the fixed default: "Unresolved `critical`/`high` disputes force COMMENT (review-only PR runs) and block APPROVE; unresolved `medium` disputes move the item to Deferred." Delete the `comment`-policy variant.

- [ ] **Step 3: Replace approve-param semantics with env-only**

Find every `approve` param mention; the only control is `REVIEW_ANVIL_NO_APPROVE=1` (presets export it). Update the `.approval.json` `approval_allowed` prose to reference the env var, not the param. Keep `"never approve"/"comment only"` as plain-English → sets the env behavior for the run.

- [ ] **Step 4: Update preset pass-through lists**

In all three preset SKILLs, remove `disagreement_policy`, `adversarial_rounds`, and `approve` from the "pass-through args" bullet lists. In `review-anvil-readonly` keep `adversarial: off|on` only.

- [ ] **Step 5: Verify**

Run: `cd plugins/review-anvil && grep -rn 'disagreement_policy\|adversarial_rounds\|approve:' skills/`
Expected: zero config references (English "approve" in prose is fine).
Run both test harnesses (as Task 1 Step 8). Expected: pass.

- [ ] **Step 6: Commit** (`refactor(review-anvil): drop disagreement_policy, adversarial_rounds, approve params` — body: diagnosis that each added a parse branch + precedence interaction for a sub-distinction; two died with the adversarial collapse; `approve` duplicated an env switch; fixed defaults now cover the behavior.)

---

### Task 3: C2 — Single convergence stop + one `max_rounds`

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (Parameters `max_rounds` row; Parsing `max_rounds`/adaptive bullets; §6 Adaptive-continuation block; entire "Tuning suggestion rule" section; Output `Tuning suggestion` line; Edge Cases `max_rounds` rows)

**Interfaces:**
- Produces: `max_rounds` default `6` for `per_fix`, `= rounds` for `commit_mode=none`. Adaptive continuation keeps its existing *criteria* (latest round `material_findings`, applied a verified fix, verification not newly red, all reviewers parseable, risk likely to converge) but the **phrase ladder** ("exactly/only/allow one extra/continue if needed/no extra rounds") and the **Tuning-suggestion section** are removed. "exactly N / only N / no extra rounds" → still recognized as `max_rounds = rounds`, stated once in Parsing.

- [ ] **Step 1:** Simplify the `max_rounds` Parameters row to one sentence + the `= rounds` read-only collapse.
- [ ] **Step 2:** In Parsing, keep ONE statement of the `max_rounds` resolution (default `max(6, rounds)` for per_fix; `rounds` for none; reject `< rounds`; "exactly/only/no extra" → `= rounds`). Delete the duplicate statements elsewhere (this overlaps C4 — fine to do here).
- [ ] **Step 3:** Keep §6 adaptive-continuation *criteria* bullets; delete the prose that re-derives the cap arithmetic.
- [ ] **Step 4:** Delete the whole "### Tuning suggestion rule" section and the `Tuning suggestion:` line in the Run Details output block.
- [ ] **Step 5:** Verify: `grep -n 'Tuning suggestion\|allow one extra\|continue if needed' SKILL.md` → zero. Run harnesses → pass.
- [ ] **Step 6:** Commit (`refactor(review-anvil): replace adaptive-round arithmetic with one convergence stop`).

---

### Task 4: C4 — One source of truth per cross-cutting rule

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (the repeated rules); confirm the `adversarial: auto` contradiction is already gone (Task 1).

**Interfaces:**
- Produces: each of these rules stated once, others reduced to a pointer ("see §X"): pin-rejection algorithm, reproduction verifier-failure handling, adaptive-round abort gate, `commit_mode=none` constraints, max_rounds resolution (mostly done in Task 3). No behavior change.

- [ ] **Step 1:** For each repeated rule, pick the canonical home (pin-rejection → Parsing; verifier-failure → §3; abort gate → §6; commit_mode=none constraints → "Commit modes"). Reduce the other occurrences to one-line pointers.
- [ ] **Step 2:** Verify the `auto`-mode contradiction is gone: `grep -n 'adversarial.*auto' SKILL.md` → zero.
- [ ] **Step 3:** Read-through: confirm no pointer points at a section that no longer states the rule.
- [ ] **Step 4:** Run harnesses → pass. Commit (`docs(review-anvil): deduplicate cross-cutting rules to single sources`).

---

### Task 5: C5 — Reproduction verdicts → `confirmed|refuted|unclear`

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (§3 "Apply reproduction verdicts" list)
- Modify: `skills/review-anvil/references/reproduction-prompt.md` (Output Contract enum + Orchestrator Rules)
- Modify: `skills/review-anvil/references/reproduction-examples.md` (verdict column)
- Modify: `skills/review-anvil/scripts/test-reproduction-policy.sh` (`effect_with_reproduction` cases + CASES fixtures)

**Interfaces:**
- Produces: verdict enum is `confirmed | refuted | unclear` (plus the failure sentinel `verifier_failure`). `narrowed` folds into `confirmed` + the verifier's returned `safer_wording`. `downgraded` folds into `confirmed` + the verifier's returned lower `severity` (the `confirmed` branch already keys effect off `final_severity`, so `downgrade-to-low` still yields `suggestion`). The test's distinct `actionable:narrowed` marker is removed; a narrowed finding is `actionable` carrying narrower wording.

- [ ] **Step 1: Update the test harness first (TDD-style — change the spec, watch it pin behavior)**

In `test-reproduction-policy.sh` `effect_with_reproduction`, delete the `narrowed)` and `downgraded)` case arms. Update the two affected CASES rows:
- `live-doc-drift|medium|1|none|confirmed|medium|yes|actionable|deferred:reproduction-disabled` (was `narrowed`→`actionable:narrowed`)
- `downgrade-to-low|medium|1|none|confirmed|low|yes|suggestion|deferred:reproduction-disabled` (was `downgraded`, final_severity already `low` → `suggestion`)

- [ ] **Step 2: Run the harness, expect PASS**

Run: `cd plugins/review-anvil && bash skills/review-anvil/scripts/test-reproduction-policy.sh`
Expected: `all reproduction policy examples passed`. (If it fails, the case table and the case arms disagree — reconcile before touching prose.)

- [ ] **Step 3:** Update `reproduction-prompt.md` Output Contract `verdict:` enum to `confirmed | refuted | unclear`; in Orchestrator Rules, replace the `narrowed`/`downgraded` bullets with: "`confirmed`: keep actionable at the verifier's returned severity, using `safer_wording` if narrower." Keep `refuted`/`unclear`.
- [ ] **Step 4:** Update SKILL.md §3 "Apply reproduction verdicts" list the same way (3 verdicts; severity/wording carried by fields).
- [ ] **Step 5:** Update `reproduction-examples.md` Verdict column: `live-doc-drift` and `downgrade-to-low` → `confirmed` (narrower wording / lower severity noted in the "Final Effect" column prose).
- [ ] **Step 6:** Verify: `grep -rn 'narrowed\|downgraded' skills/review-anvil/` → only historical/English mentions, no verdict-enum usage. Run harness → pass.
- [ ] **Step 7:** Commit (`refactor(review-anvil): collapse reproduction verdicts to confirmed|refuted|unclear`).

---

### Task 6: C6 — Compress reproduction candidate-selection

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (§3 `REPRODUCTION CANDIDATES` 4-bullet list + consensus-exemption + deletion truth-table)

**Interfaces:**
- Produces: candidate selection stated as one principle + a 2-sentence deletion gate, with **identical** selection behavior to the test harness's `should_reproduce()`. The harness is the executable spec; prose must match it.

- [ ] **Step 1: Re-read `should_reproduce()` in the harness** — the canonical selection logic (single-reviewer medium+; OR deletion/dead/unused/redundant/simplification with medium+ OR runtime_cut/public_surface; OR high+ inferred; OR uncertain; dismissed/historical/generated/vendored → no).
- [ ] **Step 2:** Replace the §3 candidate bullets with: "Reproduce any `medium`+ finding that is single-reviewer, destructive (deletion/dead/unused/redundant/simplification), inferred-from-hunk, or orchestrator-doubted; trust 2+-reviewer consensus otherwise. Deletions also require execution in `per_fix`: apply the cut, run the suite — a red gate means keep it; a green gate is necessary but not sufficient, so the skeptic must still find a concrete reason it can stay (caller/back-compat/ordering/trust-boundary/dedup/edge-semantics) before the cut ships." Preserve the runtime-cut/public-surface escalation explicitly so it still matches the harness.
- [ ] **Step 3: Cross-check prose vs harness** — enumerate the harness cases mentally against the new prose; confirm no case changes classification. Run harness → pass.
- [ ] **Step 4:** Commit (`docs(review-anvil): compress reproduction candidate-selection to one principle`).

---

### Task 7: C7 — Delete the legacy `F-001`/`W-001` ID grammar

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (§3 ID-assignment paragraph)
- Verify/Modify: `skills/review-anvil-pr/scripts/pr-helper.sh` (any legacy dashed-ID parsing)

**Interfaces:**
- Produces: the only ID grammar is `RAV([FW])([0-9]{3,})`. No legacy dashed form accepted anywhere.

- [ ] **Step 1: Check the helper for legacy parsing**

Run: `cd plugins/review-anvil && grep -n 'F-0\|W-0\|legacy.*id\|RAV\[\|F-\[0-9\]\|dashed' skills/review-anvil-pr/scripts/pr-helper.sh`
Record matches. If the helper accepts `F-001`/`W-001`, remove that branch and keep only the canonical regex.

- [ ] **Step 2:** In SKILL.md §3, delete the sentence permitting legacy dashed IDs at parsing boundaries; keep "findings are `RAVF001`…, plans `RAVW001`…; canonical grammar `RAV([FW])([0-9]{3,})`."
- [ ] **Step 3:** Verify: `grep -rn 'F-001\|W-001\|legacy dashed' skills/` → zero. Run `test-pr-helper.sh` → pass (it must still pass; if it asserted legacy IDs, update that assertion — read the test first).
- [ ] **Step 4:** Commit (`refactor(review-anvil): drop never-shipped legacy finding-ID grammar`).

---

### Task 8: C8 — Inline fix-application.md; relocate reproduction-examples.md

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (§4 now contains the fix-application policy inline; remove the "read references/fix-application.md" pointer)
- Delete: `skills/review-anvil/references/fix-application.md`
- Move: `skills/review-anvil/references/reproduction-examples.md` → `skills/review-anvil/scripts/reproduction-examples.md` (it is a test fixture for `test-reproduction-policy.sh`, not a runtime reference); update the comment in `test-reproduction-policy.sh` and the SKILL.md pointer that currently says "live in `references/reproduction-examples.md`".

**Interfaces:**
- Produces: §4 is self-contained (severity gate, no-new-deps + `allow_new_deps` note from Task 2, round size cap, build/test gate). Mid-loop reference-file loads drop from 6 toward 3.

- [ ] **Step 1:** Copy fix-application.md's content into SKILL.md §4 verbatim (it's ~22 lines), placing the `allow_new_deps` note here. Replace the §4 "read references/fix-application.md before any edit" with the inline policy.
- [ ] **Step 2:** `git rm skills/review-anvil/references/fix-application.md`.
- [ ] **Step 3:** `git mv skills/review-anvil/references/reproduction-examples.md skills/review-anvil/scripts/reproduction-examples.md`; update the SKILL.md §3 pointer and the test-harness header comment to the new path.
- [ ] **Step 4:** Verify: `grep -rn 'references/fix-application\|references/reproduction-examples' skills/` → zero. Run both harnesses → pass.
- [ ] **Step 5:** Commit (`refactor(review-anvil): inline fix-application policy; relocate reproduction fixtures`).

---

### Task 9: C9 — Simplify `reviewer_timeout`

**Files:**
- Modify: `skills/review-anvil/SKILL.md` (Parameters `reviewer_timeout` row; Edge Cases `>5000 lines` row)

**Interfaces:**
- Produces: `reviewer_timeout` row is one line (`hard per-reviewer wall-clock cap in seconds; default 600`). No auto-doubling rule; the 98–213s empirical rationale leaves the param table. The `>5000-line` Edge Cases row keeps "warn and continue; tell reviewers to focus on the impactful slice" but drops "double `reviewer_timeout`."

- [ ] **Step 1:** Trim the param row; delete the auto-doubling clause and the empirical-range parenthetical.
- [ ] **Step 2:** Edit the `>5000 lines` Edge Cases row to remove the timeout-doubling.
- [ ] **Step 3:** Verify `grep -n 'doubl' SKILL.md` → no timeout-doubling. Harnesses → pass. Commit (`refactor(review-anvil): drop reviewer_timeout auto-doubling magic number`).

---

### Task 10: C10 — Mix table → one line

**Files:**
- Modify: `skills/review-anvil/SKILL.md` ("Default Mix Policy" section)

**Interfaces:**
- Produces: the 6-row count→mix table becomes one sentence; the rationale stays one line.

- [ ] **Step 1:** Replace the table with: "Default ~60% codex-exec / 40% claude-exec; codex takes the odd agent and the solo (`agents=1`) slot. Honor an explicit mix exactly." Keep the one-line rationale (codex surfaces more issues per call in our usage).
- [ ] **Step 2:** Verify the `agents` Parsing bullet still points here. Harnesses → pass. Commit (`refactor(review-anvil): collapse reviewer-mix table to a single heuristic`).

---

### Task 11: Phase-1 close-out — structural read-through & line-count check

**Files:** none (review only)

- [ ] **Step 1:** Run: `cd plugins/review-anvil && wc -l skills/review-anvil/SKILL.md` — expect a meaningful drop from 570 (target ~380–430).
- [ ] **Step 2:** Run the full grep invariant sweep for every removed concept: `grep -rEn 'challenge|: targeted|: full|: strict|adversarial: auto|adversarial_rounds|disagreement_policy|approve:|narrowed|downgraded|Tuning suggestion|F-001|W-001|fix-application\.md|references/reproduction-examples' skills/` — confirm each remaining hit is benign English, not removed config.
- [ ] **Step 3:** Read SKILL.md end-to-end once for coherence (no pointer to a deleted section; presets' pass-through lists match the surviving param set).
- [ ] **Step 4:** Both harnesses green. No commit (or a trivial `docs:` if the read-through finds a stray reference).

---

## Phase 2 — D1 self-measurement harness (design-level; detail-plan at phase start)

**Goal:** an offline P/R/F1 harness so every later prompt/policy change is validated, not vibes-checked.

**Files (planned):**
- Create: `skills/review-anvil/scripts/eval/run-eval.sh` (driver), `skills/review-anvil/scripts/eval/fixtures/` (labeled corpus: planted-bug diffs + clean diffs + expected-findings JSON), `skills/review-anvil/scripts/eval/score.py` (or `.sh`+`jq`: match findings→ground truth, emit precision/recall/F1/FP-rate per lens/config).
- Extend: the existing `test-reproduction-policy.sh` fixture style is the model for fixture format.

**Interfaces (planned):** `run-eval.sh <fixtures-dir>` → per-config metrics table + machine-readable JSON. Ground-truth match keyed on `(file, line-window, root-cause-tag)`. CI target added.

**Why not detailed now:** depends on the post-cut SKILL.md (finding schema may shift in Phase 1) and is a new code subsystem deserving its own TDD plan. Re-invoke writing-plans at Phase 2 start.

---

## Phase 3 — Testing track: A2 then A1 (design-level)

**A2 — patch-coverage qualifier (first).**
- Files (planned): new `references/coverage.md` or inline §3 rule; optional `scripts/patch-coverage.sh` (run `verify_cmd` under coverage, intersect uncovered lines with diff hunks).
- Interface: produces a `patch coverage: X%` report field + escalates uncovered changed `medium`+ lines into reproduction candidates; downgrades a green gate over uncovered changed lines to weak evidence. New param `coverage: auto|off`.

**A1 — executable reproduction (`reproduction: executable` tier).**
- Files (planned): `references/reproduction-prompt.md` (new executable instructions), SKILL.md §3 (new tier), `references/fix-application.md` content now in §4 (red-then-green gate before committing a fix-group), reuse `run-reviewer.sh` for sandboxed dispatch.
- Interface: verifier writes a test that FAILS on current code, PASSES after fix; new finding key `reproduction_test_status`; new verdict tier `proven` (outranks `confirmed`) — note this *re-introduces* a verdict, so reconcile with C5 by making `proven` a `confirmed` sub-state carried in a field, keeping the enum at three. Read-only: run both states in a scratch git worktree; per_fix: keep the test as a regression guard. D1 fixtures gain expected `proven` cases.

**Why not detailed now:** lands on the post-cut + post-harness baseline; A1's `proven` state must be designed against the C5-simplified verdict model. Re-invoke writing-plans at Phase 3 start.

---

## Phase 4 — B1 static-analyzer ground-truth lens (design-level)

- Files (planned): `scripts/run-analyzers.sh` (sibling to `run-reviewer.sh`; auto-detect + diff-scope semgrep/CodeQL/ruff/eslint/mypy/tsc/clippy), SKILL.md (new optional pre-pass + `analyzers: auto|off` param + STATIC ANALYSIS HITS context block in `reviewer-prompt.md`).
- Interface: emits `source=static:<tool>` findings reviewers CONFIRM/REFUTE; tool-confirmed findings skip reproduction; tool+LLM agreement on `(file,line)` bumps confidence (feeds B2). Measure lift with D1 before/after.
- **Why staged after cuts+harness:** heaviest add; only worth landing on a simplified base with measurement in place.

---

## Phase 5 — B2 confidence + B3 consensus, then D2 learnings + D3 config (design-level)

**B2 confidence + B3 cross-family consensus.**
- Files (planned): `reviewer-prompt.md` (new `confidence` YAML key), SKILL.md §3 (dedup record stores reviewer family-diversity; confidence = f(reviewer diversity, reproduction verdict, analyzer corroboration, adversarial survival)), new `confidence_floor` param; gate posting/auto-fix on confidence×severity; add a Findings-table confidence column + `.inline.json` field.
- Interface (B3): same-backend consensus alone never promotes a finding past reproduction; cross-family agreement weighted higher. Cheap §3 policy change on the dedup record anvil already keeps.

**D2 learnings store + D3 project config.**
- Files (planned): `.review-anvil/learnings.jsonl` (repo-scoped dismissed/refuted/accepted history → CALIBRATION block in reviewer/adversary prompts; semantic match → auto-defer), `.review-anvil.yaml` (persistent defaults/path rules/exclusions/banned patterns, merged config-defaults < invocation-args, **treated as untrusted content** → PROJECT RULES reviewer block, never engine override). New startup step; extends the existing single-PR dismissed-suppression to cross-PR.
- **Why D2 after D1:** the harness must prove the learnings store reduces noise rather than silently suppressing true positives.

---

## Self-Review (Phase 1)

**Spec coverage:** C1✓(T1) C2✓(T3) C3✓(T2) C4✓(T4) C5✓(T5) C6✓(T6) C7✓(T7) C8✓(T8) C9✓(T9) C10✓(T10); APPROVE-opt-in-only → handled within T2's env-only approval + noted (no default APPROVE) — confirm during T2. Phases 2–5 mapped to the roadmap adds (D1, A2/A1, B1, B2/B3, D2/D3); deferred opt-ins (mutation/fuzz/loom/A3/A4/C-add*/E*) explicitly out of scope.

**Placeholder scan:** Phase 1 steps carry concrete file targets, exact grep/test commands, and the replacement text or its precise content. Phases 2–5 are intentionally design-level (justified in the scope note), not placeholder Phase-1 work.

**Type/term consistency:** verdict enum `confirmed|refuted|unclear` (+`verifier_failure` sentinel) used consistently in T5/T6; A1's `proven` flagged as a `confirmed` sub-state to avoid re-expanding the enum. `adversarial: off|on` used consistently T1/T2/presets. `REVIEW_ANVIL_NO_APPROVE` is the single approval control after T2.

**Ordering risk:** T1 must precede T2 (T2 assumes `adversarial_rounds` already gone) and T4 (T1 removes the `auto` contradiction T4 would otherwise fix). T5 updates the harness before prose. T2 edits fix-application.md in place; T8 then inlines+deletes it — order T2→T8 preserved.
