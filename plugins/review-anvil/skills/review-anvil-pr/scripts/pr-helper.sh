#!/usr/bin/env bash
# pr-helper.sh — GitHub PR locator parsing, preflight, and report posting
# for the review-anvil-pr skill. Co-located with the skill so it travels
# across agents via `npx skills add mrshu/agent-skills --skill review-anvil-pr`.
#
# Subcommands (see the case dispatch at the bottom for exact signatures):
#
#   init [<locator>]        — locator parse/auto-detect, gh preflight, marker
#                             UUID + report path; prints KEY=VALUE lines.
#   post …                  — suppress dismissed findings, prepend marker,
#                             post as PR review (inline) or top-level comment;
#                             prints the comment URL.
#   verify-checkout […]     — improve-pr preflight: checkout matches PR head,
#                             clean worktree; prints KEY=VALUE lines.
#   post-start …            — post the "starting" comment, cc the author;
#                             prints COMMENT_ID/COMMENT_URL/STARTED_AT.
#   post-update …           — PATCH-edit the starting comment with the final
#                             report (suppression applied on success outcome).
#   dismissed …             — print itemized dismissed findings (resolved
#                             threads + local suppressions) for prompt blocks.
#   dismiss …               — record a local suppression in the dismissals
#                             state file ($REVIEW_ANVIL_DISMISSALS).
#   check-pins …            — mechanical preset pin-rejection over raw args.
#
# Environment switches:
#   REVIEW_ANVIL_NO_APPROVE=1     never submit APPROVE (downgrade to COMMENT)
#   REVIEW_ANVIL_SKIP_DISMISSED=1 skip dismissed-finding lookups (degraded
#                                 mode for hosts without GraphQL; also forces
#                                 APPROVE -> COMMENT)
#   REVIEW_ANVIL_DISMISSALS=path  local-suppressions state file (default
#                                 ~/.review-anvil/dismissed-findings.json)
#
# All subcommands exit non-zero on failure with an error on stderr.
#
# Locator forms accepted by init:
#   - Full GitHub URL: https://<host>/<owner>/<repo>/pull/<N>
#       (host = github.com OR a GitHub Enterprise hostname)
#   - Slug:            <owner>/<repo>#<N>  (host = github.com)
#
# Bare integers are rejected — the user must pass an unambiguous form.

set -euo pipefail

die() { printf 'pr-helper: %s\n' "$*" >&2; exit 1; }

# Create the artifact dir with a self-ignoring .gitignore. Leftover artifacts
# from failed runs must never show up as dirty worktree state (verify-checkout
# would refuse the next run with a misleading "uncommitted changes" error) or
# get staged into fix commits and pushed to the PR.
_ensure_artifact_dir() {
    local dir="$1"
    mkdir -p "$dir"
    [[ -f "$dir/.gitignore" ]] || printf '*\n' > "$dir/.gitignore"
}

# Remove this run's artifacts, and the directory itself when no other run's
# artifacts remain (the self-ignoring .gitignore doesn't count). Called only
# on successful post paths (failures leave the artifacts in place so the
# user can inspect / post manually).
# True when the dir contains anything besides its own .gitignore.
_dir_has_other_artifacts() {
    local dir="$1" f
    for f in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
        [[ -e "$f" ]] || continue
        [[ "${f##*/}" == ".gitignore" ]] && continue
        return 0
    done
    return 1
}

cleanup_post_artifacts() {
    local report_path="$1" dir
    rm -f "$report_path" "${report_path}.inline.json" "${report_path}.approval.json" "${report_path}.followups.json"
    dir=$(dirname "$report_path")
    if [[ -d "$dir" ]] && ! _dir_has_other_artifacts "$dir"; then
        rm -f "$dir/.gitignore"
        rmdir "$dir" 2>/dev/null || true
    fi
}

# Submit one PR review via the REST reviews endpoint. Relies on the caller's
# owner/repo/n/report_path locals (bash dynamic scoping). $1 = event,
# $2 = inline-comments JSON file, or "" for a body-only review. On success
# prints the review's html_url (possibly empty) and returns 0; on failure
# prints a one-line warning to stderr and returns 1 — the caller decides the
# next step in the fallback cascade.
_submit_review() {
    # jq availability is preflighted at the top of cmd_post — a die here
    # would run inside a command-substitution subshell and silently degrade
    # the cascade instead of aborting.
    local event="$1" inline="${2:-}" payload response
    if [[ -n "$inline" ]]; then
        payload=$(jq -n --rawfile body "$report_path" --arg event "$event" --slurpfile comments "$inline" \
            '{event: $event, body: $body, comments: $comments[0]}')
    else
        payload=$(jq -n --rawfile body "$report_path" --arg event "$event" \
            '{event: $event, body: $body}')
    fi
    if ! response=$(printf '%s' "$payload" | gh api \
                      "repos/${owner}/${repo}/pulls/${n}/reviews" \
                      -X POST --input - 2>&1); then
        printf 'warning: %s review submission%s failed (%s)\n' \
            "$event" "${inline:+ with inline comments}" \
            "$(printf '%s' "$response" | head -n1)" >&2
        return 1
    fi
    printf '%s' "$response" | jq -r '.html_url // empty' 2>/dev/null || true
}

# Print the post result and clean up artifacts. $1 = event, $2 = url (may be
# empty). Uses the caller's report_path local.
_emit_post_result() {
    local event="$1" url="$2"
    cleanup_post_artifacts "$report_path"
    if [[ -n "$url" ]]; then
        printf '%s\n' "$url"
    elif [[ "$event" == "APPROVE" ]]; then
        printf 'approved (URL unavailable)\n'
    else
        printf 'posted (URL unavailable)\n'
    fi
}

# Resolve a Python runner: prefer uv (which can provision an interpreter
# itself), fall back to system python3. The dismissed-findings logic is
# stdlib-only, so --no-project keeps uv from looking for a pyproject.
_py() {
    if command -v uv >/dev/null 2>&1; then
        uv run --no-project python3 "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 "$@"
    else
        die "neither uv nor python3 found; one is required for dismissed-finding handling (install uv: https://docs.astral.sh/uv/)"
    fi
}

# Shared dismissed-findings engine. Modes:
#   list <owner> <repo> <n>
#       Print itemized dismissed findings (resolved review threads + local
#       suppressions), one per line: "- <path>:<line> — <summary> (<source>)",
#       or "None." — used to build the DISMISSED FINDINGS reviewer-prompt block.
#   suppress <owner> <repo> <n> <report_path> <inline_json>
#       Remove dismissed findings from the inline-comments artifact and
#       DEMOTE matching report-body findings into a "Previously dismissed"
#       section (never silently delete — a false positive must stay visible).
#
# Matching is deliberately conservative: inline items require an exact path
# match AND text similarity >= 0.9; silently dropping a real finding is worse
# than occasionally repeating a dismissed one. Only each thread's root comment
# counts as the finding (replies are discussion). The GraphQL fetch is
# paginated and retried once; on persistent failure the script exits non-zero
# and the caller decides whether that is fatal (cmd_post) or a warning
# (cmd_post_update). Local suppressions come from $REVIEW_ANVIL_DISMISSALS,
# default ~/.review-anvil/dismissed-findings.json (a legacy
# ~/.hermes/state/review-anvil-dismissed-findings.json is honored if present).
# Shape: {"<owner>/<repo>#<N>": [{"path":"...", "pattern":"...", "reason":"..."}]}
_dismissed_py() {
    _py - "$@" <<'PY'
import difflib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

mode, owner, repo, n = sys.argv[1:5]

QUERY = r'''
query($owner:String!,$repo:String!,$number:Int!,$cursor:String){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      reviewThreads(first:100, after:$cursor){
        pageInfo{ hasNextPage endCursor }
        nodes{
          isResolved
          isOutdated
          path
          line
          comments(first:50){ nodes{ body author{login} url } }
        }
      }
    }
  }
}
'''

def gh_graphql(cursor):
    args = ["gh", "api", "graphql", "-f", f"owner={owner}", "-f", f"repo={repo}",
            "-F", f"number={n}", "-f", f"query={QUERY}"]
    if cursor:
        args += ["-f", f"cursor={cursor}"]
    for attempt in (1, 2):
        cp = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if cp.returncode == 0:
            return cp
        if attempt == 1:
            time.sleep(2)
    print(cp.stderr.strip() or cp.stdout.strip(), file=sys.stderr)
    raise SystemExit("pr-helper: could not read resolved PR review threads after retry")

def fetch_threads():
    nodes, cursor = [], None
    while True:
        page = json.loads(gh_graphql(cursor).stdout)["data"]["repository"]["pullRequest"]["reviewThreads"]
        nodes.extend(page["nodes"] or [])
        if not page["pageInfo"]["hasNextPage"]:
            return nodes
        cursor = page["pageInfo"]["endCursor"]

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

def summary(body: str) -> str:
    body = body or ""
    m = re.search(r"\*\*\[(critical|high|medium|low|nit)\]\s*([^*]+?)\*\*\s*[-—:]+\s*([^\n]+)", body, re.I)
    if m:
        return f"[{m.group(1).lower()}] {m.group(2).strip()} — {m.group(3).strip()}"[:160]
    lines = [ln.strip() for ln in body.splitlines() if ln.strip() and not ln.strip().startswith("<!--")]
    return (lines[0] if lines else "")[:160]

def state_file():
    env = os.environ.get("REVIEW_ANVIL_DISMISSALS")
    if env:
        return Path(env)
    for p in (Path.home() / ".review-anvil" / "dismissed-findings.json",
              Path.home() / ".hermes" / "state" / "review-anvil-dismissed-findings.json"):
        if p.exists():
            return p
    return None

dismissed = []
for t in fetch_threads():
    if not t.get("isResolved"):
        continue
    comments = (t.get("comments") or {}).get("nodes") or []
    if not comments:
        continue
    # Root comment only: it carries the finding; replies are discussion and
    # would inflate the false-positive surface of fuzzy matching.
    body = comments[0].get("body") or ""
    sig = signature(body)
    if sig:
        dismissed.append({"path": t.get("path") or "", "line": t.get("line"),
                          "sig": sig, "summary": summary(body),
                          "source": comments[0].get("url") or "resolved-thread"})

sp = state_file()
if sp and sp.exists():
    try:
        state = json.loads(sp.read_text())
        for item in state.get(f"{owner}/{repo}#{n}", []):
            sig = norm(item.get("pattern", ""))
            if sig:
                dismissed.append({"path": item.get("path", ""), "line": item.get("line"),
                                  "sig": sig, "summary": item.get("pattern", "")[:160],
                                  "source": item.get("reason", "local-suppression")})
    except Exception as exc:
        raise SystemExit(f"pr-helper: invalid dismissal state {sp}: {exc}")

if mode == "list":
    if not dismissed:
        print("None.")
    else:
        for d in dismissed:
            if d["path"]:
                loc = f'{d["path"]}:{d["line"]}' if d.get("line") else d["path"]
            else:
                loc = "(no file anchor)"
            print(f'- {loc} — {d["summary"]} ({d["source"]})')
    raise SystemExit(0)

if mode != "suppress":
    raise SystemExit(f"pr-helper: unknown dismissed-findings mode: {mode}")

report = Path(sys.argv[5])
inline = Path(sys.argv[6])
if not dismissed:
    raise SystemExit(0)

def same_finding(cand, dis, require_path):
    cs, ds = cand.get("sig", ""), dis.get("sig", "")
    if not cs or not ds:
        return False
    cpath, dpath = cand.get("path") or "", dis.get("path") or ""
    if require_path:
        # Inline comments get deleted outright, so demand the strongest
        # evidence: same file, near-identical text.
        if not cpath or not dpath or cpath != dpath:
            return False
    elif cpath and dpath and cpath != dpath:
        return False
    if cs == ds:
        return True
    if len(cs) > 35 and len(ds) > 35 and (cs in ds or ds in cs):
        return True
    return difflib.SequenceMatcher(None, cs, ds).ratio() >= 0.9

suppressed = []
if inline.exists() and inline.read_text().strip() not in {"", "[]"}:
    items = json.loads(inline.read_text())
    if not isinstance(items, list):
        raise SystemExit(f"pr-helper: {inline} is not a JSON array of comment objects")
    kept = []
    for item in items:
        if not isinstance(item, dict):
            kept.append(item)  # let posting fail loudly on malformed members
            continue
        cand = {"path": item.get("path") or "", "sig": signature(item.get("body") or "")}
        hit = next((d for d in dismissed if same_finding(cand, d, require_path=True)), None)
        if hit:
            suppressed.append({**cand, "summary": summary(item.get("body") or ""), "source": hit["source"]})
        else:
            kept.append(item)
    if len(kept) != len(items):
        inline.write_text(json.dumps(kept, indent=2) + "\n")

# Demote (never delete) matching findings in the report body: matched blocks
# move to a "Previously dismissed" section so a false positive stays visible
# to the author instead of vanishing. The walk is fence-aware ("**[" inside a
# code block must not start a finding) and paragraph-aware (a blank line ends
# a block only when what follows is not indented continuation or a fence).
demoted = []
if report.exists():
    lines = report.read_text().splitlines()

    def is_fence(s):
        ls = s.lstrip()
        return ls.startswith("```") or ls.startswith("~~~")

    def block_end(start):
        j = start + 1
        fence = False
        while j < len(lines):
            ln = lines[j]
            if is_fence(ln):
                fence = not fence
                j += 1
                continue
            if fence:
                j += 1
                continue
            if ln.startswith("## ") or ln.startswith("### ") or ln.lstrip().startswith("- **["):
                return j
            if not ln.strip():
                k = j + 1
                while k < len(lines) and not lines[k].strip():
                    k += 1
                if k < len(lines) and (lines[k].startswith((" ", "\t")) or is_fence(lines[k])):
                    j = k  # blank gap inside the block; continuation follows
                    continue
                return j
            j += 1
        return j

    out, i = [], 0
    in_fence = False
    while i < len(lines):
        line = lines[i]
        if is_fence(line):
            in_fence = not in_fence
            out.append(line)
            i += 1
            continue
        if not in_fence and "**[" in line:
            j2 = block_end(i)
            block = lines[i:j2]
            cand = {"path": "", "sig": signature("\n".join(block))}
            hit = next((d for d in dismissed if same_finding(cand, d, require_path=False)), None)
            if hit:
                demoted.append({"line": block[0].strip(), "sig": cand["sig"], "source": hit["source"]})
                i = j2
                continue
        out.append(line)
        i += 1
    if demoted or suppressed:
        demoted_sigs = {d["sig"] for d in demoted}
        tail = ["", "---", "", "### Previously dismissed on this PR (suppressed)", ""]
        tail += [f'{d["line"]} _(dismissed: {d["source"]})_' for d in demoted]
        tail += [f'- **(inline)** {s["path"]} — {s["summary"]} _(dismissed: {s["source"]})_'
                 for s in suppressed if s["sig"] not in demoted_sigs]
        report.write_text("\n".join(out).rstrip() + "\n" + "\n".join(tail) + "\n")

if suppressed or demoted:
    print(f"pr-helper: suppressed {len(suppressed)} inline / demoted {len(demoted)} report finding(s) already dismissed on this PR", file=sys.stderr)
PY
}

# Remove/demote findings the PR author already dismissed. Callers choose the
# failure semantics: cmd_post treats a non-zero exit as fatal (refuse to post
# possible repeat feedback), cmd_post_update degrades to a warning (the
# starting comment must always be updated).
suppress_dismissed_findings() {
    local host="$1" owner="$2" repo="$3" n="$4" report_path="$5" inline_json="$6"
    if [[ "${REVIEW_ANVIL_SKIP_DISMISSED:-}" == "1" ]]; then
        # Escape hatch for hosts where the GraphQL reviewThreads API is
        # unavailable (GHE without GraphQL, restricted token scopes).
        # Degraded mode: dismissed findings may be repeated; cmd_post
        # also forces APPROVE -> COMMENT when this is set.
        printf 'warning: REVIEW_ANVIL_SKIP_DISMISSED=1 — skipping dismissed-finding suppression (degraded mode)\n' >&2
        return 0
    fi
    export GH_HOST="$host"
    _dismissed_py suppress "$owner" "$repo" "$n" "$report_path" "$inline_json"
}

cmd_dismissed() {
    # Print the itemized dismissed-findings list for a PR — consumed by the
    # presets to build the DISMISSED FINDINGS reviewer-prompt block.
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}"
    for v in host owner repo n; do
        [[ -n "${!v}" ]] || die "dismissed: missing <$v>"
    done
    if [[ "${REVIEW_ANVIL_SKIP_DISMISSED:-}" == "1" ]]; then
        printf 'None. (dismissed-finding lookup skipped: REVIEW_ANVIL_SKIP_DISMISSED=1 — degraded mode)\n'
        return 0
    fi
    export GH_HOST="$host"
    _dismissed_py list "$owner" "$repo" "$n"
}

cmd_dismiss() {
    # Record a local suppression in the dismissals state file so future runs
    # against this PR skip the finding. Usage:
    #   dismiss <host> <owner> <repo> <n> <path-or-empty> <pattern> [<reason>]
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}" fpath="${5:-}" pattern="${6:-}" reason="${7:-local-suppression}"
    for v in host owner repo n pattern; do
        [[ -n "${!v}" ]] || die "dismiss: missing <$v>"
    done
    _py - "$owner" "$repo" "$n" "$fpath" "$pattern" "$reason" <<'PY'
import json
import os
import sys
from pathlib import Path

owner, repo, n, fpath, pattern, reason = sys.argv[1:7]
sp = Path(os.environ.get("REVIEW_ANVIL_DISMISSALS")
          or (Path.home() / ".review-anvil" / "dismissed-findings.json"))
sp.parent.mkdir(parents=True, exist_ok=True)
state = {}
if sp.exists():
    try:
        state = json.loads(sp.read_text())
    except Exception as exc:
        raise SystemExit(f"pr-helper: invalid dismissal state {sp}: {exc}")
key = f"{owner}/{repo}#{n}"
state.setdefault(key, []).append({"path": fpath, "pattern": pattern, "reason": reason})
sp.write_text(json.dumps(state, indent=2) + "\n")
print(f"recorded suppression for {key} in {sp}")
PY
}

cmd_check_pins() {
    # Mechanical pin-rejection (the engine's prose algorithm, made binding):
    #   check-pins <preset-name> <pins-csv> [<raw-args>]
    # Segment-split raw args on commas, take each segment's key (text before
    # its first ':'), lowercase, abort if it matches a pinned param. A comma
    # inside a quoted value can split into stray segments, but those only
    # abort if their derived key exactly equals a pin name — refusing in an
    # ambiguous case is the safe direction.
    local preset="${1:-}" pins_csv="${2:-}" raw="${3:-}"
    [[ -n "$preset" && -n "$pins_csv" ]] || die "check-pins: usage: check-pins <preset> <pins-csv> [<raw-args>]"
    if [[ -z "$raw" ]]; then
        printf 'pins-ok\n'
        return 0
    fi
    local seg key pin pin_norm
    local IFS=','
    for seg in $raw; do
        key=$(printf '%s' "${seg%%:*}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        [[ -n "$key" ]] || continue
        for pin in $pins_csv; do
            pin_norm=$(printf '%s' "$pin" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
            if [[ "$key" == "$pin_norm" ]]; then
                die "error: $pin_norm is pinned by $preset and cannot be overridden in args"
            fi
        done
    done
    printf 'pins-ok\n'
}

# Preflight the dependencies that would otherwise fail only at post time,
# after the expensive review has already run.
_preflight_deps() {
    command -v gh >/dev/null 2>&1 || die "install gh first; the review-anvil PR skills require gh"
    command -v uuidgen >/dev/null 2>&1 || die "uuidgen not available"
    command -v jq >/dev/null 2>&1 \
        || die "jq not found — required at post time (gh's --jq is built-in gojq, not a jq binary; install jq now so the run doesn't fail after the review)"
    command -v uv >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 \
        || die "neither uv nor python3 found — required for dismissed-finding handling (install uv: https://docs.astral.sh/uv/)"
}

cmd_init() {
    local locator="${1:-}"
    _preflight_deps

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
            die "no <locator> supplied and no PR detected for the current branch — pass a URL or <owner>/<repo>#<N>, or check out the PR's branch first (if gh is not authenticated, run 'gh auth login' first)"
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

    # Verify PR reachability AND extract title + head SHA in one network
    # call. Capture stderr separately: gh writes update/deprecation notices
    # to stderr even on success, and 2>&1 would corrupt the parsed values.
    local pr_data errf
    errf=$(mktemp -t review-anvil-err.XXXXXX)
    if ! pr_data=$(gh pr view "$n" -R "$owner/$repo" --json title,headRefOid \
                     --jq '[.headRefOid, .title] | @tsv' 2>"$errf"); then
        sleep 2
        if ! pr_data=$(gh pr view "$n" -R "$owner/$repo" --json title,headRefOid \
                         --jq '[.headRefOid, .title] | @tsv' 2>"$errf"); then
            local err
            err=$(head -n1 "$errf" || true)
            rm -f "$errf"
            die "gh pr view failed for $owner/$repo#$n on host=$host: $err"
        fi
    fi
    rm -f "$errf"
    local head_sha title
    IFS=$'\t' read -r head_sha title <<<"$pr_data"
    [[ -n "$title" ]] || title='(title unavailable)'

    # Anchor the report path inside the repo's worktree, not whatever
    # CWD the orchestrator happens to be in. Falls back to CWD if we
    # are not inside a git worktree (degenerate but tolerated).
    local anchor
    anchor=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local marker report_path
    marker=$(uuidgen | tr '[:upper:]' '[:lower:]')
    _ensure_artifact_dir "$anchor/.review-anvil"
    # Emit an absolute path so the engine writes to and the post step
    # reads from the same file regardless of CWD changes between
    # invocations.
    report_path="$anchor/.review-anvil/final-report-${marker}.md"

    printf 'HOST=%s\n' "$host"
    printf 'OWNER=%s\n' "$owner"
    printf 'REPO=%s\n' "$repo"
    printf 'N=%s\n' "$n"
    printf 'HEAD_SHA=%s\n' "$head_sha"
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

    # Preflight jq at top level: a die inside the cascade's command
    # substitutions cannot abort the script. Note: gh's --jq is built-in
    # gojq — it does NOT provide a jq binary on PATH.
    command -v jq >/dev/null 2>&1 \
        || die "jq not found — required to post reviews (gh's --jq is built-in gojq, not a jq binary; install jq)"

    # Prepend the marker atomically, exactly once (post is retryable after a
    # suppression failure — a retry must not stack marker lines).
    if ! grep -q "review-anvil-marker: $marker" "$report_path"; then
        local tmp="${report_path}.tmp"
        {
            printf '<!-- review-anvil-marker: %s -->\n' "$marker"
            cat "$report_path"
        } > "$tmp"
        mv "$tmp" "$report_path"
    fi

    local inline_json="${report_path}.inline.json"
    local approval_json="${report_path}.approval.json"
    local review_event="COMMENT"
    if [[ -f "$approval_json" ]]; then
        review_event=$(jq -r '.event // "COMMENT"' "$approval_json" 2>/dev/null || printf 'COMMENT')
        case "$review_event" in
            APPROVE|COMMENT) ;;
            *)
                # Same safe direction as malformed JSON: an unexpected value
                # must never block the post — and must never approve.
                printf 'warning: unexpected review event in %s: %s — defaulting to COMMENT\n' \
                    "$approval_json" "$review_event" >&2
                review_event="COMMENT" ;;
        esac
    fi

    # Mechanical approve kill-switches: the engine's approve:never rule is
    # LLM-enforced prose; these make it (and skipped dismissed lookups, which
    # invalidate the approval criteria) binding regardless of what the
    # orchestrator wrote into approval.json.
    if [[ "$review_event" == "APPROVE" && "${REVIEW_ANVIL_NO_APPROVE:-}" == "1" ]]; then
        printf 'warning: REVIEW_ANVIL_NO_APPROVE=1 — downgrading APPROVE to COMMENT\n' >&2
        review_event="COMMENT"
    fi
    if [[ "$review_event" == "APPROVE" && "${REVIEW_ANVIL_SKIP_DISMISSED:-}" == "1" ]]; then
        printf 'warning: dismissed-finding lookup was skipped, so the approval criteria cannot hold — downgrading APPROVE to COMMENT\n' >&2
        review_event="COMMENT"
    fi

    # Staleness gate: an approval is only valid for the head SHA the review
    # actually saw. approval.json may carry "head_sha" (copied by the engine
    # from init's HEAD_SHA output); when the PR head has moved, downgrade —
    # new commits pushed mid-run were never reviewed.
    if [[ "$review_event" == "APPROVE" ]]; then
        local reviewed_sha current_sha
        reviewed_sha=$(jq -r '.head_sha // empty' "$approval_json" 2>/dev/null || true)
        if [[ -n "$reviewed_sha" ]]; then
            current_sha=$(gh pr view "$n" -R "$owner/$repo" --json headRefOid --jq '.headRefOid' 2>/dev/null || true)
            if [[ -n "$current_sha" && "$current_sha" != "$reviewed_sha" ]]; then
                printf 'warning: PR head moved since review (%s -> %s); downgrading APPROVE to COMMENT\n' \
                    "${reviewed_sha:0:8}" "${current_sha:0:8}" >&2
                # shellcheck disable=SC2016  # backticks are markdown, not expansion
                printf '\n\n---\n\n_review-anvil decided APPROVE for head `%s`, but the PR has since moved to `%s`; posted as a comment instead — the newer commits were not reviewed._\n' \
                    "${reviewed_sha:0:8}" "${current_sha:0:8}" >> "$report_path"
                review_event="COMMENT"
            fi
        else
            printf 'warning: approval.json carries no head_sha; cannot verify the approval matches the reviewed state\n' >&2
        fi
    fi

    suppress_dismissed_findings "$host" "$owner" "$repo" "$n" "$report_path" "$inline_json" \
        || die "dismissed-finding suppression failed; refusing to post possible repeat findings (report left at $report_path)"

    # Compute inline presence after suppression (which may have emptied the
    # array). Empty array / whitespace-only / missing file = no inline.
    local has_inline=0
    if [[ -f "$inline_json" ]] \
       && [[ -n "$(tr -d '[:space:]' <"$inline_json")" ]] \
       && [[ "$(tr -d '[:space:]' <"$inline_json")" != "[]" ]]; then
        has_inline=1
    fi

    # Review-submission cascade — a failed approval must never cost the
    # report (GitHub rejects self-approval with 422, the most common case
    # for the "review the PR I'm on" workflow):
    #   1. review {requested event + inline comments}   (if inline exists;
    #      can also fail when reviewer line refs aren't in the PR's diff)
    #   2. review {APPROVE, body-only}                  (if event is APPROVE)
    #   3. downgrade APPROVE -> COMMENT, note it in the report, retry
    #      {COMMENT + inline}                           (if inline exists)
    #   4. top-level comment fallback (below)
    local url
    if [[ "$has_inline" -eq 1 ]]; then
        if url=$(_submit_review "$review_event" "$inline_json"); then
            _emit_post_result "$review_event" "$url"
            return 0
        fi
    fi

    if [[ "$review_event" == "APPROVE" ]]; then
        if url=$(_submit_review APPROVE ""); then
            _emit_post_result APPROVE "$url"
            return 0
        fi
        review_event="COMMENT"
        printf 'warning: approval could not be submitted (common cause: GitHub rejects approving your own PR); downgrading to a comment review\n' >&2
        printf '\n\n---\n\n_review-anvil decided APPROVE, but GitHub rejected the approval (commonly: self-authored PRs cannot be approved); posted as a comment instead._\n' >> "$report_path"
        if [[ "$has_inline" -eq 1 ]]; then
            if url=$(_submit_review COMMENT "$inline_json"); then
                _emit_post_result COMMENT "$url"
                return 0
            fi
        fi
    fi

    # A gh failure while reading the response can leave a review created
    # server-side; check for our marker among existing reviews before
    # posting the report a second time.
    local existing
    existing=$(gh api "repos/${owner}/${repo}/pulls/${n}/reviews" --paginate \
               --jq ".[] | select(.body | contains(\"$marker\")) | .html_url" 2>/dev/null \
               | head -n1 || true)
    if [[ -n "$existing" ]]; then
        printf 'note: a review with this marker already exists on the PR; not posting again\n' >&2
        cleanup_post_artifacts "$report_path"
        printf '%s\n' "$existing"
        return 0
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

    _preflight_deps

    # Auto-detect PR from current branch if no locator given (same logic
    # as cmd_init — `gh pr view` with no args uses the working
    # directory's repo and the current branch's tracking info).
    if [[ -z "$locator" ]]; then
        local detected
        if detected=$(gh pr view --json url --jq '.url' 2>/dev/null) && [[ -n "$detected" ]]; then
            locator="$detected"
            printf 'auto-detected PR: %s\n' "$locator" >&2
        else
            die "no <locator> supplied and no PR detected for the current branch — pass a URL or <owner>/<repo>#<N>, or check out the PR's branch first (if gh is not authenticated, run 'gh auth login' first)"
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
    # reachability + capture fields). Stderr captured separately — gh
    # notices on success would corrupt the TSV parse.
    # Output looks like: <headRefName>\t<headRefOid>\t<baseRefName>\t<title>\t<author>
    local pr_fields errf
    errf=$(mktemp -t review-anvil-err.XXXXXX)
    if ! pr_fields=$(gh pr view "$n" -R "$owner/$repo" \
                       --json headRefName,headRefOid,baseRefName,title,author \
                       --jq '[.headRefName, .headRefOid, .baseRefName, .title, .author.login] | @tsv' 2>"$errf"); then
        sleep 2
        if ! pr_fields=$(gh pr view "$n" -R "$owner/$repo" \
                           --json headRefName,headRefOid,baseRefName,title,author \
                           --jq '[.headRefName, .headRefOid, .baseRefName, .title, .author.login] | @tsv' 2>"$errf"); then
            local err
            err=$(head -n1 "$errf" || true)
            rm -f "$errf"
            die "gh pr view failed for $owner/$repo#$n on host=$host: $err"
        fi
    fi
    rm -f "$errf"
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

    # Ensure the base branch resolves to a usable diff target (the engine
    # runs `git diff <BASE_BRANCH>...HEAD` with the value we emit). A bare
    # branch name does NOT resolve through refs/remotes/<remote>/<name>, so
    # after fetching we must re-verify and emit the remote-tracking ref when
    # only that exists. The remote comes from the current branch's upstream
    # (falling back to origin) — PR checkouts aren't always on "origin".
    local remote
    remote=$(git config "branch.${current_branch}.remote" 2>/dev/null || true)
    [[ -n "$remote" ]] || remote="origin"
    if ! git rev-parse --verify --quiet "$base_branch" >/dev/null; then
        if ! git rev-parse --verify --quiet "$remote/$base_branch" >/dev/null; then
            git fetch "$remote" "$base_branch:refs/remotes/$remote/$base_branch" 2>/dev/null \
                || git fetch "$remote" "$base_branch" 2>/dev/null \
                || die "base branch '$base_branch' not available locally and 'git fetch $remote $base_branch' failed; ensure the base branch is reachable"
        fi
        if git rev-parse --verify --quiet "$remote/$base_branch" >/dev/null; then
            base_branch="$remote/$base_branch"
        elif ! git rev-parse --verify --quiet "$base_branch" >/dev/null; then
            die "fetched '$base_branch' from $remote but no resolvable ref exists for it; ensure the base branch is reachable"
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
    _ensure_artifact_dir "$anchor/.review-anvil"
    report_path="$anchor/.review-anvil/final-report-${marker}.md"

    printf 'HOST=%s\n' "$host"
    printf 'OWNER=%s\n' "$owner"
    printf 'REPO=%s\n' "$repo"
    printf 'N=%s\n' "$n"
    printf 'HEAD_BRANCH=%s\n' "$head_branch"
    printf 'HEAD_SHA=%s\n' "$head_sha"
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
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}" comment_id="${5:-}" marker="${6:-}" report_path="${7:-}" author="${8:-}" outcome="${9:-}" started_at="${10:-}"
    for v in host owner repo n comment_id marker report_path author outcome; do
        [[ -n "${!v}" ]] || die "post-update: missing <$v>"
    done
    [[ -f "$report_path" ]] || die "report file not found: $report_path"
    [[ "$outcome" == "success" || "$outcome" == "failure" ]] \
        || die "post-update: outcome must be 'success' or 'failure', got '$outcome'"

    export GH_HOST="$host"
    command -v jq >/dev/null 2>&1 \
        || die "jq not found — required to PATCH-encode the comment body (gh's --jq is built-in gojq, not a jq binary; install jq)"

    # Suppress dismissed findings on the success path only (a failure summary
    # has nothing to suppress). Non-fatal: the starting comment must be
    # updated even if GitHub's thread state is momentarily unreadable —
    # aborting here would create a dangling "starting" comment.
    if [[ "$outcome" == "success" ]]; then
        suppress_dismissed_findings "$host" "$owner" "$repo" "$n" "$report_path" "${report_path}.inline.json" \
            || printf 'pr-helper: warning: dismissed-finding suppression failed; updating comment with unfiltered report\n' >&2
    fi

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
    dismissed)        shift; cmd_dismissed "$@" ;;
    dismiss)          shift; cmd_dismiss "$@" ;;
    check-pins)       shift; cmd_check_pins "$@" ;;
    "")               die "usage: pr-helper.sh {init [<locator>] | post <host> <owner> <repo> <n> <marker> <report_path> | verify-checkout [<locator>] | post-start <host> <owner> <repo> <n> <marker> <author> | post-update <host> <owner> <repo> <n> <comment_id> <marker> <report_path> <author> <success|failure> [<started_at>] | dismissed <host> <owner> <repo> <n> | dismiss <host> <owner> <repo> <n> <path> <pattern> [<reason>] | check-pins <preset> <pins-csv> [<raw-args>]}" ;;
    *)                die "unknown subcommand: $1" ;;
esac
