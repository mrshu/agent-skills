#!/usr/bin/env bash
# Deterministic fixtures for the review-anvil reviewer dispatch wrapper.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$ROOT/run-reviewer.sh"

fail() {
    printf 'test-run-reviewer: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    local actual="$1" expected="$2" context="$3"
    [[ "$actual" == "$expected" ]] || \
        fail "$context: got '$actual', want '$expected'"
}

assert_contains() {
    local path="$1" needle="$2" context="$3"
    grep -Fq "$needle" "$path" || fail "$context: missing '$needle' in $path"
}

assert_file_text() {
    local path="$1" expected="$2" context="$3"
    local actual
    actual="$(cat "$path")"
    assert_eq "$actual" "$expected" "$context"
}

assert_file_empty() {
    local path="$1" context="$2"
    [[ -f "$path" ]] || fail "$context: missing file $path"
    [[ ! -s "$path" ]] || fail "$context: expected empty file $path"
}

assert_file_missing() {
    local path="$1"
    [[ ! -e "$path" ]] || fail "expected file to be absent: $path"
}

run_wrapper() {
    local stdout_file="$1" stderr_file="$2"
    shift 2

    set +e
    "$HELPER" "$@" >"$stdout_file" 2>"$stderr_file"
    local status=$?
    set -e
    printf '%s' "$status"
}

test_ok_captures_stdout_and_stderr() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/nested/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    status="$(run_wrapper "$stdout" "$stderr" "$out" 5 -- \
        bash -c 'printf reviewer-output; printf diagnostic >&2')"

    assert_eq "$status" "0" "ok exit"
    assert_file_text "$stdout" "STATUS=ok" "ok wrapper stdout"
    assert_file_text "$stderr" "" "ok wrapper stderr"
    assert_file_text "$out" "reviewer-output" "ok reviewer output"
    assert_file_text "$out.err" "diagnostic" "ok reviewer stderr"
    assert_file_missing "$out.timedout"
}

test_empty_stdout_is_failure_even_with_stderr() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    status="$(run_wrapper "$stdout" "$stderr" "$out" 5 -- \
        bash -c 'printf stderr-only >&2')"

    assert_eq "$status" "3" "empty exit"
    assert_file_text "$stdout" "STATUS=empty" "empty wrapper stdout"
    assert_file_text "$stderr" "" "empty wrapper stderr"
    assert_file_empty "$out" "empty reviewer output"
    assert_file_text "$out.err" "stderr-only" "empty reviewer stderr"
}

test_command_failure_reports_exit_and_preserves_streams() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    status="$(run_wrapper "$stdout" "$stderr" "$out" 5 -- \
        bash -c 'printf partial; printf boom >&2; exit 7')"

    assert_eq "$status" "1" "failed exit"
    assert_file_text "$stdout" $'EXIT_CODE=7\nSTATUS=failed' "failed wrapper stdout"
    assert_file_text "$stderr" "" "failed wrapper stderr"
    assert_file_text "$out" "partial" "failed reviewer output"
    assert_file_text "$out.err" "boom" "failed reviewer stderr"
}

test_timeout_reports_timeout_and_cleans_stamp() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    status="$(run_wrapper "$stdout" "$stderr" "$out" 1 -- \
        bash -c 'printf partial; exec sleep 5')"

    assert_eq "$status" "124" "timeout exit"
    assert_contains "$stdout" "EXIT_CODE=" "timeout wrapper stdout"
    assert_contains "$stdout" "STATUS=timeout" "timeout wrapper stdout"
    assert_file_text "$stderr" "" "timeout wrapper stderr"
    assert_file_text "$out" "partial" "timeout reviewer output"
    assert_file_missing "$out.timedout"
}

test_stdin_is_forwarded() {
    local tmp out prompt stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/out.md"
    prompt="$tmp/prompt.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"
    printf 'prompt payload' >"$prompt"

    set +e
    "$HELPER" "$out" 5 -- bash -c 'cat' <"$prompt" >"$stdout" 2>"$stderr"
    status=$?
    set -e

    assert_eq "$status" "0" "stdin exit"
    assert_file_text "$stdout" "STATUS=ok" "stdin wrapper stdout"
    assert_file_text "$stderr" "" "stdin wrapper stderr"
    assert_file_text "$out" "prompt payload" "stdin reviewer output"
}

test_usage_missing_separator() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    set +e
    "$HELPER" "$out" 5 bash -c ':' >"$stdout" 2>"$stderr"
    status=$?
    set -e

    assert_eq "$status" "2" "missing separator exit"
    assert_file_text "$stdout" "" "missing separator stdout"
    assert_contains "$stderr" "usage: run-reviewer.sh" "missing separator stderr"
    assert_file_missing "$out"
    assert_file_missing "$out.err"
}

test_usage_missing_command() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    set +e
    "$HELPER" "$out" 5 -- >"$stdout" 2>"$stderr"
    status=$?
    set -e

    assert_eq "$status" "2" "missing command exit"
    assert_file_text "$stdout" "" "missing command stdout"
    assert_contains "$stderr" "no command given after --" "missing command stderr"
    assert_file_missing "$out"
    assert_file_missing "$out.err"
}

test_usage_bad_timeout() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    set +e
    "$HELPER" "$out" nope -- bash -c 'printf x' >"$stdout" 2>"$stderr"
    status=$?
    set -e

    assert_eq "$status" "2" "bad timeout exit"
    assert_file_text "$stdout" "" "bad timeout stdout"
    assert_contains "$stderr" "timeout must be an integer number of seconds" "bad timeout stderr"
    assert_file_missing "$out"
    assert_file_missing "$out.err"
}

test_stale_timeout_stamp_is_removed_before_run() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN

    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"
    mkdir -p "$(dirname "$out")"
    printf stale >"$out.timedout"

    status="$(run_wrapper "$stdout" "$stderr" "$out" 5 -- bash -c 'printf fresh')"

    assert_eq "$status" "0" "stale stamp exit"
    assert_file_text "$stdout" "STATUS=ok" "stale stamp wrapper stdout"
    assert_file_text "$out" "fresh" "stale stamp reviewer output"
    assert_file_missing "$out.timedout"
}

test_findings_protocol_accepts_completed_review() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    export REVIEW_ANVIL_REQUIRE_FINDINGS=1
    status="$(run_wrapper "$stdout" "$stderr" "$out" 5 -- \
        bash -c 'printf "Review complete.\\n\\n\`\`\`findings\\n[]\\n\`\`\`\\n"')"
    unset REVIEW_ANVIL_REQUIRE_FINDINGS

    assert_eq "$status" "0" "findings protocol success exit"
    assert_file_text "$stdout" "STATUS=ok" "findings protocol success status"
}

test_findings_protocol_rejects_confirmation_only_output() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    export REVIEW_ANVIL_REQUIRE_FINDINGS=1
    status="$(run_wrapper "$stdout" "$stderr" "$out" 5 -- \
        bash -c 'printf "I will inspect the changes first. Please confirm with looks good before I begin.\\n"')"
    unset REVIEW_ANVIL_REQUIRE_FINDINGS

    assert_eq "$status" "4" "findings protocol failure exit"
    assert_file_text "$stdout" "STATUS=protocol" "findings protocol failure status"
    assert_file_text "$out.err" "The reviewer output lacks a complete fenced findings block. Confirmation requests and plan-only responses are invalid." "findings protocol failure reason"
}

test_review_protocol_is_wired_into_prompt_and_dispatch() {
    assert_contains "$ROOT/../references/reviewer-prompt.md" \
        "NON-INTERACTIVE EXECUTION CONTRACT" "reviewer prompt contract"
    assert_contains "$ROOT/../references/reviewer-prompt.md" \
        "Do not present a plan, ask for confirmation" "reviewer prompt confirmation guard"
    assert_contains "$ROOT/../SKILL.md" \
        "REVIEW_ANVIL_REQUIRE_FINDINGS=1" "reviewer dispatch validation flag"
    assert_contains "$ROOT/../SKILL.md" \
        "PROTOCOL RETRY" "reviewer corrective retry"
}

test_protocol_failure_uses_short_declarative_diagnostic() {
    local tmp out stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    out="$tmp/out.md"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"

    export REVIEW_ANVIL_REQUIRE_FINDINGS=1
    status="$(run_wrapper "$stdout" "$stderr" "$out" 5 -- bash -c 'printf incomplete')"
    unset REVIEW_ANVIL_REQUIRE_FINDINGS

    assert_eq "$status" "4" "short diagnostic exit"
    assert_file_text "$out.err" \
        "The reviewer output lacks a complete fenced findings block. Confirmation requests and plan-only responses are invalid." \
        "short declarative protocol diagnostic"
}

main() {
    test_ok_captures_stdout_and_stderr
    test_empty_stdout_is_failure_even_with_stderr
    test_command_failure_reports_exit_and_preserves_streams
    test_timeout_reports_timeout_and_cleans_stamp
    test_stdin_is_forwarded
    test_usage_missing_separator
    test_usage_missing_command
    test_usage_bad_timeout
    test_stale_timeout_stamp_is_removed_before_run
    test_findings_protocol_accepts_completed_review
    test_findings_protocol_rejects_confirmation_only_output
    test_protocol_failure_uses_short_declarative_diagnostic
    test_review_protocol_is_wired_into_prompt_and_dispatch

    printf 'test-run-reviewer: all wrapper tests passed\n'
}

main "$@"
