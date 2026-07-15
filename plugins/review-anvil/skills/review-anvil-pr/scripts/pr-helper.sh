#!/usr/bin/env bash
# pr-helper.sh — GitHub PR locator parsing, preflight, and report posting
# for the review-anvil-pr skill. Co-located with the skill so it travels
# across agents via `npx skills add mrshu/agent-skills --skill review-anvil-pr`.
#
# Subcommands (see the case dispatch at the bottom for exact signatures):
#
#   init [<locator>]        — locator parse/auto-detect, gh preflight, marker
#                             UUID + report path; prints KEY=VALUE lines.
#   post …                  — classify prior feedback and suppress duplicate
#                             inline threads, prepend marker,
#                             post as PR review (inline) or top-level comment;
#                             prints the comment URL.
#   verify-checkout […]     — improve-pr preflight: checkout matches PR head,
#                             clean worktree; prints KEY=VALUE lines.
#   post-start …            — post the "starting" comment, cc the author;
#                             prints COMMENT_ID/COMMENT_URL/STARTED_AT.
#   post-update …           — PATCH-edit the starting comment with the final
#                             report (suppression applied on success outcome).
#   history …               — print all prior PR findings with open/resolved/
#                             outdated/reported/suppressed status for prompts.
#   dismissed …             — legacy resolved/suppressed-only history view.
#   dismiss …               — record a local suppression in the dismissals
#                             state file ($REVIEW_ANVIL_DISMISSALS).
#   compact-report …        — legacy no-op; reports are posted without loss.
#   process-inline …        — filter/prepare inline review comments.
#   check-pins …            — mechanical preset pin-rejection over raw args.
#
# Environment switches:
#   REVIEW_ANVIL_NO_APPROVE=1     never submit APPROVE (downgrade to COMMENT)
#   REVIEW_ANVIL_SKIP_DISMISSED=1 legacy name: skip full PR-history lookups
#                                 (degraded mode for hosts without GraphQL;
#                                 also forces APPROVE -> COMMENT)
#   REVIEW_ANVIL_DISMISSALS=path  local-suppressions state file (default
#                                 ~/.review-anvil/dismissed-findings.json)
#   REVIEW_ANVIL_INLINE_MIN_SEVERITY=medium
#                                 minimum severity posted as inline comments
#                                 (lower findings stay in the summary)
#   REVIEW_ANVIL_ENABLE_SUGGESTIONS=0
#                                 disable helper-added ```suggestion blocks
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
    rm -f "$report_path" "${report_path}.inline.json" "${report_path}.approval.json" "${report_path}.followups.json" "${report_path}.full.md"
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
# itself), fall back to system python3. The PR-history logic is
# stdlib-only, so --no-project keeps uv from looking for a pyproject.
_py() {
    if command -v uv >/dev/null 2>&1; then
        uv run --no-project python3 "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 "$@"
    else
        die "neither uv nor python3 found; one is required for PR-feedback history handling (install uv: https://docs.astral.sh/uv/)"
    fi
}

compact_report_for_github() {
    local report_path="${1:-}"
    [[ -f "$report_path" ]] || die "compact-report: report file not found: $report_path"

    # Historical versions rewrote long reports into a compact summary before
    # posting. Review output is now kept lossless; if GitHub rejects an
    # unusually large payload, the original report remains on disk for the
    # caller to rewrite intentionally and retry.
    return 0
}

process_inline_comments_for_github() {
    local inline_json="${1:-}" min_severity="${REVIEW_ANVIL_INLINE_MIN_SEVERITY:-medium}"
    [[ -n "$inline_json" && -f "$inline_json" ]] || return 0

    _py - "$inline_json" "$min_severity" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

inline = Path(sys.argv[1])
min_severity = sys.argv[2].lower()
enable_suggestions = os.environ.get("REVIEW_ANVIL_ENABLE_SUGGESTIONS", "1") != "0"

rank = {"critical": 0, "high": 1, "medium": 2, "low": 3, "nit": 4}
if min_severity not in rank:
    raise SystemExit(
        "pr-helper: REVIEW_ANVIL_INLINE_MIN_SEVERITY must be one of "
        "critical|high|medium|low|nit"
    )

raw = inline.read_text().strip()
if not raw or raw == "[]":
    raise SystemExit(0)

items = json.loads(raw)
if not isinstance(items, list):
    raise SystemExit(f"pr-helper: {inline} is not a JSON array of comment objects")

allowed = {"path", "position", "body", "line", "side", "start_line", "start_side"}

def infer_severity(item):
    explicit = str(item.get("severity", "")).lower()
    if explicit in rank:
        return explicit
    body = item.get("body") or ""
    id_pattern = r"(?:RAV[FW]\d{3,}|[FW]-\d{3,})"
    m = re.search(rf"\*\*(?:{id_pattern}\s+)?\[(critical|high|medium|low|nit)\]", body, re.I)
    if m:
        return m.group(1).lower()
    m = re.search(r"\b(critical|high|medium|low|nit)\s*:", body, re.I)
    if m:
        return m.group(1).lower()
    # Unknown severity stays visible; medium is the least surprising default.
    return "medium"

def append_suggestion(body, item):
    suggestion = item.get("suggestion")
    if suggestion is None:
        suggestion = item.get("suggested_change")
    if suggestion is None:
        suggestion = item.get("suggestedChange")
    if not enable_suggestions or suggestion is None:
        return body
    suggestion = str(suggestion).strip("\n")
    if not suggestion or "```" in suggestion or "```suggestion" in body:
        return body
    # GitHub suggestions apply to the commented line/range. Only append when
    # the comment has a concrete new-side anchor that GitHub can apply.
    if not (item.get("line") or item.get("start_line") or item.get("position")):
        return body
    return body.rstrip() + "\n\n```suggestion\n" + suggestion + "\n```"

kept = []
filtered = 0
suggested = 0

for item in items:
    if not isinstance(item, dict):
        kept.append(item)
        continue
    severity = infer_severity(item)
    if rank[severity] > rank[min_severity]:
        filtered += 1
        continue
    original_body = item.get("body") or ""
    body = append_suggestion(original_body, item)
    if "```suggestion" in body and "```suggestion" not in original_body:
        suggested += 1
    clean = {key: item[key] for key in allowed if key in item}
    clean["body"] = body
    kept.append(clean)

inline.write_text(json.dumps(kept, indent=2) + "\n")
if filtered or suggested:
    print(
        "pr-helper: inline comments processed "
        f"({filtered} summary-only, {suggested} suggestion block(s) added)",
        file=sys.stderr,
    )
PY
}

# Shared PR-feedback-history engine. Modes:
#   history <owner> <repo> <n>
#       Print every prior root review thread with its open/resolved/outdated
#       state, plus summary-only findings from earlier review-anvil reports and
#       explicit local suppressions. This builds the PR REVIEW HISTORY prompt.
#   list <owner> <repo> <n>
#       Backwards-compatible resolved/suppressed-only view.
#   suppress <owner> <repo> <n> <report_path> <inline_json>
#       Remove duplicate prior findings from the inline-comments artifact and
#       classify matching report-body findings in a status-aware section.
#
# Matching is deliberately conservative: inline items require an exact path
# match AND text similarity >= 0.9. Only each thread's root comment counts as
# the finding (replies are discussion). The GraphQL fetch is paginated across
# threads, reviews, and issue comments and retried once; on persistent failure
# the script exits non-zero
# and the caller decides whether that is fatal (cmd_post) or a warning
# (cmd_post_update). Local suppressions come from $REVIEW_ANVIL_DISMISSALS,
# default ~/.review-anvil/dismissed-findings.json (a legacy
# ~/.hermes/state/review-anvil-dismissed-findings.json is honored if present).
# Shape: {"<owner>/<repo>#<N>": [{"path":"...", "pattern":"...", "reason":"..."}]}
_review_history_py() {
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
query($owner:String!,$repo:String!,$number:Int!,$threadCursor:String,$reviewCursor:String,$commentCursor:String){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      reviewThreads(first:100, after:$threadCursor){
        pageInfo{ hasNextPage endCursor }
        nodes{
          isResolved
          isOutdated
          path
          line
          comments(first:50){ nodes{ body author{login} url } }
        }
      }
      reviews(first:100, after:$reviewCursor){
        pageInfo{ hasNextPage endCursor }
        nodes{ body state url author{login} }
      }
      comments(first:100, after:$commentCursor){
        pageInfo{ hasNextPage endCursor }
        nodes{ body url author{login} }
      }
    }
  }
}
'''

def gh_graphql(thread_cursor, review_cursor, comment_cursor):
    args = ["gh", "api", "graphql", "-f", f"owner={owner}", "-f", f"repo={repo}",
            "-F", f"number={n}", "-f", f"query={QUERY}"]
    for key, value in (("threadCursor", thread_cursor),
                       ("reviewCursor", review_cursor),
                       ("commentCursor", comment_cursor)):
        if value:
            args += ["-f", f"{key}={value}"]
    for attempt in (1, 2):
        cp = subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if cp.returncode == 0:
            return cp
        if attempt == 1:
            time.sleep(2)
    print(cp.stderr.strip() or cp.stdout.strip(), file=sys.stderr)
    raise SystemExit("pr-helper: could not read PR review history after retry")

def fetch_history():
    threads, reviews, comments = [], [], []
    thread_cursor = review_cursor = comment_cursor = None
    thread_done = review_done = comment_done = False
    while True:
        try:
            payload = json.loads(gh_graphql(thread_cursor, review_cursor, comment_cursor).stdout)
            if not isinstance(payload, dict):
                raise TypeError("top-level response is not an object")
            if payload.get("errors"):
                raise KeyError(f'GraphQL errors: {payload["errors"]}')
            pr = payload["data"]["repository"]["pullRequest"]
            if pr is None:
                raise KeyError("pullRequest")
            thread_page = pr["reviewThreads"]
            review_page = pr["reviews"]
            comment_page = pr["comments"]
        except (KeyError, TypeError, json.JSONDecodeError) as exc:
            raise SystemExit(f"pr-helper: malformed PR review history response: {exc}")

        for name, page in (("reviewThreads", thread_page), ("reviews", review_page),
                           ("comments", comment_page)):
            if not isinstance(page, dict) or not isinstance(page.get("pageInfo"), dict):
                raise SystemExit(f"pr-helper: malformed PR review history response: {name} connection/pageInfo")
            if "hasNextPage" not in page["pageInfo"] or "endCursor" not in page["pageInfo"]:
                raise SystemExit(f"pr-helper: malformed PR review history response: {name} pageInfo fields")

        if not thread_done:
            threads.extend(thread_page.get("nodes") or [])
            thread_done = not thread_page["pageInfo"]["hasNextPage"]
            thread_cursor = thread_page["pageInfo"]["endCursor"] if not thread_done else None
            if not thread_done and not thread_cursor:
                raise SystemExit("pr-helper: malformed PR review history response: reviewThreads page has no endCursor")
        if not review_done:
            reviews.extend(review_page.get("nodes") or [])
            review_done = not review_page["pageInfo"]["hasNextPage"]
            review_cursor = review_page["pageInfo"]["endCursor"] if not review_done else None
            if not review_done and not review_cursor:
                raise SystemExit("pr-helper: malformed PR review history response: reviews page has no endCursor")
        if not comment_done:
            comments.extend(comment_page.get("nodes") or [])
            comment_done = not comment_page["pageInfo"]["hasNextPage"]
            comment_cursor = comment_page["pageInfo"]["endCursor"] if not comment_done else None
            if not comment_done and not comment_cursor:
                raise SystemExit("pr-helper: malformed PR review history response: comments page has no endCursor")
        if thread_done and review_done and comment_done:
            return threads, reviews, comments

def norm(text: str) -> str:
    text = re.sub(r"https?://\S+", " ", text or "")
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", " ", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"[^a-zA-Z0-9]+", " ", text).lower()
    words = [w for w in text.split() if len(w) > 2 and w not in {"the", "and", "for", "with", "this", "that", "from", "into", "when", "because"}]
    return " ".join(words)

ID_PATTERN = r"(?:RAVF\d{3,}|F-\d{3,})"
SEVERITY_NAMES = {"critical", "high", "medium", "low", "nit"}
SEVERITY_INITIALS = {"c": "critical", "h": "high", "m": "medium", "l": "low", "n": "nit"}

FINDING_RE = re.compile(
    rf"\*\*(?:{ID_PATTERN}\s+)?\[(?P<severity>critical|high|medium|low|nit)\]\s*(?P<area>[^*]+?)\*\*(?:\s+`(?P<location>[^`]+)`)?\s*[-—:]+\s*(?P<finding>[^\n]+)",
    re.I,
)
SUMMARY_RE = re.compile(
    rf"^\s*(?:[-*]\s+)?(?:{ID_PATTERN}\s+)?\[(?P<severity>critical|high|medium|low|nit)\]\s*(?P<area>.+?)\s*[-—:]+\s*(?P<finding>.+)$",
    re.I,
)

def severity_name(value):
    value = (value or "").strip().lower()
    if value in SEVERITY_NAMES:
        return value
    return SEVERITY_INITIALS.get(value)

def severity_from_body(body):
    match = FINDING_RE.search(body or "")
    if match:
        return severity_name(match.group("severity"))
    for line in (body or "").splitlines():
        item = table_finding(line)
        if item:
            return item["severity"]
        match = SUMMARY_RE.search(line)
        if match:
            return severity_name(match.group("severity"))
    return None

def table_finding(line):
    stripped = (line or "").strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        return None
    cells = [cell.strip() for cell in stripped.strip("|").split("|")]
    if len(cells) < 5 or not re.fullmatch(ID_PATTERN, cells[0], re.I):
        return None
    sev = severity_name(cells[1])
    if not sev:
        return None
    finding = " | ".join(cells[4:]).strip()
    if not cells[2] or not finding:
        return None
    return {"id": cells[0], "severity": sev, "area": cells[2],
            "location": cells[3], "finding": finding}

def path_from_location(location):
    loc = (location or "").strip().strip("`")
    if not loc or loc in {"-", "—"}:
        return ""
    match = re.match(r"([^:\s]+)(?::\d+(?:-\d+)?)?$", loc)
    return match.group(1) if match else ""

def path_from_block(block):
    for line in block:
        m = FINDING_RE.search(line or "")
        if m:
            path = path_from_location(m.group("location"))
            if path:
                return path
        item = table_finding(line)
        if item:
            path = path_from_location(item.get("location"))
            if path:
                return path
    return ""

def is_finding_line(line: str) -> bool:
    return bool(FINDING_RE.search(line or "") or table_finding(line))

def signature(body: str) -> str:
    body = body or ""
    # review-anvil body: **[medium] area** -- What ...
    # Stable IDs are optional: **RAVF001 [medium] area** -- What ...
    # Legacy dashed F/W IDs are accepted too.
    # Report rows may include a code location between the bold label and dash.
    m = FINDING_RE.search(body)
    if m:
        return norm(f'{m.group("area")} {m.group("finding")}')
    for line in body.splitlines():
        item = table_finding(line)
        if item:
            return norm(f'{item["area"]} {item["finding"]}')
        m = SUMMARY_RE.search(line)
        if m:
            return norm(f'{m.group("area")} {m.group("finding")}')
    # GitHub/Codex-style body: Medium: what...
    m = re.search(r"\b(critical|high|medium|low|nit)\s*:\s*([^\n]+)", body, re.I)
    if m:
        return norm(m.group(2))
    lines = [ln.strip() for ln in body.splitlines() if ln.strip() and not ln.strip().startswith("<!--")]
    return norm(" ".join(lines[:2])[:500])

def summary(body: str) -> str:
    body = body or ""
    m = FINDING_RE.search(body)
    if m:
        return f'[{m.group("severity").lower()}] {m.group("area").strip()} — {m.group("finding").strip()}'[:160]
    for line in body.splitlines():
        item = table_finding(line)
        if item:
            return f'[{item["severity"]}] {item["area"]} — {item["finding"]}'[:160]
        m = SUMMARY_RE.search(line)
        if m:
            return f'[{m.group("severity").lower()}] {m.group("area").strip()} — {m.group("finding").strip()}'[:160]
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

def same_finding(cand, previous, require_path):
    cs, ps = cand.get("sig", ""), previous.get("sig", "")
    if not cs or not ps:
        return False
    cpath, ppath = cand.get("path") or "", previous.get("path") or ""
    if require_path:
        if not cpath or not ppath or cpath != ppath:
            return False
    elif cpath and ppath and cpath != ppath:
        return False
    if cs == ps:
        return True
    if len(cs) > 35 and len(ps) > 35 and (cs in ps or ps in cs):
        return True
    return difflib.SequenceMatcher(None, cs, ps).ratio() >= 0.9

threads, reviews, issue_comments = fetch_history()
history = []
for t in threads:
    comments = (t.get("comments") or {}).get("nodes") or []
    if not comments:
        continue
    # Root comment only: it carries the finding; replies are discussion and
    # would inflate the false-positive surface of fuzzy matching.
    body = comments[0].get("body") or ""
    sig = signature(body)
    if sig:
        history.append({"path": t.get("path") or "", "line": t.get("line"),
                        "sig": sig, "summary": summary(body),
                        "source": comments[0].get("url") or "review-thread",
                        "status": "resolved" if t.get("isResolved") else "open",
                        "severity": severity_from_body(body),
                        "outdated": bool(t.get("isOutdated"))})

def report_findings(node):
    body = node.get("body") or ""
    if (node.get("state") or "").upper() == "PENDING":
        return []
    if "review-anvil-marker:" not in body and "review-anvil report" not in body:
        return []
    found = []
    section_status = None
    in_fence = False
    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if line.startswith("## "):
            heading = line[3:].strip().lower()
            if heading.startswith(("findings", "diagnoses", "what i noticed", "suggestions", "things to try", "non-blocking")):
                section_status = "reported"
            elif heading.startswith(("deferred / out-of-scope", "set aside / outside this change")):
                section_status = "deferred"
            else:
                section_status = None
            continue
        if not section_status:
            continue
        match = FINDING_RE.search(line)
        item = table_finding(line)
        if match:
            location = match.group("location") or ""
            finding_body = line
        elif item:
            location = item.get("location") or ""
            finding_body = line
        else:
            continue
        sig = signature(finding_body)
        if sig:
            loc_match = re.match(r"([^:\s]+)(?::(\d+)(?:-(\d+))?)?$", location.strip().strip("`"))
            parsed_line = None
            if loc_match and loc_match.group(2):
                parsed_line = loc_match.group(2)
                if loc_match.group(3):
                    parsed_line += f'-{loc_match.group(3)}'
            status = "review-dismissed" if (node.get("state") or "").upper() == "DISMISSED" else section_status
            found.append({"path": path_from_location(location), "line": parsed_line,
                          "sig": sig, "summary": summary(finding_body),
                          "source": node.get("url") or "prior-review-anvil-report",
                          "status": status,
                          "severity": severity_from_body(finding_body),
                          "outdated": False})
    return found

# Summary-only and unanchored findings do not create GitHub review threads.
# Preserve them from earlier review-anvil review bodies and fallback comments,
# but deduplicate findings already represented by a thread root.
for node in reviews + issue_comments:
    for candidate in report_findings(node):
        if not any(same_finding(candidate, previous, require_path=False)
                   for previous in history):
            history.append(candidate)

sp = state_file()
if sp and sp.exists():
    try:
        state = json.loads(sp.read_text())
        for item in state.get(f"{owner}/{repo}#{n}", []):
            sig = signature(item.get("pattern", ""))
            if sig:
                suppression = {"path": item.get("path", ""), "line": item.get("line"),
                               "sig": sig, "summary": summary(item.get("pattern", "")),
                               "source": item.get("reason", "local-suppression"),
                               "status": "suppressed",
                               "severity": severity_from_body(item.get("pattern", "")),
                               "outdated": False}
                history = [previous for previous in history
                           if not same_finding(suppression, previous, require_path=False)]
                history.append(suppression)
    except Exception as exc:
        raise SystemExit(f"pr-helper: invalid dismissal state {sp}: {exc}")

if mode in {"history", "list"}:
    selected = history if mode == "history" else [
        item for item in history if item["status"] in {"resolved", "suppressed"}
    ]
    if not selected:
        print("None.")
    else:
        for d in selected:
            if d["path"]:
                loc = f'{d["path"]}:{d["line"]}' if d.get("line") else d["path"]
            else:
                loc = "(no file anchor)"
            flags = d["status"] + (",outdated" if d.get("outdated") else "")
            print(f'- [{flags}] {loc} — {d["summary"]} ({d["source"]})')
    raise SystemExit(0)

if mode != "suppress":
    raise SystemExit(f"pr-helper: unknown dismissed-findings mode: {mode}")

report = Path(sys.argv[5])
inline = Path(sys.argv[6])
if not history:
    raise SystemExit(0)

def display_status(item):
    status = {
        "open": "This is still present.",
        "resolved": "This is still present after the thread was closed.",
        "reported": "This was mentioned earlier and is still present.",
        "deferred": "This was set aside earlier and is still present.",
        "review-dismissed": "This was dismissed earlier and is still present.",
    }.get(item["status"], "This was mentioned earlier.")
    if item.get("outdated"):
        status += " The code line has moved."
    return status

suppressed = []
matched_history = []
categorically_removed = 0
explicit_suppressions = []
if inline.exists() and inline.read_text().strip() not in {"", "[]"}:
    items = json.loads(inline.read_text())
    if not isinstance(items, list):
        raise SystemExit(f"pr-helper: {inline} is not a JSON array of comment objects")
    kept = []
    for item in items:
        if not isinstance(item, dict):
            kept.append(item)  # let posting fail loudly on malformed members
            continue
        cand = {"path": item.get("path") or "", "sig": signature(item.get("body") or ""),
                "severity": severity_name(item.get("severity")) or severity_from_body(item.get("body") or "")}
        hit = next((d for d in history if same_finding(cand, d, require_path=True)), None)
        if hit:
            matched_history.append((hit, cand.get("severity")))
            if hit["status"] == "suppressed":
                categorically_removed += 1
                explicit_suppressions.append({"path": cand["path"],
                                              "summary": summary(item.get("body") or ""),
                                              "source": hit["source"], "sig": cand["sig"]})
            else:
                suppressed.append({**cand, "summary": summary(item.get("body") or ""),
                                   "source": hit["source"], "status": display_status(hit)})
        else:
            kept.append(item)
    if len(kept) != len(items):
        inline.write_text(json.dumps(kept, indent=2) + "\n")

# Move matching findings in the report body to a prior-feedback status section.
# This avoids creating duplicate inline threads while keeping open or resolved-
# but-still-present findings visible to the author. The walk is fence-aware ("**[" inside a
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
            if ln.startswith("## ") or ln.startswith("### ") or is_finding_line(ln):
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
        if not in_fence and is_finding_line(line):
            j2 = block_end(i)
            block = lines[i:j2]
            cand = {"path": path_from_block(block), "sig": signature("\n".join(block))}
            hit = next((d for d in history if same_finding(cand, d, require_path=False)), None)
            if hit:
                matched_history.append((hit, severity_from_body("\n".join(block))))
                if hit["status"] == "suppressed":
                    categorically_removed += 1
                    explicit_suppressions.append({"path": cand["path"],
                                                  "summary": summary("\n".join(block)),
                                                  "source": hit["source"], "sig": cand["sig"]})
                else:
                    demoted.append({"line": block[0].strip(), "sig": cand["sig"],
                                    "source": hit["source"], "status": display_status(hit)})
                i = j2
                continue
        out.append(line)
        i += 1
    if demoted or suppressed or explicit_suppressions:
        demoted_sigs = {d["sig"] for d in demoted}
        tail = ["", "---", "", "### Earlier review comments", ""]
        tail += [f'{d["line"]} _({d["status"]} Source: {d["source"]})_' for d in demoted]
        tail += [f'- **Earlier inline comment** {s["path"]} — {s["summary"]} _({s["status"]} Source: {s["source"]})_'
                 for s in suppressed if s["sig"] not in demoted_sigs]
        tail += [f'- **Not raised again** {s["path"] or "(no file anchor)"} — {s["summary"]} _(It was intentionally set aside. Source: {s["source"]})_'
                 for s in {item["sig"]: item for item in explicit_suppressions}.values()]
        report.write_text("\n".join(out).rstrip() + "\n" + "\n".join(tail) + "\n")

# A material item discovered during the post-time refresh must not race with a
# previously selected APPROVE event. The final report must account for its URL
# or local reason on a line that explicitly says fixed/stale; absent or
# still-present assessments block. This lets a validated fix approve even when
# the author has not yet clicked Resolve in GitHub.
report_text = report.read_text() if report.exists() else ""
def material_item_blocks(item):
    if item.get("severity") not in {"critical", "high"} or item["status"] == "suppressed":
        return False
    source = item.get("source") or ""
    assessment = next((line.lower() for line in report_text.splitlines()
                       if source and source in line), "")
    return not assessment or not any(clear in assessment for clear in ("fixed", "stale/outdated", "stale"))

blocking_prior = any(material_item_blocks(item) for item in history)
blocking_match = any(severity in {"critical", "high"}
                     and item["status"] != "suppressed"
                     for item, severity in matched_history)
approval = Path(str(report) + ".approval.json")
if (blocking_prior or blocking_match) and approval.exists():
    try:
        decision = json.loads(approval.read_text())
        if decision.get("event") == "APPROVE":
            decision["event"] = "COMMENT"
            decision["approval_allowed"] = False
            decision["reason"] = "Prior critical/high PR feedback remains open or was matched as still present during the post-time history refresh."
            approval.write_text(json.dumps(decision, indent=2) + "\n")
            print("pr-helper: downgraded APPROVE to COMMENT because material prior feedback remains", file=sys.stderr)
    except Exception as exc:
        raise SystemExit(f"pr-helper: invalid approval artifact {approval}: {exc}")

if suppressed or demoted or categorically_removed:
    print(f"pr-helper: suppressed {len(suppressed)} duplicate inline / classified {len(demoted)} prior report finding(s) / removed {categorically_removed} explicit suppression match(es)", file=sys.stderr)
PY
}

# Refresh prior feedback, suppress duplicate inline threads, and classify
# matching report findings. cmd_post fails closed; cmd_post_update converts a
# refresh failure into an explicit failure outcome so its starting comment is
# still updated without publishing an unfiltered success report.
suppress_prior_feedback() {
    local host="$1" owner="$2" repo="$3" n="$4" report_path="$5" inline_json="$6"
    if [[ "${REVIEW_ANVIL_SKIP_DISMISSED:-}" == "1" ]]; then
        # Escape hatch for hosts where the GraphQL reviewThreads API is
        # unavailable (GHE without GraphQL, restricted token scopes).
        # Degraded mode: prior feedback may be missed or repeated; cmd_post
        # also forces APPROVE -> COMMENT when this is set.
        printf 'warning: REVIEW_ANVIL_SKIP_DISMISSED=1 — skipping full PR-feedback history handling (degraded mode)\n' >&2
        return 0
    fi
    export GH_HOST="$host"
    _review_history_py suppress "$owner" "$repo" "$n" "$report_path" "$inline_json"
}

cmd_dismissed() {
    # Legacy resolved/suppressed-only view retained for older callers.
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}"
    for v in host owner repo n; do
        [[ -n "${!v}" ]] || die "dismissed: missing <$v>"
    done
    if [[ "${REVIEW_ANVIL_SKIP_DISMISSED:-}" == "1" ]]; then
        printf 'None. (dismissed-finding lookup skipped: REVIEW_ANVIL_SKIP_DISMISSED=1 — degraded mode)\n'
        return 0
    fi
    export GH_HOST="$host"
    _review_history_py list "$owner" "$repo" "$n"
}

cmd_history() {
    # Print the complete status-aware PR feedback ledger for reviewer prompts.
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}"
    for v in host owner repo n; do
        [[ -n "${!v}" ]] || die "history: missing <$v>"
    done
    if [[ "${REVIEW_ANVIL_SKIP_DISMISSED:-}" == "1" ]]; then
        printf 'None. (PR review history lookup skipped: REVIEW_ANVIL_SKIP_DISMISSED=1 — degraded mode)\n'
        return 0
    fi
    export GH_HOST="$host"
    _review_history_py history "$owner" "$repo" "$n"
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
        || die "neither uv nor python3 found — required for PR-feedback history handling (install uv: https://docs.astral.sh/uv/)"
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
    # LLM-enforced prose; these make it (and skipped PR-history lookups, which
    # invalidate the approval criteria) binding regardless of what the
    # orchestrator wrote into approval.json.
    if [[ "$review_event" == "APPROVE" && "${REVIEW_ANVIL_NO_APPROVE:-}" == "1" ]]; then
        printf 'warning: REVIEW_ANVIL_NO_APPROVE=1 — downgrading APPROVE to COMMENT\n' >&2
        review_event="COMMENT"
    fi
    if [[ "$review_event" == "APPROVE" && "${REVIEW_ANVIL_SKIP_DISMISSED:-}" == "1" ]]; then
        printf 'warning: PR-feedback history lookup was skipped, so the approval criteria cannot hold — downgrading APPROVE to COMMENT\n' >&2
        review_event="COMMENT"
    fi
    if [[ "$review_event" == "APPROVE" && -f "$approval_json" ]]; then
        local approval_allowed adversarial_mode
        approval_allowed=$(jq -r 'if has("approval_allowed") then .approval_allowed else "" end' "$approval_json" 2>/dev/null || true)
        adversarial_mode=$(jq -r '.adversarial_mode // empty' "$approval_json" 2>/dev/null || true)
        if [[ "$approval_allowed" == "false" || "$adversarial_mode" == "off" ]]; then
            printf 'warning: approval.json marks adversarial approval unsafe — downgrading APPROVE to COMMENT\n' >&2
            review_event="COMMENT"
        fi
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

    suppress_prior_feedback "$host" "$owner" "$repo" "$n" "$report_path" "$inline_json" \
        || die "prior-feedback refresh failed; refusing to post a review that may ignore or repeat earlier findings (report left at $report_path)"
    if [[ "$review_event" == "APPROVE" && -f "$approval_json" ]] \
       && [[ "$(jq -r '.event // "COMMENT"' "$approval_json" 2>/dev/null || printf 'COMMENT')" != "APPROVE" ]]; then
        printf 'warning: post-time prior-feedback refresh invalidated approval — downgrading to COMMENT\n' >&2
        review_event="COMMENT"
    fi

    process_inline_comments_for_github "$inline_json"
    compact_report_for_github "$report_path" "$inline_json"

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
        compact_report_for_github "$report_path" "$inline_json"
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

    # Refresh prior-feedback state on the success path. If that fails, update
    # the starting comment as a failure instead of publishing an unfiltered
    # success report that may ignore or duplicate earlier feedback.
    if [[ "$outcome" == "success" ]]; then
        if ! suppress_prior_feedback "$host" "$owner" "$repo" "$n" "$report_path" "${report_path}.inline.json"; then
            outcome="failure"
            {
                printf '\n\n## Failure\n\n'
                printf 'Could not refresh prior PR review history before posting; refusing to publish a success report that may ignore earlier feedback.\n'
            } >>"$report_path"
            printf 'pr-helper: warning: prior-feedback refresh failed; updating comment with outcome=failure\n' >&2
        fi
    fi

    process_inline_comments_for_github "${report_path}.inline.json"
    compact_report_for_github "$report_path" "${report_path}.inline.json"

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
    history)          shift; cmd_history "$@" ;;
    dismissed)        shift; cmd_dismissed "$@" ;;
    dismiss)          shift; cmd_dismiss "$@" ;;
    compact-report)   shift; compact_report_for_github "$@" ;;
    process-inline)   shift; process_inline_comments_for_github "$@" ;;
    check-pins)       shift; cmd_check_pins "$@" ;;
    "")               die "usage: pr-helper.sh {init [<locator>] | post <host> <owner> <repo> <n> <marker> <report_path> | verify-checkout [<locator>] | post-start <host> <owner> <repo> <n> <marker> <author> | post-update <host> <owner> <repo> <n> <comment_id> <marker> <report_path> <author> <success|failure> [<started_at>] | history <host> <owner> <repo> <n> | dismissed <host> <owner> <repo> <n> | dismiss <host> <owner> <repo> <n> <path> <pattern> [<reason>] | compact-report <report_path> [<inline_json>] | process-inline <inline_json> | check-pins <preset> <pins-csv> [<raw-args>]}" ;;
    *)                die "unknown subcommand: $1" ;;
esac
