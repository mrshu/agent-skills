#!/usr/bin/env bash
# Contract checks for plain-language review-anvil output guidance.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENGINE="$ROOT/SKILL.md"
ARTIFACTS="$ROOT/references/report-artifacts.md"
IMPROVE="$ROOT/../review-anvil-improve-pr/SKILL.md"

fail() {
    printf 'test-report-language: %s\n' "$*" >&2
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

require "$ENGINE" '- Checks: off | skipped (no findings needed checking)'
require "$ENGINE" '- Things to try: W items'
require "$ENGINE" '- Second check: off | <mode>, <A> reviewers'
require "$ENGINE" '- Set aside: D items'
require "$ENGINE" '- More rounds: off | not continued because <reason>'
require "$ENGINE" '**Checks:** off | skipped (no findings needed checking)'
require "$ENGINE" '**Second check:** off | <mode>, <A> reviewers'
require "$ENGINE" 'Refresh creates a session before CSRF validation'
require "$ENGINE" 'A missing-state-token test would cover this path.'
require "$ARTIFACTS" 'Keep the comment as short as the finding allows.'
require "$ARTIFACTS" 'We could avoid that by letting non-retryable write errors reach `signup_flow`'
require "$IMPROVE" 'Changes made / Things to try'
require "$ENGINE" '- Earlier review comments: none |'
require "$ENGINE" '- Checks: off | skipped | concerns='
require "$ENGINE" '- Second check: off | <mode>; reviewers='
require "$ENGINE" '- Set aside:'
require "$ENGINE" '- Next time:'
require "$ENGINE" '## What I noticed'
require "$ENGINE" '## Changes made / Things to try'
require "$ARTIFACTS" 'Start with what you saw.'
require "$ROOT/references/reviewer-prompt.md" 'Start by explaining what you saw:'
require "$ROOT/references/reviewer-prompt.md" 'For runtime bugs, include reachability.'
require "$ENGINE" 'Otherwise, add the smallest supporting fact to what you noticed.'
require "$ARTIFACTS" 'Every claim must point to a concrete code, test, config, caller, or runtime fact.'
require "$ARTIFACTS" 'Keep evidence brief. Use separate short sentences when more than one fact is needed.'
require "$ROOT/references/reviewer-prompt.md" '- evidence: required concrete proof'
require "$ROOT/references/reviewer-prompt.md" 'Prefer the smallest clear fix and existing local patterns.'
require "$ROOT/references/reviewer-prompt.md" 'Use short everyday words. Prefer one clear sentence over a dense explanation.'
require "$ROOT/references/reviewer-prompt.md" 'If not, explain why removing it is the smallest fix.'
require "$ROOT/references/reviewer-prompt.md" 'Keep it brief, and use separate short sentences when more than one fact is needed'
require "$ENGINE" 'We could check the state token before rotating the session.'
require "$ARTIFACTS" 'Use short everyday words. Prefer one clear sentence over a dense explanation.'
require "$ROOT/references/reproduction-prompt.md" 'author-facing wording in plain language'
require "$ROOT/references/adversarial-prompt.md" 'Treat type, verdict, evidence, and reason as internal.'
require "$ENGINE" 'The CLI help could use the same option name.'
require "$ENGINE" 'We could <plain-language behavior change>. (`RAVF001`)'
require "$ENGINE" 'We set this aside because <plain-language description of the missing proof>.'
reject "$ENGINE" '- Prior feedback: none |'
reject "$ENGINE" '- Reproduction: off | skipped | candidates='
reject "$ENGINE" '- Adversarial: off |'
reject "$ENGINE" '- Tuning suggestion:'
reject "$ENGINE" '## Diagnoses'
reject "$ENGINE" 'Possible suggestions'

printf 'test-report-language: all language contract checks passed\n'
