#!/usr/bin/env bash
# Contract checks for plain-language review-anvil output guidance.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ENGINE="$ROOT/SKILL.md"
ARTIFACTS="$ROOT/references/report-artifacts.md"
IMPROVE="$ROOT/../review-anvil-improve-pr/SKILL.md"
PR_SKILL="$ROOT/../review-anvil-pr/SKILL.md"
REVIEWER="$ROOT/references/reviewer-prompt.md"
REPRODUCTION="$ROOT/references/reproduction-prompt.md"
ADVERSARIAL="$ROOT/references/adversarial-prompt.md"
STYLE="$ROOT/references/asd-ste100-inspired.md"
READONLY="$ROOT/../review-anvil-readonly/SKILL.md"
IMPROVE_PRESET="$ROOT/../review-anvil-improve-pr/SKILL.md"
PR_HELPER="$ROOT/../review-anvil-pr/scripts/pr-helper.sh"
RUN_REVIEWER="$ROOT/scripts/run-reviewer.sh"

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
require "$ARTIFACTS" 'stock opener or rotate through canned alternatives.'
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
require "$ROOT/references/reviewer-prompt.md" 'separate short sentences when more than one fact is needed'
require "$ROOT/references/reviewer-prompt.md" '- suggested_fix: state the concrete behavior change and intended result in neutral prose.'
require "$ARTIFACTS" 'Use short everyday words. Prefer one clear sentence over a dense explanation.'
require "$ARTIFACTS" 'When several inline comments include next steps, vary their grammatical construction.'
require "$ARTIFACTS" 'rewrite repeated lexical or grammatical openings when they read repetitive'
require "$ARTIFACTS" 'Never begin a next-step sentence with a bare verb.'
require "$ENGINE" 'The CLI help could use the same option name.'
require "$ENGINE" '- **[severity] area** — <plain-language behavior change>. (`RAVF001`)'
require "$ENGINE" 'We set this aside because <plain-language description of the missing proof>.'
require "$ENGINE" 'Keep `author-resolved` items in PR REVIEW HISTORY for reviewer context.'
require "$ENGINE" 'After synthesis and dedup, drop semantic matches to `author-resolved` items before building reproduction candidates.'
require "$ENGINE" '`author-resolved` history does not affect the review decision or approval.'
require "$ROOT/references/reviewer-prompt.md" 'Never raise an `author-resolved` item as a finding.'
require "$ROOT/../review-anvil-pr/SKILL.md" 'Only the PR author resolving a GitHub review thread creates `author-resolved` status.'
require "$ENGINE" '<!-- review-anvil: prior_feedback=reintroduced -->'
require "$ENGINE" '"prior_feedback": "reintroduced"'
require "$ARTIFACTS" 'helper-only `"prior_feedback": "reintroduced"`'
require "$ROOT/references/reviewer-prompt.md" 'only for a distinct new instance with new evidence.'
require "$STYLE" 'ASD-STE100-inspired, not ASD-STE100 compliant'
require "$STYLE" 'Use sentences of 20 words or fewer when practical.'
require "$STYLE" 'Do not rewrite code identifiers, quoted diagnostics, URLs, or required protocol/schema tokens.'
require "$STYLE" '## Internal Instructions'
require "$STYLE" 'Use active voice or a direct imperative.'
require "$STYLE" '## Author-Facing Reports and Comments'
require "$STYLE" 'Do not give a bare-verb command.'
for producer in "$ENGINE" "$ARTIFACTS" "$REVIEWER" "$REPRODUCTION" "$ADVERSARIAL" "$PR_SKILL" "$READONLY" "$IMPROVE" "$PR_HELPER" "$RUN_REVIEWER"; do
    require "$producer" 'asd-ste100-inspired'
done
for preset in "$IMPROVE" "$PR_SKILL"; do
    require "$preset" 'Use direct imperatives for internal steps.'
    require "$preset" 'Do not use bare-verb commands in author-facing text.'
done
require "$PR_HELPER" 'Review agents will inspect this PR against its base branch.'
require "$PR_HELPER" 'Fix commits will be applied to this branch after checks pass.'
require "$PR_HELPER" 'This comment will contain the final report or a failure summary.'
require "$RUN_REVIEWER" 'The reviewer output lacks a complete fenced findings block.'
reject "$PR_HELPER" "I'll run a multi-agent review loop on this PR's diff against its base branch"
for guide in "$ENGINE" "$ARTIFACTS" "$REVIEWER" "$REPRODUCTION" "$ADVERSARIAL"; do
    reject "$guide" 'We could '
    reject "$guide" 'One option is '
    reject "$guide" 'It may help to '
done
reject "$REPRODUCTION" 'author-facing wording'
reject "$REPRODUCTION" 'offer a gentle next step'
reject "$ADVERSARIAL" 'author-facing'
reject "$ADVERSARIAL" 'offer a gentle next step'
reject "$ENGINE" 'what happens because of it, and a friendly next step.'
reject "$REVIEWER" 'because of it. Then offer a friendly next step. Keep facts direct and short.'
reject "$REVIEWER" 'When useful, add a friendly next step.'
reject "$ROOT/references/reviewer-prompt.md" 'Revalidate `open`, `resolved`, `reported`, `deferred`, and'
reject "$ENGINE" '- Prior feedback: none |'
reject "$ENGINE" '- Reproduction: off | skipped | candidates='
reject "$ENGINE" '- Adversarial: off |'
reject "$ENGINE" '- Tuning suggestion:'
reject "$ENGINE" '## Diagnoses'
reject "$ENGINE" 'Possible suggestions'
reject "$ENGINE" 'failed reproduction:'
reject "$PR_SKILL" 'failed reproduction'

printf 'test-report-language: all language contract checks passed\n'
