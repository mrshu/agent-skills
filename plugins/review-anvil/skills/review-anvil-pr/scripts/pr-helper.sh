#!/usr/bin/env bash
# pr-helper.sh — GitHub PR locator parsing, preflight, and report posting
# for the review-anvil-pr skill. Co-located with the skill so it travels
# across agents via `npx skills add mrshu/agent-skills --skill review-anvil-pr`.
#
# Two subcommands:
#
#   pr-helper.sh init <locator>
#     Parses the locator, runs gh preflight, generates a marker UUID,
#     and prepares a report path. Prints HOST/OWNER/REPO/N/MARKER/
#     REPORT_PATH/TITLE as KEY=VALUE lines on stdout (one per line,
#     no quoting needed for values without whitespace except TITLE).
#     Exits non-zero on any failure with an error message on stderr.
#
#   pr-helper.sh post <host> <owner> <repo> <n> <marker> <report_path>
#     Prepends the marker to the report file, posts it via gh, and
#     recovers the comment URL via paginated comment lookup. Prints
#     the URL on stdout (or "posted (URL unavailable)" if recovery
#     failed twice). Exits non-zero only on post failure, not on
#     URL-recovery failure.
#
# Locator forms accepted by init:
#   - Full GitHub URL: https://<host>/<owner>/<repo>/pull/<N>
#       (host = github.com OR a GitHub Enterprise hostname)
#   - Slug:            <owner>/<repo>#<N>  (host = github.com)
#
# Bare integers are rejected — the user must pass an unambiguous form.

set -euo pipefail

die() { printf 'pr-helper: %s\n' "$*" >&2; exit 1; }

cmd_init() {
    local locator="${1:-}"
    command -v gh >/dev/null 2>&1 || die "install gh first; the review-anvil-pr skill requires gh"
    command -v uuidgen >/dev/null 2>&1 || die "uuidgen not available"

    # If the user supplied no locator, try to detect the PR for the
    # currently checked-out branch. `gh pr view` (no args) uses the
    # repo inferred from the working directory's git remote and the
    # current branch's tracking info — this is the natural "review
    # the PR I'm on" workflow.
    if [[ -z "$locator" ]]; then
        local detected
        if detected=$(gh pr view --json url --jq '.url' 2>/dev/null) && [[ -n "$detected" ]]; then
            locator="$detected"
            printf 'auto-detected PR: %s\n' "$locator" >&2
        else
            die "no <locator> supplied and no PR detected for the current branch — pass a URL or <owner>/<repo>#<N>, or check out the PR's branch first"
        fi
    fi

    local host owner repo n
    if [[ "$locator" =~ ^https?://([^/]+)/([^/]+)/([^/]+)/pull/([0-9]+)/?$ ]]; then
        host="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        repo="${BASH_REMATCH[3]}"
        n="${BASH_REMATCH[4]}"
    elif [[ "$locator" =~ ^([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)#([0-9]+)$ ]]; then
        host="github.com"
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
        n="${BASH_REMATCH[3]}"
    elif [[ "$locator" =~ ^[0-9]+$ ]]; then
        die "bare integer rejected — pass a URL or <owner>/<repo>#<N>, or omit the locator to auto-detect from the current branch"
    else
        die "unrecognized locator: $locator"
    fi

    export GH_HOST="$host"

    if ! gh auth status >/dev/null 2>&1; then
        die "gh auth status failed for host=$host; run 'gh auth login' (or set GH_TOKEN/GITHUB_TOKEN)"
    fi

    # Verify PR reachability AND extract the title in one network call,
    # using gh's built-in jq (no sed regex or python3 dependency).
    local title
    if ! title=$(gh pr view "$n" -R "$owner/$repo" --json title --jq '.title' 2>&1); then
        # one retry for transient failure
        sleep 2
        if ! title=$(gh pr view "$n" -R "$owner/$repo" --json title --jq '.title' 2>&1); then
            die "gh pr view failed for $owner/$repo#$n on host=$host: $title"
        fi
    fi
    [[ -n "$title" ]] || title='(title unavailable)'

    # Anchor the report path inside the repo's worktree, not whatever
    # CWD the orchestrator happens to be in. Falls back to CWD if we
    # are not inside a git worktree (degenerate but tolerated).
    local anchor
    anchor=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local marker report_path
    marker=$(uuidgen | tr '[:upper:]' '[:lower:]')
    mkdir -p "$anchor/.review-anvil"
    # Emit an absolute path so the engine writes to and the post step
    # reads from the same file regardless of CWD changes between
    # invocations.
    report_path="$anchor/.review-anvil/final-report-${marker}.md"

    printf 'HOST=%s\n' "$host"
    printf 'OWNER=%s\n' "$owner"
    printf 'REPO=%s\n' "$repo"
    printf 'N=%s\n' "$n"
    printf 'MARKER=%s\n' "$marker"
    printf 'REPORT_PATH=%s\n' "$report_path"
    printf 'TITLE=%s\n' "$title"
}

cmd_post() {
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}" marker="${5:-}" report_path="${6:-}"
    for v in host owner repo n marker report_path; do
        [[ -n "${!v}" ]] || die "post: missing <$v>"
    done
    [[ -f "$report_path" ]] || die "report file not found: $report_path"

    export GH_HOST="$host"

    # Atomically prepend the marker to the report.
    local tmp="${report_path}.tmp"
    {
        printf '<!-- review-anvil-marker: %s -->\n' "$marker"
        cat "$report_path"
    } > "$tmp"
    mv "$tmp" "$report_path"

    # Post.
    if ! gh pr comment "$n" -R "$owner/$repo" --body-file "$report_path" >/dev/null 2>&1; then
        die "gh pr comment failed for $owner/$repo#$n on host=$host"
    fi

    # Recover URL via marker lookup (with one retry for read-after-write lag).
    local url
    for attempt in 1 2; do
        url=$(gh api "repos/${owner}/${repo}/issues/${n}/comments" --paginate \
              --jq ".[] | select(.body | contains(\"$marker\")) | .html_url" 2>/dev/null \
              | head -n1 || true)
        [[ -n "$url" ]] && break
        [[ "$attempt" -eq 1 ]] && sleep 2
    done

    if [[ -n "$url" ]]; then
        printf '%s\n' "$url"
    else
        printf 'posted (URL unavailable)\n'
    fi
}

cmd_verify_checkout() {
    local locator="${1:-}"

    command -v gh >/dev/null 2>&1 || die "install gh first; review-anvil-improve-pr requires gh"

    # Auto-detect PR from current branch if no locator given (same logic
    # as cmd_init — `gh pr view` with no args uses the working
    # directory's repo and the current branch's tracking info).
    if [[ -z "$locator" ]]; then
        local detected
        if detected=$(gh pr view --json url --jq '.url' 2>/dev/null) && [[ -n "$detected" ]]; then
            locator="$detected"
            printf 'auto-detected PR: %s\n' "$locator" >&2
        else
            die "no <locator> supplied and no PR detected for the current branch — pass a URL or <owner>/<repo>#<N>, or check out the PR's branch first"
        fi
    fi

    local host owner repo n
    if [[ "$locator" =~ ^https?://([^/]+)/([^/]+)/([^/]+)/pull/([0-9]+)/?$ ]]; then
        host="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        repo="${BASH_REMATCH[3]}"
        n="${BASH_REMATCH[4]}"
    elif [[ "$locator" =~ ^([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)#([0-9]+)$ ]]; then
        host="github.com"
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
        n="${BASH_REMATCH[3]}"
    elif [[ "$locator" =~ ^[0-9]+$ ]]; then
        die "bare integer rejected — pass a URL or <owner>/<repo>#<N>, or omit the locator to auto-detect from the current branch"
    else
        die "unrecognized locator: $locator"
    fi

    export GH_HOST="$host"

    if ! gh auth status >/dev/null 2>&1; then
        die "gh auth status failed for host=$host; run 'gh auth login' (or set GH_TOKEN/GITHUB_TOKEN)"
    fi

    # Fetch the PR's head/base refs + title in one call (verify reachability + capture fields).
    # Output looks like: <headRefName>\t<headRefOid>\t<baseRefName>\t<title>
    local pr_fields
    if ! pr_fields=$(gh pr view "$n" -R "$owner/$repo" \
                       --json headRefName,headRefOid,baseRefName,title \
                       --jq '[.headRefName, .headRefOid, .baseRefName, .title] | @tsv' 2>&1); then
        sleep 2
        if ! pr_fields=$(gh pr view "$n" -R "$owner/$repo" \
                           --json headRefName,headRefOid,baseRefName,title \
                           --jq '[.headRefName, .headRefOid, .baseRefName, .title] | @tsv' 2>&1); then
            die "gh pr view failed for $owner/$repo#$n on host=$host: $pr_fields"
        fi
    fi
    local head_branch head_sha base_branch title
    IFS=$'\t' read -r head_branch head_sha base_branch title <<<"$pr_fields"
    [[ -n "$title" ]] || title='(title unavailable)'

    # Verify we are in a git worktree.
    git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git worktree; check out the PR's branch first (gh pr checkout $n -R $owner/$repo)"

    # Condition 1: current branch matches PR head branch (no detached HEAD).
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    [[ -n "$current_branch" && "$current_branch" != "HEAD" ]] \
        || die "current HEAD is detached; run 'gh pr checkout $n -R $owner/$repo' to switch to the PR's branch first"
    [[ "$current_branch" == "$head_branch" ]] \
        || die "current branch '$current_branch' does not match PR head branch '$head_branch'; run 'gh pr checkout $n -R $owner/$repo' first"

    # Condition 2: HEAD is at, or descended from, the PR head SHA.
    # Descendant (local commits ahead of remote PR head) is OK — the
    # final 'git push' after review will include them.
    local current_sha
    current_sha=$(git rev-parse HEAD)
    if [[ "$current_sha" != "$head_sha" ]]; then
        if git merge-base --is-ancestor "$head_sha" "$current_sha" 2>/dev/null; then
            printf 'note: local HEAD %s is ahead of PR head %s (unpushed commits will be included in push after review)\n' \
                "${current_sha:0:8}" "${head_sha:0:8}" >&2
        else
            die "local HEAD ($current_sha) does not match PR head ($head_sha) and is not a descendant; rebase/pull first or run 'gh pr checkout $n -R $owner/$repo'"
        fi
    fi

    # Condition 3: worktree and index clean.
    if [[ -n "$(git status --porcelain)" ]]; then
        die "worktree has uncommitted changes; commit or stash them before running review-anvil-improve-pr"
    fi

    # Ensure base branch is locally reachable for the diff (engine will
    # use git diff <base>...HEAD). If not, fetch it.
    if ! git rev-parse --verify "$base_branch" >/dev/null 2>&1; then
        if ! git fetch origin "$base_branch:refs/remotes/origin/$base_branch" 2>/dev/null \
           && ! git fetch origin "$base_branch" 2>/dev/null; then
            die "base branch '$base_branch' not available locally and 'git fetch origin $base_branch' failed; ensure the base branch is reachable"
        fi
    fi

    printf 'HOST=%s\n' "$host"
    printf 'OWNER=%s\n' "$owner"
    printf 'REPO=%s\n' "$repo"
    printf 'N=%s\n' "$n"
    printf 'HEAD_BRANCH=%s\n' "$head_branch"
    printf 'BASE_BRANCH=%s\n' "$base_branch"
    printf 'TITLE=%s\n' "$title"
}

case "${1:-}" in
    init)             shift; cmd_init "$@" ;;
    post)             shift; cmd_post "$@" ;;
    verify-checkout)  shift; cmd_verify_checkout "$@" ;;
    "")               die "usage: pr-helper.sh {init [<locator>] | post <host> <owner> <repo> <n> <marker> <report_path> | verify-checkout [<locator>]}" ;;
    *)                die "unknown subcommand: $1" ;;
esac
