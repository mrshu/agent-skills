#!/usr/bin/env bash
# End-to-end smoke tests for pr-helper.sh. These tests use a fake `gh`
# binary and never touch the network.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$ROOT/pr-helper.sh"

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
        printf '# review-anvil report\n\n'
        printf '**Review decision:** COMMENT — material findings need attention.\n'
        printf '**Result:** 3 findings confirmed.\n'
        printf '**Scope:** Inline processing e2e fixture.\n\n'
        printf '**Adversarial review:** targeted, 2 agents; 2 upheld, 1 hardened, 0 deferred, 0 dropped.\n\n'
        printf '## Findings\n'
        printf -- '- **F-001 [medium] auth** `src/auth.ts:12` — finding 01 has a long explanation that should compact while retaining the finding number 01 and still point to the inline comment.\n'
        printf -- '- **F-002 [high] db** `src/db.ts:8` — finding 02 remains inline.\n'
        printf -- '- **F-003 [low] docs** `README.md:4` — finding 03 stays summary-only.\n'
        printf '\n## Non-Blocking Notes\n'
        printf -- '- **[low] docs** — low priority note should be collapsed but preserved.\n'
        printf '\n## Run Details\n'
        printf -- '- Rounds: 1/1\n- Mix: 2 codex-exec + 1 claude-exec\n'
        printf '\n---\n_Reviewed with [review-anvil](https://github.com/mrshu/agent-skills)._\n'
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
    "body": "**[medium] auth** — Refresh accepts missing state.\n\nThe handler rotates the session before validating the state token, so a stale tab can mint a new session after the old token should have failed. This paragraph is intentionally long so the inline processor has to compact it into something readable without losing the core point.\n\nMove state validation before session rotation and add a regression test for missing state.",
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
    "body": "**[high] db** — Write failures are reported as success."
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
    printf '{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}\n'
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
      "pattern": "auth finding 01 has a long explanation that should compact while retaining the finding number 01 and still point to the inline comment",
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
    jq -e '.[0].body | contains("without...")' "$inline" >/dev/null
    jq -e '.[0].body | length <= 520' "$inline" >/dev/null
    jq -e 'map(select(.path == "src/db.ts")) | length == 1' "$inline" >/dev/null
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
    jq -e '.body | contains("Adversarial review")' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("github.com/mrshu/agent-skills")' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("Inline findings") and contains("2 anchored comment")' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments | length == 2' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[] | has("severity") | not' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[] | has("suggestion") | not' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[0].body | contains("```suggestion")' "$tmp/review-payload.json" >/dev/null
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
    grep -q 'Adversarial review' "$tmp/comment.md"
    grep -q 'github.com/mrshu/agent-skills' "$tmp/comment.md"
    grep -q 'finding 01' "$tmp/comment.md"
    grep -q '<details>' "$tmp/comment.md"
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
    jq -e '.body | contains("Adversarial review")' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("github.com/mrshu/agent-skills")' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("Inline findings") and contains("2 anchored comment")' "$tmp/patch.json" >/dev/null
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

    grep -q 'Previously dismissed on this PR' "$tmp/comment.md"
    grep -Fq 'F-001 [medium] auth' "$tmp/comment.md"
    grep -q 'local-test-dismissal' "$tmp/comment.md"
    assert_file_missing "$report"
    assert_file_missing "$tmp/report.md.approval.json"
}

main() {
    command -v jq >/dev/null 2>&1 || fail "jq is required"
    test_process_inline
    test_post_review_success
    test_post_fallback_comment
    test_post_update_success
    test_post_adversarial_off_downgrades_approval
    test_post_dismisses_id_prefixed_report_findings
    printf 'test-pr-helper: all e2e checks passed\n'
}

main "$@"
