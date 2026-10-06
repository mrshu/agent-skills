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
    [[ -s "$out.err" ]] || fail "protocol failure must include a diagnostic"
}

# This controlled executable consumes the workdir like Codex does, then
# exercises the filesystem there. It does not emulate model responses.
make_copy_editor_fixture() {
    local path="$1"
    cat >"$path" <<'PY'
#!/usr/bin/env python3
import os
from pathlib import Path
import stat
import sys

workspace = Path(sys.argv[sys.argv.index("-C") + 1])
Path(os.environ["WORKSPACE_RECORD"]).write_text(str(workspace))
os.chdir(workspace)
assert workspace.is_absolute()
assert workspace.stat().st_uid == os.getuid()
assert stat.S_IMODE(workspace.stat().st_mode) == 0o700
assert not list(Path(".").iterdir())
assert not Path("repository-only.txt").exists()
payload = sys.stdin.read() + os.environ["COPY_EDITOR_PAYLOAD"]
Path("scratch.txt").write_text(payload)
assert Path("scratch.txt").read_text() == payload
outcome = os.environ["COPY_EDITOR_OUTCOME"]
if outcome != "empty":
    print(Path("scratch.txt").read_text(), flush=True)
if outcome == "failed":
    # A real filesystem failure must survive in the captured diagnostic.
    Path("missing-directory/result.txt").write_text(payload)
elif outcome == "timeout":
    os.execvp("sleep", ["sleep", "10"])
PY
    chmod +x "$path"
}

test_copy_editor_isolation_and_cleanup() {
    local tmp fixture repository outcome out stdout stderr status workspace expected timeout
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    fixture="$tmp/codex-fixture"
    make_copy_editor_fixture "$fixture"
    repository="$tmp/repository"
    mkdir "$repository" "$tmp/workspaces"
    printf 'private repository data' >"$repository/repository-only.txt"
    printf 'stdin payload ' >"$tmp/stdin"

    for outcome in ok failed timeout empty; do
        out="$tmp/$outcome.md"
        stdout="$tmp/$outcome.wrapper.out"
        stderr="$tmp/$outcome.wrapper.err"
        timeout=10
        [[ "$outcome" != "timeout" ]] || timeout=3
        status="$(
            cd "$repository"
            TMPDIR="$tmp/workspaces" WORKSPACE_RECORD="$tmp/workspace-record" \
                COPY_EDITOR_PAYLOAD="inherited environment" COPY_EDITOR_OUTCOME="$outcome" \
                REVIEW_ANVIL_REQUIRE_FINDINGS=1 \
                run_wrapper "$stdout" "$stderr" "$out" "$timeout" \
                    --codex-copy-editor "$fixture" "Read only the supplied evidence." <"$tmp/stdin"
        )"
        case "$outcome" in
            ok) expected=0 ;;
            failed) expected=1 ;;
            timeout) expected=124 ;;
            empty) expected=3 ;;
        esac
        assert_eq "$status" "$expected" "copy-editor $outcome exit"
        assert_contains "$stdout" "STATUS=$outcome" "copy-editor $outcome status"
        workspace="$(cat "$tmp/workspace-record")"
        [[ "$workspace" == "$tmp/workspaces/"* ]] || fail "workspace is outside the temp root"
        assert_file_missing "$workspace"
        assert_file_missing "$out.timedout"
        assert_file_missing "$repository/scratch.txt"
        assert_file_text "$repository/repository-only.txt" "private repository data" "repository unchanged"
        if [[ "$outcome" == "empty" ]]; then
            assert_file_empty "$out" "copy-editor empty output"
        else
            assert_file_text "$out" "stdin payload inherited environment" "copy-editor stdin and environment"
        fi
        if [[ "$outcome" == "failed" ]]; then
            [[ -s "$out.err" ]] || fail "filesystem failure diagnostic was lost"
        fi
    done
}

test_copy_editor_usage_creates_no_workspace() {
    local tmp fixture scenario out stdout stderr status
    local -a workspaces
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    fixture="$tmp/codex-fixture"
    make_copy_editor_fixture "$fixture"
    mkdir "$tmp/workspaces"
    printf 'not executable' >"$tmp/non-executable"

    for scenario in missing extra relative non-executable bad-timeout; do
        out="$tmp/$scenario.md"
        stdout="$tmp/$scenario.wrapper.out"
        stderr="$tmp/$scenario.wrapper.err"
        case "$scenario" in
            missing) set -- "$out" 5 --codex-copy-editor "$fixture" ;;
            extra) set -- "$out" 5 --codex-copy-editor "$fixture" prompt extra ;;
            relative) set -- "$out" 5 --codex-copy-editor ./codex-fixture prompt ;;
            non-executable) set -- "$out" 5 --codex-copy-editor "$tmp/non-executable" prompt ;;
            bad-timeout) set -- "$out" nope --codex-copy-editor "$fixture" prompt ;;
        esac
        status="$(TMPDIR="$tmp/workspaces" run_wrapper "$stdout" "$stderr" "$@")"
        assert_eq "$status" "2" "copy-editor $scenario usage exit"
        assert_file_empty "$stdout" "copy-editor $scenario usage stdout"
        [[ -s "$stderr" ]] || fail "copy-editor $scenario usage needs a diagnostic"
        assert_file_missing "$out"
        assert_file_missing "$out.err"
        shopt -s nullglob dotglob
        workspaces=("$tmp/workspaces/"*)
        shopt -u nullglob dotglob
        [[ ${#workspaces[@]} -eq 0 ]] || fail "invalid usage allocated a workspace"
    done
}

test_copy_editor_workspace_failure_does_not_dispatch() {
    local tmp stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    make_copy_editor_fixture "$tmp/codex-fixture"
    stdout="$tmp/wrapper.out"
    stderr="$tmp/wrapper.err"
    # A nonexistent temp parent fails deterministically, even when run as root.
    status="$(TMPDIR="$tmp/missing" WORKSPACE_RECORD="$tmp/workspace-record" \
        run_wrapper "$stdout" "$stderr" "$tmp/out.md" 5 \
            --codex-copy-editor "$tmp/codex-fixture" prompt)"
    assert_eq "$status" "2" "workspace creation failure exit"
    assert_file_missing "$tmp/workspace-record"
    assert_file_missing "$tmp/out.md"
    assert_file_missing "$tmp/out.md.err"
    [[ -s "$stderr" ]] || fail "workspace creation failure needs a diagnostic"
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
    test_copy_editor_isolation_and_cleanup
    test_copy_editor_usage_creates_no_workspace
    test_copy_editor_workspace_failure_does_not_dispatch

    printf 'test-run-reviewer: all wrapper tests passed\n'
}

main "$@"
