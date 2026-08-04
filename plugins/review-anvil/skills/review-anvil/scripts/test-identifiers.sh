#!/usr/bin/env bash
# Contract checks for stable review-anvil finding and plan provenance IDs.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENGINE="$ROOT/SKILL.md"
REPRODUCTION="$ROOT/references/reproduction-prompt.md"
ADVERSARIAL="$ROOT/references/adversarial-prompt.md"
ARTIFACTS="$ROOT/references/report-artifacts.md"

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
require "$ENGINE" '`run` and `origin-round` are positive integers. `ordinal` is a zero-padded positive integer with at least three digits.'
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
require "$REPRODUCTION" 'target: RAV-RUN3-R2-F001'
require "$REPRODUCTION" 'Return the supplied complete canonical ID unchanged.'
require "$ADVERSARIAL" 'target: RAV-RUN3-R2-F001 | RAV-RUN3-R2-P001 | report | approval'
require "$ADVERSARIAL" 'Return each supplied complete canonical ID unchanged.'
require "$ARTIFACTS" 'Start every identified inline finding with its complete canonical ID.'
require "$ARTIFACTS" 'The report row, inline body, reproduction target, and adversarial target use the same complete finding ID unchanged.'
require "$ENGINE" 'Historical `RAVF###`, `RAVW###`, `F-###`, and `W-###` forms are migration/read-boundary aliases only.'

reject "$REPRODUCTION" 'RAVF001'
reject "$REPRODUCTION" 'RAVF###'
reject "$ADVERSARIAL" 'RAVF001'
reject "$ADVERSARIAL" 'RAVW001'
reject "$ADVERSARIAL" 'RAVF###'
reject "$ADVERSARIAL" 'RAVW###'
reject "$ENGINE" '| RAVF001 |'
reject "$ENGINE" '(`RAVF001`; inline)'
reject "$ENGINE" '(`RAVF001`)'

legacy_lines=$(grep -Ec 'RAVF###|RAVW###|F-###|W-###' "$ENGINE" || true)
[[ "$legacy_lines" == "1" ]] || \
    fail "historical identifier forms must appear on exactly one migration/read-boundary line (found $legacy_lines)"

printf 'test-identifiers: all provenance ID contract checks passed\n'
