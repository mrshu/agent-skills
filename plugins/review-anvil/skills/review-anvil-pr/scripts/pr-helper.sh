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

# Remove the report markdown + sibling inline JSON, and try to rmdir
# the parent directory. Called only on successful post paths (failures
# leave the artifacts in place so the user can inspect / post manually).
# rmdir fails quietly if other runs have artifacts in the same dir.
cleanup_post_artifacts() {
    local report_path="$1"
    rm -f "$report_path" "${report_path}.inline.json"
    rmdir "$(dirname "$report_path")" 2>/dev/null || true
}

# Remove findings that the PR author has already dismissed/resolved. This is a
# hard pre-post gate: if GitHub's resolved review-thread state cannot be read,
# abort rather than risk reposting stale noise.
suppress_dismissed_findings() {
    local host="$1" owner="$2" repo="$3" n="$4" report_path="$5" inline_json="$6"
    export GH_HOST="$host"
    command -v python3 >/dev/null 2>&1 || die "python3 required for dismissed-finding suppression"
    python3 - "$owner" "$repo" "$n" "$report_path" "$inline_json" <<'PY'
import difflib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

owner, repo, n, report_path, inline_json = sys.argv[1:]
report = Path(report_path)
inline = Path(inline_json)
state_path = Path.home() / ".hermes" / "state" / "review-anvil-dismissed-findings.json"

QUERY = r'''
query($owner:String!,$repo:String!,$number:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      reviewThreads(first:100){
        nodes{
          isResolved
          isOutdated
          path
          line
          comments(first:20){ nodes{ body author{login} url } }
        }
      }
    }
  }
}
'''

cp = subprocess.run(
    ["gh", "api", "graphql", "-f", f"owner={owner}", "-f", f"repo={repo}", "-F", f"number={n}", "-f", f"query={QUERY}"],
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)
if cp.returncode != 0:
    print(cp.stderr.strip() or cp.stdout.strip(), file=sys.stderr)
    raise SystemExit("pr-helper: could not read resolved PR review threads; refusing to post possible repeat findings")

def norm(text: str) -> str:
    text = re.sub(r"https?://\S+", " ", text or "")
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", " ", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"[^a-zA-Z0-9]+", " ", text).lower()
    words = [w for w in text.split() if len(w) > 2 and w not in {"the", "and", "for", "with", "this", "that", "from", "into", "when", "because"}]
    return " ".join(words)

def signature(body: str) -> str:
    body = body or ""
    # review-anvil inline body: **[medium] area** -- What ...
    m = re.search(r"\*\*\[(critical|high|medium|low|nit)\]\s*([^*]+?)\*\*\s*[-—:]+\s*([^\n]+)", body, re.I)
    if m:
        return norm(f"{m.group(2)} {m.group(3)}")
    # GitHub/Codex-style body: Medium: what...
    m = re.search(r"\b(critical|high|medium|low|nit)\s*:\s*([^\n]+)", body, re.I)
    if m:
        return norm(m.group(2))
    lines = [ln.strip() for ln in body.splitlines() if ln.strip() and not ln.strip().startswith("<!--")]
    return norm(" ".join(lines[:2])[:500])

def same_finding(candidate: dict, dismissed: dict) -> bool:
    cpath = candidate.get("path") or ""
    dpath = dismissed.get("path") or ""
    if cpath and dpath and cpath != dpath:
        return False
    cs = candidate.get("sig", "")
    ds = dismissed.get("sig", "")
    if not cs or not ds:
        return False
    if cs == ds:
        return True
    if len(cs) > 35 and len(ds) > 35 and (cs in ds or ds in cs):
        return True
    return difflib.SequenceMatcher(None, cs, ds).ratio() >= 0.62

j = json.loads(cp.stdout)
threads = j["data"]["repository"]["pullRequest"]["reviewThreads"]["nodes"] or []
dismissed = []
for t in threads:
    if not t.get("isResolved"):
        continue
    for c in (t.get("comments") or {}).get("nodes") or []:
        body = c.get("body") or ""
        sig = signature(body)
        if sig:
            dismissed.append({"path": t.get("path") or "", "sig": sig, "source": c.get("url") or "resolved-thread"})

# Optional local suppressions for product decisions/stale bot claims that may not
# map cleanly to a resolved GitHub thread yet. Shape:
# {"Cisco-CollabAI/nex#329": [{"path":"...", "pattern":"...", "reason":"..."}]}
if state_path.exists():
    try:
        state = json.loads(state_path.read_text())
        for item in state.get(f"{owner}/{repo}#{n}", []):
            sig = norm(item.get("pattern", ""))
            if sig:
                dismissed.append({"path": item.get("path", ""), "sig": sig, "source": item.get("reason", "local-suppression")})
    except Exception as exc:
        raise SystemExit(f"pr-helper: invalid dismissal state {state_path}: {exc}")

if not dismissed:
    raise SystemExit(0)

suppressed = []
if inline.exists() and inline.read_text().strip() not in {"", "[]"}:
    items = json.loads(inline.read_text())
    kept = []
    for item in items:
        cand = {"path": item.get("path") or "", "sig": signature(item.get("body") or "")}
        hit = next((d for d in dismissed if same_finding(cand, d)), None)
        if hit:
            suppressed.append({"path": cand["path"], "sig": cand["sig"], "source": hit["source"]})
        else:
            kept.append(item)
    if len(kept) != len(items):
        inline.write_text(json.dumps(kept, indent=2) + "\n")

# Best-effort markdown cleanup for bullet/paragraph findings in the report body.
# Inline comments are the authoritative GitHub UX; this prevents obvious repeats
# from also appearing in the summary body.
if suppressed and report.exists():
    lines = report.read_text().splitlines()
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if "**[" in line:
            block = [line]
            j2 = i + 1
            while j2 < len(lines) and lines[j2].strip() and not lines[j2].startswith("## ") and not lines[j2].lstrip().startswith("- **["):
                block.append(lines[j2])
                # Keep continuation lines with the finding, but stop before the
                # next review-anvil bullet/section so one suppressed finding
                # cannot delete unrelated actionable findings.
                j2 += 1
            cand = {"path": "", "sig": signature("\n".join(block))}
            if any(same_finding(cand, {"path": "", "sig": s["sig"]}) for s in suppressed):
                i = j2
                continue
        out.append(line)
        i += 1
    note = f"\n\n---\n\n_Suppressed {len(suppressed)} finding(s) already dismissed/resolved on this PR._"
    report.write_text("\n".join(out).rstrip() + note + "\n")

if suppressed:
    print(f"pr-helper: suppressed {len(suppressed)} dismissed/resolved finding(s) before posting", file=sys.stderr)
PY
}

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

    if ! gh auth status --hostname "$host" >/dev/null 2>&1; then
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

    # If a sibling .inline.json exists with a non-empty array of inline
    # comment payloads, submit as a PR review (one timeline event with
    # both a top-level body and inline-anchored comments). Otherwise
    # fall back to a top-level comment via gh pr comment + marker URL
    # recovery.
    local inline_json="${report_path}.inline.json"
    local has_inline=0
    if [[ -f "$inline_json" ]]; then
        # Treat empty array / whitespace-only / missing-file as "no inline".
        if [[ -n "$(tr -d '[:space:]' <"$inline_json")" ]] \
           && [[ "$(tr -d '[:space:]' <"$inline_json")" != "[]" ]]; then
            has_inline=1
        fi
    fi

    suppress_dismissed_findings "$host" "$owner" "$repo" "$n" "$report_path" "$inline_json"
    if [[ -f "$inline_json" ]]; then
        if [[ -n "$(tr -d '[:space:]' <"$inline_json")" ]] \
           && [[ "$(tr -d '[:space:]' <"$inline_json")" != "[]" ]]; then
            has_inline=1
        else
            has_inline=0
        fi
    fi

    if [[ "$has_inline" -eq 1 ]]; then
        # Build the review payload: {body, event, comments}. Use jq to
        # assemble JSON safely (handles quoting, multiline body, etc.).
        command -v jq >/dev/null 2>&1 \
            || die "jq required to submit inline-comment reviews (it ships with gh; ensure it is on PATH)"
        local review_payload
        review_payload=$(jq -n --rawfile body "$report_path" --slurpfile comments "$inline_json" \
            '{event: "COMMENT", body: $body, comments: $comments[0]}')

        # Submit the review. The response JSON contains html_url
        # directly — no marker lookup needed on this path.
        local response url
        if ! response=$(printf '%s' "$review_payload" | gh api \
                          "repos/${owner}/${repo}/pulls/${n}/reviews" \
                          -X POST --input - 2>&1); then
            # Fall through to the top-level fallback rather than aborting:
            # inline-comment submission can fail when reviewer-supplied
            # file/line refs aren't actually in the PR's diff. The
            # user still wants their report posted somewhere.
            printf 'warning: PR-review submission failed (%s); falling back to top-level comment\n' \
                "$(printf '%s' "$response" | head -n1)" >&2
        else
            url=$(printf '%s' "$response" | jq -r '.html_url // empty' 2>/dev/null || true)
            cleanup_post_artifacts "$report_path"
            if [[ -n "$url" ]]; then
                printf '%s\n' "$url"
            else
                printf 'posted (URL unavailable)\n'
            fi
            return 0
        fi
    fi

    # Fallback path: top-level comment + marker URL recovery.
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

    cleanup_post_artifacts "$report_path"
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

    if ! gh auth status --hostname "$host" >/dev/null 2>&1; then
        die "gh auth status failed for host=$host; run 'gh auth login' (or set GH_TOKEN/GITHUB_TOKEN)"
    fi

    # Fetch the PR's head/base refs + title + author in one call (verify
    # reachability + capture fields).
    # Output looks like: <headRefName>\t<headRefOid>\t<baseRefName>\t<title>\t<author>
    local pr_fields
    if ! pr_fields=$(gh pr view "$n" -R "$owner/$repo" \
                       --json headRefName,headRefOid,baseRefName,title,author \
                       --jq '[.headRefName, .headRefOid, .baseRefName, .title, .author.login] | @tsv' 2>&1); then
        sleep 2
        if ! pr_fields=$(gh pr view "$n" -R "$owner/$repo" \
                           --json headRefName,headRefOid,baseRefName,title,author \
                           --jq '[.headRefName, .headRefOid, .baseRefName, .title, .author.login] | @tsv' 2>&1); then
            die "gh pr view failed for $owner/$repo#$n on host=$host: $pr_fields"
        fi
    fi
    local head_branch head_sha base_branch title author
    IFS=$'\t' read -r head_branch head_sha base_branch title author <<<"$pr_fields"
    [[ -n "$title" ]] || title='(title unavailable)'
    [[ -n "$author" ]] || author='(unknown)'

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

    # Generate marker UUID + absolute report path (same scheme as cmd_init
    # so the post-summary step can post the engine's final report back
    # to the PR with race-free URL recovery).
    command -v uuidgen >/dev/null 2>&1 || die "uuidgen not available"
    local anchor
    anchor=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local marker report_path
    marker=$(uuidgen | tr '[:upper:]' '[:lower:]')
    mkdir -p "$anchor/.review-anvil"
    report_path="$anchor/.review-anvil/final-report-${marker}.md"

    printf 'HOST=%s\n' "$host"
    printf 'OWNER=%s\n' "$owner"
    printf 'REPO=%s\n' "$repo"
    printf 'N=%s\n' "$n"
    printf 'HEAD_BRANCH=%s\n' "$head_branch"
    printf 'BASE_BRANCH=%s\n' "$base_branch"
    printf 'TITLE=%s\n' "$title"
    printf 'AUTHOR=%s\n' "$author"
    printf 'MARKER=%s\n' "$marker"
    printf 'REPORT_PATH=%s\n' "$report_path"
}

# Helper: build the "@author" cc tail.
_cc_tail() {
    local author="$1"
    if [[ "$author" == "(unknown)" || -z "$author" ]]; then
        printf ''
    else
        printf '. cc @%s' "$author"
    fi
}

cmd_post_start() {
    # Create the initial "starting" PR comment for review-anvil-improve-pr.
    # The agent should call cmd_post_update later to PATCH-edit this same
    # comment with the final summary (success) or failure summary.
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}" marker="${5:-}" author="${6:-}"
    for v in host owner repo n marker author; do
        [[ -n "${!v}" ]] || die "post-start: missing <$v>"
    done

    export GH_HOST="$host"

    local started_at
    started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    local tmp
    tmp=$(mktemp -t review-anvil-start.XXXXXX)
    {
        printf '<!-- review-anvil-marker: %s -->\n' "$marker"
        printf 'review-anvil-improve-pr started on this PR%s.\n\n' "$(_cc_tail "$author")"
        printf "I'll run a multi-agent review loop on this PR's diff against its base branch, applying fix commits to this branch as I go, then push everything back. I'll edit this comment with the synthesized report (or a failure summary) when done.\n\n"
        printf 'Started: %s\n' "$started_at"
    } > "$tmp"

    if ! gh pr comment "$n" -R "$owner/$repo" --body-file "$tmp" >/dev/null 2>&1; then
        rm -f "$tmp"
        die "gh pr comment failed for $owner/$repo#$n on host=$host"
    fi
    rm -f "$tmp"

    # Look up the comment we just created by marker, capture id + url.
    local comment_data id url
    for attempt in 1 2; do
        comment_data=$(gh api "repos/${owner}/${repo}/issues/${n}/comments" --paginate \
                       --jq ".[] | select(.body | contains(\"$marker\")) | [.id, .html_url] | @tsv" 2>/dev/null \
                       | head -n1 || true)
        [[ -n "$comment_data" ]] && break
        [[ "$attempt" -eq 1 ]] && sleep 2
    done
    [[ -n "$comment_data" ]] \
        || die "posted starting comment but could not recover its ID via marker lookup; the comment exists on the PR but post-update will not be able to edit it"
    IFS=$'\t' read -r id url <<<"$comment_data"

    printf 'COMMENT_ID=%s\n' "$id"
    printf 'COMMENT_URL=%s\n' "$url"
    printf 'STARTED_AT=%s\n' "$started_at"
}

cmd_post_update() {
    # Edit (PATCH) an existing review-anvil-improve-pr comment with the
    # final summary. Replaces the body entirely — the "starting" text
    # from post-start is gone, only the final summary remains.
    local host="${1:-}" owner="${2:-}" repo="${3:-}" comment_id="${4:-}" marker="${5:-}" report_path="${6:-}" author="${7:-}" outcome="${8:-}" started_at="${9:-}"
    for v in host owner repo comment_id marker report_path author outcome; do
        [[ -n "${!v}" ]] || die "post-update: missing <$v>"
    done
    [[ -f "$report_path" ]] || die "report file not found: $report_path"
    [[ "$outcome" == "success" || "$outcome" == "failure" ]] \
        || die "post-update: outcome must be 'success' or 'failure', got '$outcome'"

    export GH_HOST="$host"
    command -v jq >/dev/null 2>&1 \
        || die "jq required to PATCH-encode the comment body (it ships with gh; ensure it is on PATH)"

    local completed_at
    completed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    local tmp
    tmp=$(mktemp -t review-anvil-update.XXXXXX)
    {
        printf '<!-- review-anvil-marker: %s -->\n' "$marker"
        if [[ "$outcome" == "success" ]]; then
            printf 'review-anvil-improve-pr completed on this PR%s.\n\n---\n\n' "$(_cc_tail "$author")"
        else
            printf 'review-anvil-improve-pr **failed** on this PR%s.\n\n---\n\n' "$(_cc_tail "$author")"
        fi
        cat "$report_path"
        printf '\n\n---\n\n'
        [[ -n "$started_at" ]] && printf 'Started: %s; ' "$started_at"
        printf 'Completed: %s (outcome: %s)\n' "$completed_at" "$outcome"
    } > "$tmp"

    # PATCH the existing comment. Use jq --rawfile to build the JSON
    # body so multi-line content + special characters round-trip safely.
    local patch_payload
    patch_payload=$(jq -n --rawfile body "$tmp" '{body: $body}')
    if ! printf '%s' "$patch_payload" | gh api \
                "repos/${owner}/${repo}/issues/comments/${comment_id}" \
                -X PATCH --input - >/dev/null 2>&1; then
        rm -f "$tmp"
        die "gh api PATCH failed for comment $comment_id on $owner/$repo on host=$host"
    fi
    rm -f "$tmp"

    # The URL of the edited comment is the same as the starting one.
    local url
    url=$(gh api "repos/${owner}/${repo}/issues/comments/${comment_id}" --jq '.html_url' 2>/dev/null || true)

    cleanup_post_artifacts "$report_path"
    if [[ -n "$url" ]]; then
        printf '%s\n' "$url"
    else
        printf 'updated (URL unavailable)\n'
    fi
}

case "${1:-}" in
    init)             shift; cmd_init "$@" ;;
    post)             shift; cmd_post "$@" ;;
    verify-checkout)  shift; cmd_verify_checkout "$@" ;;
    post-start)       shift; cmd_post_start "$@" ;;
    post-update)      shift; cmd_post_update "$@" ;;
    "")               die "usage: pr-helper.sh {init [<locator>] | post <host> <owner> <repo> <n> <marker> <report_path> | verify-checkout [<locator>] | post-start <host> <owner> <repo> <n> <marker> <author> | post-update <host> <owner> <repo> <comment_id> <marker> <report_path> <author> <success|failure> [<started_at>]}" ;;
    *)                die "unknown subcommand: $1" ;;
esac
