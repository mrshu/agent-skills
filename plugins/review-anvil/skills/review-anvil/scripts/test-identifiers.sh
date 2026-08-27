#!/usr/bin/env bash
# Contract checks for stable review-anvil finding and plan provenance IDs.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENGINE="$ROOT/SKILL.md"
REPRODUCTION="$ROOT/references/reproduction-prompt.md"
ADVERSARIAL="$ROOT/references/adversarial-prompt.md"
ARTIFACTS="$ROOT/references/report-artifacts.md"
PR_PRESET="$ROOT/../review-anvil-pr/SKILL.md"
IMPROVE_PRESET="$ROOT/../review-anvil-improve-pr/SKILL.md"

fail() {
    printf 'test-identifiers: %s\n' "$*" >&2
    exit 1
}

require() {
    local file="$1" text="$2"
    grep -Fq -- "$text" "$file" || fail "missing $text in $file"
}

reject() {
    local file="$1" text="$2"
    if grep -Fq -- "$text" "$file"; then
        fail "retired $text remains in $file"
    fi
}

require "$ENGINE" 'RAV-RUN3-R2-F001'
require "$ENGINE" 'RAV-RUN3-R2-P001'
require "$ENGINE" 'RAV-R2-F001'
require "$ENGINE" 'RAV-R2-P001'
require "$ENGINE" 'PR finding: `RAV-RUN<run>-R<origin-round>-F<ordinal>`'
require "$ENGINE" 'PR plan:    `RAV-RUN<run>-R<origin-round>-P<ordinal>`'
require "$ENGINE" 'Local:      `RAV-R<origin-round>-F<ordinal>` / `RAV-R<origin-round>-P<ordinal>`'
require "$ENGINE" 'Canonical grammar: `RAV-(RUN<run>-)?R<origin-round>-(F|P)<ordinal>`.'
require "$ENGINE" '`run` and `origin-round` are unpadded positive base-10 integers.'
require "$ENGINE" 'minimum width of three digits: encode 1 as `001`, 10 as `010`, 100 as'
require "$ENGINE" '`100`, and 1000 as `1000`; do not add any other leading zero.'
require "$ENGINE" '`RAV-RUN12-R10-F010` and `RAV-R12-P1000`'
require "$ENGINE" '`RAV-RUN03-R2-F001`, `RAV-RUN3-R02-F001`, `RAV-RUN3-R2-F0001`,'
require "$ENGINE" '`RAV-RUN0-R2-F001`, `RAV-RUN3-R0-F001`, and `RAV-RUN3-R2-F000`.'
require "$ENGINE" 'ID legend: `RUN` is the observed PR review run, `R` is the immutable origin round, `F` is a finding, and `P` is a plan.'
require "$ENGINE" 'Finding and plan ordinals are independent, run-wide counters'
require "$ENGINE" 'Counters never reset each round and never reuse gaps.'
require "$ENGINE" 'Assign IDs after semantic deduplication, prior-feedback classification, and scope filtering, and before reproduction or adversarial dispatch.'
require "$ENGINE" 'The origin round never changes after confirmation,'
require "$ENGINE" 'refutation, priority change, deferral, fix, or re-raise.'
require "$ENGINE" 'Reproduction and adversarial passes are not rounds.'
require "$ENGINE" 'priority, normalized path, line, and topic'
require "$ENGINE" 'covered-finding priority, area, and subject'
require "$ENGINE" 'consume the exact `id=` value supplied in `PR REVIEW HISTORY`'
require "$ENGINE" 'use the `legacy=` value as a source alias'
require "$ENGINE" 'Use `run_ordinal` only when it is a positive trusted value.'
require "$ENGINE" 'Keep UUID markers as the collision-resistant run identity.'
require "$ENGINE" '- Run ordinal: <positive observed PR run ordinal | unavailable (local/degraded)>'
require "$ENGINE" 'The carried `RAV-RUN1-R2-F007` has no new inline comment.'
require "$ENGINE" 'but do not create a new inline thread.'
require "$REPRODUCTION" 'target: RAV-RUN3-R2-F001'
require "$REPRODUCTION" 'Return the supplied complete canonical ID unchanged.'
require "$ADVERSARIAL" 'target: RAV-RUN3-R2-F001 | RAV-RUN3-R2-P001 | report | approval'
require "$ADVERSARIAL" 'Return each supplied complete canonical ID unchanged.'
require "$ENGINE" '"body": "The handler creates a session before it checks the state token'
require "$ENGINE" '<!-- review-anvil: id=RAV-RUN3-R2-F001 severity=high area=auth -->'
require "$ENGINE" '- The refresh handler creates a session before it validates the token.'
require "$ENGINE" 'Already-assigned in-scope low/nit and set-aside findings keep their complete canonical F IDs.'
require "$ENGINE" 'Low/nit report rows and disposition rows use suggestion/boundary mode.'
require "$ENGINE" '<summary>Optional suggestions</summary>'
require "$ENGINE" '<summary>Set aside</summary>'
require "$ENGINE" 'structured disposition inventory'
require "$ENGINE" 'Truly unassigned out-of-scope follow-ups stay distinct and do not receive an F ID.'
require "$ARTIFACTS" 'Do not add a synthetic title or visible metadata.'
require "$ARTIFACTS" '`<!-- review-anvil: id=<complete-id> severity=<severity> area=<area> -->`.'
require "$ARTIFACTS" 'The marker remains the final line.'
require "$ENGINE" 'must match the terminal marker severity exactly; the helper aborts'
require "$PR_PRESET" 'must match the terminal marker severity exactly; the helper aborts'
require "$ENGINE" 'A present but unrecognized helper severity also aborts'
require "$PR_PRESET" 'A present but unrecognized helper severity also aborts'
require "$ARTIFACTS" 'ordinary prior-feedback'
require "$ARTIFACTS" 'carry-forwards do not create a new inline thread.'
require "$ARTIFACTS" 'The hidden report marker, inline marker, reproduction target, and'
require "$ARTIFACTS" 'target use the same complete finding ID unchanged.'
require "$ENGINE" 'Historical `RAVF###`, `RAVW###`, `F-###`, and `W-###` forms are migration/read-boundary aliases only.'
require "$ENGINE" '| `review-anvil-pr [<locator>]` | `commit_mode=none`, `target=<locator>`, `report_path=<file>`, trusted `run_ordinal=<observed>` |'
require "$ENGINE" '| `review-anvil-improve-pr [<locator>]` | `commit_mode=per_fix`, `target=<base>...HEAD`, `report_path=<file>`, trusted `run_ordinal=<observed>` |'
require "$PR_PRESET" 'RUN_ORDINAL=3'
require "$PR_PRESET" '"commit_mode,target,report_path,run_ordinal"'
require "$PR_PRESET" 'report_path: <REPORT_PATH>, run_ordinal: <RUN_ORDINAL>, <extra-user-args>'
require "$PR_PRESET" '`unavailable` makes the engine emit IDs without the `RUN` segment'
require "$PR_PRESET" 'cannot override the observed value'
require "$IMPROVE_PRESET" 'RUN_ORDINAL=3'
require "$IMPROVE_PRESET" '"commit_mode,target,report_path,run_ordinal"'
require "$IMPROVE_PRESET" 'report_path: <REPORT_PATH>, run_ordinal: <RUN_ORDINAL>, <extra-user-args>'
require "$IMPROVE_PRESET" '`unavailable` makes the engine emit IDs without the `RUN` segment'
require "$IMPROVE_PRESET" 'cannot override the observed value'

reject "$REPRODUCTION" 'RAVF001'
reject "$REPRODUCTION" 'RAVF###'
reject "$ADVERSARIAL" 'RAVF001'
reject "$ADVERSARIAL" 'RAVW001'
reject "$ADVERSARIAL" 'RAVF###'
reject "$ADVERSARIAL" 'RAVW###'
reject "$ENGINE" '| RAVF001 |'
reject "$ENGINE" '(`RAVF001`; inline)'
reject "$ENGINE" '- **[low] docs** — The CLI help could use the same option name.'
reject "$ENGINE" '- **[nit] tests** — The duplicate fixture setup can be shared.'
reject "$ENGINE" '- **[severity] area** — set aside because <reason>.'
reject "$ENGINE" '- **[medium] config** — set aside after the second check: the fix is too large for a one-line default.'
reject "$ENGINE" '(`RAVF001`)'
reject "$ENGINE" '"body": "**RAV-RUN3-R2-F001 [high] auth**'
reject "$ENGINE" '(`RAV-RUN3-R2-F001`; inline)'

legacy_lines=$(grep -Ec 'RAVF###|RAVW###|F-###|W-###' "$ENGINE" || true)
[[ "$legacy_lines" == "1" ]] || \
    fail "historical identifier forms must appear on exactly one migration/read-boundary line (found $legacy_lines)"

printf 'test-identifiers: all provenance ID contract checks passed\n'
