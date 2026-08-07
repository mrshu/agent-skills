#!/usr/bin/env bash
# Deterministic fixtures for the review-anvil PR sandbox helpers.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$ROOT/pr-sandbox/run_pr_krunvm.sh"
INSPECT="$ROOT/pr-sandbox/pr_inspect.py"

fail() {
    printf 'test-pr-sandbox: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    local actual="$1" expected="$2" context="$3"
    [[ "$actual" == "$expected" ]] || fail "$context: got '$actual', want '$expected'"
}

assert_contains() {
    local path="$1" needle="$2" context="$3"
    grep -Fq -- "$needle" "$path" || fail "$context: missing '$needle' in $path"
}

assert_file_exists() {
    local path="$1" context="$2"
    [[ -f "$path" ]] || fail "$context: missing file $path"
}

assert_file_missing() {
    local path="$1" context="$2"
    [[ ! -e "$path" ]] || fail "$context: expected file to be absent: $path"
}

git_commit() {
    local repo="$1" message="$2"
    git -C "$repo" add .
    git -C "$repo" commit -q -m "$message"
}

make_remote_repo() {
    local tmp="$1" mode="$2"
    local src="$tmp/src-$mode" remote="$tmp/remote-$mode.git"
    git init -q "$src"
    git -C "$src" config user.email test@example.invalid
    git -C "$src" config user.name "Test User"
    git -C "$src" config commit.gpgsign false
    git -C "$src" checkout -q -b main
    cat >"$src/package.json" <<'JSON'
{"scripts":{"test":"node -e \"console.log('ok')\""}}
JSON
    mkdir -p "$src/src"
    printf 'base\n' >"$src/src/app.txt"
    git_commit "$src" "base"

    git init -q --bare "$remote"
    git -C "$src" remote add origin "$remote"
    git -C "$src" push -q origin main

    git -C "$src" checkout -q -b pr
    printf 'head\n' >"$src/src/app.txt"
    if [[ "$mode" == "flagged" ]]; then
        mkdir -p "$src/.github/workflows"
        printf 'name: changed\n' >"$src/.github/workflows/ci.yml"
    fi
    git_commit "$src" "pr"
    git -C "$src" push -q origin HEAD:refs/pull/1/head
    printf '%s\n' "$remote"
}

run_runner() {
    local stdout="$1" stderr="$2"
    shift 2
    set +e
    bash "$RUNNER" "$@" >"$stdout" 2>"$stderr"
    local status=$?
    set -e
    printf '%s' "$status"
}

test_pr_inspect_blocks_execution_control_files() {
    local tmp remote clone stdout status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    remote="$(make_remote_repo "$tmp" flagged)"
    clone="$tmp/clone"

    git clone -q --branch main "$remote" "$clone"
    git -C "$clone" fetch -q origin refs/pull/1/head:refs/pr/1
    git -C "$clone" checkout -q --detach refs/pr/1

    stdout="$tmp/inspect.json"
    set +e
    python3 "$INSPECT" --repo "$clone" --base-ref main --head-ref HEAD --json >"$stdout"
    status=$?
    set -e

    assert_eq "$status" "2" "flagged inspect exit"
    assert_contains "$stdout" '"safe_to_boot": false' "flagged inspect safe flag"
    assert_contains "$stdout" '.github/workflows/ci.yml' "flagged inspect path"
}

test_dry_run_writes_plan_outside_cleanup() {
    local tmp remote stdout stderr plan status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    remote="$(make_remote_repo "$tmp" clean)"
    stdout="$tmp/stdout"
    stderr="$tmp/stderr"
    plan="$tmp/plan.json"

    status="$(run_runner "$stdout" "$stderr" acme/widgets 1 \
        --repo-url "$remote" --base-ref main --dry-run --plan-out "$plan")"

    assert_eq "$status" "0" "dry-run exit"
    assert_file_exists "$plan" "dry-run plan"
    assert_contains "$stdout" '"runtime": {' "dry-run stdout"
    assert_contains "$stdout" '"kind": "node"' "dry-run runtime"
    assert_contains "$stdout" '"command": "npm install && npm test"' "dry-run command"
    assert_contains "$plan" '"command": "npm install && npm test"' "dry-run plan command"
}

test_flagged_pr_blocks_before_krunvm() {
    local tmp remote stdout stderr status bin log_path
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    remote="$(make_remote_repo "$tmp" flagged)"
    stdout="$tmp/stdout"
    stderr="$tmp/stderr"
    bin="$tmp/bin"
    log_path="$tmp/krunvm.log"
    mkdir -p "$bin"
    cat >"$bin/krunvm" <<SH
#!/usr/bin/env bash
printf 'krunvm called\n' >>"$log_path"
exit 99
SH
    chmod +x "$bin/krunvm"

    local old_path="$PATH"
    PATH="$bin:$PATH"
    status="$(run_runner "$stdout" "$stderr" acme/widgets 1 \
        --repo-url "$remote" --base-ref main)"
    PATH="$old_path"

    assert_eq "$status" "2" "flagged runner exit"
    assert_contains "$stderr" "blocked because this PR changes execution-controlling files" "flagged runner stderr"
    assert_contains "$stderr" ".github/workflows/ci.yml" "flagged runner path"
    assert_file_missing "$log_path" "krunvm not called"
}

test_allow_flagged_dry_run_continues() {
    local tmp remote stdout stderr status
    tmp="$(mktemp -d)"
    trap "rm -rf '$tmp'" RETURN
    remote="$(make_remote_repo "$tmp" flagged)"
    stdout="$tmp/stdout"
    stderr="$tmp/stderr"

    status="$(run_runner "$stdout" "$stderr" acme/widgets 1 \
        --repo-url "$remote" --base-ref main --allow-flagged --dry-run)"

    assert_eq "$status" "0" "allow flagged dry-run exit"
    assert_contains "$stdout" '"safe_to_boot": false' "allow flagged plan"
    assert_contains "$stderr" "--allow-flagged set; continuing" "allow flagged warning"
}

main() {
    test_pr_inspect_blocks_execution_control_files
    test_dry_run_writes_plan_outside_cleanup
    test_flagged_pr_blocks_before_krunvm
    test_allow_flagged_dry_run_continues
    printf 'test-pr-sandbox: all PR sandbox helper tests passed\n'
}

main "$@"
