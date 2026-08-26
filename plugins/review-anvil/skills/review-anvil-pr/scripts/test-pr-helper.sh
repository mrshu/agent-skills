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
        printf -- '- **RAV-RUN3-R2-F001 [medium] auth** `src/auth.ts:12` — finding 01 has a long explanation that should post in full while retaining the finding number 01 and still point to the inline comment.\n'
        printf -- '- **RAV-R3-F002 [high] db** `src/db.ts:8` — finding 02 remains inline.\n'
        printf -- '- **RAV-RUN3-R2-F003 [low] docs** `README.md:4` — finding 03 stays summary-only.\n'
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
    "body": "**RAV-R3-F002 [high] db** — Write failures are reported as success."
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
    if [[ "${GH_MOCK_START_COMMENT:-0}" == "1" ]]; then
      printf '456\thttps://example.invalid/comment/456\n'
    else
      printf 'https://example.invalid/comment/1\n'
    fi
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
    if [[ "${GH_MOCK_GRAPHQL_FAIL:-0}" == "1" ]]; then
      printf 'mock GraphQL failure\n' >&2
      exit 1
    fi
    if [[ -n "${GH_MOCK_GRAPHQL_RESPONSE:-}" ]]; then
      cat "$GH_MOCK_GRAPHQL_RESPONSE"
    else
      printf '{"data":{"repository":{"pullRequest":{"author":{"login":"pr-author"},"reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},"reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}\n'
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
    "body": "**RAV-RUN3-R2-F002 [high] db** — Write failures are reported as success."
  },
  {
    "path": "src/cache.ts",
    "line": 4,
    "side": "RIGHT",
    "body": "**RAV-R3-F003 [medium] cache** — Cache misses are logged as hits."
  }
]
JSON

    REVIEW_ANVIL_INLINE_MIN_SEVERITY=high "$HELPER" process-inline "$inline" >/dev/null

    jq -e 'length == 1' "$inline" >/dev/null
    jq -e '.[0].path == "src/db.ts"' "$inline" >/dev/null
}

test_process_inline_preserves_terminal_finding_metadata() {
    local tmp inline marker
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    inline="$tmp/inline.json"
    marker='<!-- review-anvil: id=RAV-RUN5-R1-F001 severity=high area=publication -->'
    cat >"$inline" <<'JSON'
[
  {
    "path": "src/publish.py",
    "line": 61,
    "side": "RIGHT",
    "body": "**`--replace-existing` can remove the only good copy before replacement is ready**\n\nThe old files are deleted before the replacement is validated.\n\nPlease keep the old files recoverable until the replacement completes.\n\n<!-- review-anvil: id=RAV-RUN5-R1-F001 severity=high area=publication -->",
    "suggestion": "keep_recoverable(old_files)\nwrite_replacement()",
    "prior_feedback": "reintroduced"
  },
  {
    "path": "docs/cli.md",
    "line": 7,
    "side": "RIGHT",
    "body": "**The CLI help uses a different option name**\n\n<!-- review-anvil: id=RAV-RUN5-R1-F002 severity=low area=docs -->"
  }
]
JSON

    "$HELPER" process-inline "$inline" >/dev/null

    jq -e 'length == 1' "$inline" >/dev/null
    jq -e '.[0].severity == null and .[0].suggestion == null and .[0].prior_feedback == null' "$inline" >/dev/null
    jq -e --arg marker "$marker" '.[0].body | endswith($marker)' "$inline" >/dev/null
    jq -e --arg marker "$marker" '.[0].body | split($marker) | length == 2' "$inline" >/dev/null
    jq -e --arg marker "$marker" '
      .[0].body
      | index("```suggestion") < index("<!-- review-anvil: prior_feedback=reintroduced -->")
        and index("<!-- review-anvil: prior_feedback=reintroduced -->") < index($marker)
    ' "$inline" >/dev/null
}

test_process_inline_rejects_severity_mismatch() {
    local tmp inline original stderr
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    inline="$tmp/inline.json"
    original="$tmp/original.json"
    stderr="$tmp/stderr.txt"
    cat >"$inline" <<'JSON'
[
  {
    "path": "src/publish.py",
    "line": 61,
    "side": "RIGHT",
    "severity": "critical",
    "body": "**Replacement can delete prior records**\n\nThe old files are removed before validation.\n\n<!-- review-anvil: id=RAV-RUN5-R1-F001 severity=high area=publication -->"
  }
]
JSON
    cp "$inline" "$original"

    if "$HELPER" process-inline "$inline" 2>"$stderr"; then
        fail "process-inline must reject helper and marker severity mismatch"
    fi
    grep -Fq 'RAV-RUN5-R1-F001' "$stderr"
    grep -Fq 'helper severity critical does not match terminal marker severity high' "$stderr"
    cmp -s "$inline" "$original" \
        || fail "severity mismatch must leave inline JSON unchanged"
}

test_process_inline_rejects_invalid_marker_severity_field() {
    local tmp inline original stderr legacy
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    inline="$tmp/inline.json"
    original="$tmp/original.json"
    stderr="$tmp/stderr.txt"
    legacy="$tmp/legacy.json"
    cat >"$inline" <<'JSON'
[
  {
    "path": "src/publish.py",
    "line": 61,
    "side": "RIGHT",
    "severity": "HIGH ",
    "body": "**Replacement can delete prior records**\n\nThe old files are removed before validation.\n\n<!-- review-anvil: id=RAV-RUN5-R1-F001 severity=high area=publication -->"
  }
]
JSON
    cp "$inline" "$original"

    if "$HELPER" process-inline "$inline" 2>"$stderr"; then
        fail "process-inline must reject an invalid helper severity beside metadata"
    fi
    grep -Fq 'RAV-RUN5-R1-F001' "$stderr"
    grep -Fq 'helper severity is invalid' "$stderr"
    cmp -s "$inline" "$original" \
        || fail "invalid helper severity must leave inline JSON unchanged"

    cat >"$legacy" <<'JSON'
[
  {
    "path": "src/legacy.py",
    "line": 8,
    "side": "RIGHT",
    "severity": "urgent",
    "body": "**RAV-R3-F002 [high] runtime** — Legacy visible severity remains readable."
  }
]
JSON
    REVIEW_ANVIL_INLINE_MIN_SEVERITY=high "$HELPER" process-inline "$legacy"
    jq -e 'length == 1 and (.[0] | keys == ["body", "line", "path", "side"])' \
        "$legacy" >/dev/null
}

test_history_parses_hidden_inline_metadata() {
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
  "reviewThreads":{"nodes":[
    {"isResolved":false,"isOutdated":false,"path":"src/publish.py","line":61,"comments":{"nodes":[
      {"body":"**`--replace-existing` can remove the only good copy before replacement is ready**\n\nThe old files are deleted before the replacement is validated.\n\nPlease keep the old files recoverable until the replacement completes.\n\n<!-- review-anvil: id=RAV-RUN5-R1-F001 severity=high area=publication -->","url":"https://example.invalid/maximum-human"}
    ]}},
    {"isResolved":false,"isOutdated":false,"path":"src/input.ts","line":13,"comments":{"nodes":[
      {"body":"**`*.json` files bypass validation**\n\nThe wildcard input reaches the parser without validation.\n\n<!-- review-anvil: id=RAV-RUN5-R1-F002 severity=high area=input-files -->","url":"https://example.invalid/input"}
    ]}}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    output="$tmp/history.txt"

    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    grep -Fq '[open] src/publish.py:61 — [high] publication — `--replace-existing` can remove the only good copy before replacement is ready' "$output"
    grep -Fq 'id=RAV-RUN5-R1-F001' "$output"
    grep -Fq '[open] src/input.ts:13 — [high] input-files — `*.json` files bypass validation' "$output"
    grep -Fq 'id=RAV-RUN5-R1-F002' "$output"
}

test_hidden_identity_outranks_rewritten_prose() {
    local tmp bin fixture report inline f001_line f002_line earlier_line
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[
    {"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":12,"comments":{"nodes":[
      {"body":"**Stale tokens can create sessions**\n\nThe old request can rotate the session before validation.\n\n<!-- review-anvil: id=RAV-RUN5-R1-F001 severity=medium area=auth -->","url":"https://example.invalid/open"}
    ]}}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    inline="$tmp/report.md.inline.json"
    cat >"$report" <<'REPORT'
# review-anvil report

## Findings
- **RAV-RUN5-R1-F001 [medium] auth** `src/auth.ts:12` — Session rotation runs before state validation.
- **RAV-RUN5-R1-F002 [medium] auth** `src/auth.ts:12` — Stale tokens can create sessions.
REPORT
    cat >"$inline" <<'JSON'
[
  {
    "path": "src/auth.ts",
    "line": 12,
    "side": "RIGHT",
    "severity": "medium",
    "body": "**Session rotation runs before state validation**\n\nThe handler mutates the session before it checks the state token.\n\n<!-- review-anvil: id=RAV-RUN5-R1-F001 severity=medium area=auth -->"
  },
  {
    "path": "src/auth.ts",
    "line": 12,
    "side": "RIGHT",
    "severity": "medium",
    "body": "**Stale tokens can create sessions**\n\nThe old request can rotate the session before validation.\n\n<!-- review-anvil: id=RAV-RUN5-R1-F002 severity=medium area=auth -->"
  }
]
JSON
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-hidden-identity "$report" \
      >/tmp/review-anvil-hidden-identity.out

    jq -e '.comments | length == 1' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[0].body | contains("id=RAV-RUN5-R1-F002")' "$tmp/review-payload.json" >/dev/null
    jq -e '.comments[0].body | contains("id=RAV-RUN5-R1-F001") | not' "$tmp/review-payload.json" >/dev/null
    jq -r '.body' "$tmp/review-payload.json" >"$tmp/review-body.md"
    f001_line="$(grep -nF 'RAV-RUN5-R1-F001' "$tmp/review-body.md" | cut -d: -f1)"
    f002_line="$(grep -nF 'RAV-RUN5-R1-F002' "$tmp/review-body.md" | cut -d: -f1)"
    earlier_line="$(grep -nF '### Earlier review comments' "$tmp/review-body.md" | cut -d: -f1)"
    [[ -n "$f001_line" && -n "$f002_line" && -n "$earlier_line" ]]
    (( f002_line < earlier_line && earlier_line < f001_line ))
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
    jq -e '.body | contains("github.com/mrshu/agent-skills/#review-anvil")' "$tmp/review-payload.json" >/dev/null
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
    grep -q 'github.com/mrshu/agent-skills/#review-anvil' "$tmp/comment.md"
    grep -q 'finding 01' "$tmp/comment.md"
    grep -q 'Non-Blocking Notes' "$tmp/comment.md"
    ! grep -q 'Compact GitHub summary' "$tmp/comment.md"
    assert_file_missing "$report"
    assert_file_missing "$inline"
    assert_file_missing "$tmp/report.md.approval.json"
}

test_post_start_uses_short_declarative_comment() {
    local tmp bin stdout
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    stdout="$tmp/stdout"

    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    GH_MOCK_START_COMMENT=1 \
    PATH="$bin:$PATH" \
      "$HELPER" post-start github.com acme widgets 42 marker-123 octocat >"$stdout"

    grep -Fxq 'review-anvil-improve-pr started on this PR. cc @octocat.' "$tmp/comment.md"
    grep -Fxq 'Review agents will inspect this PR against its base branch.' "$tmp/comment.md"
    grep -Fxq 'Fix commits will be applied to this branch after checks pass.' "$tmp/comment.md"
    grep -Fxq 'This comment will contain the final report or a failure summary.' "$tmp/comment.md"
    grep -Fxq 'COMMENT_ID=456' "$stdout"
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
    jq -e '.body | contains("review-anvil selected APPROVE") | not' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("review-anvil-marker: marker-123")' "$tmp/patch.json" >/dev/null
    jq -e --arg line "$REPRODUCTION_LINE" '.body | split("\n") | index($line)' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("Adversarial review")' "$tmp/patch.json" >/dev/null
    jq -e '.body | contains("github.com/mrshu/agent-skills/#review-anvil")' "$tmp/patch.json" >/dev/null
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

    grep -q 'Earlier review comments' "$tmp/comment.md"
    ! grep -Fq 'RAV-RUN3-R2-F001 [medium] auth' "$tmp/comment.md"
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
        printf -- '- **RAV-RUN0-R2-F001 [high] provenance** — run zero is not a finding.\n'
        printf -- '- **RAV-RUN3-R0-F001 [high] provenance** — round zero is not a finding.\n'
        printf -- '- **RAV-RUN3-R2-F000 [high] provenance** — finding zero is not a finding.\n'
        printf -- '- **RAV-RUN3-R2-P001 [high] provenance** — plan IDs are not findings.\n'
        printf '```md\n'
        printf -- '- **RAV-RUN3-R2-F999 [high] fenced** — fenced examples are not findings.\n'
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
        printf -- '- **RAV-RUN3-R2-F001 [medium] auth** `src/auth.ts:12` — wrapped metadata should stay exactly as generated.\n'
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
        printf '| RAV-RUN3-R2-F001 | M | auth | `src/auth.ts:12` | finding 01 has a long explanation that should stay intact while retaining the finding number 01 and still point to the inline comment. |\n'
    } >"$report"
    cat >"$dismissals" <<'JSON'
{
  "acme/widgets#42": [
    {
      "path": "src/auth.ts",
      "pattern": "RAV-RUN3-R2-F001 [medium] auth — finding 01 has a long explanation that should stay intact while retaining the finding number 01 and still point to the inline comment.",
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

    grep -q 'Earlier review comments' "$tmp/comment.md"
    ! grep -Fq '| RAV-RUN3-R2-F001 | M | auth | `src/auth.ts:12` |' "$tmp/comment.md"
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
        printf -- '- **RAV-RUN3-R2-F001 [medium] auth** `src/other.ts:12` — same summary text appears in another file.\n'
    } >"$report"
    cat >"$dismissals" <<'JSON'
{
  "acme/widgets#42": [
    {
      "path": "src/auth.ts",
      "pattern": "RAV-RUN3-R2-F001 [medium] auth — same summary text appears in another file.",
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
    {"state":"COMMENTED","body":"<!-- review-anvil-marker: run-c -->\n# Review result","url":"https://example.invalid/c"},
    {"state":"PENDING","body":"<!-- review-anvil-marker: pending -->\n# review-anvil report","url":"https://example.invalid/pending"}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[
    {"body":"<!-- review-anvil-marker: run-a -->\n# ⚒️ review-anvil report","url":"https://example.invalid/a-copy"},
    {"body":"<!-- review-anvil-marker: run-b -->\nreview-anvil-improve-pr failed on this PR.\n\n# ⚒️ review-anvil report","url":"https://example.invalid/b"},
    {"body":"<!-- review-anvil-marker: started -->\nreview-anvil-improve-pr started on this PR.","url":"https://example.invalid/started"}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON

    output="$(GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" next-run github.com acme widgets 42)"
    [[ "$output" == "5" ]] || fail "expected next run 5, got $output"
}

test_next_run_degrades_gracefully_when_history_is_unavailable() {
    local tmp bin output
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"

    output="$(GH_MOCK_GRAPHQL_FAIL=1 PATH="$bin:$PATH" \
      "$HELPER" next-run github.com acme widgets 42)"
    [[ "$output" == "unavailable" ]] \
      || fail "expected unavailable next run, got $output"
}

test_next_run_skips_graphql_in_degraded_mode() {
    local tmp bin output warning call_marker
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    call_marker="$tmp/gh-called"
    cat >"$bin/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail
touch "$GH_CALL_MARKER"
printf 'fake gh must not be called in degraded mode\n' >&2
exit 97
GH
    chmod +x "$bin/gh"

    output="$tmp/output.txt"
    warning="$tmp/warning.txt"
    GH_CALL_MARKER="$call_marker" \
    REVIEW_ANVIL_SKIP_DISMISSED=1 \
    PATH="$bin:$PATH" \
      "$HELPER" next-run github.com acme widgets 42 >"$output" 2>"$warning"

    [[ "$(cat "$output")" == "unavailable" ]] \
      || fail "expected unavailable next run in degraded mode"
    grep -Fq 'PR run ordinal unavailable; REVIEW_ANVIL_SKIP_DISMISSED=1 enables degraded mode; IDs will omit RUN' "$warning"
    [[ ! -e "$call_marker" ]] \
      || fail "next-run invoked GraphQL despite REVIEW_ANVIL_SKIP_DISMISSED=1"
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
        {"state": "COMMENTED", "body": "<!-- review-anvil-marker: old -->\n# review-anvil report\n\n## Findings\n- **RAV-RUN3-R2-F001 [low] docs** `README.md:4` — CLI help omits the timeout default.\n\n## Fixes / Would Apply\n- **RAVW001 [medium] auth** — would add a helper.\n\n```md\n- **RAV-RUN3-R2-F999 [high] fenced** — example only.\n```", "url": "https://example.invalid/review"},
        {"state": "PENDING", "body": "<!-- review-anvil-marker: pending -->\n## Findings\n- **RAV-RUN3-R2-F002 [high] hidden** — pending review is not shown.", "url": "https://example.invalid/pending"}
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

test_history_parses_provenance_ids_and_rejects_malformed_tokens() {
    local tmp bin fixture output summary_line fenced_line
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
        {"isResolved": false, "isOutdated": false, "path": "docs/summary.md", "line": 5,
         "comments": {"nodes": [{"body": "RAV-R3-F005 [low] docs — Summary bodies preserve finding identity even when prose says id=RAV-R9-F999-extra.", "url": "https://example.invalid/summary"}]}},
        {"isResolved": false, "isOutdated": false, "path": "docs/fenced.md", "line": 6,
         "comments": {"nodes": [{"body": "[low] docs — Real finding has no ID.\n\n```md\nRAV-R3-F777 [low] example — fenced identifier only.\n```", "url": "https://example.invalid/fenced"}]}}
      ],
      "pageInfo": {"hasNextPage": false, "endCursor": null}
    },
    "reviews": {
      "nodes": [
        {"state": "COMMENTED", "body": "<!-- review-anvil-marker: new -->\n# review-anvil report\n\n## What I noticed\n- **RAV-RUN3-R2-F001 [medium] auth** `src/auth.ts:12` — A stale token can create a session.\n- **RAV-RUN0-R2-F001 [high] invalid** `src/invalid-run.ts:1` — Run zero must not parse.\n- **RAV-RUN3-R0-F001 [high] invalid** `src/invalid-round.ts:1` — Round zero must not parse.\n- **RAV-RUN3-R2-F000 [high] invalid** `src/invalid-finding.ts:1` — Finding zero must not parse.\n- **RAV-RUN3-R2-P001 [high] invalid** `src/plan.ts:1` — Plan IDs must not parse as findings.\n\n## Set aside / Outside this change\n- **RAV-R3-F002 [low] docs** `README.md:4` — The wording needs a product decision.", "url": "https://example.invalid/new-review"}
      ],
      "pageInfo": {"hasNextPage": false, "endCursor": null}
    },
    "comments": {"nodes": [], "pageInfo": {"hasNextPage": false, "endCursor": null}}
  }}}}
JSON

    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    grep -Fq '[reported] src/auth.ts:12' "$output"
    grep -Fq 'id=RAV-RUN3-R2-F001' "$output"
    grep -Fq '[deferred] README.md:4' "$output"
    grep -Fq 'id=RAV-R3-F002' "$output"
    summary_line="$(grep -F '[open] docs/summary.md:5' "$output")"
    [[ "$summary_line" == *'; id=RAV-R3-F005)'* ]]
    fenced_line="$(grep -F '[open] docs/fenced.md:6' "$output")"
    [[ "$fenced_line" != *'; id='* ]]
    ! grep -Fq 'Run zero must not parse' "$output"
    ! grep -Fq 'Round zero must not parse' "$output"
    ! grep -Fq 'Finding zero must not parse' "$output"
    ! grep -Fq 'Plan IDs must not parse as findings' "$output"
}

test_history_parses_clarity_report_findings() {
    local tmp bin fixture output medium_line low_line deferred_line fixed_line stale_line no_id_line
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{
  "data": {"repository": {"pullRequest": {
    "reviewThreads": {"nodes": [], "pageInfo": {"hasNextPage": false, "endCursor": null}},
    "reviews": {
      "nodes": [
        {
          "state": "COMMENTED",
          "body": "<!-- review-anvil-marker: older-active -->\n# review-anvil report\n\n## Findings\n- **RAV-RUN1-R1-F009 [medium] history** `src/old.ts:4` — Older active text.",
          "url": "https://example.invalid/older-active"
        },
        {
          "state": "COMMENTED",
          "body": "<!-- review-anvil-marker: clarity-report -->\n# Review result\n\n**Review decision:** COMMENT — One issue remains.\n\n## Needs attention\n\n- **Refresh creates a session before CSRF validation** `src/auth.ts:12` — An invalid token can create a session. Check the token first. (`RAV-RUN3-R2-F001`) <!-- review-anvil-report: severity=medium area=auth -->\n\n<details>\n<summary>Non-blocking findings (1)</summary>\n\n- **CLI help omits the timeout default** `docs/cli.md:7` — Consider naming the default. (`RAV-RUN3-R2-F002`) <!-- review-anvil-report: severity=low area=docs -->\n\n</details>\n\n<details>\n<summary>Set aside / Outside this change (1)</summary>\n\n- **The runtime path remains unconfirmed** `src/runtime.ts:9` — Set aside because the failing path could not be confirmed. (`RAV-RUN3-R2-F003`) <!-- review-anvil-report: severity=medium area=runtime -->\n\n</details>\n\n<details>\n<summary>Earlier review comments (2)</summary>\n\n- **fixed** — Fixed earlier item. https://example.invalid/fixed (`RAV-RUN1-R1-F009`)\n- **stale** — Stale earlier item. https://example.invalid/stale (`RAVF007`)\n\n</details>",
          "url": "https://example.invalid/clarity-report"
        },
        {
          "state": "COMMENTED",
          "body": "<!-- review-anvil-marker: clarity-no-id -->\n# Review result\n\n<details>\n<summary>Earlier review comments (1)</summary>\n\n- **reported** — Unidentified earlier item. https://example.invalid/no-id\n\n</details>",
          "url": "https://example.invalid/clarity-no-id"
        }
      ],
      "pageInfo": {"hasNextPage": false, "endCursor": null}
    },
    "comments": {"nodes": [], "pageInfo": {"hasNextPage": false, "endCursor": null}}
  }}}
}
JSON

    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    medium_line="$(grep -F '[reported] src/auth.ts:12' "$output")"
    [[ "$medium_line" == *'[medium] auth — Refresh creates a session before CSRF validation'* ]]
    [[ "$medium_line" == *'; id=RAV-RUN3-R2-F001)'* ]]
    low_line="$(grep -F '[reported] docs/cli.md:7' "$output")"
    [[ "$low_line" == *'[low] docs — CLI help omits the timeout default'* ]]
    [[ "$low_line" == *'; id=RAV-RUN3-R2-F002)'* ]]
    fixed_line="$(grep -F '[fixed] src/old.ts:4' "$output")"
    [[ "$fixed_line" == *'Fixed earlier item.'* ]]
    [[ "$fixed_line" == *'source=https://example.invalid/fixed'* ]]
    [[ "$fixed_line" == *'; id=RAV-RUN1-R1-F009)'* ]]
    deferred_line="$(grep -F '[deferred] src/runtime.ts:9' "$output")"
    [[ "$deferred_line" == *'[medium] runtime — The runtime path remains unconfirmed'* ]]
    [[ "$deferred_line" == *'; id=RAV-RUN3-R2-F003)'* ]]
    stale_line="$(grep -F '[stale] (no file anchor)' "$output")"
    [[ "$stale_line" == *'; legacy=RAVF007)'* ]]
    no_id_line="$(grep -F 'Unidentified earlier item.' "$output")"
    [[ "$no_id_line" == *'[reported] (no file anchor)'* ]]
    [[ "$no_id_line" != *'; id='* && "$no_id_line" != *'; legacy='* ]]
}

test_history_preserves_engine_generated_inline_and_grouped_ids() {
    local tmp bin fixture output inline_line grouped_line fenced_line
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
        {"isResolved": false, "isOutdated": false, "path": "src/auth.ts", "line": 12,
         "comments": {"nodes": [{"body": "**RAV-RUN3-R2-F010 [high] auth** — Refresh accepts missing state.", "url": "https://example.invalid/generated-inline"}]}}
      ],
      "pageInfo": {"hasNextPage": false, "endCursor": null}
    },
    "reviews": {
      "nodes": [
        {"state": "COMMENTED", "body": "<!-- review-anvil-marker: generated-report -->\n# review-anvil report\n\n## What I noticed\n- **RAV-RUN3-R2-F011 [medium] db** `src/db.ts:8` — Retry accounting commits before the write.\n\n```md\n- **RAV-RUN3-R2-F012 [low] fenced** `docs/example.md:1` — Fenced examples are not findings.\n```", "url": "https://example.invalid/generated-report"}
      ],
      "pageInfo": {"hasNextPage": false, "endCursor": null}
    },
    "comments": {"nodes": [], "pageInfo": {"hasNextPage": false, "endCursor": null}}
  }}}}
JSON

    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    inline_line="$(grep -F '[open] src/auth.ts:12' "$output")"
    [[ "$inline_line" == *'; id=RAV-RUN3-R2-F010)'* ]] \
      || fail "generated inline body lost RAV-RUN3-R2-F010 in history"
    grouped_line="$(grep -F '[reported] src/db.ts:8' "$output")"
    [[ "$grouped_line" == *'; id=RAV-RUN3-R2-F011)'* ]] \
      || fail "generated grouped bullet lost RAV-RUN3-R2-F011 in history"
    fenced_line="$(grep -F 'Fenced examples are not findings.' "$output" || true)"
    [[ -z "$fenced_line" ]] || fail "fenced generated example entered history"
}

test_history_merges_duplicate_identity_into_open_thread() {
    local tmp bin fixture output
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "reviewThreads":{"nodes":[
    {"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**RAV-RUN2-R1-F003 [medium] auth** — Refresh accepts missing state.","url":"https://example.invalid/open"}]}}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[
    {"state":"COMMENTED","body":"<!-- review-anvil-marker: duplicate-identity -->\n# review-anvil report\n\n## Findings\n- **RAV-RUN2-R1-F003 [medium] auth** `src/auth.ts:12` — Refresh accepts missing state.\n- **RAVF007 [medium] auth** `src/auth.ts:12` — Refresh accepts missing state.","url":"https://example.invalid/report"}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON

    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    [[ "$(grep -Fc 'Refresh accepts missing state.' "$output")" -eq 1 ]]
    grep -Fq '[open] src/auth.ts:12' "$output"
    grep -Fq 'source=https://example.invalid/open' "$output"
    grep -Fq 'id=RAV-RUN2-R1-F003' "$output"
    grep -Fq 'legacy=RAVF007' "$output"
}

test_history_preserves_table_finding_identity() {
    local tmp bin fixture output
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[
    {"state":"COMMENTED","body":"<!-- review-anvil-marker: table-identity -->\n# review-anvil report\n\n## Findings\n| ID | Sev | Area | Location | Finding |\n|---|---|---|---|---|\n| RAV-R2-F004 | M | cache | `src/cache.ts:9` | Cache misses are logged as hits. |","url":"https://example.invalid/table"}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON

    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    grep -Fq '[reported] src/cache.ts:9' "$output"
    grep -Fq 'id=RAV-R2-F004' "$output"
}

test_post_history_round_trip_preserves_modern_and_legacy_identity() {
    local tmp bin prior_fixture next_fixture report output
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    prior_fixture="$tmp/prior-history.json"
    cat >"$prior_fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[
    {"state":"COMMENTED","body":"<!-- review-anvil-marker: legacy-history -->\n# review-anvil report\n\n## Findings\n- **RAVF007 [medium] auth** `src/auth.ts:12` — Refresh accepts missing state _(only in strict mode)_.","url":"https://example.invalid/legacy-report"}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON

    report="$tmp/report.md"
    printf '# review-anvil report\n\n- **RAV-RUN3-R1-F001 [medium] auth** `src/auth.ts:12` — Refresh accepts missing state _(only in strict mode)_.\n' >"$report"
    printf '[]\n' >"$report.inline.json"
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$report.approval.json"

    GH_MOCK_GRAPHQL_RESPONSE="$prior_fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/posted-comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-round-trip "$report" \
      >/tmp/review-anvil-identity-round-trip.out

    grep -Fq '### Earlier review comments' "$tmp/posted-comment.md"
    grep -Fq 'RAV-RUN3-R1-F001' "$tmp/posted-comment.md"

    next_fixture="$tmp/next-history.json"
    jq -n --rawfile body "$tmp/posted-comment.md" '
      {data:{repository:{pullRequest:{
        reviewThreads:{nodes:[],pageInfo:{hasNextPage:false,endCursor:null}},
        reviews:{nodes:[{
          state:"COMMENTED",
          body:"<!-- review-anvil-marker: duplicate-round-trip -->\n# review-anvil report\n\n## Findings\n- **RAV-RUN3-R1-F001 [medium] auth** `src/auth.ts:12` — Refresh accepts missing state _(only in strict mode)_.",
          url:"https://example.invalid/round-trip-duplicate"
        }],pageInfo:{hasNextPage:false,endCursor:null}},
        comments:{nodes:[{body:$body,url:"https://example.invalid/round-trip"}],
                  pageInfo:{hasNextPage:false,endCursor:null}}
      }}}}
    ' >"$next_fixture"

    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$next_fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    grep -Fq '[reported] src/auth.ts:12' "$output"
    grep -Fq 'id=RAV-RUN3-R1-F001' "$output"
    grep -Fq 'legacy=RAVF007' "$output"
    grep -Fq '_(only in strict mode)_' "$output"
    [[ "$(grep -Fc 'Refresh accepts missing state' "$output")" -eq 1 ]]
}

test_post_history_round_trip_preserves_low_nit_and_set_aside_ids() {
    local tmp bin empty_fixture next_fixture report output line
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    empty_fixture="$tmp/empty-history.json"
    cat >"$empty_fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON

    report="$tmp/report.md"
    cat >"$report" <<'REPORT'
# review-anvil report

## What I noticed
<details>
<summary>Non-blocking low/nit findings</summary>

- **RAV-RUN4-R2-F020 [low] docs** `docs/cli.md:7` — The CLI help uses a different option name.
- **RAV-RUN4-R2-F021 [nit] tests** `tests/helpers.sh:11` — The duplicate fixture setup can be shared.

</details>

## Set aside / Outside this change
- **RAV-RUN4-R2-F022 [low] runtime** `src/runtime.sh:18` — set aside because the failing path could not be confirmed.
- **RAV-RUN4-R2-F023 [medium] config** `config/defaults.yml:5` — set aside after the second check: the fix is too large for a one-line default.
- **[high] infra** `ops/deploy.yml:9` — follow-up outside this change: deployment ownership needs separate review.
REPORT
    printf '[]\n' >"$report.inline.json"
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$report.approval.json"

    GH_MOCK_GRAPHQL_RESPONSE="$empty_fixture" \
    GH_MOCK_COMMENT_BODY="$tmp/posted-comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-generated-forms "$report" \
      >"$tmp/post-output.txt"

    next_fixture="$tmp/next-history.json"
    jq -n --rawfile body "$tmp/posted-comment.md" '
      {data:{repository:{pullRequest:{
        reviewThreads:{nodes:[],pageInfo:{hasNextPage:false,endCursor:null}},
        reviews:{nodes:[],pageInfo:{hasNextPage:false,endCursor:null}},
        comments:{nodes:[{body:$body,url:"https://example.invalid/generated-forms"}],
                  pageInfo:{hasNextPage:false,endCursor:null}}
      }}}}
    ' >"$next_fixture"

    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$next_fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"

    line="$(grep -F '[reported] docs/cli.md:7' "$output")"
    [[ "$line" == *'; id=RAV-RUN4-R2-F020)'* ]] \
      || fail "low generated form lost its original ID"
    line="$(grep -F '[reported] tests/helpers.sh:11' "$output")"
    [[ "$line" == *'; id=RAV-RUN4-R2-F021)'* ]] \
      || fail "nit generated form lost its original ID"
    line="$(grep -F '[deferred] src/runtime.sh:18' "$output")"
    [[ "$line" == *'; id=RAV-RUN4-R2-F022)'* ]] \
      || fail "low set-aside generated form lost its original ID"
    line="$(grep -F '[deferred] config/defaults.yml:5' "$output")"
    [[ "$line" == *'; id=RAV-RUN4-R2-F023)'* ]] \
      || fail "material set-aside generated form lost its original ID"
    line="$(grep -F '[deferred] ops/deploy.yml:9' "$output")"
    [[ "$line" != *'; id='* ]] \
      || fail "unassigned out-of-scope follow-up gained a finding ID"
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
  "reviewThreads":{"nodes":[{"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":9,"comments":{"nodes":[{"body":"**[medium] auth** — Refresh accepts missing state.","url":"https://example.invalid/wrong-line"}]}},{"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[medium] auth** — Refresh accepts missing state.","url":"https://example.invalid/open"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    inline="$tmp/report.md.inline.json"
    printf '# Review result\n\n## Needs attention\n- **Refresh accepts missing state** `src/auth.ts:12` — Refresh accepts missing state. (`RAV-RUN3-R2-F001`) <!-- review-anvil-report: severity=medium area=auth -->\n' >"$report"
    printf '[{"path":"src/auth.ts","line":12,"side":"RIGHT","severity":"medium","body":"**[medium] auth** — Refresh accepts missing state."}]\n' >"$inline"
    printf '{"event":"COMMENT","head_sha":"head-sha"}\n' >"$tmp/report.md.approval.json"

    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-open-history.out

    grep -Fq 'Earlier review comments' "$tmp/comment.md"
    grep -Fq '(This is still present. Source: https://example.invalid/open; id=RAV-RUN3-R2-F001)' "$tmp/comment.md"
    ! grep -Fq 'https://example.invalid/wrong-line' "$tmp/comment.md"
    ! grep -Eq 'Prior PR feedback status|still-open|\*\*\(inline\)\*\*' "$tmp/comment.md"
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
  printf '%s\n' '{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"path":"src/two.ts","line":2,"comments":{"nodes":[{"body":"**[medium] paging** — second page finding.","url":"https://example.invalid/two"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},"reviews":{"nodes":[{"body":"<!-- review-anvil-marker: old -->\n## Findings\n- **RAV-RUN3-R2-F001 [low] docs** — summary appears once.","url":"https://example.invalid/review"}],"pageInfo":{"hasNextPage":false,"endCursor":null}},"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}'
else
  printf '%s\n' '{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":false,"isOutdated":false,"path":"src/one.ts","line":1,"comments":{"nodes":[{"body":"**[high] paging** — first page finding.","url":"https://example.invalid/one"}]}}],"pageInfo":{"hasNextPage":true,"endCursor":"next"}},"reviews":{"nodes":[{"body":"<!-- review-anvil-marker: old -->\n## Findings\n- **RAV-RUN3-R2-F001 [low] docs** — summary appears once.","url":"https://example.invalid/review"}],"pageInfo":{"hasNextPage":false,"endCursor":null}},"comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}}'
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
  "reviewThreads":{"nodes":[{"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**RAV-RUN2-R1-F003 [high] auth** — Refresh accepts missing state.","url":"https://example.invalid/open"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[{"state":"COMMENTED","body":"<!-- review-anvil-marker: legacy-suppression -->\n# review-anvil report\n\n## Findings\n- **RAVF007 [high] auth** `src/auth.ts:12` — Refresh accepts missing state.","url":"https://example.invalid/legacy"}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
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
    grep -Fq 'id=RAV-RUN2-R1-F003' "$output"
    grep -Fq 'legacy=RAVF007' "$output"
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
    printf '# review-anvil report\n\n## Findings\n- **RAV-RUN3-R2-F001 [medium] db** `src/db.ts:8` — New unrelated finding.\n' >"$report"
    printf '[{"path":"src/db.ts","line":8,"side":"RIGHT","severity":"medium","body":"**[medium] db** — New unrelated finding."}]\n' >"$report.inline.json"
    printf '{"event":"APPROVE","head_sha":"head-sha","adversarial_mode":"targeted","approval_allowed":true}\n' >"$report.approval.json"

    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report" >/tmp/review-anvil-history-approval.out

    jq -e '.event == "COMMENT"' "$tmp/review-payload.json" >/dev/null
}

test_author_resolved_thread_is_not_raised_again() {
    local tmp bin fixture output report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"
    grep -Fq '[author-resolved] src/auth.ts:12' "$output"

    report="$tmp/report.md"
    printf '# review-anvil report\n\n## Findings\n- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:12` — Refresh accepts missing state.\n' >"$report"
    printf '[{"path":"src/auth.ts","line":12,"side":"RIGHT","severity":"high","body":"**[high] auth** — Refresh accepts missing state."}]\n' >"$report.inline.json"
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    : >"$tmp/comment.md"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    [[ ! -e "$tmp/review-payload.json" ]] || jq -e '.comments | length == 0' "$tmp/review-payload.json" >/dev/null
    jq -e '(.body | contains("Refresh accepts missing state") | not) and (.body | contains("Earlier review comments") | not)' "$tmp/review-payload.json" >/dev/null
    ! grep -Fq 'Earlier review comments' "$tmp/comment.md"
    ! grep -Fq 'Refresh accepts missing state' "$tmp/comment.md"
    jq -e '.event == "APPROVE"' "$tmp/review-payload.json" >/dev/null
}

test_reintroduced_author_resolved_finding_is_posted_and_remains_history_actionable() {
    local tmp bin fixture report history
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/author-resolved.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    cat >"$report" <<'REPORT'
# review-anvil report

## Findings
- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:12` — Refresh accepts missing state.
- **RAV-R3-F002 [high] auth** `src/auth.ts:13` — Refresh accepts missing state.
<!-- review-anvil: prior_feedback=reintroduced -->
REPORT
    cat >"$report.inline.json" <<'JSON'
[
  {"path":"src/auth.ts","line":12,"side":"RIGHT","severity":"high","body":"**[high] auth** — Refresh accepts missing state."},
  {"path":"src/auth.ts","line":13,"side":"RIGHT","severity":"high","prior_feedback":"reintroduced","body":"**[high] auth** — Refresh accepts missing state."}
]
JSON
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    jq -e '.event == "COMMENT"' "$tmp/review-payload.json" >/dev/null
    jq -e '(.comments | length) == 1 and .comments[0].line == 13 and (.comments[0] | has("prior_feedback") | not) and (.comments[0].body | contains("<!-- review-anvil: prior_feedback=reintroduced -->"))' "$tmp/review-payload.json" >/dev/null
    jq -e '(.body | contains("RAV-R3-F002")) and (.body | contains("RAV-RUN3-R2-F001") | not)' "$tmp/review-payload.json" >/dev/null

    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[
    {"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}},
    {"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":13,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.\n\n<!-- review-anvil: prior_feedback=reintroduced -->","url":"https://example.invalid/reintroduced"}]}}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    history="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$history"
    grep -Fq '[open,reintroduced] src/auth.ts:13' "$history"
    grep -Fq 'https://example.invalid/reintroduced' "$history"
}
test_body_only_report_reintroduction_outranks_author_resolved_history() {
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
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[{"state":"COMMENTED","body":"<!-- review-anvil-marker: body-only -->\n# review-anvil report\n\n## Findings\n- **RAV-R3-F002 [high] auth** `src/auth.ts:13` — Refresh accepts missing state.\n<!-- review-anvil: prior_feedback=reintroduced -->","url":"https://example.invalid/body-only-report"}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"
    grep -Fq '[reported,reintroduced] src/auth.ts:13' "$output"
    grep -Fq 'https://example.invalid/body-only-report' "$output"
    ! grep -Fq '[author-resolved] src/auth.ts:12' "$output"
}

test_top_level_fallback_reintroduction_outranks_author_resolved_history() {
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
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[{"body":"<!-- review-anvil-marker: fallback-after-invalid-inline -->\n# review-anvil report\n\n## Findings\n- **RAV-R3-F002 [high] auth** `src/auth.ts:13` — Refresh accepts missing state.\n<!-- review-anvil: prior_feedback=reintroduced -->","url":"https://example.invalid/top-level-fallback"}],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"
    grep -Fq '[reported,reintroduced] src/auth.ts:13' "$output"
    grep -Fq 'https://example.invalid/top-level-fallback' "$output"
    ! grep -Fq '[author-resolved] src/auth.ts:12' "$output"
}


test_reintroduced_medium_finding_preserves_approval() {
    local tmp bin fixture report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/author-resolved.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    cat >"$report" <<'REPORT'
# review-anvil report

## Findings
- **RAV-RUN3-R2-F001 [medium] auth** `src/auth.ts:13` — Refresh accepts missing state.
<!-- review-anvil: prior_feedback=reintroduced -->
REPORT
    cat >"$report.inline.json" <<'JSON'
[{"path":"src/auth.ts","line":13,"side":"RIGHT","severity":"medium","prior_feedback":"reintroduced","body":"**[medium] auth** — Refresh accepts missing state."}]
JSON
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    jq -e '.event == "APPROVE" and (.comments | length) == 1 and (.comments[0] | has("prior_feedback") | not)' "$tmp/review-payload.json" >/dev/null
}

assert_reintroduced_signal_propagates_to_both_artifacts() {
    local report_signal="$1" inline_signal="$2" history_mode="${3:-author-resolved}" inline_field="" expected_event="COMMENT" tmp bin fixture report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir -p "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/author-resolved.json"
    if [[ "$history_mode" == "empty" ]]; then
        cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    else
        cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    fi
    if [[ "$history_mode" == "empty" ]]; then
        expected_event="APPROVE"
    fi
    report="$tmp/report.md"
    cat >"$report" <<'REPORT'
# review-anvil report

## Findings
- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:13` — Refresh accepts missing state.
REPORT
    if [[ "$report_signal" == "reintroduced" ]]; then
        printf '<!-- review-anvil: prior_feedback=reintroduced -->\n' >>"$report"
    fi
    if [[ "$inline_signal" == "reintroduced" ]]; then
        inline_field=',"prior_feedback":"reintroduced"'
    fi
    cat >"$report.inline.json" <<JSON
[{"path":"src/auth.ts","line":13,"side":"RIGHT","severity":"high"${inline_field},"body":"**[high] auth** — Refresh accepts missing state."}]
JSON
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    : >"$tmp/comment.md"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    jq -e --arg event "$expected_event" '.event == $event and (.comments | length) == 1 and .comments[0].line == 13 and (.comments[0].body | contains("<!-- review-anvil: prior_feedback=reintroduced -->"))' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:13` — Refresh accepts missing state.\n<!-- review-anvil: prior_feedback=reintroduced -->")' "$tmp/review-payload.json" >/dev/null

    posted_body="$(jq -r '.comments[0].body' "$tmp/review-payload.json")"
    jq -n --arg body "$posted_body" '
      {"data":{"repository":{"pullRequest":{
        "author":{"login":"pr-author"},
        "reviewThreads":{"nodes":[
          {"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}},
          {"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":13,"comments":{"nodes":[{"body":$body,"url":"https://example.invalid/reintroduced"}]}}
        ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
        "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
        "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
      }}}}
    ' >"$fixture"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$tmp/history.txt"
    grep -Fq '[open,reintroduced] src/auth.ts:13' "$tmp/history.txt"
}

test_report_marker_reintroduction_preserves_inline_companion() {
    assert_reintroduced_signal_propagates_to_both_artifacts reintroduced ""
}

test_inline_reintroduction_preserves_report_companion() {
    assert_reintroduced_signal_propagates_to_both_artifacts "" reintroduced
}

test_report_marker_reintroduction_persists_without_history() {
    assert_reintroduced_signal_propagates_to_both_artifacts reintroduced "" empty
}

test_inline_reintroduction_persists_without_history() {
    assert_reintroduced_signal_propagates_to_both_artifacts "" reintroduced empty
}
assert_reintroduced_range_signal_propagates_to_both_artifacts() {
    local report_signal="$1" inline_signal="$2" inline_field="" tmp bin fixture report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir -p "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/author-resolved.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/db.ts","line":99,"comments":{"nodes":[{"body":"**[high] db** — Write failures are reported as success.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    cat >"$report" <<'REPORT'
# review-anvil report

## Findings
- **RAV-RUN3-R2-F001 [high] db** `src/db.ts:100-110` — Write failures are reported as success.
REPORT
    if [[ "$report_signal" == "reintroduced" ]]; then
        printf '<!-- review-anvil: prior_feedback=reintroduced -->\n' >>"$report"
    fi
    if [[ "$inline_signal" == "reintroduced" ]]; then
        inline_field=',"prior_feedback":"reintroduced"'
    fi
    cat >"$report.inline.json" <<JSON
[{"path":"src/db.ts","start_line":100,"line":110,"side":"RIGHT","severity":"high"${inline_field},"body":"**[high] db** — Write failures are reported as success."}]
JSON
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    : >"$tmp/comment.md"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    jq -e '.event == "COMMENT" and (.comments | length) == 1 and .comments[0].line == 110' "$tmp/review-payload.json" >/dev/null
    jq -e '.body | contains("RAV-RUN3-R2-F001")' "$tmp/review-payload.json" >/dev/null
}

test_report_marker_range_reintroduction_preserves_inline_companion() {
    assert_reintroduced_range_signal_propagates_to_both_artifacts reintroduced ""
}

test_inline_field_range_reintroduction_preserves_report_companion() {
    assert_reintroduced_range_signal_propagates_to_both_artifacts "" reintroduced
}

test_position_only_reintroduction_does_not_mark_ambiguous_companions() {
    local tmp bin fixture report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/author-resolved.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    cat >"$report" <<'REPORT'
# review-anvil report

## Findings
- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:13` — Refresh accepts missing state.
<!-- review-anvil: prior_feedback=reintroduced -->
REPORT
    cat >"$report.inline.json" <<'JSON'
[
  {"path":"src/auth.ts","position":101,"severity":"high","body":"**[high] auth** — Refresh accepts missing state."},
  {"path":"src/auth.ts","position":102,"severity":"high","body":"**[high] auth** — Refresh accepts missing state."}
]
JSON
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    [[ ! -e "$tmp/review-payload.json" ]]
    grep -Fq '<!-- review-anvil: prior_feedback=reintroduced -->' "$tmp/comment.md"
}

test_position_only_field_does_not_mark_ambiguous_report_companion() {
    local tmp bin fixture report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/author-resolved.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    cat >"$report" <<'REPORT'
# review-anvil report

## Findings
- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:13` — Refresh accepts missing state.
REPORT
    cat >"$report.inline.json" <<'JSON'
[
  {"path":"src/auth.ts","position":101,"severity":"high","prior_feedback":"reintroduced","body":"**[high] auth** — Refresh accepts missing state."},
  {"path":"src/auth.ts","position":102,"severity":"high","body":"**[high] auth** — Refresh accepts missing state."}
]
JSON
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    jq -e '(.comments | length) == 1 and .comments[0].position == 101 and (.comments[0].body | contains("<!-- review-anvil: prior_feedback=reintroduced -->")) and (.body | contains("<!-- review-anvil: prior_feedback=reintroduced -->") | not)' "$tmp/review-payload.json" >/dev/null
}

test_non_author_resolved_thread_remains_revalidated() {
    local tmp bin fixture output report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[{"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"reviewer"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/reviewer-resolved"}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"
    grep -Fq '[resolved] src/auth.ts:12' "$output"

    report="$tmp/report.md"
    printf '# review-anvil report\n\n## Findings\n- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:12` — Refresh accepts missing state.\n' >"$report"
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    : >"$tmp/comment.md"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    grep -Fq 'Earlier review comments' "$tmp/comment.md"
    grep -Fq 'Refresh accepts missing state' "$tmp/comment.md"
}

test_author_resolved_outranks_equivalent_open_history() {
    local tmp bin fixture output report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[
    {"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/open"}]}},
    {"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"
    [[ "$(grep -Fc 'Refresh accepts missing state' "$output")" -eq 1 ]]
    grep -Fq '[author-resolved] src/auth.ts:12' "$output"

    report="$tmp/report.md"
    printf '# review-anvil report\n\n## Findings\n- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:12` — Refresh accepts missing state.\n' >"$report"
    printf '[{"path":"src/auth.ts","line":12,"side":"RIGHT","severity":"high","body":"**[high] auth** — Refresh accepts missing state."}]\n' >"$report.inline.json"
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    : >"$tmp/comment.md"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    [[ ! -e "$tmp/review-payload.json" ]] || jq -e '.comments | length == 0' "$tmp/review-payload.json" >/dev/null
    ! grep -Fq 'Earlier review comments' "$tmp/comment.md"
    jq -e '.event == "APPROVE"' "$tmp/review-payload.json" >/dev/null
}

test_author_resolved_does_not_outrank_distinct_open_history() {
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
  "reviewThreads":{"nodes":[
    {"isResolved":false,"isOutdated":false,"path":"src/auth.ts","line":40,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/open-distinct"}]}},
    {"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":12,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    output="$tmp/history.txt"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" PATH="$bin:$PATH" \
      "$HELPER" history github.com acme widgets 42 >"$output"
    grep -Fq '[open] src/auth.ts:40' "$output"
    grep -Fq '[author-resolved] src/auth.ts:12' "$output"
}

test_distinct_open_history_is_revalidated_when_author_resolved_comes_first() {
    local tmp bin fixture output report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    bin="$tmp/bin"
    mkdir "$bin"
    install_fake_gh "$bin"
    fixture="$tmp/graphql.json"
    cat >"$fixture" <<'JSON'
{"data":{"repository":{"pullRequest":{
  "author":{"login":"pr-author"},
  "reviewThreads":{"nodes":[
    {"isResolved":true,"isOutdated":false,"resolvedBy":{"login":"pr-author"},"path":"src/auth.ts","line":40,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/author-resolved"}]}},
    {"isResolved":false,"isOutdated":false,"path":"src/auth.ts","startLine":12,"line":40,"comments":{"nodes":[{"body":"**[high] auth** — Refresh accepts missing state.","url":"https://example.invalid/open-distinct"}]}}
  ],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "reviews":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}},
  "comments":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}
}}}}
JSON
    report="$tmp/report.md"
    printf '# review-anvil report\n\n## Findings\n- **RAV-RUN3-R2-F001 [high] auth** `src/auth.ts:12-40` — Refresh accepts missing state.\n- **RAV-R3-F002 [medium] db** `src/db.ts:8` — New unrelated finding.\n' >"$report"
    printf '[{"path":"src/auth.ts","start_line":12,"line":40,"side":"RIGHT","start_side":"RIGHT","severity":"high","body":"**[high] auth** — Refresh accepts missing state."},{"path":"src/db.ts","line":8,"side":"RIGHT","severity":"medium","body":"**[medium] db** — New unrelated finding."}]\n' >"$report.inline.json"
    printf '{"event":"APPROVE","head_sha":"head-sha","approval_allowed":true}\n' >"$report.approval.json"
    GH_MOCK_GRAPHQL_RESPONSE="$fixture" \
    GH_MOCK_REVIEW_PAYLOAD="$tmp/review-payload.json" \
    GH_MOCK_COMMENT_BODY="$tmp/comment.md" \
    PATH="$bin:$PATH" \
      "$HELPER" post github.com acme widgets 42 marker-123 "$report"
    jq -e '.event == "COMMENT" and (.comments | length) == 1 and (.comments[0].line == 8) and (.body | contains("Refresh accepts missing state"))' "$tmp/review-payload.json" >/dev/null
}

test_post_refuses_infra_failure_reports() {
    local tmp report
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    report="$tmp/report.md"
    {
        printf '# ⚒️ review-anvil report\n\n'
        printf '**Review decision:** COMMENT — The review did not complete because all three requested Codex reviewers returned empty output.\n'
        printf '**Result:** No findings were synthesized. This result is not a clean review.\n'
    } >"$report"

    if "$HELPER" post github.com acme widgets 42 marker-123 "$report" >"$tmp/out" 2>"$tmp/err"; then
        fail "infra-failure reports must not be posted by default"
    fi
    grep -Fq "infrastructure failure report detected" "$tmp/err" \
        || fail "infra-failure refusal should be explicit"
    [[ -f "$report" ]] || fail "infra-failure report should be left for diagnostics"
}


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

test_engine_template_footer_uses_anchor() {
    local skill="$ROOT/../../review-anvil/SKILL.md"
    [[ -f "$skill" ]] || fail "engine SKILL.md not found at $skill"
    grep -Fq '_Reviewed with [review-anvil](https://github.com/mrshu/agent-skills/#review-anvil)._' "$skill" \
        || fail "engine report template footer must deep-link to the #review-anvil anchor"
}

main() {
    command -v jq >/dev/null 2>&1 || fail "jq is required"
    test_process_inline
    test_process_inline_infers_id_prefixed_severity
    test_process_inline_preserves_terminal_finding_metadata
    test_process_inline_rejects_severity_mismatch
    test_process_inline_rejects_invalid_marker_severity_field
    test_history_parses_hidden_inline_metadata
    test_hidden_identity_outranks_rewritten_prose
    test_post_review_success
    test_post_fallback_comment
    test_post_start_uses_short_declarative_comment
    test_post_update_success
    test_post_adversarial_off_downgrades_approval
    test_post_dismisses_id_prefixed_report_findings
    test_compact_report_preserves_body_losslessly
    test_compact_report_preserves_invalid_and_fenced_text
    test_compact_report_preserves_wrapped_reproduction_metadata
    test_post_dismisses_table_report_findings
    test_dismissal_respects_report_paths
    test_next_run_counts_distinct_finalized_reports
    test_next_run_degrades_gracefully_when_history_is_unavailable
    test_next_run_skips_graphql_in_degraded_mode
    test_history_parses_provenance_ids_and_rejects_malformed_tokens
    test_history_parses_clarity_report_findings
    test_history_preserves_engine_generated_inline_and_grouped_ids
    test_history_merges_duplicate_identity_into_open_thread
    test_history_preserves_table_finding_identity
    test_post_history_round_trip_preserves_modern_and_legacy_identity
    test_post_history_round_trip_preserves_low_nit_and_set_aside_ids
    test_history_includes_open_resolved_outdated_and_summary_only
    test_post_suppresses_duplicate_open_thread_but_keeps_status
    test_history_paginates_without_refetch_duplicates
    test_local_suppression_overrides_open_history
    test_post_time_material_history_downgrades_approval
    test_author_resolved_thread_is_not_raised_again
    test_non_author_resolved_thread_remains_revalidated
    test_reintroduced_author_resolved_finding_is_posted_and_remains_history_actionable
    test_body_only_report_reintroduction_outranks_author_resolved_history
    test_top_level_fallback_reintroduction_outranks_author_resolved_history
    test_reintroduced_medium_finding_preserves_approval
    test_report_marker_reintroduction_preserves_inline_companion
    test_inline_reintroduction_preserves_report_companion
    test_report_marker_reintroduction_persists_without_history
    test_inline_reintroduction_persists_without_history
    test_report_marker_range_reintroduction_preserves_inline_companion
    test_inline_field_range_reintroduction_preserves_report_companion
    test_position_only_reintroduction_does_not_mark_ambiguous_companions
    test_position_only_field_does_not_mark_ambiguous_report_companion
    test_author_resolved_outranks_equivalent_open_history
    test_author_resolved_does_not_outrank_distinct_open_history
    test_distinct_open_history_is_revalidated_when_author_resolved_comes_first
    test_post_refuses_infra_failure_reports
    test_run_ordinal_is_pinned_by_pr_presets
    test_engine_template_footer_uses_anchor
    printf 'test-pr-helper: all e2e checks passed\n'
}

main "$@"
