#!/usr/bin/env bash
# pr-helper.sh — GitHub PR locator parsing, preflight, and report posting
# for the review-anvil-pr skill. Co-located with the skill so it travels
# across agents via `npx skills add mrshu/agent-skills --skill review-anvil-pr`.
# Helper-authored PR comments follow the ASD-STE100-inspired language contract
# in ../review-anvil/references/asd-ste100-inspired.md.
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


report_is_infra_failure() {
    local report_path="$1"
    # Do not publish transparent infrastructure-failure reports. They are local
    # diagnostics, not PR feedback. The watchdog should mark the run failed and
    # retry with a healthy reviewer wave instead of notifying the author.
    grep -Eqi 'reviewer wave failed|reviewer wave produced no usable|reviewer wave did not (return|produce)|all three (Codex )?reviewers (returned empty|timed out|reached|failed)|all requested reviewers failed|every reviewer process ended without|without a completed findings block|could not produce a code assessment|no valid reviewer output to synthesize|no candidate findings were available|no completed reviewer findings were available|no reviewer produced usable evidence|no usable code review|no code-review result is available|no code-quality decision was made|review did not (complete|produce a reliable result|finish)|review could not (finish|produce a reliable result)|reviewer execution failed|STATUS=empty|returned no final (response|output|review)|no final findings block' "$report_path"
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
reintroduced_marker = "<!-- review-anvil: prior_feedback=reintroduced -->"
positive_padded_ordinal = r"(?:00[1-9]|0[1-9][0-9]|[1-9][0-9]{2,})"
finding_id_pattern = (
    rf"(?:RAV-(?:RUN[1-9][0-9]*-)?R[1-9][0-9]*-F{positive_padded_ordinal}"
    r"|RAVF[0-9]{3,}|F-[0-9]{3,})"
)
finding_metadata_re = re.compile(
    rf"<!--\s*review-anvil:\s*id=(?P<id>{finding_id_pattern})\s+"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s*-->",
    re.I,
)

def terminal_finding_metadata(body):
    text = (body or "").rstrip()
    if not text:
        return None
    match = finding_metadata_re.fullmatch(text.splitlines()[-1])
    if match and "--" not in match.group("area"):
        return match
    return None

def append_before_finding_metadata(body, addition):
    text = (body or "").rstrip()
    metadata = terminal_finding_metadata(text)
    marker = metadata.group(0) if metadata else None
    if marker:
        text = text[:text.rfind(marker)].rstrip()
    parts = [part for part in (text, str(addition).strip("\n")) if part]
    rendered = "\n\n".join(parts)
    if marker:
        rendered = "\n\n".join(part for part in (rendered, marker) if part)
    return rendered

def infer_severity(item):
    severity_present = "severity" in item
    raw_explicit = item.get("severity")
    explicit = str(raw_explicit).lower()
    body = item.get("body") or ""
    metadata = terminal_finding_metadata(body)
    marker_severity = metadata.group("severity").lower() if metadata else None
    if marker_severity:
        if not severity_present:
            return marker_severity
        if explicit not in rank:
            raise SystemExit(
                f"pr-helper: inline finding {metadata.group('id')} helper severity "
                f"is invalid: {raw_explicit!r}"
            )
        if explicit != marker_severity:
            raise SystemExit(
                f"pr-helper: inline finding {metadata.group('id')} helper severity "
                f"{explicit} does not match terminal marker severity {marker_severity}"
            )
        return explicit
    if explicit in rank:
        return explicit
    m = re.search(rf"\*\*(?:{finding_id_pattern}\s+)?\[(critical|high|medium|low|nit)\]", body, re.I)
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
    block = "```suggestion\n" + suggestion + "\n```"
    return append_before_finding_metadata(body, block)

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
    if item.get("prior_feedback") == "reintroduced" and reintroduced_marker not in body:
        body = append_before_finding_metadata(body, reintroduced_marker)
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
append_inline_details_to_report() {
    local report_path="${1:-}" inline_json="${2:-}"
    [[ -f "$report_path" && -f "$inline_json" ]] || return 0

    _py - "$report_path" "$inline_json" <<'PY'
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
inline_path = Path(sys.argv[2])
section_marker = "<!-- review-anvil: appended-inline-details -->"
report = report_path.read_text()
if section_marker in report:
    raise SystemExit(0)

raw = inline_path.read_text().strip()
if not raw or raw == "[]":
    raise SystemExit(0)
items = json.loads(raw)
if not isinstance(items, list):
    raise SystemExit(f"pr-helper: {inline_path} is not a JSON array")
items = [item for item in items if isinstance(item, dict) and item.get("body")]
if not items:
    raise SystemExit(0)

parts = [
    "",
    "<details>",
    "<summary>Finding details</summary>",
    "",
]
for index, item in enumerate(items, 1):
    path = item.get("path")
    start_line = item.get("start_line")
    line = item.get("line")
    if path and start_line and line and start_line != line:
        location = f"{path}:{start_line}-{line}"
    elif path and line:
        location = f"{path}:{line}"
    elif path:
        location = str(path)
    else:
        location = f"Finding {index}"
    parts.extend((f"### `{location}`", "", str(item["body"]).strip(), ""))
parts.extend(("</details>", section_marker, ""))
section = "\n".join(parts).strip()
footer = (
    "_Reviewed with [review-anvil]"
    "(https://github.com/mrshu/agent-skills/#review-anvil)._"
)
rendered = report.rstrip()
if rendered.endswith(footer):
    rendered = (
        rendered[: -len(footer)].rstrip()
        + "\n\n"
        + section
        + "\n\n"
        + footer
    )
else:
    rendered = rendered + "\n\n" + section
report_path.write_text(rendered + "\n")
PY
}
append_review_context_note() {
    local report_path="${1:-}" note="${2:-}"
    [[ -f "$report_path" && -n "$note" ]] || return 0

    _py - "$report_path" "$note" <<'PY'
import re
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
note = sys.argv[2]
report = report_path.read_text()
if note in report:
    raise SystemExit(0)

pattern = re.compile(
    r"(<details>\n<summary>Review context</summary>\n\n)"
    r"([\s\S]*?)(\n\n?</details>)"
)
match = pattern.search(report)
if match:
    body = match.group(2).rstrip()
    footer = "_Reviewed with [review-anvil]"
    footer_at = body.find(footer)
    if footer_at >= 0:
        before = body[:footer_at].rstrip()
        after = body[footer_at:]
        body = "\n\n".join(part for part in (before, note, after) if part)
    else:
        body = "\n\n".join(part for part in (body, note) if part)
    report = report[:match.start()] + match.group(1) + body + match.group(3) + report[match.end():]
else:
    section = (
        "<details>\n<summary>Review context</summary>\n\n"
        + note
        + "\n\n</details>"
    )
    footer = (
        "_Reviewed with [review-anvil]"
        "(https://github.com/mrshu/agent-skills/#review-anvil)._"
    )
    rendered = report.rstrip()
    if rendered.endswith(footer):
        report = (
            rendered[: -len(footer)].rstrip()
            + "\n\n"
            + section
            + "\n\n"
            + footer
            + "\n"
        )
    else:
        report = rendered + "\n\n" + section + "\n"
report_path.write_text(report)
PY
}


# Shared PR-feedback-history engine. Modes:
#   history <owner> <repo> <n>
#       Print every prior root review thread with its open/resolved/outdated
#       state, plus summary-only findings from earlier review-anvil reports and
#       explicit local suppressions. This builds the PR REVIEW HISTORY prompt.
#   list <owner> <repo> <n>
#       Backwards-compatible resolved/suppressed-only view.
#   next-run <owner> <repo> <n>
#       Print the next positive run ordinal derived from distinct finalized
#       review-anvil reports.
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
from urllib.parse import unquote

mode, owner, repo, n = sys.argv[1:5]

QUERY = r'''
query($owner:String!,$repo:String!,$number:Int!,$threadCursor:String,$reviewCursor:String,$commentCursor:String){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      author{ login }
      reviewThreads(first:100, after:$threadCursor){
        pageInfo{ hasNextPage endCursor }
        nodes{
          isResolved
          isOutdated
          resolvedBy{ login }
          path
          line
          startLine
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
            pr_author = ((pr.get("author") or {}).get("login") or "")
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
            return pr_author, threads, reviews, comments

def norm(text: str) -> str:
    text = re.sub(r"https?://\S+", " ", text or "")
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", " ", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"[^a-zA-Z0-9]+", " ", text).lower()
    words = [w for w in text.split() if len(w) > 2 and w not in {"the", "and", "for", "with", "this", "that", "from", "into", "when", "because"}]
    return " ".join(words)

POSITIVE_PADDED_ORDINAL = r"(?:00[1-9]|0[1-9][0-9]|[1-9][0-9]{2,})"
PROVENANCE_FINDING_ID = (
    rf"RAV-(?:RUN[1-9][0-9]*-)?R[1-9][0-9]*-F{POSITIVE_PADDED_ORDINAL}"
)
LEGACY_FINDING_ID = r"(?:RAVF[0-9]{3,}|F-[0-9]{3,})"
FINDING_ID_PATTERN = rf"(?:{PROVENANCE_FINDING_ID}|{LEGACY_FINDING_ID})"
SEVERITY_NAMES = {"critical", "high", "medium", "low", "nit"}
SEVERITY_INITIALS = {"c": "critical", "h": "high", "m": "medium", "l": "low", "n": "nit"}
REINTRODUCED_MARKER = "<!-- review-anvil: prior_feedback=reintroduced -->"

FINDING_RE = re.compile(
    rf"\*\*(?:(?P<finding_id>{FINDING_ID_PATTERN})\s+)?\[(?P<severity>critical|high|medium|low|nit)\]\s*(?P<area>[^*]+?)\*\*(?:\s+`(?P<location>[^`]+)`)?\s*[-—:]+\s*(?P<finding>[^\n]+)",
    re.I,
)
SUMMARY_RE = re.compile(
    rf"^\s*(?:[-*]\s+)?(?:(?P<finding_id>{FINDING_ID_PATTERN})\s+)?\[(?P<severity>critical|high|medium|low|nit)\]\s*(?P<area>.+?)\s*[-—:]+\s*(?P<finding>.+)$",
    re.I,
)
FINDING_METADATA_RE = re.compile(
    rf"<!--\s*review-anvil:\s*id=(?P<id>{FINDING_ID_PATTERN})\s+"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s*-->",
    re.I,
)
NATURAL_INLINE_TITLE_RE = re.compile(
    r"^\*\*(?P<title>.+)\*\*$"
)
CLARITY_REPORT_RE = re.compile(
    rf"^\s*[-*]\s+\*\*(?P<title>.+?)\*\*"
    r"(?:\s+`(?P<location>[^`]+)`)?\s*[-—:]+\s*"
    rf"(?P<detail>.+?)\s+\(`(?P<finding_id>{FINDING_ID_PATTERN})`\)\s+"
    r"<!--\s*review-anvil-report:\s*"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s*-->\s*$",
    re.I,
)
HUMAN_REPORT_RE = re.compile(
    rf"^\s*[-*]\s+(?P<text>.+?)\s+<!--\s*review-anvil-report:\s*"
    rf"id=(?P<finding_id>{FINDING_ID_PATTERN}|-)\s+"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s+"
    r"path=(?P<path>\S+)\s+start_line=(?P<start_line>\d+|-)\s+"
    r"line=(?P<line>\d+|-)\s+"
    r"disposition=(?P<disposition>active|deferred|outside)\s*-->\s*$",
    re.I,
)
HUMAN_REPORT_TABLE_RE = re.compile(
    r"^\|\s*(?P<visible_severity>Critical|High|Medium|Low|Nit)\s*\|\s*"
    r"(?P<location>(?:\\\||[^|\n])+?)\s*\|\s*"
    r"(?P<issue>(?:\\\||[^|\n])+?)\s*\|\s*"
    r"(?P<action>(?:\\\||[^|\n])+?)\s+"
    rf"<!--\s*review-anvil-report:\s*id=(?P<finding_id>{FINDING_ID_PATTERN})\s+"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s+"
    r"path=(?P<path>\S+)\s+start_line=(?P<start_line>\d+|-)\s+"
    r"line=(?P<line>\d+|-)\s+disposition=(?P<disposition>active)\s*-->"
    r"\s*\|\s*$",
    re.I,
)
EARLIER_FEEDBACK_RE = re.compile(
    rf"^\s*[-*]\s+\*\*(?P<status>open|still-present|fixed|stale|reported|author-resolved)\*\*"
    rf"\s*[-—:]+\s*(?P<text>.+?)(?:\s+\(`(?P<finding_id>{FINDING_ID_PATTERN})`\))?\s*$",
    re.I,
)
IDENTITY_METADATA_RE = re.compile(
    rf"(?:^|;\s*)(?:id|legacy)=(?P<ids>{FINDING_ID_PATTERN}(?:,{FINDING_ID_PATTERN})*)"
    r"(?=\s*(?:;|$))",
    re.I,
)
HELPER_STATUS_SUFFIX_RE = re.compile(
    r"\s+_\((?P<annotation>(?:This is still present|This was mentioned earlier|"
    r"This was set aside earlier|This was dismissed earlier)[^\n]*\bSource:\s*[^\n]*)\)_\s*$",
    re.I,
)
LEDGER_IDENTITY_SUFFIX_RE = re.compile(
    r"\(source=(?P<annotation>[^\n]*)\)\s*$",
    re.I,
)
def iter_unfenced_lines(body):
    in_fence = False
    for index, line in enumerate((body or "").splitlines()):
        stripped = line.lstrip()
        if stripped.startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if not in_fence:
            yield index, line

def terminal_finding_metadata(body):
    lines = (body or "").rstrip().splitlines()
    if not lines:
        return None
    last_index = len(lines) - 1
    if not any(index == last_index for index, _ in iter_unfenced_lines("\n".join(lines))):
        return None
    match = FINDING_METADATA_RE.fullmatch(lines[-1])
    if match and "--" not in match.group("area"):
        return match
    return None

def natural_inline_title(body):
    for _, line in iter_unfenced_lines(body):
        match = NATURAL_INLINE_TITLE_RE.fullmatch(line.strip())
        if match:
            return match.group("title").strip()
    return None


def severity_name(value):
    value = (value or "").strip().lower()
    if value in SEVERITY_NAMES:
        return value
    return SEVERITY_INITIALS.get(value)

def severity_from_body(body):
    metadata = terminal_finding_metadata(body)
    if metadata:
        return severity_name(metadata.group("severity"))
    match = FINDING_RE.search(body or "")
    if match:
        return severity_name(match.group("severity"))
    for line in (body or "").splitlines():
        item = table_finding(line)
        if item:
            return item["severity"]
        item = clarity_report_finding(line)
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
    if len(cells) < 5 or not re.fullmatch(FINDING_ID_PATTERN, cells[0], re.I):
        return None
    sev = severity_name(cells[1])
    if not sev:
        return None
    finding = " | ".join(cells[4:]).strip()
    if not cells[2] or not finding:
        return None
    return {"id": cells[0], "severity": sev, "area": cells[2],
            "location": cells[3], "finding": finding}
def unescape_table_cell(value):
    return (value or "").replace(r"\|", "|").strip()



def clarity_report_finding(line):
    match = CLARITY_REPORT_RE.fullmatch(line or "")
    if match and "--" not in match.group("area"):
        return {
            "id": match.group("finding_id"),
            "severity": severity_name(match.group("severity")),
            "area": match.group("area"),
            "location": match.group("location") or "",
            "finding": match.group("title").strip(),
            "detail": match.group("detail").strip(),
            "disposition": "active",
        }
    match = HUMAN_REPORT_TABLE_RE.fullmatch(line or "")
    if match and "--" not in match.group("area"):
        path = "" if match.group("path") == "-" else unquote(match.group("path"))
        line_number = match.group("line")
        start_line = match.group("start_line")
        location = ""
        if path and line_number != "-":
            location = (
                f"{path}:{start_line}-{line_number}"
                if start_line != "-"
                else f"{path}:{line_number}"
            )
        return {
            "id": match.group("finding_id"),
            "severity": severity_name(match.group("severity")),
            "area": match.group("area"),
            "location": location,
            "finding": unescape_table_cell(match.group("issue")),
            "detail": unescape_table_cell(match.group("action")),
            "disposition": "active",
        }
    match = HUMAN_REPORT_RE.fullmatch(line or "")
    if not match or "--" in match.group("area"):
        return None
    path = "" if match.group("path") == "-" else unquote(match.group("path"))
    line_number = match.group("line")
    start_line = match.group("start_line")
    location = ""
    if path and line_number != "-":
        location = (
            f"{path}:{start_line}-{line_number}"
            if start_line != "-"
            else f"{path}:{line_number}"
        )
    return {
        "id": None if match.group("finding_id") == "-" else match.group("finding_id"),
        "severity": severity_name(match.group("severity")),
        "area": match.group("area"),
        "location": location,
        "finding": match.group("text").strip(),
        "detail": "",
        "disposition": match.group("disposition").lower(),
    }

def earlier_feedback_finding(line):
    match = EARLIER_FEEDBACK_RE.fullmatch(line or "")
    if not match:
        return None
    text = match.group("text").strip()
    url_match = re.search(r"\s+(https?://\S+)$", text)
    source_url = url_match.group(1) if url_match else None
    if url_match:
        text = text[:url_match.start()].rstrip()
    return {
        "id": match.group("finding_id"),
        "status": match.group("status").lower(),
        "finding": text,
        "url": source_url,
    }

def finding_id_from_body(body):
    metadata = terminal_finding_metadata(body)
    if metadata:
        return metadata.group("id")
    for _, line in iter_unfenced_lines(body):
        match = FINDING_RE.search(line)
        if match and match.group("finding_id"):
            return match.group("finding_id")
        item = table_finding(line)
        if item:
            return item["id"]
        item = clarity_report_finding(line)
        if item:
            return item["id"]
        match = SUMMARY_RE.search(line)
        if match and match.group("finding_id"):
            return match.group("finding_id")
    return None

def identity_metadata(finding_id):
    modern_id = None
    legacy_ids = []
    if finding_id and re.fullmatch(PROVENANCE_FINDING_ID, finding_id, re.I):
        modern_id = finding_id
    elif finding_id and re.fullmatch(LEGACY_FINDING_ID, finding_id, re.I):
        legacy_ids.append(finding_id)
    return {"finding_id": modern_id, "legacy_ids": legacy_ids}

def merge_identity(target, *items):
    finding_id = next(
        (item.get("finding_id") for item in items if item.get("finding_id")),
        None,
    )
    legacy_ids = []
    seen = set()
    for item in items:
        for legacy_id in item.get("legacy_ids") or []:
            key = legacy_id.casefold()
            if key not in seen:
                seen.add(key)
                legacy_ids.append(legacy_id)
    target["finding_id"] = finding_id
    target["legacy_ids"] = legacy_ids

def generated_identity_annotation(body):
    text = (body or "").rstrip()
    for pattern in (HELPER_STATUS_SUFFIX_RE, LEDGER_IDENTITY_SUFFIX_RE):
        match = pattern.search(text)
        if match:
            return match.group("annotation")
    return ""

def identity_from_body(body):
    identities = []
    annotation = generated_identity_annotation(body)
    for match in IDENTITY_METADATA_RE.finditer(annotation):
        identities.extend(
            identity_metadata(finding_id)
            for finding_id in match.group("ids").split(",")
        )
    identities.append(identity_metadata(finding_id_from_body(body)))
    merged = {}
    merge_identity(merged, *identities)
    return merged

def rendered_identity_fields(item):
    fields = []
    if item.get("finding_id"):
        fields.append(f'id={item["finding_id"]}')
    if item.get("legacy_ids"):
        fields.append(f'legacy={",".join(item["legacy_ids"])}')
    return fields

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
        item = clarity_report_finding(line)
        if item:
            path = path_from_location(item.get("location"))
            if path:
                return path
        item = table_finding(line)
        if item:
            path = path_from_location(item.get("location"))
            if path:
                return path
    return ""

def is_finding_line(line: str) -> bool:
    return bool(FINDING_RE.search(line or "") or table_finding(line)
                or clarity_report_finding(line))

def signature(body: str) -> str:
    body = body or ""
    metadata = terminal_finding_metadata(body)
    title = natural_inline_title(body) if metadata else None
    if metadata and title:
        return norm(f'{metadata.group("area")} {title}')
    # Legacy review-anvil body. Provenance and historical IDs are optional.
    # Report rows may include a code location between the bold label and dash.
    m = FINDING_RE.search(body)
    if m:
        return norm(f'{m.group("area")} {m.group("finding")}')
    for line in body.splitlines():
        item = table_finding(line)
        if item:
            return norm(f'{item["area"]} {item["finding"]}')
        item = clarity_report_finding(line)
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
    metadata = terminal_finding_metadata(body)
    title = natural_inline_title(body) if metadata else None
    if metadata and title:
        return f'[{metadata.group("severity").lower()}] {metadata.group("area")} — {title}'[:160]
    m = FINDING_RE.search(body)
    if m:
        return f'[{m.group("severity").lower()}] {m.group("area").strip()} — {m.group("finding").strip()}'[:160]
    for line in body.splitlines():
        item = table_finding(line)
        if item:
            return f'[{item["severity"]}] {item["area"]} — {item["finding"]}'[:160]
        item = clarity_report_finding(line)
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
    cpath, ppath = cand.get("path") or "", previous.get("path") or ""
    if require_path:
        if not cpath or not ppath or cpath != ppath:
            return False
    elif cpath and ppath and cpath != ppath:
        return False
    current_id = (cand.get("finding_id") or "").casefold()
    previous_id = (previous.get("finding_id") or "").casefold()
    if current_id and previous_id:
        return current_id == previous_id
    cs, ps = cand.get("sig", ""), previous.get("sig", "")
    if not cs or not ps:
        return False
    if cs == ps:
        return True
    if len(cs) > 35 and len(ps) > 35 and (cs in ps or ps in cs):
        return True
    return difflib.SequenceMatcher(None, cs, ps).ratio() >= 0.9

pr_author, threads, reviews, issue_comments = fetch_history()

if mode == "next-run":
    legacy_heading = re.compile(
        r"^#\s+(?:(?:⚒️\s+)?review-anvil report|review result)\s*$",
        re.I | re.M,
    )
    human_heading = re.compile(r"^#\s+review\s*$", re.I | re.M)
    marker_pattern = re.compile(
        r"<!--\s*review-anvil-marker:\s*([^\s>]+)\s*-->", re.I
    )
    finalized = set()
    for index, node in enumerate(reviews + issue_comments):
        if (node.get("state") or "").upper() == "PENDING":
            continue
        body = node.get("body") or ""
        marker = marker_pattern.search(body)
        has_human_report_item = any(
            HUMAN_REPORT_RE.fullmatch(line) is not None
            or HUMAN_REPORT_TABLE_RE.fullmatch(line) is not None
            for line in body.splitlines()
        )
        has_review_footer = (
            "_Reviewed with [review-anvil]" in body
        )
        if not legacy_heading.search(body) and not (
            marker
            and (
                human_heading.search(body)
                or has_human_report_item
                or has_review_footer
            )
        ):
            continue
        key = (
            f"marker:{marker.group(1).lower()}"
            if marker
            else f"url:{node.get('url') or index}"
        )
        finalized.add(key)
    print(len(finalized) + 1)
    raise SystemExit(0)
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
        resolver = ((t.get("resolvedBy") or {}).get("login") or "")
        status = (
            "author-resolved"
            if t.get("isResolved") and pr_author and resolver == pr_author
            else "resolved" if t.get("isResolved") else "open"
        )
        thread_start = t.get("startLine")
        thread_end = t.get("line")
        thread_line = (
            f"{thread_start}-{thread_end}"
            if thread_start and thread_end and thread_start != thread_end
            else thread_end
        )
        history.append({"path": t.get("path") or "", "line": thread_line,
                        "sig": sig, "summary": summary(body),
                        "source": comments[0].get("url") or "review-thread",
                        "status": status, "severity": severity_from_body(body),
                        "prior_feedback": "reintroduced" if REINTRODUCED_MARKER in body else None,
                        "outdated": bool(t.get("isOutdated")),
                        **identity_from_body(body)})

def report_findings(node):
    body = node.get("body") or ""
    if (node.get("state") or "").upper() == "PENDING":
        return []
    if "review-anvil-marker:" not in body and "review-anvil report" not in body:
        return []
    found = []
    prior_feedback_section = False
    section_status = None
    in_fence = False
    last_finding = None
    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if stripped == REINTRODUCED_MARKER and last_finding is not None:
            last_finding["prior_feedback"] = "reintroduced"
            last_finding = None
            continue
        last_finding = None
        if stripped.startswith("<summary>") and stripped.endswith("</summary>"):
            summary_heading = re.sub(r"<[^>]+>", "", stripped).strip().lower()
            prior_feedback_section = summary_heading.startswith(
                ("earlier review comments", "earlier feedback")
            )
            if summary_heading.startswith(
                (
                    "non-blocking",
                    "suggestions",
                    "optional suggestions",
                    "issues and fixes",
                    "earlier review comments",
                    "earlier feedback",
                )
            ):
                section_status = "reported"
            elif summary_heading.startswith("set aside"):
                section_status = "deferred"
            elif summary_heading.startswith("outside this change"):
                section_status = "outside"
            else:
                section_status = None
            continue
        if line.startswith("### "):
            heading = line[4:].strip().lower()
            if heading == "earlier review comments":
                section_status = "reported"
                prior_feedback_section = True
            continue
        if line.startswith("## "):
            heading = line[3:].strip().lower()
            prior_feedback_section = False
            if heading.startswith(("findings", "main issues", "needs attention", "diagnoses", "what i noticed", "suggestions", "things to try", "non-blocking")):
                section_status = "reported"
            elif heading.startswith(("deferred / out-of-scope", "set aside / outside this change")):
                section_status = "deferred"
            else:
                section_status = None
            continue
        if not section_status:
            continue
        parse_line = (
            HELPER_STATUS_SUFFIX_RE.sub("", line)
            if prior_feedback_section else line
        )
        if prior_feedback_section:
            earlier_item = earlier_feedback_finding(parse_line)
            if earlier_item:
                identity = identity_metadata(earlier_item["id"])
                found.append(
                    {
                        "path": "",
                        "line": None,
                        "sig": norm(
                            f'{earlier_item["status"]} {earlier_item["finding"]}'
                        ),
                        "summary": (
                            f'[{earlier_item["status"]}] history — '
                            f'{earlier_item["finding"]}'
                        )[:160],
                        "source": (
                            earlier_item["url"]
                            or node.get("url")
                            or "prior-review-anvil-report"
                        ),
                        "status": earlier_item["status"],
                        "severity": None,
                        "prior_feedback": None,
                        "structured_history": True,
                        "outdated": False,
                        **identity,
                    }
                )
                last_finding = found[-1]
                continue
        match = FINDING_RE.search(parse_line)
        item = table_finding(parse_line)
        clarity_item = clarity_report_finding(parse_line)
        if match:
            location = match.group("location") or ""
            finding_body = parse_line
        elif item:
            location = item.get("location") or ""
            finding_body = parse_line
        elif clarity_item:
            location = clarity_item.get("location") or ""
            finding_body = parse_line
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
            if (node.get("state") or "").upper() == "DISMISSED":
                status = "review-dismissed"
            elif clarity_item and clarity_item.get("disposition") in {
                "deferred",
                "outside",
            }:
                status = clarity_item["disposition"]
            else:
                status = section_status
            identity = identity_from_body(line)
            found.append({"path": path_from_location(location), "line": parsed_line,
                          "sig": sig, "summary": summary(finding_body),
                          "source": node.get("url") or "prior-review-anvil-report",
                          "status": status,
                          "severity": severity_from_body(finding_body),
                          "prior_feedback": None,
                          "outdated": False,
                          **identity})
            last_finding = found[-1]
    return found

# Summary-only and unanchored findings do not create GitHub review threads.
# Preserve them from earlier review-anvil review bodies and fallback comments,
# but deduplicate findings already represented by a thread root.
for node in reviews + issue_comments:
    for candidate in report_findings(node):
        previous = next(
            (item for item in history
             if same_finding(candidate, item, require_path=False)),
            None,
        )
        if candidate.get("prior_feedback") == "reintroduced" or previous is None:
            history.append(candidate)
        elif candidate.get("structured_history"):
            previous["status"] = candidate["status"]
            previous["summary"] = candidate["summary"]
            previous["source"] = candidate["source"]
            previous["prior_feedback"] = candidate.get("prior_feedback")
            merge_identity(previous, previous, candidate)
        else:
            merge_identity(previous, previous, candidate)

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
                               "outdated": False,
                               **identity_from_body(item.get("pattern", ""))}
                matches = [
                    previous for previous in history
                    if same_finding(suppression, previous, require_path=False)
                ]
                merge_identity(suppression, *matches, suppression)
                history = [previous for previous in history
                           if not same_finding(suppression, previous, require_path=False)]
                history.append(suppression)
    except Exception as exc:
        raise SystemExit(f"pr-helper: invalid dismissal state {sp}: {exc}")

def history_rank(item):
    if item.get("prior_feedback") == "reintroduced":
        return 3
    return {"suppressed": 2, "author-resolved": 1}.get(item["status"], 0)

def same_history_item(item, current):
    if not same_finding(item, current, require_path=False):
        return False
    if (item.get("prior_feedback") == "reintroduced"
            or current.get("prior_feedback") == "reintroduced"):
        return True
    item_line = item.get("line")
    current_line = current.get("line")
    return not (item_line and current_line and item_line != current_line)

def coalesce_history(items):
    coalesced = []
    for item in items:
        match_index = next(
            (index for index, current in enumerate(coalesced)
             if same_history_item(item, current)),
            None,
        )
        if match_index is None:
            coalesced.append(item)
            continue
        current = coalesced[match_index]
        if history_rank(item) > history_rank(current):
            merge_identity(item, current, item)
            coalesced[match_index] = item
        else:
            merge_identity(current, current, item)
    return coalesced

history = coalesce_history(history)

if mode in {"history", "list"}:
    selected = history if mode == "history" else [
        item for item in history if item["status"] in {"resolved", "author-resolved", "suppressed"}
    ]
    if not selected:
        print("None.")
    else:
        for d in selected:
            if d["path"]:
                loc = f'{d["path"]}:{d["line"]}' if d.get("line") else d["path"]
            else:
                loc = "(no file anchor)"
            flags = d["status"] + (",reintroduced" if d.get("prior_feedback") == "reintroduced" else "") + (",outdated" if d.get("outdated") else "")
            metadata = [f'source={d["source"]}', *rendered_identity_fields(d)]
            print(f'- [{flags}] {loc} — {d["summary"]} ({"; ".join(metadata)})')
    raise SystemExit(0)

if mode != "suppress":
    raise SystemExit(f"pr-helper: unknown dismissed-findings mode: {mode}")

report = Path(sys.argv[5])
inline = Path(sys.argv[6])

def display_status(item):
    status = {
        "open": "This is still present.",
        "resolved": "This is still present after the thread was closed.",
        "reported": "This was mentioned earlier and is still present.",
        "deferred": "This was set aside earlier and is still present.",
        "outside": "This was outside this change and remains outside it.",
        "review-dismissed": "This was dismissed earlier and is still present.",
    }.get(item["status"], "This was mentioned earlier.")
    if item.get("outdated"):
        status += " The code line has moved."
    return status

suppressed = []
matched_history = []
categorically_removed = 0
explicit_suppressions = []

def does_not_reraise(item):
    return item["status"] in {"suppressed", "author-resolved", "outside"}

def location_range_from_block(block):
    for line in block:
        match = FINDING_RE.search(line or "")
        location = match.group("location") if match else None
        if not location:
            item = table_finding(line)
            location = item.get("location") if item else None
        if not location:
            item = clarity_report_finding(line)
            location = item.get("location") if item else None
        line_match = re.search(r":(\d+)(?:-(\d+))?$", (location or "").strip().strip("`"))
        if line_match:
            start_line = line_match.group(1)
            return start_line, line_match.group(2) or start_line
    return None, None

def inline_candidate(item):
    return {
        "path": item.get("path") or "",
        "position": str(item.get("position") or "") or None,
        "start_line": str(item.get("start_line") or item.get("line") or "") or None,
        "line": str(item.get("line") or item.get("start_line") or "") or None,
        "sig": signature(item.get("body") or ""),
        "severity": severity_name(item.get("severity")) or severity_from_body(item.get("body") or ""),
        **identity_from_body(item.get("body") or ""),
    }

inline_items = None
delivery_candidates = []
reintroduced_candidates = []
if inline.exists() and inline.read_text().strip() not in {"", "[]"}:
    inline_items = json.loads(inline.read_text())
    if not isinstance(inline_items, list):
        raise SystemExit(f"pr-helper: {inline} is not a JSON array of comment objects")
    for item in inline_items:
        if isinstance(item, dict):
            candidate = inline_candidate(item)
            delivery_candidates.append(candidate)
            if item.get("prior_feedback") == "reintroduced":
                reintroduced_candidates.append(candidate)

if report.exists():
    report_lines = report.read_text().splitlines()
    in_fence = False
    for index, line in enumerate(report_lines):
        stripped = line.lstrip()
        if stripped.startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if not in_fence and is_finding_line(line):
            start_line, end_line = location_range_from_block([line])
            candidate = {
                "path": path_from_block([line]),
                "start_line": start_line,
                "line": end_line,
                "sig": signature(line),
                "severity": severity_from_body(line),
                **identity_from_body(line),
            }
            delivery_candidates.append(candidate)
            if (index + 1 < len(report_lines)
                    and report_lines[index + 1].strip() == REINTRODUCED_MARKER):
                reintroduced_candidates.append(candidate)

def same_delivery_candidate_without_position(cand, candidate):
    if not same_finding(cand, candidate,
                        require_path=bool(cand.get("path") and candidate.get("path"))):
        return False
    start_line = cand.get("start_line") or cand.get("line")
    end_line = cand.get("line") or start_line
    candidate_start_line = candidate.get("start_line") or candidate.get("line")
    candidate_end_line = candidate.get("line") or candidate_start_line
    return (not start_line or not candidate_start_line
            or (start_line == candidate_start_line and end_line == candidate_end_line))

def same_delivery_candidate(cand, candidate):
    if not same_delivery_candidate_without_position(cand, candidate):
        return False
    position = cand.get("position")
    candidate_position = candidate.get("position")
    return not (position and candidate_position) or position == candidate_position

def explicitly_reintroduced(cand, local_disposition):
    if local_disposition:
        return True
    for candidate in reintroduced_candidates:
        if not same_delivery_candidate(cand, candidate):
            continue
        cand_start_line = cand.get("start_line") or cand.get("line")
        candidate_start_line = candidate.get("start_line") or candidate.get("line")
        if not cand_start_line or not candidate_start_line:
            coordinate_less = cand if not cand_start_line else candidate
            matches = sum(
                same_delivery_candidate_without_position(
                    coordinate_less, delivery_candidate
                )
                for delivery_candidate in delivery_candidates
            )
            if matches != 2:
                continue
        return True
    return False

def matching_history(cand, require_path):
    matches = [
        item for item in history
        if same_finding(cand, item, require_path=require_path)
    ]
    if not matches:
        return None
    start_line = cand.get("start_line") or cand.get("line")
    end_line = cand.get("line") or start_line
    if start_line:
        anchors = []
        if end_line and end_line != start_line:
            anchors.append(f"{start_line}-{end_line}")
        anchors.append(str(end_line or start_line))
        for anchor in anchors:
            exact = next(
                (item for item in matches if str(item.get("line") or "") == anchor),
                None,
            )
            if exact:
                return exact
    return matches[0]

inline_rewrite = None
if inline_items is not None:
    items = inline_items
    kept = []
    inline_reintroduced = False
    for item in items:
        if not isinstance(item, dict):
            kept.append(item)  # let posting fail loudly on malformed members
            continue
        cand = inline_candidate(item)
        reintroduced = explicitly_reintroduced(
            cand, item.get("prior_feedback") == "reintroduced"
        )
        inline_reintroduced |= (
            reintroduced and item.get("prior_feedback") != "reintroduced"
        )
        hit = matching_history(cand, require_path=True)
        if hit:
            bypass_author_resolved = (
                hit["status"] == "author-resolved" and reintroduced
            )
            matched_history.append((hit, cand.get("severity"), bypass_author_resolved))
            if does_not_reraise(hit) and not bypass_author_resolved:
                categorically_removed += 1
                if hit["status"] == "suppressed":
                    explicit_suppressions.append({"path": cand["path"],
                                                  "summary": summary(item.get("body") or ""),
                                                  "source": hit["source"], "sig": cand["sig"]})
            elif does_not_reraise(hit):
                kept.append(
                    {**item, "prior_feedback": "reintroduced"}
                    if reintroduced else item
                )
            else:
                suppressed.append({**cand, "summary": summary(item.get("body") or ""),
                                   "source": hit["source"], "status": display_status(hit)})
        else:
            kept.append(
                {**item, "prior_feedback": "reintroduced"}
                if reintroduced else item
            )
    if len(kept) != len(items) or inline_reintroduced:
        inline_rewrite = json.dumps(kept, indent=2) + "\n"

# Move matching findings in the report body to a prior-feedback status section.
# This avoids creating duplicate inline threads while keeping open or resolved-
# but-still-present findings visible to the author. The walk is fence-aware ("**[" inside a
# code block must not start a finding) and paragraph-aware (a blank line ends
# a block only when what follows is not indented continuation or a fence).
demoted = []
report_reintroduced = False
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
            start_line, end_line = location_range_from_block(block)
            block_body = "\n".join(block)
            cand = {"path": path_from_block(block), "start_line": start_line,
                    "line": end_line, "sig": signature(block_body),
                    **identity_from_body(block_body)}
            reintroduced = explicitly_reintroduced(
                cand,
                len(block) > 1 and block[1].strip() == REINTRODUCED_MARKER,
            )
            marked_block = (
                block if len(block) > 1 and block[1].strip() == REINTRODUCED_MARKER
                else [block[0], REINTRODUCED_MARKER, *block[1:]]
            )
            report_reintroduced |= reintroduced and marked_block != block
            hit = matching_history(cand, require_path=False)
            if hit:
                bypass_author_resolved = (
                    hit["status"] == "author-resolved" and reintroduced
                )
                matched_history.append((hit, severity_from_body("\n".join(block)), bypass_author_resolved))
                if does_not_reraise(hit) and not bypass_author_resolved:
                    categorically_removed += 1
                    if hit["status"] == "suppressed":
                        explicit_suppressions.append({"path": cand["path"],
                                                      "summary": summary("\n".join(block)),
                                                      "source": hit["source"], "sig": cand["sig"]})
                elif does_not_reraise(hit):
                    out.extend(marked_block if reintroduced else block)
                else:
                    identity = {}
                    merge_identity(identity, hit, identity_from_body(block_body))
                    demoted.append({"line": block[0].strip(), "sig": cand["sig"],
                                    "source": hit["source"], "status": display_status(hit),
                                    **identity})
                i = j2
                continue
            if reintroduced:
                out.extend(marked_block)
                i = j2
                continue
        out.append(line)
        i += 1
    compact_envelope = (
        report.exists()
        and "<summary>Review context</summary>" in report.read_text()
    )
    inventory_changed = bool(
        demoted or suppressed or explicit_suppressions or categorically_removed
    )
    if compact_envelope and inventory_changed:
        raise SystemExit(
            "pr-helper: post-time prior-feedback refresh changed the finding "
            "inventory; rerun review-anvil so the visible summary can be "
            "rendered from the refreshed inventory"
        )
    if inline_rewrite is not None:
        inline.write_text(inline_rewrite)
    if demoted or suppressed or explicit_suppressions or categorically_removed or report_reintroduced:
        rewritten = "\n".join(out).rstrip() + "\n"
        if demoted or suppressed or explicit_suppressions:
            demoted_sigs = {d["sig"] for d in demoted}
            feedback_rows = []
            for d in demoted:
                identity_fields = rendered_identity_fields(d)
                identity_suffix = (
                    f'; {"; ".join(identity_fields)}' if identity_fields else ""
                )
                feedback_rows.append(
                    f'{d["line"]} _({d["status"]} Source: {d["source"]}'
                    f'{identity_suffix})_'
                )
            feedback_rows += [
                f'- **Earlier inline comment** {s["path"]} — {s["summary"]} '
                f'_({s["status"]} Source: {s["source"]})_'
                for s in suppressed if s["sig"] not in demoted_sigs
            ]
            feedback_rows += [
                f'- **Not raised again** {s["path"] or "(no file anchor)"} — '
                f'{s["summary"]} _(It was intentionally set aside. '
                f'Source: {s["source"]})_'
                for s in {
                    item["sig"]: item for item in explicit_suppressions
                }.values()
            ]
            feedback = "\n".join(feedback_rows)
            pattern = re.compile(
                r"(<details>\n<summary>Earlier feedback</summary>\n\n)"
                r"([\s\S]*?)(\n\n?</details>)"
            )
            existing = pattern.search(rewritten)
            if existing:
                content = existing.group(2).rstrip()
                content = "\n".join(
                    part for part in (content, feedback) if part
                )
                rewritten = (
                    rewritten[:existing.start()]
                    + existing.group(1)
                    + content
                    + existing.group(3)
                    + rewritten[existing.end():]
                )
            else:
                section = (
                    "<details>\n<summary>Earlier feedback</summary>\n\n"
                    + feedback
                    + "\n\n</details>\n\n"
                )
                context_marker = (
                    "<details>\n<summary>Review context</summary>"
                )
                if context_marker in rewritten:
                    rewritten = rewritten.replace(
                        context_marker,
                        section + context_marker,
                        1,
                    )
                else:
                    rewritten = rewritten.rstrip() + "\n\n" + section
        report.write_text(rewritten)

# A material item discovered during the post-time refresh must not race with a
# previously selected APPROVE event. The final report must account for its URL
# or local reason on a line that explicitly says fixed/stale; absent or
# still-present assessments block. This lets a validated fix approve even when
# the author has not yet clicked Resolve in GitHub.
report_text = report.read_text() if report.exists() else ""
def material_item_blocks(item):
    if item.get("severity") not in {"critical", "high"} or does_not_reraise(item):
        return False
    source = item.get("source") or ""
    assessment = next((line.lower() for line in report_text.splitlines()
                       if source and source in line), "")
    return not assessment or not any(clear in assessment for clear in ("fixed", "stale/outdated", "stale"))

blocking_prior = any(material_item_blocks(item) for item in history)
blocking_match = any(
    severity in {"critical", "high"} and (reintroduced or not does_not_reraise(item))
    for item, severity, reintroduced in matched_history
)
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

cmd_next_run() {
    local host="${1:-}" owner="${2:-}" repo="${3:-}" n="${4:-}"
    for v in host owner repo n; do
        [[ -n "${!v}" ]] || die "next-run: missing <$v>"
    done
    if [[ "${REVIEW_ANVIL_SKIP_DISMISSED:-}" == "1" ]]; then
        printf 'pr-helper: warning: PR run ordinal unavailable; REVIEW_ANVIL_SKIP_DISMISSED=1 enables degraded mode; IDs will omit RUN\n' >&2
        printf 'unavailable\n'
        return 0
    fi
    export GH_HOST="$host"
    local ordinal
    if ordinal=$(_review_history_py next-run "$owner" "$repo" "$n"); then
        printf '%s\n' "$ordinal"
    else
        printf 'pr-helper: warning: PR run ordinal unavailable; IDs will omit RUN\n' >&2
        printf 'unavailable\n'
    fi
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
    local run_ordinal
    run_ordinal=$(cmd_next_run "$host" "$owner" "$repo" "$n")

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
    printf 'RUN_ORDINAL=%s\n' "$run_ordinal"
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
    if [[ "${REVIEW_ANVIL_POST_INFRA_FAILURES:-0}" != "1" ]] && report_is_infra_failure "$report_path"; then
        die "review-anvil infrastructure failure report detected; refusing to post PR noise (report left at $report_path; set REVIEW_ANVIL_POST_INFRA_FAILURES=1 only for manual debugging)"
    fi

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
                append_review_context_note "$report_path" \
                    "Delivery: review-anvil selected APPROVE for head \`${reviewed_sha:0:8}\`. The PR now has head \`${current_sha:0:8}\`, so review-anvil posted a comment instead. The newer commits were not reviewed."
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
        local original_report_path="$report_path"
        local approval_report_path=""
        if [[ "$has_inline" -eq 1 ]]; then
            approval_report_path=$(mktemp -t review-anvil-approval.XXXXXX)
            cat "$report_path" >"$approval_report_path"
            append_inline_details_to_report "$approval_report_path" "$inline_json"
            report_path="$approval_report_path"
        fi
        if url=$(_submit_review APPROVE ""); then
            report_path="$original_report_path"
            [[ -z "$approval_report_path" ]] || rm -f "$approval_report_path"
            _emit_post_result APPROVE "$url"
            return 0
        fi
        report_path="$original_report_path"
        [[ -z "$approval_report_path" ]] || rm -f "$approval_report_path"
        review_event="COMMENT"
        printf 'warning: approval could not be submitted (common cause: GitHub rejects approving your own PR); downgrading to a comment review\n' >&2
        append_review_context_note "$report_path" \
            "Delivery: review-anvil selected APPROVE, but GitHub rejected the approval, so review-anvil posted a comment instead."
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

    append_inline_details_to_report "$report_path" "$inline_json"
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
    local run_ordinal
    run_ordinal=$(cmd_next_run "$host" "$owner" "$repo" "$n")

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
    printf 'RUN_ORDINAL=%s\n' "$run_ordinal"
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
        printf 'Review agents will inspect this PR against its base branch.\n'
        printf 'Fix commits will be applied to this branch after checks pass.\n'
        printf 'This comment will contain the final report or a failure summary.\n\n'
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
            append_review_context_note "$report_path" \
                "Failure: The prior-feedback refresh failed. review-anvil did not publish the success report because it can repeat earlier feedback."
            printf 'pr-helper: warning: prior-feedback refresh failed; updating comment with outcome=failure\n' >&2
        fi
    fi

    process_inline_comments_for_github "${report_path}.inline.json"
    compact_report_for_github "$report_path" "${report_path}.inline.json"
    if [[ "$outcome" == "success" ]]; then
        append_inline_details_to_report "$report_path" "${report_path}.inline.json"
    fi

    local completed_at delivery_note
    completed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    if [[ "$outcome" == "success" ]]; then
        delivery_note="Delivery: review-anvil-improve-pr completed on this PR$(_cc_tail "$author")."
    else
        delivery_note="Delivery: review-anvil-improve-pr failed on this PR$(_cc_tail "$author")."
    fi
    [[ -n "$started_at" ]] \
        && delivery_note+=" Started: $started_at;"
    delivery_note+=" Completed: $completed_at (outcome: $outcome)."
    append_review_context_note "$report_path" "$delivery_note"

    local tmp
    tmp=$(mktemp -t review-anvil-update.XXXXXX)
    {
        printf '<!-- review-anvil-marker: %s -->\n' "$marker"
        if [[ "$outcome" == "failure" ]]; then
            printf 'review-anvil-improve-pr **failed** on this PR%s.\n\n---\n\n' "$(_cc_tail "$author")"
        fi
        cat "$report_path"
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
    next-run)         shift; cmd_next_run "$@" ;;
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
    "")               die "usage: pr-helper.sh {init [<locator>] | next-run <host> <owner> <repo> <n> | post <host> <owner> <repo> <n> <marker> <report_path> | verify-checkout [<locator>] | post-start <host> <owner> <repo> <n> <marker> <author> | post-update <host> <owner> <repo> <n> <comment_id> <marker> <report_path> <author> <success|failure> [<started_at>] | history <host> <owner> <repo> <n> | dismissed <host> <owner> <repo> <n> | dismiss <host> <owner> <repo> <n> <path> <pattern> [<reason>] | compact-report <report_path> [<inline_json>] | process-inline <inline_json> | check-pins <preset> <pins-csv> [<raw-args>]}" ;;
    *)                die "unknown subcommand: $1" ;;
esac
