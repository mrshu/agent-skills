# review-anvil Provenance Identifiers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace newly emitted report-local `RAVF001` / `RAVW001` identifiers with provenance-bearing `RAV-RUN3-R2-F001` / `RAV-RUN3-R2-P001` identifiers while preserving historical parsing.

**Architecture:** The GitHub PR helper derives a best-effort run ordinal from finalized reports already present in PR history and supplies it to the instruction-driven review-anvil engine. The engine owns stable origin-round and run-wide finding/plan allocation; the PR helper remains only a historical parser and posting boundary. Local or degraded runs omit `RUN` rather than inventing a value.

**Tech Stack:** Bash 3-compatible shell, embedded Python 3 in `pr-helper.sh`, Markdown skills/prompts, deterministic shell contract tests, fresh-context agent pressure tests.

## Global Constraints

- Canonical PR IDs are `RAV-RUN<run>-R<origin-round>-F<ordinal>` and `RAV-RUN<run>-R<origin-round>-P<ordinal>`.
- Canonical local/degraded IDs omit the run segment: `RAV-R<origin-round>-F<ordinal>` and `RAV-R<origin-round>-P<ordinal>`.
- Run and round are positive unpadded integers; item ordinals are positive integers with a minimum emitted width of three digits.
- `RUN` counts distinct finalized success and failure reports across read-only and improve modes; unfinished starting comments do not count.
- Run allocation is best-effort. Concurrent runs may share an ordinal; UUID report markers remain collision-resistant identities.
- Origin round is immutable. Reproduction and adversarial checks are not rounds.
- Finding and plan counters are independent, monotonic, run-wide, and never reuse gaps.
- New reports emit only `F` / `P` provenance IDs. Historical parsing continues to accept `RAVF001`, `RAVW001`, `F-001`, and `W-001` where those forms were already accepted.
- PR history failure produces `RUN_ORDINAL=unavailable`; it must never fabricate `RUN1`.
- No new runtime dependency.

---

### Task 1: Derive the Best-Effort PR Run Ordinal

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh:277-385,1061-1073,1146-1230,1409-1549,1685-1699`
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh:72-143,559-632,1286-1328`

**Interfaces:**
- Consumes: existing paginated `_review_history_py(mode, owner, repo, n, ...)` GraphQL history fetch.
- Produces: `cmd_next_run <host> <owner> <repo> <n>` printing a positive integer or `unavailable`; `init` and `verify-checkout` each emit `RUN_ORDINAL=<value>`.

- [ ] **Step 1: Add failing finalized-report counting tests**

Add a fixture with three distinct finalized reports, one duplicate marker, one unfinished starting comment, and one pending review. The observable contract is `next-run == 4`:

```bash
test_next_run_counts_distinct_finalized_reports() {
    local tmp bin fixture output
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[
    {"state":"COMMENTED","body":"<!-- review-anvil-marker: run-a -->\n# ⚒️ review-anvil report","url":"https://example.invalid/a"},
    {"state":"COMMENTED","body":"# review-anvil report","url":"https://example.invalid/legacy"},
    {"state":"PENDING","body":"<!-- review-anvil-marker: pending -->\n# review-anvil report","url":"https://example.invalid/pending"}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[
    {"body":"<!-- review-anvil-marker: run-a -->\n# ⚒️ review-anvil report","url":"https://example.invalid/a-copy"},
    {"body":"<!-- review-anvil-marker: run-b -->\nreview-anvil-improve-pr failed on this PR.\n\n# ⚒️ review-anvil report","url":"https://example.invalid/b"},
    {"body":"<!-- review-anvil-marker: started -->\nreview-anvil-improve-pr started on this PR.","url":"https://example.invalid/started"}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}}
JSON

    output="$(GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" next-run github.com acme widgets 42)"
    [[ "$output" == "4" ]] || fail "expected next run 4, got $output"
}
```

Add a second test that makes fake `gh api graphql` fail and expects `unavailable` with exit 0. Extend the fake `gh` branch with:

```bash
if [[ "${GH_MOCK_GRAPHQL_FAIL:-0}" == "1" ]]; then
    printf 'mock GraphQL failure\n' >&2
    exit 1
fi
```

- [ ] **Step 2: Run the new tests and verify RED**

Run:

```bash
bash plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
```

Expected: FAIL because `next-run` is an unknown subcommand.

- [ ] **Step 3: Implement finalized-report recognition and deduplication**

After `fetch_history()` returns, add an early `_review_history_py` mode:

```python
pr_author, threads, reviews, issue_comments = fetch_history()

if mode == "next-run":
    report_heading = re.compile(
        r"^#\s+(?:⚒️\s+)?review-anvil report\s*$", re.I | re.M
    )
    marker_pattern = re.compile(
        r"<!--\s*review-anvil-marker:\s*([^\s>]+)\s*-->", re.I
    )
    finalized = set()
    for index, node in enumerate(reviews + issue_comments):
        if (node.get("state") or "").upper() == "PENDING":
            continue
        body = node.get("body") or ""
        if not report_heading.search(body):
            continue
        marker = marker_pattern.search(body)
        key = (
            f"marker:{marker.group(1).lower()}"
            if marker
            else f"url:{node.get('url') or index}"
        )
        finalized.add(key)
    print(len(finalized) + 1)
    raise SystemExit(0)
```

Do not classify a body as finalized from a UUID marker alone; the report heading is the terminal-state signal that excludes unfinished starting comments.

- [ ] **Step 4: Add the shell command and graceful degradation**

Add:

```bash
cmd_next_run() {
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}"
    for v in host owner repo n; do
        [[ -n "${!v}" ]] || die "next-run: missing <$v>"
    done
    export GH_HOST="$host"
    local ordinal
    if ordinal=$(_review_history_py next-run "$owner" "$repo" "$n"); then
        printf '%s\n' "$ordinal"
    else
        printf 'pr-helper: warning: PR run ordinal unavailable; IDs will omit RUN\n' >&2
        printf 'unavailable\n'
    fi
}
```

Wire `next-run` into the case statement and usage. In both `cmd_init` and `cmd_verify_checkout`, resolve it once after PR reachability succeeds and emit:

```bash
printf 'RUN_ORDINAL=%s\n' "$run_ordinal"
```

Use the same function in both paths; do not duplicate counting logic.

- [ ] **Step 5: Run helper tests and verify GREEN**

Run:

```bash
bash plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
bash -n plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh
```

Expected: both exit 0; the e2e script ends `test-pr-helper: all e2e checks passed`.

- [ ] **Step 6: Commit the run ordinal helper**

```bash
git add plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh \
  plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
git commit -F - <<'EOF'
feat(review-anvil-pr): derive PR review run ordinals

Previously PR initialization did not expose how many finalized review-anvil
reports already existed. Derive a best-effort next ordinal from paginated PR
history while keeping unavailable history non-fatal.

- Count distinct finalized success and failure reports
- Exclude pending reviews and unfinished starting comments
- Emit `RUN_ORDINAL` from both PR initialization paths
EOF
```

### Task 2: Parse and Preserve Finding Identity Across PR History

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh:386-699`
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh:21-69,179-205,369-548,559-632,1286-1328`

**Interfaces:**
- Consumes: canonical finding forms `RAV-RUN3-R2-F001` and `RAV-R2-F001` plus historical forms already accepted by the helper.
- Produces: one `FINDING_ID_PATTERN` used by bullet, summary, table, severity, path, signature, dismissal, and prior-feedback parsing; history entries with `finding_id` and `legacy_ids`; rendered `PR REVIEW HISTORY` lines that preserve both the canonical origin ID and legacy source aliases.

- [ ] **Step 1: Add failing parser and carry-forward coverage**

Change normal generated fixtures to use new IDs and add a focused history test containing both canonical forms:

```bash
- **RAV-RUN3-R2-F001 [medium] auth** `src/auth.ts:12` — A stale token can create a session.
- **RAV-R3-F002 [low] docs** `README.md:4` — The option name differs.
```

Keep `test_compact_report_preserves_body_losslessly` as the explicit legacy fixture with `RAVF001`, `RAVW001`, `F-001`, and `W-001`. Add malformed cases that must not parse as findings:

```text
RAV-RUN0-R2-F001
RAV-RUN3-R0-F001
RAV-RUN3-R2-F000
RAV-RUN3-R2-P001
```

The last case verifies that a plan token cannot be parsed as a finding.

Add a carry-forward fixture where:

- an open inline thread contains the canonical ID `RAV-RUN2-R1-F003`;
- a semantically duplicate report row carries the same canonical ID;
- a legacy report row for the same finding carries `RAVF007`;
- coalescing prefers the open status but must not lose either identity.

Assert that the rendered history line contains:

```text
[open] src/auth.ts:12 — Refresh accepts missing state.
id=RAV-RUN2-R1-F003
legacy=RAVF007
```

Add a second table-only case to prove that the ID in the first table cell reaches the history output. These tests defend the engine's ability to retain a prior ID; merely accepting the token syntax is insufficient.

- [ ] **Step 2: Run helper tests and verify RED**

Run:

```bash
bash plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
```

Expected: FAIL because the current `ID_PATTERN` accepts only `RAVF###` / `F-###`, `FINDING_RE` discards optional IDs, and history rendering omits identity metadata.

- [ ] **Step 3: Replace the finding ID pattern and capture IDs**

Use a complete-token-safe finding pattern:

```python
POSITIVE_PADDED_ORDINAL = r"(?:00[1-9]|0[1-9][0-9]|[1-9][0-9]{2,})"
PROVENANCE_FINDING_ID = (
    rf"RAV-(?:RUN[1-9][0-9]*-)?R[1-9][0-9]*-F{POSITIVE_PADDED_ORDINAL}"
)
LEGACY_FINDING_ID = r"(?:RAVF[0-9]{3,}|F-[0-9]{3,})"
FINDING_ID_PATTERN = rf"(?:{PROVENANCE_FINDING_ID}|{LEGACY_FINDING_ID})"
```

Replace every parser reference to the generic `ID_PATTERN` with `FINDING_ID_PATTERN`. Make the optional ID a named `finding_id` capture in `FINDING_RE` and `SUMMARY_RE`; keep `table_finding()["id"]` as the table source. Add one `finding_id_from_body()` helper so thread roots, bullets, summaries, and tables use the same extraction path.

Keep parsing case-insensitive for historical GitHub content, but normalize emitted ledger IDs to their source spelling. Do not add plan IDs to finding parsing.

- [ ] **Step 4: Preserve identity through report extraction and coalescing**

Every history item carries:

```python
{
    # existing status/path/line/signature fields
    "finding_id": "RAV-RUN2-R1-F003",  # canonical modern origin, or None
    "legacy_ids": ["RAVF007"],         # stable, deduplicated aliases
}
```

Classify `RAV-RUN...` and `RAV-R...` as modern IDs. Classify `RAVF...` and `F-...` as legacy aliases. When report findings match an existing thread, merge identity metadata into the existing entry instead of discarding the report candidate. When `coalesce_history()` replaces an item because another status has higher rank, merge identity metadata from both items into the winner first. Preserve the first observed modern ID; never silently replace it with a later run's ID.

Render the metadata inside the source parentheses so the existing status/location/summary prefix remains stable:

```text
- [open] src/auth.ts:12 — Refresh accepts missing state. (source=https://…; id=RAV-RUN2-R1-F003; legacy=RAVF007)
```

Omit `id=` or `legacy=` when unavailable. This rendered line is the exact `PR REVIEW HISTORY` input the engine receives.

- [ ] **Step 5: Run helper tests and verify GREEN**

Run:

```bash
bash plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
```

Expected: all e2e checks pass, including canonical provenance parsing, legacy fixtures, bullet/table identity extraction, and carry-forward identity after coalescing.

- [ ] **Step 6: Commit parser and history migration**

```bash
git add plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh \
  plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
git commit -F - <<'EOF'
feat(review-anvil-pr): preserve provenance IDs in PR history

Previously PR history parsing discarded item IDs while coalescing feedback.
Parse provenance finding IDs and carry canonical origins plus legacy aliases
into the reviewer history ledger.

- Capture IDs from inline, bullet, summary, and table findings
- Merge identity metadata across duplicate history entries
- Keep legacy ID fixtures as a historical read boundary
EOF
```

### Task 3: Teach the Engine Stable Provenance Allocation

**Files:**
- Create: `plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh`
- Modify: `plugins/review-anvil/skills/review-anvil/SKILL.md:21-85,172-205,313-350,362-430,495-584,608-625`
- Modify: `plugins/review-anvil/skills/review-anvil/references/reproduction-prompt.md:7-64`
- Modify: `plugins/review-anvil/skills/review-anvil/references/adversarial-prompt.md:7-128`
- Modify: `plugins/review-anvil/skills/review-anvil/references/report-artifacts.md:26-61`
- Modify: `plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh:1-80`

**Interfaces:**
- Consumes: optional trusted `run_ordinal` context (`positive integer` or `unavailable`) and normal round number `N`.
- Produces: immutable `RAV-RUN<run>-R<origin>-F<ordinal>` / `P<ordinal>` IDs, or local/degraded forms without `RUN`, used unchanged by reproduction, adversarial review, reports, inline comments, and plans.

- [ ] **Step 1: Run five baseline pressure scenarios before editing the skill**

Use five fresh-context agent calls with the current `SKILL.md` and this task:

```text
You are synthesizing review-anvil PR run 3. PR REVIEW HISTORY contains:
`- [reported] src/auth.ts:12 — stale state creates a session
(source=https://example.invalid/old; id=RAV-RUN1-R2-F007; legacy=RAVF007)`.
Round 1 re-raises that finding and adds one new finding. Round 2 re-raises the
new finding and adds a third. Round 2 also creates one plan covering findings
from both rounds. Emit the exact IDs used in reproduction, adversarial review,
the report table, and inline comments. Then show the same newly allocated IDs
for a local run with no PR history.
```

Record the outputs under an uncommitted `.review-anvil/id-skill-tests/baseline/` directory. Expected baseline failure: the current guidance emits `RAVF###` / `RAVW###`, resets or leaves round provenance implicit, or invents no coherent local form. If all five already satisfy the new contract, stop: the proposed skill change lacks a demonstrated behavior gap.

- [ ] **Step 2: Add a failing executable contract test**

Create `test-identifiers.sh` with `require` checks for the exact canonical examples, grammar, legend, run-wide counters, immutable origin round, reproduction/adversarial reuse, and local omission. Include checks such as:

```bash
require "$ENGINE" 'RAV-RUN3-R2-F001'
require "$ENGINE" 'RAV-RUN3-R2-P001'
require "$ENGINE" 'RAV-R2-F001'
require "$ENGINE" 'Finding and plan ordinals are independent, run-wide counters'
require "$ENGINE" 'Reproduction and adversarial passes are not rounds.'
require "$REPRODUCTION" 'target: RAV-RUN3-R2-F001'
require "$ADVERSARIAL" 'target: RAV-RUN3-R2-F001 | RAV-RUN3-R2-P001 | report | approval'
require "$ARTIFACTS" 'Start every identified inline finding with its complete canonical ID.'
```

Run:

```bash
bash plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh
```

Expected: FAIL on the first missing provenance contract.

- [ ] **Step 3: Replace report-local allocation with the positive provenance recipe**

In the engine, define one canonical output recipe rather than a prohibition list:

```text
PR finding: RAV-RUN<run>-R<origin-round>-F<ordinal>
PR plan:    RAV-RUN<run>-R<origin-round>-P<ordinal>
Local:     RAV-R<origin-round>-F<ordinal> / P<ordinal>
```

State the canonical grammar and semantic validation. Define assignment after semantic deduplication, prior-feedback classification, and scope filtering, before reproduction/adversarial dispatch. Define:

- independent `next_finding_ordinal` and `next_plan_ordinal` counters per run;
- counters never reset each round and never reuse gaps;
- origin round remains unchanged after confirmation, refutation, priority change, deferral, fix, or re-raise;
- carried findings consume the exact `id=` supplied in `PR REVIEW HISTORY`; legacy-only entries use their `legacy=` value as a source alias and receive a new canonical ID only when actionable;
- deterministic order by priority, normalized path, line, and topic for findings; covered-finding priority, area, and subject for plans;
- plans get the round in which their concrete fix group is first assembled.

Use `run_ordinal` only when it is a positive trusted value. Treat absent or `unavailable` as the local/degraded form. Keep UUID markers as the collision-resistant run identity.

- [ ] **Step 4: Update verifier and adversary schemas**

Replace every current generated `RAVF###` / `RAVW###` example with full provenance examples. Use `F` targets for finding verdicts and `P` targets for plan verdicts. Preserve the rule that adversaries do not create new actionable finding IDs.

Update report and inline guidance so the same complete finding ID appears in the report row, inline body, reproduction target, and adversarial target. Add the one-line legend near the first ID and add run ordinal availability to Run details.

Mention historical forms only in the migration/read-boundary paragraph; do not emit them in examples of new output.

- [ ] **Step 5: Update report-language contract expectations**

Change generated examples in `test-report-language.sh` from `RAVF001` to the canonical provenance form and invoke `test-identifiers.sh` from the verification sequence. Do not remove plain-language assertions unrelated to identifiers.

- [ ] **Step 6: Run contract tests and verify GREEN**

Run:

```bash
bash plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh
bash plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh
bash plugins/review-anvil/skills/review-anvil/scripts/test-reproduction-policy.sh
```

Expected: all three scripts exit 0.

- [ ] **Step 7: Re-run the five fresh-context scenarios with the edited skill**

Use the identical prompt from Step 1. Read every response. Each response must:

- use `RUN3` for PR-backed items and omit `RUN` locally;
- retain `RAV-RUN1-R2-F007` for the carried historical finding;
- keep the new round-1 finding's `R1` ID when it is re-raised in round 2;
- allocate the third finding and plan without resetting type counters;
- use the same IDs in reproduction, adversarial, report, and inline contexts;
- avoid emitting `RAVF###` or `RAVW###` as new IDs.

If responses diverge, tighten the positive recipe and rerun until all five have one consistent shape. Do not add exception-heavy prose.

- [ ] **Step 8: Commit engine and prompt behavior**

```bash
git add plugins/review-anvil/skills/review-anvil/SKILL.md \
  plugins/review-anvil/skills/review-anvil/references/reproduction-prompt.md \
  plugins/review-anvil/skills/review-anvil/references/adversarial-prompt.md \
  plugins/review-anvil/skills/review-anvil/references/report-artifacts.md \
  plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh \
  plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh
git commit -F - <<'EOF'
feat(review-anvil): emit provenance-bearing item IDs

Previously finding and plan IDs were scoped only to one report. Encode the
observed PR run and immutable origin round while keeping local output honest
when no run ordinal exists.

- Add stable run-wide finding and plan allocation rules
- Carry canonical IDs through verification, reports, and inline comments
- Add executable and agent-pressure contract coverage
EOF
```

### Task 4: Wire Both PR Presets to the Engine Contract

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil-pr/SKILL.md:29-41,59-118,132-144`
- Modify: `plugins/review-anvil/skills/review-anvil-improve-pr/SKILL.md:34-46,52-133`
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh:1286-1328`
- Modify: `plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh`

**Interfaces:**
- Consumes: `RUN_ORDINAL=<positive integer|unavailable>` from `init` or `verify-checkout`.
- Produces: pinned engine context `run_ordinal: <RUN_ORDINAL>` in both PR presets; user args cannot override it.

- [ ] **Step 1: Add failing preset wiring and pin tests**

Extend `test-identifiers.sh` to require `RUN_ORDINAL` capture and `run_ordinal: <RUN_ORDINAL>` in both presets. Add helper pin tests:

```bash
test_run_ordinal_is_pinned_by_pr_presets() {
    if "$HELPER" check-pins review-anvil-pr \
        "commit_mode,target,report_path,run_ordinal" \
        "focus: auth, run_ordinal: 99" >/dev/null 2>&1; then
        fail "review-anvil-pr must reject run_ordinal overrides"
    fi
    if "$HELPER" check-pins review-anvil-improve-pr \
        "commit_mode,target,report_path,run_ordinal" \
        "run_ordinal: 99" >/dev/null 2>&1; then
        fail "review-anvil-improve-pr must reject run_ordinal overrides"
    fi
}
```

Run both scripts and verify they fail because the preset text still lists only three pins.

- [ ] **Step 2: Update read-only PR preset**

Add `RUN_ORDINAL` to the documented `init` output and captured values. Change the pin list and activation recipe to:

```text
commit_mode: none, target: <locator>, report_path: <REPORT_PATH>,
run_ordinal: <RUN_ORDINAL>, <extra-user-args>, adversarial: auto, rounds: 1
```

Explain that `unavailable` makes the engine emit the no-`RUN` form and that the user cannot override the observed value.

- [ ] **Step 3: Update improve PR preset**

Add `RUN_ORDINAL` to `verify-checkout` output and capture. Pin it and pass:

```text
commit_mode: per_fix, target: <BASE_BRANCH>...HEAD,
report_path: <REPORT_PATH>, run_ordinal: <RUN_ORDINAL>, <extra-user-args>
```

The run ordinal is resolved before the starting comment. The unfinished current starting comment therefore cannot count itself.

- [ ] **Step 4: Run preset and helper contract tests**

Run:

```bash
bash plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
bash plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh
bash plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh
```

Expected: all exit 0.

- [ ] **Step 5: Commit preset wiring**

```bash
git add plugins/review-anvil/skills/review-anvil-pr/SKILL.md \
  plugins/review-anvil/skills/review-anvil-improve-pr/SKILL.md \
  plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh \
  plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh
git commit -F - <<'EOF'
feat(review-anvil): pass PR run ordinals through presets

Previously the engine had no trusted PR-wide run context. Capture the helper's
observed ordinal in both PR workflows and pin it against user overrides.

- Add `RUN_ORDINAL` to both PR preflight contracts
- Pass trusted run context into read-only and improve runs
- Cover pin rejection and unavailable-history behavior
EOF
```

### Task 5: Verify the Integrated Feature

**Files:**
- Modify only if verification exposes a defect in files already listed above.

**Interfaces:**
- Consumes: all behavior from Tasks 1-4.
- Produces: evidence that the helper, skill contracts, and reviewer dispatch wrapper remain compatible.

- [ ] **Step 1: Run every review-anvil deterministic test script**

```bash
bash plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
bash plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh
bash plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh
bash plugins/review-anvil/skills/review-anvil/scripts/test-reproduction-policy.sh
bash plugins/review-anvil/skills/review-anvil/scripts/test-run-reviewer.sh
```

Expected: every script exits 0 with its `all ... passed` terminal line.

- [ ] **Step 2: Run syntax checks**

```bash
bash -n plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh
bash -n plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
bash -n plugins/review-anvil/skills/review-anvil/scripts/test-identifiers.sh
bash -n plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh
```

Expected: all exit 0 with no output.

- [ ] **Step 3: Smoke the actual `next-run` command with a fake GitHub response**

Invoke `pr-helper.sh next-run github.com acme widgets 42` with a temporary fake `gh` that returns one finalized report and one unfinished starting comment. Observe exactly:

```text
2
```

Then make the fake GraphQL request fail and observe:

```text
unavailable
```

with the warning on stderr and exit 0.

- [ ] **Step 4: Inspect generated-skill behavior once end to end**

Run one fresh agent scenario with PR run 3 and two rounds. Require the response to show:

```text
RAV-RUN3-R1-F001
RAV-RUN3-R2-F002
RAV-RUN3-R2-P001
```

and the local equivalents without `RUN3`. This is the behavioral smoke test; shell text checks alone do not prove an agent follows the contract.

- [ ] **Step 5: Review the final staged diff and commit any verification repair**

If verification required a repair, stage only the affected review-anvil files and commit with a Conventional Commit message describing that repair. If no repair was needed, do not create an empty commit.
