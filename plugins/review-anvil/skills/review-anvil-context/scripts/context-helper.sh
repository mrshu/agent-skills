#!/usr/bin/env bash
# context-helper.sh — show the code context of review-anvil PR comments in a
# tmux side pane (fzf + bat). Used by the `review-anvil-context` and
# `review-anvil-comments` skills.
#
# Subcommands:
#
#   context <finding> [--pr N | --local] [--inline]
#                           — open the pane on <finding>'s context items.
#   comments [<finding>] [--pr N | --local] [--inline]
#                           — open the pane on the PR's comment list, cursor
#                             on <finding> when given.
#
# <finding> is a review-anvil finding ID (F001, R1-F001, RAV-R1-F001; any
# unambiguous suffix) or a numeric GitHub review-comment ID. Run inside the
# reviewed checkout; --pr defaults to the current branch's PR, whose inline
# comments and review-anvil reports are read. --local (or a branch without a
# PR) reads the newest report a local review left in .review-anvil/ instead. Prints KEY=VALUE lines (SOURCE,
# PANE, COMMENT_ID, FINDING_ID) on success.
#
# Keys in the pane:
#   context view — Enter: open item in $EDITOR · Backspace (empty query):
#                  comment list · Esc: close
#   comment list — Enter: context view · Esc: close
#
# Context items: the comment's own anchor (path, line, commit) from GitHub,
# then the items of its hidden context line, which pr-helper.sh writes from
# the reviewers' `context` lists:
#   <!-- review-anvil: context={"v":1,"items":[ITEM, ...]} -->
# ITEM one of
#   {"label", "path", "repo"?, "ref"?, "range": [a, b]?, "lines": [n, ...]?, "focus"?}
#   {"label", "kind": "pr", "repo"?, "number"}
# repo is owner/name and defaults to the PR's repo; paths are relative to
# their repo's root. Files in other repos need a full 40-character ref and
# are fetched from GitHub at that commit (cached). A range highlights one
# span in the full file; 2+ lines render as snippets (±2 lines each). The
# line comes from the PR, so every item is validated before use.
#
# Environment switches:
#   REVIEW_ANVIL_CACHE=dir    comment, PR and file cache (default ~/.cache/review-anvil)
#   EDITOR                    editor for Enter in the context view (default vi)
#
# Requires tmux (pane mode), fzf >= 0.45, jq, gh, git, less, bat or batcat,
# and the GNU/util-linux `column` (-o) and `readlink` (-f).
# All subcommands exit non-zero on failure with an error on stderr.

set -euo pipefail

die() { printf 'context-helper: %s\n' "$*" >&2; exit 1; }

self=$(readlink -f "$0")
cache_root=${REVIEW_ANVIL_CACHE:-$HOME/.cache/review-anvil}

need() { for c in "$@"; do command -v "$c" >/dev/null || die "$c not found"; done; }
bat_bin() { command -v bat || command -v batcat || die "bat not found"; }

# --- comment lookup (CTX_COMMENTS: cached `pulls/N/comments` array) ---

# jq `marker`: a comment's finding marker {f: id, s: severity, a: area}, or
# null. Only the last non-empty body line counts, and only when the whole
# line is a marker: the rule of terminal_finding_metadata in pr-helper.sh.
# Prose, evidence or suggestion blocks may quote markers earlier in a body.
jq_marker='def marker:
  [.body // "" | split("\n")[] | sub("\\s+$"; "") | select(. != "")] | last // ""
  | [capture("^<!--\\s*review-anvil:\\s*id=(?<f>[A-Za-z0-9-]+)\\s+severity=(?<s>critical|high|medium|low|nit)\\s+area=(?<a>[A-Za-z0-9][A-Za-z0-9._/-]*)\\s*-->$"; "i")
     | select(.a | contains("--") | not)] | first // null;'

# Finding ID from a comment's terminal review-anvil marker, or empty.
finding_of() {
  jq -r --argjson id "$1" "$jq_marker"'
    .[] | select(.id == $id) | marker.f // empty' "$CTX_COMMENTS"
}

comment_json() { jq --argjson id "$1" '.[] | select(.id == $id)' "$CTX_COMMENTS"; }

# <finding> -> GitHub comment ID. Matches the full finding ID or a "-"-bounded
# suffix, top-level comments only; dies on no match or ambiguity.
resolve_finding() {
  local q=$1 hits
  if [[ $q =~ ^[0-9]+$ ]]; then
    [[ -n $(comment_json "$q") ]] || die "no review comment $q in $CTX_LABEL"
    echo "$q"; return
  fi
  hits=$(jq -r --arg q "${q^^}" "$jq_marker"'
    .[] | select(.in_reply_to_id == null)
    | (marker.f // empty) as $f
    | ($f | ascii_upcase) as $u
    | select($u == $q or ($u | endswith("-" + $q)))
    | "\(.id)\t\($f)"' "$CTX_COMMENTS")
  [[ -n $hits ]] || die "no review-anvil finding $q in $CTX_LABEL"
  (( $(wc -l <<<"$hits") == 1 )) || die "ambiguous finding $q: $(cut -f2 <<<"$hits" | paste -sd' ')"
  cut -f1 <<<"$hits"
}

# --- findings from review-anvil reports ---

# Newest local report: one the engine wrote (.review-anvil/report-*.md), or a
# PR run's final-report-*.md that was not posted. Files tracked by git are
# skipped: the engine never commits one, so a tracked file came from the
# reviewed repository itself.
local_report_file() {
  local f
  while IFS= read -r f; do
    git -C "$CTX_DIR" ls-files --error-unmatch -- "${f#"$CTX_DIR"/}" >/dev/null 2>&1 && continue
    echo "$f"
    return 0
  done < <(ls -t "$CTX_DIR"/.review-anvil/report-*.md "$CTX_DIR"/.review-anvil/final-report-*.md 2>/dev/null)
  return 1
}

# jq `report_rows($login; $head)` on a report body: one comment-shaped object
# per finding line (its `review-anvil-report` marker), its context and commit
# from the report's hidden block (`<!-- review-anvil: context id=<ID> {...} -->`).
# Raw reviewer-schema `context` (a local report) is converted to viewer items;
# a posted report carries `items` re-encoded by pr-helper.sh. Untrusted like
# any comment: values that do not fit become null or an item sanitize_context
# rejects.
jq_report='
def unhex: ascii_downcase | explode | map(if . >= 97 then . - 87 else . - 48 end) | .[0] * 16 + .[1];
def pdecode: gsub("%(?<h>[0-9A-Fa-f]{2})"; [.h | unhex] | implode);
def num: if . == "-" then null else tonumber end;
def citem: if type != "object" then {label: null}
  else {label} + (if .repo != null then {repo} else {} end)
  + (if .pr != null then {kind: "pr", number: .pr}
     else {path: .file} + (if .ref != null then {ref} else {} end)
       + (.line | if . == null then {}
                  else (tostring | gsub(" "; "")) as $l
                  | if $l | test("^[0-9]+-[0-9]+$") then {range: ($l | split("-") | map(tonumber))}
                    elif $l | test("^[0-9]+(,[0-9]+)*$") then {lines: ($l | split(",") | map(tonumber))}
                    else {lines: [$l]} end end)
       + (if .focus != null then {focus} else {} end) end) end;
def sha: strings | select(test("^[0-9a-f]{40}$"));
def report_rows($login; $fallback):
  [split("\n")[] | sub("\\s+$"; "")] as $ls
  | ([$ls[] | capture("^<!--\\s*review-anvil:\\s*context\\s+id=(?<id>[A-Za-z0-9-]+)\\s+(?<j>\\{.*\\})\\s*-->$")
      | {key: .id, value: (.j | try fromjson catch {invalid: true})}] | from_entries) as $ctx
  | [$ls[] | capture("^(?<pre>.*?)\\s*<!--\\s*review-anvil-report:\\s*id=(?<id>[A-Za-z0-9-]+)\\s+severity=(?<s>[a-z]+)\\s+area=(?<a>[A-Za-z0-9][A-Za-z0-9._/-]*)\\s+path=(?<p>\\S+)\\s+start_line=(?<sl>[0-9]+|-)\\s+line=(?<l>[0-9]+|-)\\s+disposition=(?<d>[a-z]+)\\s*-->")
     | select(.id != "-")
     | ($ctx[.id] // {}) as $c
     | (($c.commit | sha) // ($fallback | sha) // null) as $commit
     | (.pre | if startswith("|") then ([splits("(?<!\\\\)\\|")] | .[3] // "" | gsub("\\\\\\|"; "|") | gsub("^\\s+|\\s+$"; ""))
               else sub("^\\s*[-*]\\s+"; "") end) as $text
     # No known commit (a report written before the context block, posted as
     # a plain comment): its line numbers may belong to any older commit, so
     # the anchor shows the whole file instead of a possibly wrong line.
     | (if $commit == null then null else (.l | num) end) as $line
     | {finding: .id, in_reply_to_id: null, user: {login: $login},
        path: (.p | if . == "-" then null else pdecode end), line: $line, original_line: $line,
        start_line: (if $commit == null then null else (.sl | num) end),
        commit_id: ($commit // $head), original_commit_id: ($commit // $head),
        body: ($text + "\n\n<!-- review-anvil: id=\(.id) severity=\(.s) area=\(.a) -->"),
        ctx_items: (if $c.invalid then [{kind: "invalid", label: "invalid context block"}]
                    elif ($c.items | type) == "array" then $c.items
                    elif ($c.context | type) == "array" then [$c.context[] | citem]
                    else [] end)}];'

# Comments the UI reads: the inline comments (stdin, may be []), then the
# findings of the reports in $1 (JSON [{body, login, commit}], newest first)
# that no inline comment already carries. `commit` = the report's own commit
# when known (a review's commit_id, a local report's HEAD), else null. $2 =
# the commit files are read at when a row has none. Report rows get ids that
# cannot collide with GitHub's.
merge_report_findings() {
  jq -s --slurpfile reports "$1" --arg head "$2" "$jq_marker$jq_report"'
    .[0] as $inline
    | ([$inline[] | marker.f // empty]) as $have
    | (reduce ($reports[0][] | .login as $u | .commit as $k | .body | report_rows($u; $k)[]) as $r
        ([]; if any(.[]; .finding == $r.finding) then . else . + [$r] end))
    | [.[] | select(.finding as $f | $have | index($f) | not)]
    | $inline + (to_entries | map(.value + {id: (900000000000 + .key)} | del(.finding)))'
}

# --- files in other repositories ---

# A file at an exact commit, fetched once from GitHub and cached for good: a
# path at a fixed SHA never changes. The reader's gh login decides access.
# Callers pass validated values only (sanitize_context). Prints the path.
remote_file() {
  local repo=$1 ref=$2 path=$3 f enc
  f="$cache_root/files/${repo//\//_}/$ref/$path"
  if [[ ! -f $f ]]; then
    enc=$(jq -rn --arg p "$path" '$p | split("/") | map(@uri) | join("/")')
    mkdir -p "$(dirname "$f")"
    if ! gh api -H 'Accept: application/vnd.github.raw' "repos/$repo/contents/$enc?ref=$ref" \
         > "$f.tmp" 2> "$f.err"; then
      echo "cannot fetch $repo@${ref:0:7}:$path: $(tail -1 "$f.err" | strip_ctl)" >&2
      rm -f "$f.tmp" "$f.err"
      return 1
    fi
    mv "$f.tmp" "$f"; rm -f "$f.err"; chmod a-w "$f"
  fi
  echo "$f"
}

# --- context file ---

# Control characters (ESC etc.) out of untrusted text before it reaches the
# terminal; keeps tab and newline.
strip_ctl() { tr -d '\000-\010\013-\037\177'; }

# Validated copy of a context file. Its items come from a PR comment, which
# anyone can write: keep known fields only, and reject values that could
# reach git/bat as options or read outside the repo. Invalid items stay
# visible as "invalid item: <reason>". Keep the rules in step with
# context_entry in review-anvil-pr/scripts/pr-helper.sh, which writes them.
sanitize_context() {
  jq '
    def bad($why): {kind: "invalid", label: "invalid item: \($why)"};
    def posint: type == "number" and . >= 1 and . == floor;
    def clean: gsub("[\u0001-\u001f\u007f]"; "");
    def has_ctl: explode | any(. < 32 or . == 127);
    {items: [(.items // [])[] |
      if type != "object" or (.label | type) != "string" or (.label | clean | test("^\\s*$"))
        then bad("label")
      elif .repo != null and (.repo | type != "string" or (test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$") | not)
            or (split("/") | any(. == "." or . == ".."))) then bad("repo")
      elif (.kind // "file") == "pr" then
        if (.number | posint) then {kind, label: (.label | clean), number} + (if .repo then {repo} else {} end)
        else bad("number") end
      elif (.kind // "file") != "file" then bad("kind")
      elif (.path | type != "string" or . == "" or has_ctl or test("^[/-]|(^|/)\\.\\.(/|$)")) then bad("path")
      elif (.ref // "" | type != "string" or (test("^([0-9a-fA-F]{7,40})?$") | not)) then bad("ref")
      elif (.repo // $pr) != $pr and (.ref // "" | test("^[0-9a-fA-F]{40}$") | not) then bad("ref: other repo needs a full SHA")
      elif ((.range // []) | type) != "array" or ((.lines // []) | type) != "array"
           or ([(.range // [])[], (.lines // [])[], (.focus // empty)] | all(posint) | not)
           or ((.range // [1, 1]) | length != 2 or .[1] < .[0]) then bad("line numbers")
      else {label: (.label | clean), path}
           + ({repo, ref, range, lines, focus} | with_entries(select(.value != null)))
      end]}' --arg pr "$CTX_REPO" "$1"
}

# Items of the comment's hidden `<!-- review-anvil: context={...} -->` line as
# a JSON array ([] when absent; one invalid item when unparsable).
marker_items() {
  local c raw
  c=$(comment_json "$1")
  if jq -e 'has("ctx_items")' <<<"$c" >/dev/null; then jq -c '.ctx_items' <<<"$c"; return; fi
  raw=$(jq -r '
    [.body | split("\n")[] | sub("\r$"; "")
     | select(startswith("<!-- review-anvil: context="))
     | sub("^<!-- review-anvil: context="; "") | sub("\\s*-->\\s*$"; "")][0] // empty' <<<"$c")
  [[ -n $raw ]] || { echo '[]'; return; }
  jq -c 'if .v == 1 and (.items | type) == "array" then .items else error("version") end' <<<"$raw" 2>/dev/null \
    || echo '[{"kind": "invalid", "label": "invalid context marker"}]'
}

# Path of the context file for a comment: the anchor, then the items of the
# comment's context marker, validated.
context_file() {
  local id=$1 f c head commit line ocommit oline pick ctx_ref=""
  # GitHub moves commit_id/line to the newest PR head where the comment still
  # applies; original_* stay at the reviewed commit. Take the first pair this
  # checkout can show: HEAD itself (read from disk), else a local commit.
  c=$(comment_json "$id")
  head=$(git -C "$CTX_DIR" rev-parse HEAD)
  read -r commit line ocommit oline < <(jq -r '"\(.commit_id) \(.line // "null") \(.original_commit_id) \(.original_line)"' <<<"$c")
  has() { [[ $2 != null ]] && git -C "$CTX_DIR" cat-file -e "$1^{commit}" 2>/dev/null; }
  if   [[ $commit == "$head" && $line != null ]]; then pick="disk $line"
  elif [[ $ocommit == "$head" ]];                 then pick="disk $oline"
  elif has "$commit" "$line";                     then pick="$commit $line"
  elif has "$ocommit" "$oline";                   then pick="$ocommit $oline"
  elif [[ $line != null ]];                       then pick="$commit $line"    # not local:
  else pick="$ocommit $oline"                                             # item_file fetches
  fi
  read -r commit line <<<"$pick"

  # Marker items were written against the reviewed commit (original_*). When
  # the checkout is elsewhere, pin PR-repo items to it.
  [[ $ocommit != "$head" ]] && ctx_ref=$ocommit

  f="$CTX_CACHE/context-$id.json"
  jq -n --argjson path "$(jq '.path' <<<"$c")" --argjson l "$line" --arg ref "$commit" \
        --argjson sl "$(jq '.start_line // .original_start_line // null' <<<"$c")" \
        --arg repo "$CTX_REPO" --arg cref "$ctx_ref" \
        --argjson marker "$(marker_items "$id")" '
    ({label: "Anchor", path: $path}
     + (if $l == null then {}
        elif ($sl | type) == "number" and $sl < $l then {range: [$sl, $l], focus: $sl}
        else {lines: [$l], focus: $l} end)
     + (if $ref == "disk" then {} else {ref: $ref} end)) as $anchor
    | {items: (if $path == null then [] else [$anchor] end) + [$marker[]
        | if $cref != "" and (.kind // "file") == "file" and .ref == null
             and ((.repo // $repo) == $repo) then .ref = $cref else . end]}' > "$f.raw"
  sanitize_context "$f.raw" > "$f"
  rm -f "$f.raw"
  echo "$f"
}

# Readable path of an item's file. PR repo: the checkout, or `git show` at
# its ref (from GitHub when the commit is not local). Other repos: GitHub at
# the item's full SHA. Errors go to stderr.
item_file() {
  local item=$1 repo path ref tmp
  path=$(jq -r '.path' <<<"$item")
  ref=$(jq -r '.ref // empty' <<<"$item")
  repo=$(jq -r --arg d "$CTX_REPO" '.repo // $d' <<<"$item")

  [[ $repo == "$CTX_REPO" ]] || { remote_file "$repo" "$ref" "$path"; return; }
  if [[ -z $ref ]]; then
    [[ -f "$CTX_DIR/$path" ]] || { echo "missing: $path" >&2; return 1; }
    echo "$CTX_DIR/$path"
    return
  fi
  mkdir -p "$CTX_CACHE/tmp"
  tmp="$CTX_CACHE/tmp/${ref}-${path//\//_}"
  if git -C "$CTX_DIR" show "$ref:$path" > "$tmp" 2>/dev/null; then
    echo "$tmp"
  elif [[ $ref =~ ^[0-9a-fA-F]{40}$ ]]; then
    remote_file "$repo" "$ref" "$path"
  else
    echo "missing: $path @ ${ref:0:7} (commit not in this checkout)" >&2
    return 1
  fi
}

# --- previews (fzf callbacks) ---

# Item preview. First 2 lines are a header, pinned by the caller (~2).
cmd_preview_item() {
  local json=$1 i=$2 item kind repo path ref file lang bat w=${FZF_PREVIEW_COLUMNS:-100}
  item=$(jq ".items[$i]" "$json")
  kind=$(jq -r '.kind // "file"' <<<"$item")
  repo=$(jq -r --arg d "$CTX_REPO" '.repo // $d' <<<"$item")
  bat=$(bat_bin)

  if [[ $kind == invalid ]]; then
    printf '\033[1;31m%s\033[0m\n\n' "$(jq -r '.label' <<<"$item")"
    echo "The context file entry was rejected; see sanitize_context in $self."
    return 0
  fi

  if [[ $kind == pr ]]; then
    local n cache pr
    n=$(jq -r '.number' <<<"$item")
    printf '\033[1;36m%s\033[0m\033[1m#%s\033[0m\n\033[2m%s\033[0m\n' "$repo" "$n" "$(jq -r '.label' <<<"$item")"
    # gh is ~1s per call and fzf re-runs previews on every visit: cache 5 min.
    cache="$CTX_CACHE/pr-${repo//\//_}-$n-$w"
    if [[ ! -s $cache || -n $(find "$cache" -mmin +5) ]]; then
      # --json only: gh's default view queries classic Projects, which the
      # API rejects. Failures are shown, not cached.
      pr=$(gh pr view "$n" -R "$repo" --json title,state,isDraft,author,url,body,files 2>&1) \
        || { echo "$pr"; return 0; }
      {
        jq -r '"\u001b[1m\(.title)\u001b[0m",
               "\(if .isDraft then "DRAFT" else .state end) · @\(.author.login) · \(.url)", ""' <<<"$pr"
        jq -r '.body' <<<"$pr" | "$bat" --color=always --paging=never --style=plain \
          --language markdown --terminal-width "$w"
        printf '\n\033[1mFiles changed (%s)\033[0m\n' "$(jq '.files | length' <<<"$pr")"
        jq -r '.files[] | "  \u001b[32m+\(.additions)\u001b[0m \u001b[31m-\(.deletions)\u001b[0m  \(.path)"' <<<"$pr"
      } > "$cache"
    fi
    cat "$cache"
    return 0
  fi

  path=$(jq -r '.path' <<<"$item")
  ref=$(jq -r '.ref // empty' <<<"$item")
  printf '\033[1;36m%s\033[0m%s:\033[1m%s\033[0m\n\033[2m%s\033[0m\n' \
    "$repo" "${ref:+@${ref:0:7}}" "$path" "$(jq -r '.label' <<<"$item")"
  file=$(item_file "$item" 2>&1) || { echo "$file"; return 0; }

  # bat misses .env.<anything>.
  lang=""
  [[ $(basename "$path") == .env* ]] && lang=DotENV
  batf() {
    "$bat" --color=always --paging=never --wrap=never --style=numbers \
      --terminal-width "$w" --file-name "$path" ${lang:+--language "$lang"} "$@" "$file"
  }

  local -a lines hl=()
  mapfile -t lines < <(jq -r '.lines[]?' <<<"$item")
  for l in "${lines[@]}"; do hl+=(--highlight-line "$l"); done

  if (( ${#lines[@]} >= 2 )); then
    # Snippets: each line ±2, merged; gaps <=2 lines are shown, not hidden,
    # since a "┄" row would cost as much.
    local last windows prev=0 s e
    last=$(wc -l < "$file")
    windows=$(printf '%s\n' "${lines[@]}" | sort -n | awk -v c=2 -v m="$last" '
      { s = ($1 - c <= 3) ? 1 : $1 - c; e = ($1 + c >= m - 2) ? m : $1 + c
        if (NR > 1 && s <= pe + 3) { pe = e } else { if (NR > 1) print ps, pe; ps = s; pe = e } }
      END { print ps, pe }')
    while read -r s e; do
      (( s > prev + 1 )) && printf '\033[2m     ┄ %d–%d ┄\033[0m\n' $(( prev + 1 )) $(( s - 1 ))
      batf --line-range "$s:$e" "${hl[@]}"
      prev=$e
    done <<<"$windows"
    (( prev < last )) && printf '\033[2m     ┄ %d–%d ┄\033[0m\n' $(( prev + 1 )) "$last"
  else
    jq -e '.range' <<<"$item" >/dev/null \
      && hl+=(--highlight-line "$(jq -r '"\(.range[0]):\(.range[1])"' <<<"$item")")
    batf "${hl[@]}"
  fi
}

# Comment preview: header, body as markdown (markers stripped), replies.
cmd_preview_comment() {
  local id=$1 c
  c=$(comment_json "$id")
  jq -r --arg f "$(finding_of "$id")" '
    "\u001b[1m\(if $f != "" then $f + " · " else "" end)@\(.user.login)\u001b[0m · \(.path // "(no file)"):\(.line // .original_line // "-")"
    + (if .line == null and .original_line != null then " \u001b[33m(outdated)\u001b[0m" else "" end)
    + " · \(.commit_id[0:7])", ""' <<<"$c"
  jq -r '.body' <<<"$c" | strip_ctl | sed -E 's/<!--.*-->//g' \
    | "$(bat_bin)" --color=always --paging=never --style=plain --language markdown \
        --terminal-width "${FZF_PREVIEW_COLUMNS:-100}"
  jq -r --argjson id "$id" '.[] | select(.in_reply_to_id == $id)
    | "\n\u001b[1m↩ @\(.user.login)\u001b[0m\n\(.body | gsub("[\u0001-\u0008\u000b-\u001f\u007f]"; ""))"' "$CTX_COMMENTS" | sed -E 's/<!--.*-->//g'
}

# Enter in the context view: file items in $EDITOR at the focus line, PR
# items in a pager.
cmd_open_item() {
  local json=$1 i=$2 item file focus
  item=$(jq ".items[$i]" "$json")
  case $(jq -r '.kind // "file"' <<<"$item") in
    invalid) return 0 ;;
    pr)      cmd_preview_item "$json" "$i" | less -R; return 0 ;;
  esac
  file=$(item_file "$item") || { read -rp 'Enter to go back' _; return 0; }
  focus=$(jq -r '.focus // .range[0]? // .lines[0]? // 1' <<<"$item")
  "${EDITOR:-vi}" "+$focus" "$file"
}

# --- UI (runs in the pane) ---

# Context view for one comment. Prints "@comments" on Backspace-to-comments;
# returns non-zero on Esc.
ui_context() {
  local id=$1 json header tsv rows fid
  json=$(context_file "$id")
  fid=$(finding_of "$id")
  header=$(comment_json "$id" | jq -r --arg f "$fid" '
    "\(if $f != "" then $f + " · " else "" end)@\(.user.login) · \(.path // "(no file)"):\(.line // .original_line // "-")",
    (.body | split("\n")[0] | gsub("[\u0001-\u001f\u007f]"; "") | .[0:200])')
  header+=$'\n'"Enter: open · ⌫: comments · Esc: close"

  # Row: focus <TAB> repo (· = PR's)  label  location. focus is hidden, drives the
  # preview scroll; snippet items (2+ lines) render compact, so start at top.
  tsv=$(jq -r --arg d "$CTX_REPO" '
    .items[] as $v
    | (if ($v.repo // $d) == $d then "·" else ($v.repo | split("/")[-1]) end) as $r
    | (if ($v.kind // "file") == "pr" then "#\($v.number)"
       else ((if $v.ref then "\($v.ref[0:7]):" else "" end) + $v.path
             + (if   $v.range then ":\($v.range[0])-\($v.range[1])"
                elif $v.lines then ":" + ($v.lines | map(tostring) | join(","))
                else "" end))
       end) as $loc
    | ($loc | split("/") | if length > 4 then (.[:2] + ["…"] + .[-2:]) else . end | join("/")) as $loc
    | (if (($v.lines // []) | length) >= 2 then 1 else ($v.focus // $v.range[0]? // ($v.lines // [1])[0]) end) as $f
    | [$f, $r, $v.label, $loc] | @tsv' "$json")
  rows=$(paste <(cut -f1 <<<"$tsv") <(cut -f2- <<<"$tsv" | column -t -s $'\t' -o '  '))

  fzf --header "$header" --header-first --layout reverse --prompt 'context> ' \
    --delimiter '\t' --with-nth 2 \
    --preview "'$self' _preview-item '$json' {n}" \
    --preview-window 'down,65%,border-top,~2,+{1}+2-/2' \
    --bind "enter:execute('$self' _open-item '$json' {n})" \
    --bind 'bspace:transform:[[ -n {q} ]] && echo backward-delete-char || echo "become(echo @comments)"' \
    <<<"$rows"
}

# Comment list. Prints the selected comment ID; returns non-zero on Esc.
ui_comments() {
  local id=${1:-} tsv rows pos
  # Row: id <TAB> finding  severity  author  location  context  replies  first line.
  tsv=$(jq -r "$jq_marker"'
    . as $all | map(select(.in_reply_to_id == null)) | sort_by(.path, (.line // .original_line))[]
    | . as $c
    | ([$all[] | select(.in_reply_to_id == $c.id)] | length) as $n
    | (marker // {f: "-", s: "-"} | .f |= sub("^RAV-"; "")) as $m
    | (.path // "(no file)" | split("/") | if length > 4 then (.[:2] + ["…"] + .[-2:]) else . end | join("/")) as $p
    | (if has("ctx_items") then (.ctx_items | length) else
        [.body | split("\n")[] | sub("\r$"; "") | select(startswith("<!-- review-anvil: context="))
         | sub("^<!-- review-anvil: context="; "") | sub("\\s*-->\\s*$"; "")
         | (try fromjson catch null) | .items? // [] | length][0] // 0 end) as $k
    | [.id, $m.f, $m.s, "@" + .user.login, "\($p):\(.line // .original_line // "-")",
       (if $k > 0 then "+\($k) ctx" else "·" end),
       (if $n > 0 then "↩\($n)" else "·" end), (.body | split("\n")[0] | gsub("[\u0001-\u001f\u007f]"; "") | .[0:90])] | @tsv' "$CTX_COMMENTS")
  [[ -n $tsv ]] || { echo "$CTX_LABEL has no review comments" >&2; sleep 2; return 1; }
  rows=$(paste <(cut -f1 <<<"$tsv") <(cut -f2- <<<"$tsv" | column -t -s $'\t' -o '  '))
  pos=$(cut -f1 <<<"$rows" | grep -nx "${id:-none}" | cut -d: -f1 || true)

  fzf --layout reverse --prompt 'comment> ' --delimiter '\t' --with-nth 2 \
    --header "$CTX_REPO · $CTX_LABEL · $(wc -l <<<"$rows") comments · Enter: context · Esc: close" \
    --preview "'$self' _preview-comment {1}" \
    --preview-window 'down,60%,wrap,border-top' \
    ${pos:+--bind "load:pos($pos)"} \
    --bind 'enter:become(echo {1})' <<<"$rows"
}

cmd_ui() {
  local mode=$1 id=${2:-} out
  # fzf runs bind/preview commands with $SHELL; the bspace bind needs bash.
  SHELL=$(command -v bash); export SHELL
  while :; do
    case $mode in
      context) out=$(ui_context "$id") || return 0
               [[ $out == @comments ]] && mode=comments ;;
      comments) id=$(ui_comments "$id") || return 0
               mode=context ;;
    esac
  done
}

# --- entry points (run by the agent) ---

cmd_open() {
  local mode=$1; shift
  local finding="" pr="" inline=0 local_mode=0 id="" pane lf pr_head
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pr)     pr=${2:?--pr needs a number}
                [[ $pr =~ ^[1-9][0-9]*$ ]] || die "--pr must be a PR number, got: $pr"
                shift 2 ;;
      --inline) inline=1; shift ;;
      --local)  local_mode=1; shift ;;
      -*)       die "unknown option: $1" ;;
      *)        [[ -z $finding ]] || die "unexpected argument: $1"; finding=$1; shift ;;
    esac
  done
  [[ $mode == comments || -n $finding ]] || die "context needs a finding ID (e.g. F001)"
  [[ $local_mode == 0 || -z $pr ]] || die "--local and --pr exclude each other"
  need jq gh fzf git less column readlink sha256sum
  bat_bin >/dev/null

  CTX_DIR=$(git rev-parse --show-toplevel 2>/dev/null) || die "run inside the reviewed git checkout"
  # No PR for the branch (and none given): a local review is the only source.
  # Any other gh failure (auth, network, rate limit) stops here.
  if [[ $local_mode == 0 && -z $pr ]]; then
    local gh_out
    if ! gh_out=$(gh pr view --json number -q .number 2>&1); then
      grep -qi 'no pull requests found' <<<"$gh_out" || die "gh pr view failed: $gh_out"
      local_mode=1
    else
      pr=$gh_out
    fi
  fi

  if [[ $local_mode == 1 ]]; then
    lf=$(local_report_file) \
      || die "no local review report in $CTX_DIR/.review-anvil/ (run a review first, or pass --pr N)"
    CTX_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || CTX_REPO="local/$(basename "$CTX_DIR")"
    CTX_PR=local
    CTX_LABEL="local review ${lf##*/}"
    # Local findings belong to one checkout: key the cache on it, not the repo.
    CTX_CACHE="$cache_root/${CTX_REPO//\//_}/local-$(printf '%s' "$CTX_DIR" | sha256sum | cut -c1-12)"
    CTX_COMMENTS="$CTX_CACHE/comments.json"
    mkdir -p "$CTX_CACHE"
    jq -Rs --arg head "$(git -C "$CTX_DIR" rev-parse HEAD)" '[{body: ., login: "review-anvil (local)", commit: $head}]' \
      "$lf" > "$CTX_CACHE/reports.json" || die "cannot read $lf"
    echo '[]' | merge_report_findings "$CTX_CACHE/reports.json" "$(git -C "$CTX_DIR" rev-parse HEAD)" \
      > "$CTX_COMMENTS" || die "cannot parse $lf"
  else
    CTX_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner) || die "gh cannot resolve this repo"
    CTX_PR=$pr
    CTX_LABEL="PR #$CTX_PR"
    CTX_CACHE="$cache_root/${CTX_REPO//\//_}/pr-$CTX_PR"
    CTX_COMMENTS="$CTX_CACHE/comments.json"
    mkdir -p "$CTX_CACHE"
    # Inline comments carry their own context line; the PR's review-anvil
    # reports (top-level comments, review bodies) carry the rest in their block.
    gh api --paginate "repos/$CTX_REPO/pulls/$CTX_PR/comments" | jq -s 'add // []' > "$CTX_CACHE/inline.json" \
      || die "cannot fetch review comments of PR #$CTX_PR"
    { gh api --paginate "repos/$CTX_REPO/issues/$CTX_PR/comments" && gh api --paginate "repos/$CTX_REPO/pulls/$CTX_PR/reviews"; } \
      | jq -s '[add // [] | .[] | select((.body // "") | contains("review-anvil-report:") and contains("<!-- review-anvil-marker:"))
               | {body, login: .user.login, commit: (.commit_id // null), at: (.updated_at // .submitted_at // .created_at)}]
               | sort_by(.at) | reverse' > "$CTX_CACHE/reports.json" \
      || die "cannot fetch the review reports of PR #$CTX_PR"
    pr_head=$(gh api "repos/$CTX_REPO/pulls/$CTX_PR" -q .head.sha) && [[ $pr_head =~ ^[0-9a-f]{40}$ ]] \
      || die "cannot read the head commit of PR #$CTX_PR"
    merge_report_findings "$CTX_CACHE/reports.json" "$pr_head" \
      < "$CTX_CACHE/inline.json" > "$CTX_COMMENTS.tmp" && mv "$CTX_COMMENTS.tmp" "$CTX_COMMENTS" \
      || die "cannot merge the review findings of PR #$CTX_PR"
  fi
  export CTX_DIR CTX_REPO CTX_PR CTX_LABEL CTX_CACHE CTX_COMMENTS

  [[ -n $finding ]] && id=$(resolve_finding "$finding")
  printf 'SOURCE=%s\nCOMMENT_ID=%s\nFINDING_ID=%s\n' "$CTX_LABEL" "$id" "${id:+$(finding_of "$id")}"

  if [[ -z ${TMUX:-} || $inline == 1 ]]; then
    cmd_ui "$mode" "$id"
    return
  fi
  # One context pane per window: replace an earlier one.
  tmux list-panes -F '#{pane_id} #{@review_anvil_context}' | awk '$2 == 1 { print $1 }' \
    | xargs -r -n1 tmux kill-pane -t
  pane=$(tmux split-window -h -P -F '#{pane_id}' ${TMUX_PANE:+-t "$TMUX_PANE"} -c "$CTX_DIR" \
    -e CTX_DIR="$CTX_DIR" -e CTX_REPO="$CTX_REPO" -e CTX_PR="$CTX_PR" -e CTX_LABEL="$CTX_LABEL" \
    -e CTX_CACHE="$CTX_CACHE" -e CTX_COMMENTS="$CTX_COMMENTS" -e REVIEW_ANVIL_CACHE="$cache_root" \
    "$self" _ui "$mode" "$id")
  tmux set-option -p -t "$pane" @review_anvil_context 1
  printf 'PANE=%s\n' "$pane"
}

case "${1:-}" in
  context|comments)  m=$1; shift; cmd_open "$m" "$@" ;;
  _ui)               shift; cmd_ui "$@" ;;
  _preview-item)     shift; cmd_preview_item "$@" ;;
  _preview-comment)  shift; cmd_preview_comment "$@" ;;
  _open-item)        shift; cmd_open_item "$@" ;;
  *) die "usage: context-helper.sh {context <finding>|comments [<finding>]} [--pr N] [--inline]" ;;
esac
