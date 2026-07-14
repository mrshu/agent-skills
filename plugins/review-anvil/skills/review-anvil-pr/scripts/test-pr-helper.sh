#!/usr/bin/env bash
# End-to-end smoke tests for pr-helper.sh. These tests use a fake `gh`
# binary and never touch the network.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$ROOT/pr-helper.sh"
REPRODUCTION_LINE='**Reproduction:** 4 candidates; 3 confirmed, 1 deferred after failed reproduction.'

fail() {
    printf 'test-pr-helper: %s\n' "$*" >&2
    exit 1
}

assert_file_missing() {
    local path="$1"
    [[ ! -e "$path" ]] || fail "expected file to be cleaned up: $path"
}

make_report() {
    local path="$1"
    {
        printf '# ⚒️ review-anvil report\n\n'
        printf '**Review decision:** COMMENT — material findings need attention.\n'
        printf '**Result:** 3 findings confirmed.\n'
        printf '**Scope:** Inline processing e2e fixture.\n\n'
        printf '%s\n\n' "$REPRODUCTION_LINE"
        printf '**Adversarial review:** targeted, 2 agents; 2 upheld, 1 hardened, 0 deferred, 0 dropped.\n\n'
        printf '## Findings\n'
        printf -- '- **RAVF001 [medium] auth** `src/auth.ts:12` — finding 01 has a long explanation that should post in full while retaining the finding number 01 and still point to the inline comment.\n'
        printf -- '- **RAVF002 [high] db** `src/db.ts:8` — finding 02 remains inline.\n'
        printf -- '- **RAVF003 [low] docs** `README.md:4` — finding 03 stays summary-only.\n'
        printf '\n## Non-Blocking Notes\n'
        printf -- '- **[low] docs** — low priority note should be collapsed but preserved.\n'
        printf '\n<details>\n<summary>Run details</summary>\n\n'
        printf -- '- Rounds: 1/1\n- Mix: 2 codex-exec + 1 claude-exec\n'
        printf '\n</details>\n'
        printf '\n---\n_Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._\n'
    } >"$path"
}

make_inline() {
    local path="$1"
    cat >"$path" <<'JSON'
[
  {
    "path": "src/auth.ts",
    "line": 12,
    "side": "RIGHT",
    "severity": "medium",
    "body": "**[medium] auth** — Refresh accepts missing state.\n\nThe handler rotates the session before validating the state token, so a stale tab can mint a new session after the old token should have failed. This paragraph is intentionally long so the inline processor has to preserve it without losing the core point.\n\nMove state validation before session rotation and add a regression test for missing state.",
    "suggestion": "validateState(req);\nreturn refreshSession(req);"
  },
  {
    "path": "README.md",
    "line": 4,
    "side": "RIGHT",
    "severity": "low",
    "body": "**[low] docs** — Option name differs from CLI help."
  },
  {
    "path": "src/db.ts",
    "line": 8,
    "side": "RIGHT",
    "body": "**RAVF002 [high] db** — Write failures are reported as success."
  }
]
JSON
}

install_fake_gh() {
    local bin_dir="$1"
    cat >"$bin_dir/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail

case "$1 $2" in
  "api repos/acme/widgets/pulls/42/reviews")
    has_input=0
    for arg in "$@"; do
      if [[ "$arg" == "--input" ]]; then
        has_input=1
      fi
    done
    if [[ "$has_input" == "0" ]]; then
      exit 0
    fi
    if [[ "${GH_MOCK_REVIEW_FAIL:-0}" == "1" ]]; then
      printf 'mock review failure\n' >&2
      exit 1
    fi
    cat >"$GH_MOCK_REVIEW_PAYLOAD"
    printf '{"html_url":"https://example.invalid/review/1"}\n'
    ;;
  "api repos/acme/widgets/issues/42/comments")
    printf 'https://example.invalid/comment/1\n'
    ;;
  "api repos/acme/widgets/issues/comments/123")
    for arg in "$@"; do
      if [[ "$arg" == "--input" ]]; then
        cat >"$GH_MOCK_PATCH_PAYLOAD"
        printf '{"html_url":"https://example.invalid/comment/123"}\n'
        exit 0
      fi
    done
    printf 'https://example.invalid/comment/123\n'
    ;;
  "api graphql")
    if [[ -n "${GH_MOCK_GRAPHQL_RESPONSE:-}" ]]; then
      cat "$GH_MOCK_GRAPHQL_RESPONSE"
    else
      printf '{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}\n'
    fi
    ;;
  "pr comment")
    body_file=""
    while (($#)); do
      if [[ "$1" == "--body-file" ]]; then
        body_file="$2"
        shift 2
        continue
      fi
      shift
    done
    [[ -n "$body_file" ]] || { printf 'missing --body-file\n' >&2; exit 2; }
    cp "$body_file" "$GH_MOCK_COMMENT_BODY"
    ;;
  "pr view")
    printf 'head-sha\n'
    ;;
  *)
    printf 'unexpected gh invocation: %s\n' "$*" >&2
    exit 99
    ;;
esac
GH
    chmod +x "$bin_dir/gh"
}

make_dismissals() {
    local path="$1"
    cat >"$path" <<'JSON'
{
  "acme/widgets#42": [
    {
      "path": "",
      "pattern": "auth finding 01 has a long explanation that should post in full while retaining the finding number 01 and still point to the inline comment",
      "reason": "local-test-dismissal"
    }
  ]
}
JSON
}

test_process_inline() {
    local tmp inline
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    inline="$tmp/inline.json"
    make_inline "$inline"

    REVIEW_ANVIL_INLINE_MAX_CHARS=220 "$HELPER" process-inline "$inline" >/dev/null

    jq -e 'length == 2' "$inline" >/dev/null
    jq -e 'map(select(.path == "README.md")) | length == 0' "$inline" >/dev/null
    jq -e '.[0].severity == null and .[0].suggestion == null' "$inline" >/dev/null
    jq -e '.[0].body | contains("```suggestion")' "$inline" >/dev/null
    jq -e '.[0].body | contains("without losing the core point")' "$inline" >/dev/null
    jq -e '.[0].body | contains("preserve it without losing")' "$inline" >/dev/null
    jq -e '.[0].body | contains("without...") | not' "$inline" >/dev/null
    jq -e 'map(select(.path == "src/db.ts")) | length == 1' "$inline" >/dev/null
}

test_process_inline_infers_id_prefixed_severity() {
    local tmp inline
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    inline="$tmp/inline.json"
    cat >"$inline" <<'JSON'
[
  {
    "path": "src/db.ts",
    "line": 8,
    "side": "RIGHT",
    "body": "**RAVF002 [high] db** — Write failures are reported as success."
  },
  {
    "path": "src/cache.ts",
    "line": 4,
    "side": "RIGHT",
    "body": "**RAVF003 [medium] cache** — Cache misses are logged as hits."
  }
]
JSON

    REVIEW_ANVIL_INLINE_MIN_SEVERITY=high "$HELPER" process-inline "$inline" >/dev/null

    jq -e 'length == 1' "$inline" >/dev/null
    jq -e '.[0].path == "src/db.ts"' "$inline" >/dev/null
}

test_post_review_success() {
    local tmp bin report inline
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"

    report="$tmp/report.md"
    inline="$tmp/report.md.inline.json"
    make_report "$report"
    make_inline "$inline"
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    REVIEW_ANVIL_SKIP_DISMISSED=1 \
    REVIEW_ANVIL_GITHUB_MAX_CHARS=500 \
    REVIEW_ANVIL_INLINE_MAX_CHARS=220 \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-post.out

    jq -e '.event == "COMMENT"' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("review-anvil-marker: marker-123")' "$tmp/review-payload.json" >/dev/null
    jq -e --arg line "$REPRODUCTION_LINE" '.body | split("\n") | index($line)' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("Adversarial review")' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("github.com/mrshu/agent-skills")' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("finding 01 has a long explanation that should post in full")' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("<details>\n<summary>Run details</summary>")' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("- Mix: 2 codex-exec + 1 claude-exec\n\n</details>")' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("Compact GitHub summary") | not' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments | length == 2' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[] | has("severity") | not' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[] | has("suggestion") | not' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[0].body | contains("```suggestion")' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[0].body | contains("preserve it without losing the core point")' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[0].body | contains("without...") | not' "$tmp/review-payload.json" >/dev/null
    jq -e '[.comments[].path] | index("README.md") | not' "$tmp/review-payload.json" >/dev/null
    assert_file_missing "$report"
    assert_file_missing "$inline"
    assert_file_missing "$tmp/report.md.approval.json"
}

test_post_fallback_comment() {
    local tmp bin report inline
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"

    report="$tmp/report.md"
    inline="$tmp/report.md.inline.json"
    make_report "$report"
    make_inline "$inline"
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    GH_MOCK_REVIEW_FAIL=1 \
    REVIEW_ANVIL_SKIP_DISMISSED=1 \
    REVIEW_ANVIL_GITHUB_MAX_CHARS=500 \
    REVIEW_ANVIL_INLINE_MAX_CHARS=220 \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-fallback.out

    grep -q 'review-anvil-marker: marker-123' "$tmp/comment.md"
    grep -Fxq "$REPRODUCTION_LINE" "$tmp/comment.md"
    grep -q 'Adversarial review' "$tmp/comment.md"
    grep -q 'github.com/mrshu/agent-skills' "$tmp/comment.md"
    grep -q 'finding 01' "$tmp/comment.md"
    grep -q 'Non-Blocking Notes' "$tmp/comment.md"
    ! grep -q 'Compact GitHub summary' "$tmp/comment.md"
    assert_file_missing "$report"
    assert_file_missing "$inline"
    assert_file_missing "$tmp/report.md.approval.json"
}

test_post_update_success() {
    local tmp bin report inline
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"

    report="$tmp/report.md"
    inline="$tmp/report.md.inline.json"
    make_report "$report"
    make_inline "$inline"
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_PATCH_PAYLOAD="$tmp/patch.json" \
    REVIEW_ANVIL_SKIP_DISMISSED=1 \
    REVIEW_ANVIL_GITHUB_MAX_CHARS=500 \
    REVIEW_ANVIL_INLINE_MAX_CHARS=220 \
    PATH="$bin:$PATH" \
      "$HELPER" post-update github.com acme widgets 42 123 marker-123 "$report" octocat success 2026-06-19T00:00:00Z >/tmp/review-anvil-update.out

    jq -e '.body | contains("review-anvil-improve-pr completed on this PR. cc @octocat.")' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("review-anvil-marker: marker-123")' "$tmp/patch.json" >/dev/null
    jq -e --arg line "$REPRODUCTION_LINE" '.body | split("\n") | index($line)' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("Adversarial review")' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("github.com/mrshu/agent-skills")' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("finding 01 has a long explanation that should post in full")' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("Compact GitHub summary") | not' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("Completed:")' "$tmp/patch.json" >/dev/null
    assert_file_missing "$report"
    assert_file_missing "$inline"
    assert_file_missing "$tmp/report.md.approval.json"
}

test_post_adversarial_off_downgrades_approval() {
    local tmp bin report inline
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"

    report="$tmp/report.md"
    inline="$tmp/report.md.inline.json"
    make_report "$report"
    make_inline "$inline"
    printf '{"event":"APPROVE","head_sha":"head-sha","adversarial_mode":"off"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    REVIEW_ANVIL_SKIP_DISMISSED=1 \
    REVIEW_ANVIL_GITHUB_MAX_CHARS=500 \
    REVIEW_ANVIL_INLINE_MAX_CHARS=220 \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-adversarial-off.out

    jq -e '.event == "COMMENT"' "$tmp/review-payload.json" >/dev/null
    assert_file_missing "$report"
    assert_file_missing "$inline"
    assert_file_missing "$tmp/report.md.approval.json"
}

test_post_dismisses_id_prefixed_report_findings() {
    local tmp bin report dismissals
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"

    report="$tmp/report.md"
    dismissals="$tmp/dismissals.json"
    make_report "$report"
    make_dismissals "$dismissals"
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    REVIEW_ANVIL_DISMISSALS="$dismissals" \
    REVIEW_ANVIL_GITHUB_MAX_CHARS=12000 \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-dismissed-id.out

    grep -q 'Prior PR feedback status' "$tmp/comment.md"
    ! grep -Fq 'RAVF001 [medium] auth' "$tmp/comment.md"
    grep -q 'local-test-dismissal' "$tmp/comment.md"
    assert_file_missing "$report"
    assert_file_missing "$tmp/report.md.approval.json"
}

test_compact_report_preserves_body_losslessly() {
    local tmp report expected
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    report="$tmp/report.md"
    expected="$tmp/expected.md"
    {
        printf '# ⚒️ review-anvil report\n\n'
        printf '**Result:** legacy ID compatibility fixture.\n\n'
        printf '## Findings\n'
        printf '| ID | Sev | Area | Location | Finding |\n'
        printf '|---|---|---|---|---|\n'
        printf '| RAVF001 | H | db | `src/db.ts:8` | table rows stay in the full report. |\n'
        printf -- '- **F-001 [medium] auth** `src/auth.ts:12` — dashed legacy IDs stay untouched.\n'
        printf '\n## Fixes / Would Apply\n'
        printf -- '- **RAVW001 [medium] auth** — would commit as `fix(auth): validate state`; covers RAVF001\n'
        printf '\n## Deferred / Out-of-Scope\n'
        printf -- '- **W-001 [medium] config** — legacy would-apply IDs stay untouched.\n'
    } >"$report"
    cp "$report" "$expected"

    REVIEW_ANVIL_GITHUB_MAX_CHARS=1 "$HELPER" compact-report "$report" >/tmp/review-anvil-legacy-compact.out

    cmp -s "$expected" "$report"
    [[ ! -e "$report.full.md" ]] || fail "compact-report should not create a full-copy artifact"
}

test_compact_report_preserves_invalid_and_fenced_text() {
    local tmp report expected
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    report="$tmp/report.md"
    expected="$tmp/expected.md"
    {
        printf '# ⚒️ review-anvil report\n\n'
        printf '**Result:** invalid ID fixture.\n\n'
        printf '## Misc\n'
        printf -- '- **F001 [high] db** — bare transitional IDs are not findings.\n'
        printf -- '- **F1 [high] auth** — short IDs are not findings.\n'
        printf -- '- **RAVF-001 [high] api** — dashed RAV IDs are not findings.\n'
        printf '```md\n'
        printf -- '- **RAVF999 [high] fenced** — fenced examples are not findings.\n'
        printf '```\n'
    } >"$report"
    cp "$report" "$expected"

    REVIEW_ANVIL_GITHUB_MAX_CHARS=1 "$HELPER" compact-report "$report" >/tmp/review-anvil-invalid-compact.out

    cmp -s "$expected" "$report"
}

test_compact_report_preserves_wrapped_reproduction_metadata() {
    local tmp report expected
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    report="$tmp/report.md"
    expected="$tmp/expected.md"
    {
        printf '# ⚒️ review-anvil report\n\n'
        printf '**Result:** wrapped metadata fixture.\n'
        printf '**Reproduction:** 4 candidates; 3 confirmed, 1 deferred after\n'
        printf 'failed reproduction.\n\n'
        printf '## Findings\n'
        printf -- '- **RAVF001 [medium] auth** `src/auth.ts:12` — wrapped metadata should stay exactly as generated.\n'
    } >"$report"
    cp "$report" "$expected"

    REVIEW_ANVIL_GITHUB_MAX_CHARS=1 "$HELPER" compact-report "$report" >/tmp/review-anvil-wrapped-reproduction.out

    cmp -s "$expected" "$report"
}

test_post_dismisses_table_report_findings() {
    local tmp bin report dismissals
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"

    report="$tmp/report.md"
    dismissals="$tmp/dismissals.json"
    {
        printf '# ⚒️ review-anvil report\n\n'
        printf '**Review decision:** COMMENT — table finding needs attention.\n\n'
        printf '## Findings\n'
        printf '| ID | Sev | Area | Location | Finding |\n'
        printf '|---|---|---|---|---|\n'
        printf '| RAVF001 | M | auth | `src/auth.ts:12` | finding 01 has a long explanation that should stay intact while retaining the finding number 01 and still point to the inline comment. |\n'
    } >"$report"
    cat >"$dismissals" <<'JSON'
{
  "acme/widgets#42": [
    {
      "path": "src/auth.ts",
      "pattern": "RAVF001 [medium] auth — finding 01 has a long explanation that should stay intact while retaining the finding number 01 and still point to the inline comment.",
      "reason": "local-table-dismissal"
    }
  ]
}
JSON
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    REVIEW_ANVIL_DISMISSALS="$dismissals" \
    REVIEW_ANVIL_GITHUB_MAX_CHARS=12000 \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-dismissed-table.out

    grep -q 'Prior PR feedback status' "$tmp/comment.md"
    ! grep -Fq '| RAVF001 | M | auth | `src/auth.ts:12` |' "$tmp/comment.md"
    grep -q 'local-table-dismissal' "$tmp/comment.md"
    assert_file_missing "$report"
    assert_file_missing "$tmp/report.md.approval.json"
}

test_dismissal_respects_report_paths() {
    local tmp bin report dismissals
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"

    report="$tmp/report.md"
    dismissals="$tmp/dismissals.json"
    {
        printf '# ⚒️ review-anvil report\n\n'
        printf '**Review decision:** COMMENT — same text in another file remains actionable.\n\n'
        printf '## Findings\n'
        printf -- '- **RAVF001 [medium] auth** `src/other.ts:12` — same summary text appears in another file.\n'
    } >"$report"
    cat >"$dismissals" <<'JSON'
{
  "acme/widgets#42": [
    {
      "path": "src/auth.ts",
      "pattern": "RAVF001 [medium] auth — same summary text appears in another file.",
      "reason": "local-path-dismissal"
    }
  ]
}
JSON
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    REVIEW_ANVIL_DISMISSALS="$dismissals" \
    REVIEW_ANVIL_GITHUB_MAX_CHARS=12000 \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-path-dismissal.out

    ! grep -q 'Prior PR feedback status' "$tmp/comment.md"
    grep -Fq 'same summary text appears in another file' "$tmp/comment.md"
    assert_file_missing "$report"
    assert_file_missing "$tmp/report.md.approval.json"
}

test_history_includes_open_resolved_outdated_and_summary_only() {
    local tmp bin fixture output
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{
  "data": {"repository": {"pullRequest": {
    "reviewThreads": {
      "nodes": [
        {"isResolved": true, "isOutdated": false, "path": "src/auth.ts", "line": 12,
         "comments": {"nodes": [{"body": "**[high] auth** — Refresh accepts missing state.", "url": "https://example.invalid/resolved"}]}},
        {"isResolved": false, "isOutdated": true, "path": "src/db.ts", "line": 8,
         "comments": {"nodes": [{"body": "**[medium] db** — Retry accounting commits before the write.", "url": "https://example.invalid/open"}]}}
      ],
      "pageInfo": {"hasNextPage": false, "endCursor": null}
    },
    "reviews": {
      "nodes": [
        {"state": "COMMENTED", "body": "<!-- review-anvil-marker: old -->\n# review-anvil report\n\n## Findings\n- **RAVF001 [low] docs** `README.md:4` — CLI help omits the timeout default.\n\n## Fixes / Would Apply\n- **RAVW001 [medium] auth** — would add a helper.\n\n```md\n- **RAVF999 [high] fenced** — example only.\n```", "url": "https://example.invalid/review"},
        {"state": "PENDING", "body": "<!-- review-anvil-marker: pending -->\n## Findings\n- **RAVF002 [high] hidden** — pending review is not shown.", "url": "https://example.invalid/pending"}
      ],
      "pageInfo": {"hasNextPage": false, "endCursor": null}
    },
    "comments": {"nodes": [{"body": "<!-- review-anvil-marker: fallback -->\n# review-anvil report\n\n## Suggestions\n- **[low] cli** — fallback comment finding.", "url": "https://example.invalid/comment"}], "pageInfo": {"hasNextPage": false, "endCursor": null}}
  }}}}
JSON

    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    grep -Fq '[resolved] src/auth.ts:12' "$output"
    grep -Fq '[open,outdated] src/db.ts:8' "$output"
    grep -Fq '[reported] README.md:4' "$output"
    grep -Fq 'CLI help omits the timeout default' "$output"
    grep -Fq 'fallback comment finding' "$output"
    ! grep -Fq 'would add a helper' "$output"
    ! grep -Fq 'example only' "$output"
    ! grep -Fq 'pending review is not shown' "$output"
}

test_post_suppresses_duplicate_open_thread_but_keeps_status() {
    local tmp bin fixture report inline
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "reviewThreads":{"nodes":[{"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[medium] auth** — Refresh accepts missing state.","url":"https://example.invalid/open"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    inline="$tmp/report.md.inline.json"
    printf '# review-anvil report\n\n- **RAVF001 [medium] auth** `src/auth.ts:12` — Refresh accepts missing state.\n' >"$report"
    printf '[{"path":"src/auth.ts","line":12,"side":"RIGHT","severity":"medium","body":"**[medium] auth** — Refresh accepts missing state."}]\n' >"$inline"
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-open-history.out

    grep -Fq 'Prior PR feedback status' "$tmp/comment.md"
    grep -Fq '(still-open: https://example.invalid/open)' "$tmp/comment.md"
    [[ ! -e "$tmp/review-payload.json" ]] || jq -e '.comments | length == 0' "$tmp/review-payload.json" >/dev/null
}

test_history_paginates_without_refetch_duplicates() {
    local tmp bin output
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    cat >"$bin/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail
if [[ " $* " == *" threadCursor=next "* ]]; then
  printf '%s\n' '{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"path":"src/two.ts","line":2,"comments":{"nodes":[{"body":"**[medium] paging** — second page finding.","url":"https://example.invalid/two"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},"reviews":{"nodes":[{"body":"<!-- review-anvil-marker: old -->\n## Findings\n- **RAVF001 [low] docs** — summary appears once.","url":"https://example.invalid/review"}],"pageInfo":{"hasNextPage":false,"endCursor":null}},"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}'
else
  printf '%s\n' '{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":false,"isOutdated":false,"path":"src/one.ts","line":1,"comments":{"nodes":[{"body":"**[high] paging** — first page finding.","url":"https://example.invalid/one"}]}}],"pageInfo":{"hasNextPage":true,"endCursor":"next"}},"reviews":{"nodes":[{"body":"<!-- review-anvil-marker: old -->\n## Findings\n- **RAVF001 [low] docs** — summary appears once.","url":"https://example.invalid/review"}],"pageInfo":{"hasNextPage":false,"endCursor":null}},"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}'
fi
GH
    chmod +x "$bin/gh"
    output="$tmp/history.txt"

    PATH="$bin:$PATH" "$HELPER" history github.com acme widgets 42 >"$output"

    grep -Fq '[open] src/one.ts:1' "$output"
    grep -Fq '[resolved] src/two.ts:2' "$output"
    [[ "$(grep -Fc 'summary appears once' "$output")" -eq 1 ]]
}

test_local_suppression_overrides_open_history() {
    local tmp bin fixture dismissals output
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    dismissals="$tmp/dismissals.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "reviewThreads":{"nodes":[{"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/open"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    cat >"$dismissals" <<'JSON'
{"acme/widgets#42":[{"path":"src/auth.ts","pattern":"**[high] auth** — Refresh accepts missing state.","reason":"explicit-product-decision"}]}
JSON
    output="$tmp/history.txt"

    GH_MOCK_GRAPHQL_RESPONSE="$fixture" REVIEW_ANVIL_DISMISSALS="$dismissals" \
      PATH="$bin:$PATH" "$HELPER" history github.com acme widgets 42 >"$output"

    grep -Fq '[suppressed] src/auth.ts' "$output"
    grep -Fq 'explicit-product-decision' "$output"
    ! grep -Fq '[open]' "$output"
}

test_post_time_material_history_downgrades_approval() {
    local tmp bin fixture report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "reviewThreads":{"nodes":[{"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/open-high"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    printf '# review-anvil report\n\n## Findings\n- **RAVF001 [medium] db** `src/db.ts:8` — New unrelated finding.\n' >"$report"
    printf '[{"path":"src/db.ts","line":8,"side":"RIGHT","severity":"medium","body":"**[medium] db** — New unrelated finding."}]\n' >"$report.inline.json"
    printf '{"event":"APPROVE","head_sha":"head-sha","adversarial_mode":"targeted","approval_allowed":true}\n' >"$report.approval.json"

    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-history-approval.out

    jq -e '.event == "COMMENT"' "$tmp/review-payload.json" >/dev/null
}

main() {
    command -v jq >/dev/null 2>&1 || fail "jq is required"
    test_process_inline
    test_process_inline_infers_id_prefixed_severity
    test_post_review_success
    test_post_fallback_comment
    test_post_update_success
    test_post_adversarial_off_downgrades_approval
    test_post_dismisses_id_prefixed_report_findings
    test_compact_report_preserves_body_losslessly
    test_compact_report_preserves_invalid_and_fenced_text
    test_compact_report_preserves_wrapped_reproduction_metadata
    test_post_dismisses_table_report_findings
    test_dismissal_respects_report_paths
    test_history_includes_open_resolved_outdated_and_summary_only
    test_post_suppresses_duplicate_open_thread_but_keeps_status
    test_history_paginates_without_refetch_duplicates
    test_local_suppression_overrides_open_history
    test_post_time_material_history_downgrades_approval
    printf 'test-pr-helper: all e2e checks passed\n'
}

main "$@"
