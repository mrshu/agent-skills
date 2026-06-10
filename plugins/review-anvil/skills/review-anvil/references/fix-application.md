# review-anvil — Fix Application (commit_mode=per_fix only)

Read before making any edit in Loop Mechanics §4 of the engine SKILL.md.

Make the edits as the orchestrator. Commit one logical fix-group per commit, conventional-commit style: `fix(area):` correctness, `refactor(area):` maintainability/simplicity, `test(area):` tests, `chore(area):` production-readiness.

#### Auto-fix policy (proportionality rules)

1. **Severity gate.** Auto-fix only at severity ≥ `min_fix_severity`. Below-gate findings land under "Suggestions". Exception: an obvious one-line fix at any severity may be applied without bumping severity.
2. **No new dependencies (default).** A fix introducing a new import, package, or subsystem is deferred with reason `introduces new dependency: <X>` even above the gate; `allow_new_deps: true` opts in. Don't grow the architecture without permission.
3. **Round size cap.** A round's fixes may grow the target file by at most ~50% of its starting line count or 200 lines, whichever is larger; apply highest-severity first, defer the rest with `round size cap reached`.

Noise/false positives are also **deferred** with a one-line reason — never silently dropped.

#### Build/test gate (`verify_cmd`)

Fix commits must not leave the branch red. In `per_fix`:

- **Resolve:** explicit `verify_cmd` → use it; `verify_cmd: none` → record `Verification: skipped (user)`; unset → auto-detect (repo docs naming a test command; `package.json` `scripts.test`; `Makefile` `test`; pytest/cargo/go-test config). Nothing found → record `Verification: none detected` and proceed (downstream consumers surface the caveat).
- **Baseline:** run once before round 1; if already failing, gate only on *new* failures and record the round state as `pre-existing failures (no new)`.
- **Gate each round:** run after the round's fixes. On a new failure: one fix-forward attempt if the cause is obvious (`fix(<area>): repair <verify_cmd> failure from round <N> fixes`), else `git revert --no-edit` the round's fix commits and defer the findings with `fix failed verification`. If the revert itself fails to restore green, stop the loop and surface it (same handling as a failed `git commit`). A round never ends with the gate newly red.

