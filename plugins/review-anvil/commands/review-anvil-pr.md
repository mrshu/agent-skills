---
description: Read-only review of a GitHub PR with the synthesized report posted back as a PR comment (notifies the author).
argument-hint: <pr-url-or-slug> [rounds: N] [N codex + M claude] [focus: ...] [only: ...]
---

Thin orchestrator. The heavy lifting (locator parsing, `gh` preflight, marker injection, posting, URL recovery) lives in `${CLAUDE_PLUGIN_ROOT}/scripts/pr-helper.sh` (`set -euo pipefail` shell script). This file just sequences the model's tool calls.

**Pins (rejected if user tries to redefine):** `commit_mode`, `target`, `report_path`. The wrapper aborts before invoking the skill if any of these appear in `$ARGUMENTS`.

### Steps

1. **Reject overrides of pinned params.** Scan `$ARGUMENTS` with the regex `(^|[[:space:],])(commit_mode|target|report_path)[[:space:]]*:` — case-sensitive. If any match, abort with: `error: <param> is pinned by /review-anvil-pr and cannot be overridden in args`. Bare integers also rejected (see step 2).

2. **Parse first whitespace-delimited token of `$ARGUMENTS` as `<locator>`** (full GitHub URL or `<owner>/<repo>#<N>` slug). If absent, abort with: `usage: /review-anvil-pr <pr-url-or-slug> [extra args]`.

3. **Init via the helper script** — this does locator parsing, `gh` preflight (auth + PR reachability), and prepares the report path + marker:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/pr-helper.sh" init "<locator>"
   ```

   On success the script prints `HOST=…\nOWNER=…\nREPO=…\nN=…\nMARKER=…\nREPORT_PATH=…\nTITLE=…` on stdout. Capture all values; echo `review target: $HOST/$OWNER/$REPO#$N — $TITLE` to the user. On non-zero exit, surface the script's stderr and stop — do not dispatch reviewers.

4. **Invoke the skill** with the pinned params prepended and a sensible default for rounds:

   ```
   Skill review-anvil "commit_mode: none, target: <locator>, report_path: <REPORT_PATH>, <rest-of-$ARGUMENTS>, rounds: 2"
   ```

   Wait for the skill to complete. Its final output line is exactly `REPORT_PATH` — verify it matches what we passed in.

5. **Post via the helper script:**

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/pr-helper.sh" post "$HOST" "$OWNER" "$REPO" "$N" "$MARKER" "$REPORT_PATH"
   ```

   The script prepends the marker to the report file atomically, posts via `gh pr comment`, recovers the URL via paginated marker lookup (with one retry for read-after-write lag), and prints either the URL or `posted (URL unavailable)`.

6. **Surface the URL** to the user. If the line says `posted (URL unavailable)`, surface that instead.

### Examples

- `/review-anvil-pr https://github.com/acme/widgets/pull/137`
- `/review-anvil-pr acme/widgets#137 only: security, 3 codex + 1 claude`
- `/review-anvil-pr https://ghe.internal.acme.com/team/repo/pull/42` (GitHub Enterprise; `GH_HOST` handled internally by the script)

### Notes

- Bare integers (`/review-anvil-pr 42`) are rejected by the helper script — pass a URL or slug to be unambiguous about the repo identity.
- `/review-anvil-pr` is a developer convenience that requires `gh` to be installed. The script aborts with `install gh first` if it isn't on `PATH`.
- v1 supports github.com and GitHub Enterprise. Multi-forge support (GitLab MR, Gitea PR, …) is a v2 concern.
