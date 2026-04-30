# review-anvil Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a new `review-anvil` plugin to the `mrshu-skills` marketplace that wraps the recurring "let's do three rounds of fix/review" pattern into a parameterized, prose-driven skill.

**Architecture:** Pure-prose skill (no scripts, no binaries). A single `SKILL.md` instructs the orchestrating Claude session how to dispatch parallel reviewer subagents (`codex-exec` + `claude-exec`), synthesize their findings, apply fixes with logically-separated commits, and report. Each round runs in parallel; rounds run sequentially.

**Tech Stack:** Markdown + YAML frontmatter (skill), JSON (plugin/marketplace manifests). Skill consumes the existing `codex-exec` and `claude-exec` plugins via the `Skill` / `Agent` tools at runtime.

**Spec:** `docs/superpowers/specs/2026-04-30-review-anvil-design.md`

---

## File Structure

Files created/modified by this plan:

| Path | Responsibility |
|---|---|
| `plugins/review-anvil/.claude-plugin/plugin.json` | Plugin manifest (name, version, description, keywords). |
| `plugins/review-anvil/skills/review-anvil/SKILL.md` | The skill itself — prose instructions for orchestrating the loop. |
| `.claude-plugin/marketplace.json` | Add `review-anvil` entry to the marketplace plugin list. |
| `README.md` | Add install instruction and a `### review-anvil` section. |

The skill is intentionally a single file. Splitting it into helper docs would force the orchestrator to load multiple files just to follow the procedure; the procedure is short enough to fit comfortably in one SKILL.md.

---

## Task 1: Scaffold plugin directory and manifest

**Files:**
- Create: `plugins/review-anvil/.claude-plugin/plugin.json`

- [ ] **Step 1: Create the plugin manifest**

Create `plugins/review-anvil/.claude-plugin/plugin.json` with this exact content:

```json
{
  "name": "review-anvil",
  "version": "0.1.0",
  "description": "Iterative multi-agent review-and-fix loop. Dispatch N rounds of parallel codex-exec/claude-exec reviewers, synthesize findings, apply fixes with logically-separated commits.",
  "author": {
    "name": "mrshu"
  },
  "keywords": ["review", "code-review", "iterative", "multi-agent", "codex-exec", "claude-exec", "rounds"]
}
```

- [ ] **Step 2: Verify JSON is valid**

Run: `python3 -c "import json; print(json.load(open('plugins/review-anvil/.claude-plugin/plugin.json'))['name'])"`
Expected output: `review-anvil`

- [ ] **Step 3: Commit**

```bash
git add plugins/review-anvil/.claude-plugin/plugin.json
git commit -F - <<'EOF'
feat(review-anvil): scaffold plugin manifest

Add the plugin.json for the new review-anvil plugin. Empty skill file
follows in subsequent commits.

- Create plugins/review-anvil/.claude-plugin/plugin.json with name,
  version, description, and keywords matching the marketplace style
EOF
```

---

## Task 2: Create SKILL.md skeleton with frontmatter

**Files:**
- Create: `plugins/review-anvil/skills/review-anvil/SKILL.md`

- [ ] **Step 1: Create the file with frontmatter and section headers only**

Create `plugins/review-anvil/skills/review-anvil/SKILL.md` with this exact content:

```markdown
---
name: review-anvil
description: Iteratively refine code via N rounds of parallel subagent review and orchestrator-applied fixes. Use when the user says "let's do three rounds", "fix/review loop", "back-and-forth review", "iterative review", or asks to harden a change with multiple rounds of codex/claude review. Configurable rounds, agent count/mix, focus, and target.
---

# review-anvil — Iterative Multi-Agent Fix/Review Loop

Wrap a code change in **N rounds of parallel reviewer subagents + orchestrator-applied fixes**. Each round = (parallel review by M agents) → (you synthesize findings) → (you apply fixes, commit) → next round.

## How to Use

(parameters, parsing — Task 3)

## Default Mix Policy

(table — Task 3)

## Loop Mechanics

(6-step round procedure — Task 4)

## Reviewer Prompt Template

(context + task blocks — Task 5)

## Output Format

(final report + per-round status — Task 6)

## Edge Cases

(failure handling, target detection, parse fallback — Task 6)
```

- [ ] **Step 2: Verify YAML frontmatter parses**

Run:
```bash
python3 -c "
import sys
text = open('plugins/review-anvil/skills/review-anvil/SKILL.md').read()
assert text.startswith('---\n'), 'missing opening ---'
end = text.index('\n---\n', 4)
import re
fm = text[4:end]
# Crude parse: ensure name and description keys present
assert re.search(r'^name:\s*review-anvil\s*$', fm, re.M), 'bad name'
assert re.search(r'^description:', fm, re.M), 'missing description'
print('OK')
"
```
Expected output: `OK`

- [ ] **Step 3: Commit**

```bash
git add plugins/review-anvil/skills/review-anvil/SKILL.md
git commit -F - <<'EOF'
feat(review-anvil): add SKILL.md skeleton with frontmatter

Stand up the empty skill file with YAML frontmatter (name, description
including trigger phrases) and the section headers that subsequent
commits will fill in.

- Create plugins/review-anvil/skills/review-anvil/SKILL.md with
  frontmatter and stub sections (How to Use, Default Mix Policy,
  Loop Mechanics, Reviewer Prompt Template, Output Format, Edge Cases)
EOF
```

---

## Task 3: Fill in "How to Use" + "Default Mix Policy" sections

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil/SKILL.md`

- [ ] **Step 1: Replace the "How to Use" stub**

Replace the line `(parameters, parsing — Task 3)` (and the blank line after it) under `## How to Use` with this content:

````markdown
The user invokes the skill with a free-form args string. Parse it to extract these parameters:

| Param | Default | Plain-English forms |
|---|---|---|
| `rounds` | `3` | "5 rounds", "three rounds", "do 4 passes" |
| `agents` | `3` | "3 agents", "2 reviewers", or a mix like `"2 codex + 1 claude"`, `"three claude reviewers and one codex"` |
| `focus` | the four pillars (correctness, maintainability, simplicity, production blast-radius) | "focus on async correctness", "only: security" (the `only:` prefix replaces defaults instead of appending) |
| `target` | auto-detect | "PR #42", "branch", "uncommitted", "src/auth/", "last 3 commits" |

### Parsing rules

- `agents` may be a single number (use the default mix policy below) **or** a plain-English mix. If a mix is given, honor it exactly. The mix may name `codex`/`codex-exec` or `claude`/`claude-exec`.
- `focus` defaults are *appended* to user input. If the user prefixes their focus with `only:`, replace defaults with their list.
- `target` auto-detection precedence (when not specified):
  1. Currently checked-out PR (run `gh pr view --json number,headRefName 2>/dev/null`); if a PR is found, use its diff.
  2. Else, if the current branch differs from `main`, use the branch-vs-main diff (`git diff main...HEAD`).
  3. Else, use uncommitted changes (`git diff` and `git diff --cached`).
- If the args string is missing or empty, use all defaults.

### Example invocations

- `Skill review-anvil` → 3 rounds, default mix (2 codex + 1 claude), default four-pillar focus, auto-detected target.
- `Skill review-anvil "5 rounds, 2 codex + 1 claude, focus: async correctness, target: PR #42"`
- `Skill review-anvil "1 round, only: security, target: src/auth/"`
- `Skill review-anvil "three rounds, three claude reviewers"` → 3 rounds × 3 claude-exec.
````

- [ ] **Step 2: Replace the "Default Mix Policy" stub**

Replace the line `(table — Task 3)` (and the blank line after it) under `## Default Mix Policy` with this content:

```markdown
When the user gives a count but no mix, pick the mix from this table:

| `agents` | Mix |
|---|---|
| 1 | 1 codex-exec |
| 2 | 1 codex-exec + 1 claude-exec |
| 3 | 2 codex-exec + 1 claude-exec |
| 4 | 2 codex-exec + 2 claude-exec |
| 5 | 3 codex-exec + 2 claude-exec |
| N | ~60/40 codex/claude split, codex gets the odd one |

Rationale: codex-exec tends to surface more issues per call in our usage, so it gets the larger share. When `agents=1` we use codex-exec for the same reason.
```

- [ ] **Step 3: Verify the file still parses and the new sections are present**

Run:
```bash
grep -c '^### Parsing rules$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### Example invocations$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^| `agents` | Mix |$' plugins/review-anvil/skills/review-anvil/SKILL.md
```
Expected: each command outputs `1`.

- [ ] **Step 4: Commit**

```bash
git add plugins/review-anvil/skills/review-anvil/SKILL.md
git commit -F - <<'EOF'
feat(review-anvil): document parameters and default mix policy

Fill in the "How to Use" and "Default Mix Policy" sections of SKILL.md.
Defines the four parameters (rounds, agents, focus, target), the
plain-English parsing rules (mix forms, only: focus prefix, target
auto-detection precedence), and the codex/claude mix table.

- Add parameters table with plain-English forms
- Add parsing rules including target auto-detection precedence
- Add four worked example invocations
- Add default mix policy table for agents=1..5 and N
EOF
```

---

## Task 4: Fill in "Loop Mechanics" section

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil/SKILL.md`

- [ ] **Step 1: Replace the "Loop Mechanics" stub**

Replace the line `(6-step round procedure — Task 4)` (and the blank line after it) under `## Loop Mechanics` with this content:

````markdown
Run the loop **once per round** for `rounds` total. Within a round:

### 1. Snapshot the target

Capture the current state of the diff/branch/PR at the start of the round so all reviewers see the same input. Concretely:

- Run the appropriate `git diff …` command(s) to materialize the diff as text.
- Note the commit SHA at round start (`git rev-parse HEAD`) so the round summary can reference the exact baseline.

### 2. Dispatch reviewers in parallel

Send a **single message containing M `Agent` tool calls**, one per reviewer in the mix. For each:

- For codex-exec reviewers: `subagent_type: "general-purpose"`, with a prompt that opens with "Use the codex-exec skill to perform this review." The prompt body is the **Reviewer Prompt Template** below, filled in.
- For claude-exec reviewers: `subagent_type: "general-purpose"`, with a prompt that opens with "Use the claude-exec skill to perform this review." Same template body.

Always dispatch in parallel. Never serialize reviewers within a round.

### 3. Synthesize

When all reviewers return, merge their findings:

- **Dedup** overlapping issues (same area + same root cause). Keep the highest-severity instance and note which reviewers raised it.
- **Group** by severity (`critical` → `nit`), then by topic within severity.
- **Drop** any item already addressed in this round's earlier fixes (defensive — shouldn't normally happen in v1 since fixes happen after synthesis).

If a reviewer's output is unparseable, label its findings "unstructured" and pass through the prose into a separate section of the synthesis. Do not retry.

### 4. Apply fixes

Make the edits as the orchestrator. Group fixes by topic and **commit one logical fix-group per commit**, conventional-commit style:

- `fix(area): <what>` — for bug/correctness fixes
- `refactor(area): <what>` — for maintainability/simplicity changes
- `test(area): <what>` — when adding tests
- `chore(area): <what>` — for production-readiness tweaks (logging, error handling, config)

Items judged noise (e.g., reviewer disagreement with house style, false positives) are **deferred**, not silently dropped. Record each deferred item with a one-line reason.

### 5. Round summary

Append a short markdown block to running output:

```
### Round N — <convergence flag>
- Reviewers: <list of agents dispatched>
- Findings: C critical, H high, M medium, L low, X nit
- Fixes applied: K commits (<sha1>..<shaN>)
- Deferred: D items (see below)
```

The convergence flag is one of:
- `clean` — no findings at all
- `nits_only` — no findings above `low` severity
- `material_findings` — at least one `medium` or higher

### 6. Continue or finish

If the round number is less than `rounds`, start the next round (back to step 1). Round N+1 reviews the new state — its prior-round summary input includes the commits from round N.

After the final round, emit the **Final Report** described under "Output Format."

### Failure handling

- If a reviewer agent fails or times out, log it in the round summary as `<agent>: failed (<reason>)` and proceed with the others. No retries.
- If **all** reviewers in a round fail, abort the loop and report what happened. Do not "carry on" with zero findings — that produces a misleading clean signal.
- If `git commit` fails (pre-commit hook, conflicts), surface the error and stop the loop. Do not bypass hooks.

### Concurrency

- Within a round: parallel (single multi-tool-call message).
- Between rounds: strictly sequential (round N+1 needs round N's commits to exist).
````

- [ ] **Step 2: Verify the section is present and well-formed**

Run:
```bash
grep -c '^### 1\. Snapshot the target$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### 6\. Continue or finish$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### Failure handling$' plugins/review-anvil/skills/review-anvil/SKILL.md
```
Expected: each command outputs `1`.

- [ ] **Step 3: Commit**

```bash
git add plugins/review-anvil/skills/review-anvil/SKILL.md
git commit -F - <<'EOF'
feat(review-anvil): document the per-round loop mechanics

Specify the 6-step procedure each round executes (snapshot, parallel
dispatch, synthesize, apply fixes, round summary, continue) plus
failure-handling and concurrency rules.

- Snapshot rule: capture diff + base SHA at round start
- Dispatch rule: single message with M parallel Agent calls
- Synthesis rule: dedup + group by severity, fall back to prose for
  unparseable outputs
- Fix application rule: one commit per logical fix-group, conventional
  commit prefix per fix kind, deferred items recorded with reasons
- Round summary block format with convergence flag (clean/nits_only/
  material_findings)
- Failure handling: log-and-continue for individual reviewer failures,
  abort if all reviewers fail, never bypass git hooks
EOF
```

---

## Task 5: Fill in "Reviewer Prompt Template" section

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil/SKILL.md`

- [ ] **Step 1: Replace the "Reviewer Prompt Template" stub**

Replace the line `(context + task blocks — Task 5)` (and the blank line after it) under `## Reviewer Prompt Template` with this content:

````markdown
Each reviewer subagent receives a self-contained prompt assembled from a **context block** and a **task block**.

### Context block (orchestrator fills in)

```
You are a strict code reviewer for round {N} of {ROUNDS}.

TARGET
{Description of the target — e.g. "PR #42 (12 files, +340/-89) on branch
feature/auth-rewrite"; or "diff between `main` and `feature/x` (`git diff
main...HEAD`)"; or "uncommitted changes in src/auth/ (`git diff` +
`git diff --cached`)". Include the actual diff text or instructions to
fetch it.}

PRIOR ROUNDS
{One line per prior round, e.g.:
  Round 1: 4 critical / 6 high / 3 medium / 5 nit; 7 fixes applied
  (commits a1b2c3d..7e8f9a0); 2 deferred.
If this is round 1, write "None — this is round 1."}

FOCUS
- Correctness
- Maintainability
- Simplicity
- Production blast-radius (what could blow up in production?)
{plus any user-supplied additions, or only the user-supplied list when
they prefixed it with `only:`}
```

### Task block (fixed boilerplate, identical for every reviewer)

```
TASK
Review the target above. Be very critical. Surface issues across the
focus areas. IMPORTANT: research only — do not edit any files.

Severity guide:
- critical: data loss, security breach, production crash
- high: correctness bug or major maintainability problem
- medium: should fix but not blocking
- low: style or minor
- nit: preference

Do not repeat issues already addressed in prior rounds (see PRIOR
ROUNDS).

For each issue, return a structured finding with these keys:
- severity: one of critical|high|medium|low|nit
- area: short topic tag (e.g. "auth", "db-migration", "error-handling")
- what: one-sentence description of the problem
- why: one-to-three-sentence explanation of why it matters
- suggested_fix: PROSE description of how to fix (no patches, no code
  blocks unless quoting a single short line for clarity)

Output format: a markdown report. End the report with a fenced
```findings block containing one YAML list item per finding, like:

  ```findings
  - severity: high
    area: auth
    what: ...
    why: ...
    suggested_fix: ...
  ```

If you find nothing worth raising, return an empty findings block:

  ```findings
  []
  ```
```

### Filling in the template

- The orchestrator constructs the full prompt by concatenating the context block (with placeholders filled) and the task block verbatim.
- The reviewer subagent is invoked with a sentence like "Use the {codex-exec|claude-exec} skill to perform this review." prepended to the assembled prompt.
- Reviewers must return **prose findings only**. The skill rejects (or simply ignores) any embedded patches.
````

- [ ] **Step 2: Verify the section is present**

Run:
```bash
grep -c '^### Context block (orchestrator fills in)$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### Task block (fixed boilerplate, identical for every reviewer)$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### Filling in the template$' plugins/review-anvil/skills/review-anvil/SKILL.md
```
Expected: each command outputs `1`.

- [ ] **Step 3: Commit**

```bash
git add plugins/review-anvil/skills/review-anvil/SKILL.md
git commit -F - <<'EOF'
feat(review-anvil): document the reviewer prompt template

Specify the prompt every reviewer subagent receives: a context block
(target description, prior-round summary, focus list — filled in by the
orchestrator) and a fixed task block (severity guide, finding schema,
output format with a fenced findings YAML block).

- Reviewers are read-only critics; "research only — do not edit any files"
  is part of the boilerplate
- Findings schema: severity / area / what / why / suggested_fix (prose)
- Output format: markdown report ending with a fenced ```findings YAML
  list (or `[]` for clean rounds), so the orchestrator can parse
- Reviewers are invoked via the Agent tool with a leading instruction to
  use the codex-exec or claude-exec skill
EOF
```

---

## Task 6: Fill in "Output Format" + "Edge Cases" sections

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil/SKILL.md`

- [ ] **Step 1: Replace the "Output Format" stub**

Replace the line `(final report + per-round status — Task 6)` (and the blank line after it) under `## Output Format` with this content:

````markdown
### During execution

Print a one-line status before each round:

```
Round 2/3: dispatching 2 codex-exec + 1 claude-exec on PR #42 …
```

Append the round summary block (defined under Loop Mechanics, step 5) after each round completes.

### Final report

After the last round, emit a single markdown report with this structure:

```
# review-anvil report

**Target:** <description, e.g. "PR #42 (feature/auth-rewrite, 12 files, +340/-89)">
**Rounds:** <N>
**Mix per round:** <e.g. "2 codex-exec + 1 claude-exec">
**Focus:** <comma-separated focus list actually used>

## Round 1 — <convergence flag>
- Findings: C critical, H high, M medium, L low, X nit
- Fixes applied: K commits (<sha1>..<shaK>)
- Deferred: D items

## Round 2 — <convergence flag>
…

## Total
- Total commits: T
- Findings addressed: A
- Findings deferred: D
- Tuning suggestion: <one line, e.g. "round 3 was clean — `rounds=2`
  likely sufficient next time"; omit if no clean rounds occurred>

## Deferred items
For each deferred item across all rounds:
- **[severity] area** — what (deferred because: reason)
```

### Tuning suggestion rule

Look at the convergence flags across rounds:

- If the **last** round was `clean` or `nits_only` and any earlier round was `material_findings`, suggest `rounds = N - 1` (or further if the last two rounds were both clean/nits).
- If **every** round was `material_findings`, suggest `rounds = N + 1` next time (the loop hadn't converged).
- Otherwise omit the suggestion.
````

- [ ] **Step 2: Replace the "Edge Cases" stub**

Replace the line `(failure handling, target detection, parse fallback — Task 6)` (and the blank line after it) under `## Edge Cases` with this content:

````markdown
### Empty or trivial target

If the auto-detected target has no diff (e.g., user is on `main` with no uncommitted changes), abort early and report: "No target detected — nothing to review." Do not invent work to do.

### Target spanning a binary file or huge diff

If the diff exceeds ~5000 lines, warn in the per-round status and continue — but include in the reviewer prompt a note: "This is a large diff; you may focus on the most impactful slice if a thorough whole-diff review is impractical."

### `agents` requested exceeds reasonable limits

Reject `agents > 8` with an explanatory error before round 1. Eight parallel reviewers per round is already aggressive; higher counts produce more dedup work than signal.

### `rounds = 0`

Reject before starting. Zero rounds is a no-op and almost certainly a typo.

### A reviewer returns an unparseable findings block

Use the prose body as a free-form findings list. Do not retry. Note in the round summary: "<agent>: unstructured findings (parse failed)."

### A reviewer fails outright

Note in the round summary: "<agent>: failed (<reason>)." Continue with remaining reviewers. If **all** reviewers fail, abort and report.

### A `git commit` fails inside a round

Stop the loop, print the git error, leave any partial fixes in the working tree (or staged) for the user to resolve. Do not bypass hooks (`--no-verify`) and do not amend earlier commits.

### Conflicting findings across reviewers

If two reviewers contradict each other (one says "wrap in a try/except," another says "don't swallow this exception"), surface both under the same area in the synthesis with their reviewers tagged, and pick the orchestrator's judgment when applying fixes. Mention the disagreement in the round summary.

### Re-runs

This skill is **not idempotent**. Re-running it will start fresh review rounds against the latest state (including this run's own commits). That is usually what the user wants. If the prior run left deferred items, surface them at the top of the new run's final report under "Deferred from previous runs (still present)" — the orchestrator can detect this by inspecting recent commit messages for `fix(…)`/`refactor(…)` etc. associated with prior rounds.
````

- [ ] **Step 3: Verify both sections are present**

Run:
```bash
grep -c '^### During execution$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### Final report$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### Tuning suggestion rule$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### Empty or trivial target$' plugins/review-anvil/skills/review-anvil/SKILL.md
grep -c '^### Re-runs$' plugins/review-anvil/skills/review-anvil/SKILL.md
```
Expected: each command outputs `1`.

- [ ] **Step 4: Commit**

```bash
git add plugins/review-anvil/skills/review-anvil/SKILL.md
git commit -F - <<'EOF'
feat(review-anvil): document output format and edge cases

Spell out the per-round status line, the round summary block, and the
final report shape (target, rounds, mix, focus, per-round summaries,
totals, tuning suggestion, deferred items). Add an edge-case section
covering empty targets, oversized diffs, agent/round bounds, parse
failures, reviewer failures, git failures, conflicting findings, and
re-runs.

- Output: one-line per-round status; round summary blocks; final
  report with totals and tuning suggestion derived from convergence
  flags
- Tuning rule: shrink rounds if last round(s) were clean/nits_only,
  grow if every round had material findings
- Edge cases include hard rejects (agents>8, rounds=0), graceful
  degradation (unparseable findings → use prose), and re-run
  behavior (surface still-deferred items from prior runs)
EOF
```

---

## Task 7: Register the plugin in marketplace.json

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Add the review-anvil entry**

Open `.claude-plugin/marketplace.json`. Inside the `"plugins"` array, append a new object after the existing `claude-exec` entry. The closing `]` of the plugins array currently follows the `claude-exec` object — add a comma after that object's closing `}` and then the new entry.

The new entry should be exactly:

```json
    {
      "name": "review-anvil",
      "source": "./plugins/review-anvil",
      "description": "Iterative multi-agent review-and-fix loop. N rounds of parallel codex-exec/claude-exec reviewers, synthesized fixes with logically-separated commits.",
      "version": "0.1.0"
    }
```

Use the `Edit` tool to make this change precisely (replace the trailing `}` of the `claude-exec` entry plus the closing of the array with the comma + new object + closing).

- [ ] **Step 2: Verify the JSON is valid and contains the new plugin**

Run:
```bash
python3 -c "
import json
m = json.load(open('.claude-plugin/marketplace.json'))
names = [p['name'] for p in m['plugins']]
assert 'review-anvil' in names, f'review-anvil missing from {names}'
print('OK:', names)
"
```
Expected output starts with `OK:` and the list includes `review-anvil`.

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -F - <<'EOF'
feat(review-anvil): register plugin in marketplace.json

Add the review-anvil entry to the mrshu-skills marketplace plugin
list so it can be installed with `/plugin install review-anvil`.

- Append review-anvil entry (name, source, description, version 0.1.0)
  after claude-exec
EOF
```

---

## Task 8: Document the plugin in README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add the install line**

In the install code block in README.md (the second fenced bash block, currently containing `/plugin install scholar-search` etc.), append a new line after `/plugin install claude-exec`:

```
/plugin install review-anvil
```

- [ ] **Step 2: Add the plugin section**

After the existing `### claude-exec` section (and before `### wshot`), insert a new section. Match the prose style of the surrounding sections (one introductory paragraph + a short bullet list of key behaviors).

```markdown
### review-anvil

Iterative multi-agent review-and-fix loop. Wraps the *"let's do three rounds of fix/review"* pattern: dispatch parallel `codex-exec` and `claude-exec` reviewers, synthesize their findings, apply fixes with logically-separated commits, and repeat. Defaults to 3 rounds × 3 reviewers (2 codex + 1 claude). Configurable rounds, agent count/mix, focus, and target.

- `Skill review-anvil` — run with all defaults against auto-detected target
- `Skill review-anvil "5 rounds, 2 codex + 1 claude, focus: async correctness, target: PR #42"` — fully specified
- `Skill review-anvil "1 round, only: security, target: src/auth/"` — narrow focus, single pass

```

- [ ] **Step 3: Verify the README contains the new plugin**

Run:
```bash
grep -c '^### review-anvil$' README.md
grep -c '/plugin install review-anvil' README.md
```
Expected: each command outputs `1`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -F - <<'EOF'
docs(review-anvil): add plugin to README

Add the install instruction and a plugin section describing
review-anvil so users can discover and install it from the
marketplace.

- Add `/plugin install review-anvil` to the install block
- Add `### review-anvil` section with three example invocations
  matching the rest of the README's style
EOF
```

---

## Task 9: End-to-end verification

**Files:** None modified — this task confirms the previous tasks landed correctly.

- [ ] **Step 1: Validate every JSON file we touched**

Run:
```bash
python3 -c "
import json
for path in [
    'plugins/review-anvil/.claude-plugin/plugin.json',
    '.claude-plugin/marketplace.json',
]:
    json.load(open(path))
    print('OK:', path)
"
```
Expected: two `OK:` lines.

- [ ] **Step 2: Validate the SKILL.md frontmatter and required sections**

Run:
```bash
python3 << 'EOF'
text = open('plugins/review-anvil/skills/review-anvil/SKILL.md').read()
assert text.startswith('---\n'), 'missing opening frontmatter'
end = text.index('\n---\n', 4)
fm = text[4:end]
assert 'name: review-anvil' in fm
assert 'description:' in fm
required_headings = [
    '## How to Use',
    '## Default Mix Policy',
    '## Loop Mechanics',
    '## Reviewer Prompt Template',
    '## Output Format',
    '## Edge Cases',
]
for h in required_headings:
    assert h in text, f'missing heading: {h}'
print('OK: frontmatter + all 6 sections present')
EOF
```
Expected: `OK: frontmatter + all 6 sections present`.

- [ ] **Step 3: Confirm there are no leftover stub markers**

Run:
```bash
grep -nE '\(.*— Task [0-9]+\)' plugins/review-anvil/skills/review-anvil/SKILL.md && echo "FAIL: stub markers still present" || echo "OK: no stub markers"
```
Expected: `OK: no stub markers`.

- [ ] **Step 4: Confirm every committed file is what `git log` claims**

Run:
```bash
git log --oneline -10
git ls-files plugins/review-anvil
```
Expected: `git log` shows the 8 review-anvil commits from Tasks 1–8 (in reverse chronological order). `git ls-files` lists exactly:
```
plugins/review-anvil/.claude-plugin/plugin.json
plugins/review-anvil/skills/review-anvil/SKILL.md
```

- [ ] **Step 5: Manual smoke test (after install)**

This step is for the user to run after merging and installing. It cannot be automated from inside this plan.

```bash
# In a repo with at least one uncommitted change:
/plugin install review-anvil
# Then in a Claude Code session:
#   "let's do three rounds on the uncommitted changes"
# Verify:
#   - The skill auto-triggers on the phrase
#   - It correctly auto-detects the uncommitted-changes target
#   - It dispatches 2 codex-exec + 1 claude-exec reviewers in parallel
#   - It applies fixes and commits with logically-separated messages
#   - The final report includes all sections from the spec
```

Document the outcome (pass/fail/notes) in a follow-up commit if anything needed adjustment, but do not attempt to "fix forward" within this plan — issues found here go into a separate follow-up.

- [ ] **Step 6: Commit (only if any quick fixes needed)**

If steps 1–4 surfaced minor issues (formatting, typos), fix and commit:

```bash
git add <files>
git commit -F - <<'EOF'
fix(review-anvil): address verification findings

<one-paragraph description of what was wrong and how it was fixed>

- <bullet per fix>
EOF
```

If no issues, skip — no commit needed for a clean verification.

---

## Self-review notes

- **Spec coverage:** every section of the design spec has a corresponding task. Parameters → Task 3. Mix policy → Task 3. Loop mechanics (6 steps) → Task 4. Reviewer prompt template → Task 5. Output format → Task 6. Edge cases → Task 6. File layout → Tasks 1, 2, 7, 8. Out-of-scope items remain out of scope (no tasks for them).
- **Placeholders:** none. Every step has explicit code/content. The only "TBD" is the user's manual smoke test (Task 9, Step 5), which is appropriately scoped because it requires a real repo with uncommitted changes that the plan-executor doesn't have.
- **Type/name consistency:** `review-anvil` (kebab-case) is used everywhere — file paths, plugin name, skill frontmatter `name`, marketplace entry `name`, README section. The mix-policy table uses `codex-exec`/`claude-exec` (full names) consistently with the example invocations and reviewer-dispatch instructions.
