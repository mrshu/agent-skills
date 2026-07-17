# Author-resolved PR History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop review-anvil from re-raising a PR finding whose GitHub review thread was resolved by that PR's author.

**Architecture:** The PR helper obtains the PR author and review-thread resolver from the existing paginated GraphQL request. It records an `author-resolved` root-history item only when those logins match. That item remains in reviewer history as context, then the engine drops semantic matches after synthesis/dedup and before reproduction; helper post-processing gives it the same no-reraise effect as local suppression.

**Tech Stack:** Bash, embedded Python 3, GitHub GraphQL through `gh api graphql`, Markdown skill contracts, shell integration tests with a fake `gh` binary.

## Global Constraints

- Compare `resolvedBy.login` exactly to `pullRequest.author.login`; no prose inference and no report-local finding IDs.
- Only a PR-author-resolved root review thread receives `author-resolved`; unresolved and non-author-resolved threads keep current behavior.
- Keep concise `author-resolved` records in `PR REVIEW HISTORY` for reviewer context.
- Remove semantic matches only after synthesis/dedup and before reproduction, report assembly, inline generation, and approval gating.
- Coalesce equivalent history before it reaches reviewers or post-time matching: `suppressed` wins, then `author-resolved`, then every other status.
- Do not add dependencies or change the helper's GraphQL pagination/retry behavior.

---

### Task 1: Classify PR-author-resolved history and suppress it at posting

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh:72-115,533-576,608-722`
- Modify: `plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh:285-375,522-538,622-635,646-797`

**Interfaces:**
- Consumes: GitHub GraphQL `pullRequest.author.login`, `reviewThreads.nodes[].resolvedBy.login`, existing root comment fields, and local suppression records.
- Produces: history items whose `status` is one of existing statuses plus `author-resolved`; `author-resolved` has `path`, `line`, `sig`, `summary`, `source`, `severity`, and `outdated` fields matching other root items.
- Invariant: `author-resolved` is emitted only for `isResolved == true` and an exact non-empty resolver/PR-author login match.

- [ ] **Step 1: Write failing PR-helper integration tests**

Extend the fake GraphQL default payload so its pull request contains an author:

```bash
printf '{"data":{"repository":{"pullRequest":{"author":{"login":"pr-author"},"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}\n'
```

Add `test_author_resolved_thread_is_not_raised_again` with this fixture and assertions:

```json
{
  "author": {"login": "pr-author"},
  "reviewThreads": {
    "nodes": [{
      "isResolved": true,
      "isOutdated": false,
      "resolvedBy": {"login": "pr-author"},
      "path": "src/auth.ts",
      "line": 12,
      "comments": {"nodes": [{
        "body": "**[high] auth** — Refresh accepts missing state.",
        "url": "https://example.invalid/author-resolved"
      }]}
    }],
    "pageInfo": {"hasNextPage": false, "endCursor": null}
  }
}
```

```bash
GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
PATH="$bin:$PATH" \
  "$HELPER" history github.com acme widgets 42 >"$output"
grep -Fq '[author-resolved] src/auth.ts:12' "$output"

GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
PATH="$bin:$PATH" \
  "$HELPER" post github.com acme widgets 42 marker-123 "$report"
[[ ! -e "$tmp/review-payload.json" ]] || jq -e '.comments | length == 0' "$tmp/review-payload.json" >/dev/null
! grep -Fq 'Earlier review comments' "$tmp/comment.md"
! grep -Fq 'Refresh accepts missing state' "$tmp/comment.md"
jq -e '.event == "APPROVE"' "$tmp/review-payload.json" >/dev/null
```

Add `test_non_author_resolved_thread_remains_revalidated` using the same PR author but `"resolvedBy":{"login":"reviewer"}`. Assert `[resolved]` history output and the existing `Earlier review comments` report treatment. Add both tests to `main` after the existing history/post tests.

Add `test_author_resolved_outranks_equivalent_open_history`. Put an unresolved root thread first and a PR-author-resolved root thread second; give both `src/auth.ts` and the same finding body. Assert `history` emits exactly one matching row, it is `[author-resolved]`, and posting a matching high-severity report preserves `APPROVE` without an inline comment or earlier-feedback row. This proves API connection order cannot let an open duplicate re-raise the author-resolved concern.

- [ ] **Step 2: Run the focused test file to verify RED**

Run:

```bash
bash scripts/test-pr-helper.sh
```

Expected: FAIL because history output still says `[resolved]` for the PR-author-resolved fixture and its finding still creates an earlier-feedback row or approval downgrade.

- [ ] **Step 3: Extend the GraphQL payload and history classification**

In `QUERY`, request the PR author and each thread resolver:

```graphql
pullRequest(number:$number){
  author{ login }
  reviewThreads(first:100, after:$threadCursor){
    pageInfo{ hasNextPage endCursor }
    nodes{
      isResolved
      isOutdated
      resolvedBy{ login }
      path
      line
      comments(first:50){ nodes{ body author{login} url } }
    }
  }
}
```

Have `fetch_history()` return the author login with the three existing collections:

```python
pr_author = ((pr.get("author") or {}).get("login") or "")
# Preserve the existing pagination and validation loop.
if thread_done and review_done and comment_done:
    return pr_author, threads, reviews, comments
```

Classify only exact PR-author resolutions:

```python
pr_author, threads, reviews, issue_comments = fetch_history()
history = []
for t in threads:
    comments = (t.get("comments") or {}).get("nodes") or []
    if not comments:
        continue
    body = comments[0].get("body") or ""
    sig = signature(body)
    if not sig:
        continue
    resolver = ((t.get("resolvedBy") or {}).get("login") or "")
    status = (
        "author-resolved"
        if t.get("isResolved") and pr_author and resolver == pr_author
        else "resolved" if t.get("isResolved") else "open"
    )
    history.append({"path": t.get("path") or "", "line": t.get("line"),
                    "sig": sig, "summary": summary(body),
                    "source": comments[0].get("url") or "review-thread",
                    "status": status, "severity": severity_from_body(body),
                    "outdated": bool(t.get("isOutdated"))})
```

After report-body candidates and local suppressions are loaded, coalesce equivalent records before `history` is read by `history`, `list`, or `suppress` mode:

```python
def history_rank(item):
    return {"suppressed": 2, "author-resolved": 1}.get(item["status"], 0)

def coalesce_history(items):
    coalesced = []
    for item in items:
        match_index = next(
            (index for index, current in enumerate(coalesced)
             if same_finding(item, current, require_path=False)),
            None,
        )
        if match_index is None:
            coalesced.append(item)
        elif history_rank(item) > history_rank(coalesced[match_index]):
            coalesced[match_index] = item
    return coalesced

history = coalesce_history(history)
```

When post-time matching uses `next(...)`, it will then see a single deterministic disposition. Keep equal-ranked records in their first-seen order; their behavior is identical for no-reraise purposes.

Keep report-body history and local dismissal loading unchanged. The local suppression overlay already removes matching prior history before appending `suppressed`, preserving its precedence.

- [ ] **Step 4: Give `author-resolved` the no-reraise post-time effect**

Define a local predicate before inline/report matching:

```python
def does_not_reraise(item):
    return item["status"] in {"suppressed", "author-resolved"}
```

Use it for approval gating:

```python
if item.get("severity") not in {"critical", "high"} or does_not_reraise(item):
    return False

blocking_match = any(
    severity in {"critical", "high"} and not does_not_reraise(item)
    for item, severity in matched_history
)
```

Handle matching inline and report findings without exposing an author-resolved item:

```python
if does_not_reraise(hit):
    categorically_removed += 1
    if hit["status"] == "suppressed":
        explicit_suppressions.append({
            "path": cand["path"],
            "summary": summary(item.get("body") or ""),
            "source": hit["source"],
            "sig": cand["sig"],
        })
```

Apply the equivalent branch in the report-block walk, using `summary("\n".join(block))` and `cand["path"]`. Do not append an `explicit_suppressions` row for `author-resolved`; remove the matching block and retain only the helper's aggregate audit count.

Also include `author-resolved` in `list` mode so the helper exposes the recorded disposition for audit:

```python
item for item in history
if item["status"] in {"resolved", "author-resolved", "suppressed"}
```

- [ ] **Step 5: Run the focused test file to verify GREEN**

Run:

```bash
bash scripts/test-pr-helper.sh
```

Expected: `test-pr-helper: all e2e checks passed`.

- [ ] **Step 6: Commit the tested helper behavior**

```bash
git add plugins/review-anvil/skills/review-anvil-pr/scripts/pr-helper.sh \
  plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh
git commit -F - <<'EOF'
fix(review-anvil-pr): honor author-resolved threads

Previously every resolved thread was revalidated and could be raised again.
This change treats a PR author's own resolution as an explicit disposition.

- Classify matching PR-author resolutions as author-resolved
- Suppress matching inline/report findings and approval downgrades
- Cover author, reviewer, and unresolved thread behavior
EOF
```

### Task 2: Preserve author-resolved context and drop semantic matches before reproduction

**Files:**
- Modify: `plugins/review-anvil/skills/review-anvil/SKILL.md:184-200,366-379,513-520,564-573`
- Modify: `plugins/review-anvil/skills/review-anvil/references/reviewer-prompt.md:146-160,189-196`
- Modify: `plugins/review-anvil/skills/review-anvil-pr/SKILL.md:133-134`
- Modify: `plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh:16-73`

**Interfaces:**
- Consumes: `PR REVIEW HISTORY` items from `pr-helper history`, including `author-resolved` item summaries and source URLs.
- Produces: reviewer status output that acknowledges `author-resolved` without emitting a finding; synthesis removes semantic matches before `REPRODUCTION CANDIDATES` are built.
- Invariant: `author-resolved` is context for reviewers but not an actionable carry-forward item; distinct new code instances remain reviewable only when the orchestrator documents why they are distinct.

- [ ] **Step 1: Write failing source-contract assertions**

Add a `require` helper assertion for each exact policy sentence:

```bash
require "$ENGINE" 'Keep `author-resolved` items in PR REVIEW HISTORY for reviewer context.'
require "$ENGINE" 'After synthesis and dedup, drop semantic matches to `author-resolved` items before building reproduction candidates.'
require "$ROOT/references/reviewer-prompt.md" 'Never raise an `author-resolved` item as a finding.'
require "$ROOT/../review-anvil-pr/SKILL.md" 'Only the PR author resolving a GitHub review thread creates `author-resolved` status.'
```

Add a `reject` assertion preventing the old resolved-only vocabulary from being the complete supported status set:

```bash
reject "$ROOT/references/reviewer-prompt.md" 'Revalidate `open`, `resolved`, `reported`, `deferred`, and'
```

- [ ] **Step 2: Run the language contract test to verify RED**

Run:

```bash
bash scripts/test-report-language.sh
```

Expected: FAIL with a missing `author-resolved` policy assertion.

- [ ] **Step 3: Update the engine, reviewer, and PR contracts**

In `SKILL.md`, amend the prior-feedback rule so the ordering is explicit:

```md
Keep `author-resolved` items in PR REVIEW HISTORY for reviewer context.
After synthesis and dedup, drop semantic matches to `author-resolved` items
before building reproduction candidates. Do not report, post, auto-fix, or let
those matches affect approval. A distinct new instance remains reviewable only
when the orchestrator explains the new evidence.
```

Update the round and final-report status templates to count `author-resolved` separately as skipped and to omit its individual finding text from the external report.

In `reviewer-prompt.md`, add `author-resolved` to the history vocabulary and require:

```md
- Never raise an `author-resolved` item as a finding. Keep it out of the
  findings block and mark it `author-resolved` in PRIOR FEEDBACK STATUS.
  Report a concern only when new code creates a distinct instance, and explain
  the new evidence.
```

Update the `PRIOR FEEDBACK STATUS` allowed values to include `author-resolved`.

In `review-anvil-pr/SKILL.md`, document that only an API-confirmed resolution by the PR author creates `author-resolved`; ordinary thread resolution remains revalidated.

- [ ] **Step 4: Run the language contract test to verify GREEN**

Run:

```bash
bash scripts/test-report-language.sh
```

Expected: `test-report-language: all language contract checks passed`.

- [ ] **Step 5: Run the reproduction-policy test**

Run:

```bash
bash scripts/test-reproduction-policy.sh
```

Expected: `test-reproduction-policy: all reproduction policy examples passed`.

- [ ] **Step 6: Commit the tested workflow contract**

```bash
git add plugins/review-anvil/skills/review-anvil/SKILL.md \
  plugins/review-anvil/skills/review-anvil/references/reviewer-prompt.md \
  plugins/review-anvil/skills/review-anvil-pr/SKILL.md \
  plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh
git commit -F - <<'EOF'
fix(review-anvil): skip author-resolved history

Previously reviewers revalidated every resolved PR thread as a possible
carry-forward. This change preserves author-resolved context without re-raising it.

- Add author-resolved status to PR history contracts
- Drop semantic matches after synthesis and before reproduction
- Verify the new author-facing workflow rules
EOF
```

### Task 3: Verify the integrated no-reraise contract

**Files:**
- Test: `plugins/review-anvil/skills/review-anvil-pr/scripts/test-pr-helper.sh`
- Test: `plugins/review-anvil/skills/review-anvil/scripts/test-report-language.sh`
- Test: `plugins/review-anvil/skills/review-anvil/scripts/test-reproduction-policy.sh`
- Test: `plugins/review-anvil/skills/review-anvil/scripts/test-run-reviewer.sh`

**Interfaces:**
- Consumes: Task 1 helper history and posting behavior plus Task 2 skill contracts.
- Produces: proof that author resolution is no-reraise while non-author resolution retains the existing revalidation path.

- [ ] **Step 1: Run all changed-contract test suites**

Run:

```bash
bash scripts/test-pr-helper.sh
```

from `plugins/review-anvil/skills/review-anvil-pr`, then run:

```bash
bash scripts/test-report-language.sh
bash scripts/test-reproduction-policy.sh
bash scripts/test-run-reviewer.sh
```

from `plugins/review-anvil/skills/review-anvil`.

Expected: each command exits 0 and reports its suite passed.

- [ ] **Step 2: Inspect the final staged diff**

Run:

```bash
git diff --check
git diff --staged --name-only
git diff --staged
```

Expected: no whitespace errors; staged paths match Tasks 1 and 2; no unrelated plan/spec files are staged.

- [ ] **Step 3: Report the behavior boundary**

State the verified invariant precisely:

```text
A thread resolved by the PR author is carried as reviewer context, then semantic
matches are dropped after synthesis and before reproduction. A thread resolved
by another user is still revalidated and can remain actionable.
```
