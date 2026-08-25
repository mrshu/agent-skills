#!/usr/bin/env bash
# Clone a GitHub PR on the host, derive the runtime from the base ref, and run
# the project command inside a disposable krunvm microVM.

set -euo pipefail

die() {
    printf 'review-anvil-pr-sandbox: %s\n' "$*" >&2
    exit 1
}

log() {
    printf 'review-anvil-pr-sandbox: %s\n' "$*" >&2
}

usage() {
    cat >&2 <<'EOF'
usage: run_pr_krunvm.sh <owner/repo> <pr-number> [options]

Options:
  --host <host>          GitHub host (default: github.com)
  --repo-url <url>       clone URL override, mainly for deterministic tests
  --base-ref <branch>    base branch/ref override; skips gh base lookup
  --is-fork <bool>       fork flag override used in the plan
  --image <image>        OCI image override; otherwise inferred from base ref
  --cmd <command>        full guest command override
  --install-cmd <cmd>    install command override
  --lint-cmd <cmd>       lint command override
  --test-cmd <cmd>       test command override
  --cpus <n>             krunvm vCPU count
  --mem <mib>            krunvm memory in MiB
  --allow-flagged        run even when PR changes execution-controlling files
  --no-install           do not auto-install krunvm when it is missing
  --dry-run              inspect and print the plan without creating a VM
  --plan-out <path>      write the plan JSON outside the cleanup directory
  --keep                 keep the clone and VM for debugging
EOF
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSPECT="$SCRIPT_DIR/pr_inspect.py"

repo_slug="${1:-}"
pr_number="${2:-}"
[[ -n "$repo_slug" && -n "$pr_number" ]] || usage
shift 2

host="github.com"
repo_url=""
base_ref=""
is_fork="false"
image_override=""
cmd_override=""
install_override=""
lint_override=""
test_override=""
cpus=""
mem=""
allow_flagged=0
auto_install="${REVIEW_ANVIL_KRUNVM_AUTO_INSTALL:-1}"
dry_run=0
keep=0
plan_out=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)            [[ $# -ge 2 ]] || usage; host="$2"; shift 2 ;;
        --repo-url)        [[ $# -ge 2 ]] || usage; repo_url="$2"; shift 2 ;;
        --base-ref)        [[ $# -ge 2 ]] || usage; base_ref="$2"; shift 2 ;;
        --is-fork)         [[ $# -ge 2 ]] || usage; is_fork="$2"; shift 2 ;;
        --image)           [[ $# -ge 2 ]] || usage; image_override="$2"; shift 2 ;;
        --cmd)             [[ $# -ge 2 ]] || usage; cmd_override="$2"; shift 2 ;;
        --install-cmd)     [[ $# -ge 2 ]] || usage; install_override="$2"; shift 2 ;;
        --lint-cmd)        [[ $# -ge 2 ]] || usage; lint_override="$2"; shift 2 ;;
        --test-cmd)        [[ $# -ge 2 ]] || usage; test_override="$2"; shift 2 ;;
        --cpus)            [[ $# -ge 2 ]] || usage; cpus="$2"; shift 2 ;;
        --mem)             [[ $# -ge 2 ]] || usage; mem="$2"; shift 2 ;;
        --allow-flagged)   allow_flagged=1; shift ;;
        --no-install)      auto_install=0; shift ;;
        --dry-run)         dry_run=1; shift ;;
        --plan-out)        [[ $# -ge 2 ]] || usage; plan_out="$2"; shift 2 ;;
        --keep)            keep=1; shift ;;
        -h|--help)         usage ;;
        *)                 die "unknown option: $1" ;;
    esac
done

[[ "$repo_slug" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] \
    || die "repo must be <owner>/<repo>, got '$repo_slug'"
[[ "$pr_number" =~ ^[0-9]+$ ]] || die "PR number must be numeric, got '$pr_number'"
[[ -f "$INSPECT" ]] || die "missing pr_inspect.py next to this script"
command -v git >/dev/null 2>&1 || die "git not found"
command -v python3 >/dev/null 2>&1 || die "python3 not found"

if [[ -z "$base_ref" ]]; then
    command -v gh >/dev/null 2>&1 || die "gh not found; pass --base-ref or install gh"
    export GH_HOST="$host"
    fields="$(gh pr view "$pr_number" -R "$repo_slug" \
        --json baseRefName,isCrossRepository \
        --jq '[.baseRefName, .isCrossRepository] | @tsv')" \
        || die "gh pr view failed for $repo_slug#$pr_number on host=$host"
    IFS=$'\t' read -r base_ref is_fork <<<"$fields"
    [[ -n "$base_ref" ]] || die "gh did not return a baseRefName for $repo_slug#$pr_number"
fi

if [[ -z "$repo_url" ]]; then
    repo_url="https://${host}/${repo_slug}.git"
fi

tmp_parent="${REVIEW_ANVIL_SANDBOX_TMPDIR:-${TMPDIR:-/tmp}}"
tmp_parent="${tmp_parent%/}"
run_root="$(mktemp -d "$tmp_parent/review-anvil-pr-sandbox.XXXXXX")"
clone_dir="$run_root/checkout"
inspect_json="$run_root/inspect.json"
plan_json="$run_root/plan.json"
vm_name=""
vm_created=0

cleanup() {
    local status=$?
    set +e
    if [[ "$keep" -eq 1 ]]; then
        log "keep requested; clone retained at $clone_dir"
        if [[ -n "$vm_name" && "$vm_created" -eq 1 ]]; then
            log "keep requested; VM retained as $vm_name"
        fi
        return "$status"
    fi
    if [[ -n "$vm_name" && "$vm_created" -eq 1 ]]; then
        krunvm delete "$vm_name" >/dev/null 2>&1 || true
    fi
    rm -rf "$run_root"
    return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

sanitize_name() {
    printf '%s' "$1" | tr '/[:upper:]' '-[:lower:]' | tr -cd 'a-z0-9_.-'
}

git_safe=(-c core.hooksPath=/dev/null -c submodule.recurse=false \
          -c filter.lfs.smudge= -c filter.lfs.process= \
          -c filter.lfs.required=false)

log "step 1/5: cloning $repo_slug#$pr_number on the host"
GIT_LFS_SKIP_SMUDGE=1 git "${git_safe[@]}" clone \
    --no-recurse-submodules --depth 1 --branch "$base_ref" \
    "$repo_url" "$clone_dir" >/dev/null
git -C "$clone_dir" config core.hooksPath /dev/null
git -C "$clone_dir" remote set-url origin "$repo_url"
GIT_LFS_SKIP_SMUDGE=1 git -C "$clone_dir" "${git_safe[@]}" fetch \
    --depth 1 origin "refs/pull/${pr_number}/head:refs/review-anvil/pr/${pr_number}" >/dev/null
GIT_LFS_SKIP_SMUDGE=1 git -C "$clone_dir" "${git_safe[@]}" checkout \
    --detach "refs/review-anvil/pr/${pr_number}" >/dev/null

log "step 2/5: deriving runtime from base ref '$base_ref'"
set +e
python3 "$INSPECT" --repo "$clone_dir" --base-ref "$base_ref" \
    --head-ref HEAD --is-fork "$is_fork" --json >"$inspect_json"
inspect_status=$?
set -e

if [[ "$inspect_status" -eq 2 && "$allow_flagged" -ne 1 ]]; then
    python3 - "$inspect_json" <<'PY' >&2
import json
import sys
payload = json.load(open(sys.argv[1]))
print("review-anvil-pr-sandbox: blocked because this PR changes execution-controlling files:")
for item in payload.get("flagged_files", []):
    print(f"  - {item['path']} ({item['reason']})")
print("review-anvil-pr-sandbox: rerun with --allow-flagged only after reviewing those changes.")
PY
    exit 2
elif [[ "$inspect_status" -ne 0 && "$inspect_status" -ne 2 ]]; then
    cat "$inspect_json" >&2 || true
    die "pr_inspect.py failed"
elif [[ "$inspect_status" -eq 2 ]]; then
    log "--allow-flagged set; continuing despite execution-control changes"
fi

python3 - "$inspect_json" "$plan_json" "$repo_slug" "$pr_number" "$host" \
    "$base_ref" "$repo_url" "$image_override" "$cmd_override" \
    "$install_override" "$lint_override" "$test_override" <<'PY'
import json
import sys

(
    inspect_path,
    plan_path,
    repo,
    pr,
    host,
    base_ref,
    repo_url,
    image_override,
    cmd_override,
    install_override,
    lint_override,
    test_override,
) = sys.argv[1:13]

payload = json.load(open(inspect_path))
runtime = payload["runtime"]
commands = {
    "install": install_override or runtime.get("install", ""),
    "lint": lint_override or runtime.get("lint", ""),
    "test": test_override or runtime.get("test", ""),
}
command = cmd_override or " && ".join(part for part in commands.values() if part)
image = image_override or runtime.get("default_image") or "docker.io/library/ubuntu:24.04"

plan = {
    "host": host,
    "repo": repo,
    "repo_url": repo_url,
    "pr": int(pr),
    "base_ref": base_ref,
    "head_ref": "HEAD",
    "is_fork": payload.get("is_fork", False),
    "safe_to_boot": payload.get("safe_to_boot", False),
    "changed_files": payload.get("changed_files", []),
    "flagged_files": payload.get("flagged_files", []),
    "runtime": runtime,
    "image": image,
    "commands": commands,
    "command": command,
}
with open(plan_path, "w", encoding="utf-8") as fh:
    json.dump(plan, fh, indent=2, sort_keys=True)
    fh.write("\n")
PY

guest_command="$(python3 - "$plan_json" <<'PY'
import json
import sys
print(json.load(open(sys.argv[1])).get("command", ""))
PY
)"
image="$(python3 - "$plan_json" <<'PY'
import json
import sys
print(json.load(open(sys.argv[1])).get("image", ""))
PY
)"

if [[ -z "$guest_command" ]]; then
    die "no runtime command detected; pass --cmd or explicit --install-cmd/--lint-cmd/--test-cmd"
fi

if [[ -n "$plan_out" ]]; then
    cp "$plan_json" "$plan_out"
fi

if [[ "$dry_run" -eq 1 ]]; then
    cat "$plan_json"
    exit 0
fi

ensure_krunvm() {
    command -v krunvm >/dev/null 2>&1 && return 0

    case "$auto_install" in
        0|false|FALSE|no|NO)
            die "krunvm not found; auto-install disabled. Install it or remove --no-install / REVIEW_ANVIL_KRUNVM_AUTO_INSTALL=0."
            ;;
    esac

    command -v brew >/dev/null 2>&1 \
        || die "krunvm not found and Homebrew is not available. Install Homebrew, then run 'brew install krunvm'."

    log "krunvm not found; installing with Homebrew"
    brew install krunvm
    command -v krunvm >/dev/null 2>&1 \
        || die "brew install krunvm completed but krunvm is still not on PATH"
}

ensure_krunvm

check_macos_krunvm_volume() {
    local config_path volume tmp_case
    volume="$(python3 - <<'PY'
from pathlib import Path
import os
import re

candidates = [
    Path.home() / "Library" / "Preferences" / "rs.krunvm" / "krunvm.toml",
    Path.home() / "Library" / "Application Support" / "krunvm" / "krunvm.toml",
]
keys = ("volume_path", "storage_path", "storage_dir", "volume", "rootfs")
for path in candidates:
    if not path.exists():
        continue
    text = path.read_text(errors="ignore")
    for key in keys:
        match = re.search(rf'(?m)^\s*{re.escape(key)}\s*=\s*"([^"]+)"', text)
        if match:
            print(os.path.expanduser(match.group(1)))
            raise SystemExit(0)
    match = re.search(r'"((?:/Volumes|/private/var|/Users)/[^"]*krunvm[^"]*)"', text)
    if match:
        print(os.path.expanduser(match.group(1)))
        raise SystemExit(0)
raise SystemExit(1)
PY
)" || die "krunvm macOS storage volume is not configured; run krunvm once and configure a case-sensitive APFS volume"
    config_path="$volume"
    [[ -d "$config_path" ]] || die "krunvm storage volume does not exist: $config_path"
    tmp_case="$(mktemp -d "$config_path/.review-anvil-case.XXXXXX")" \
        || die "cannot create a case-sensitivity probe under $config_path"
    printf x >"$tmp_case/CaseCheck"
    if [[ -e "$tmp_case/casecheck" ]]; then
        rm -rf "$tmp_case"
        die "krunvm storage volume is case-insensitive: $config_path"
    fi
    rm -rf "$tmp_case"
}

if [[ "$(uname -s)" == "Darwin" ]]; then
    check_macos_krunvm_volume
fi

vm_name="rav-$(sanitize_name "$repo_slug")-${pr_number}-$$"
create_args=(create "$image" --name "$vm_name" --volume "$clone_dir:/work" --workdir /work)
[[ -n "$cpus" ]] && create_args+=(--cpus "$cpus")
[[ -n "$mem" ]] && create_args+=(--mem "$mem")

log "step 3/5: boot boundary will be krunvm VM '$vm_name'"
log "warning: krunvm guests have unrestricted network egress; malicious install/test code can exfiltrate anything reachable inside the VM"
krunvm "${create_args[@]}" >/dev/null
vm_created=1

log "step 4/5: running install/lint/test inside the guest"
guest_script=$'set -eu\ncd /work\n'
guest_script+="$guest_command"
set +e
krunvm start --env CI=1 "$vm_name" /bin/sh -lc "$guest_script" </dev/null
run_status=$?
set -e

log "step 5/5: destroying VM and clone"
exit "$run_status"
