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
require "$ENGINE" 'Please check the state token before rotating the session'
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
require "$ARTIFACTS" 'Write the body in this order:'
require "$ROOT/references/reviewer-prompt.md" 'Build each finding in this order: problem, impact, requested change.'
require "$ROOT/references/reviewer-prompt.md" 'For runtime bugs, include reachability.'
require "$ENGINE" 'Otherwise, add the smallest supporting fact to what you noticed.'
require "$ARTIFACTS" 'Keep only evidence that helps the author trust or fix the finding.'
require "$ARTIFACTS" 'Each sentence explains one relationship between code concepts.'
require "$ROOT/references/reviewer-prompt.md" '- evidence: required concrete proof'
require "$ROOT/references/reviewer-prompt.md" 'Prefer the smallest clear fix and existing local patterns.'
require "$ROOT/references/reviewer-prompt.md" 'Use short everyday words. Prefer one clear sentence over a dense explanation.'
require "$ROOT/references/reviewer-prompt.md" 'If not, explain why removing it is the smallest fix.'
require "$ROOT/references/reviewer-prompt.md" 'Each sentence explains one relationship between code concepts.'
require "$ROOT/references/reviewer-prompt.md" '- suggested_fix: state the concrete requested change and intended result.'
require "$ARTIFACTS" 'Use short everyday words. Prefer one clear sentence over a dense explanation.'
reject "$ARTIFACTS" 'vary their grammatical construction'
require "$ARTIFACTS" 'Write the body in this order:'
require "$ARTIFACTS" '**Problem:** Name the code behavior and trigger.'
require "$ARTIFACTS" '**Impact:** State the concrete bad result.'
require "$ARTIFACTS" '**Requested change:** State the exact action or decision.'
require "$ARTIFACTS" 'The title states the failure, not only its technical category.'
require "$ARTIFACTS" 'Each sentence explains one relationship between code concepts.'
require "$ARTIFACTS" 'Before emitting the body, run this author check:'
require "$ARTIFACTS" 'The title and first sentence answer: what breaks, and when?'
require "$ARTIFACTS" 'Replace an abstract label with the code actor and a direct verb.'
require "$ARTIFACTS" 'The title names the actor that produces the concrete bad result.'
require "$ARTIFACTS" "Do not attribute an aggregate run's result to one file or record inside it."
require "$ARTIFACTS" 'Rewrite the title only when every fact-lock item in it still matches.'
require "$ARTIFACTS" 'Preserve title qualifiers and ownership, including diagnostic modals and scope words.'
require "$ARTIFACTS" 'restore the synthesized finding sentence verbatim.'
require "$ARTIFACTS" 'give one minimal example instead of making the reader simulate it.'
require "$ARTIFACTS" 'Remove a test sentence unless it defines the failure boundary.'
require "$ARTIFACTS" 'Before rewriting, make a private fact lock'
require "$ARTIFACTS" 'technical verbs and actor-action-target relationships'
require "$ARTIFACTS" 'quantifiers, scope words, and certainty'
require "$ARTIFACTS" 'valid behavior that the requested change must preserve'
require "$ARTIFACTS" 'Compare the draft with the fact lock.'
require "$ARTIFACTS" 'Clarity does not permit a stronger, broader, or different claim.'
require "$ARTIFACTS" 'Edit structure before vocabulary.'
require "$ARTIFACTS" 'Keep an exact supporting phrase for every fact-lock item.'
require "$ARTIFACTS" 'Privately map every fact-lock item to its exact supporting phrase in the draft.'
require "$ARTIFACTS" 'Do not emit until every fact-lock item has a supporting phrase.'
require "$ARTIFACTS" 'Privately map every draft relationship and boundary back to one fact-lock item.'
require "$ARTIFACTS" 'Delete any draft claim that has no source fact.'
require "$ARTIFACTS" 'If deletion would break the meaning, restore the source sentence.'
require "$ARTIFACTS" 'You may reorder clauses and split sentences'
require "$ARTIFACTS" 'Do not replace technical verbs, quantifiers, or scope words.'
require "$ARTIFACTS" 'Preserve modals that express diagnostic certainty.'
require "$ARTIFACTS" 'Treat remediation as a requested change, not as observed code.'
require "$ARTIFACTS" 'Apply the actor-action-target check to requested-change sentences as well as titles.'
require "$ARTIFACTS" 'If a requested change shifts the target, restore the source plan sentence verbatim.'
require "$ARTIFACTS" 'For each source-backed action in a critical, high, or medium finding'
require "$ARTIFACTS" 'Preserve suggestion grammar for low and nit guidance.'
require "$ARTIFACTS" 'If no source-backed requested change exists, stop after the consequence.'
require "$ARTIFACTS" 'Do not invent why a requested test exists.'
require "$ARTIFACTS" 'Please use the shared top-level parser in the module entry point. Please add one offline entry-point test.'
require "$ARTIFACTS" 'Delete a source clause only when another retained clause states the same fact.'
require "$ENGINE" 'Please check the state token before rotating the session'
require "$ENGINE" 'Please increment `attempts_succeeded` only after `insert_event` returns'
require "$ENGINE" 'Please reject invalid tokens without creating sessions. Please add a missing-state-token test.'
require "$ENGINE" 'Please keep timed-out attempts eligible for retry. Please add a timeout test.'
require "$ENGINE" 'the source-backed requested change.'
require "$ENGINE" 'The CLI help could use the same option name.'
require "$ENGINE" '- **[severity] area** — <plain-language behavior change>. (`RAV-RUN3-R2-P001`; covers `RAV-RUN3-R2-F001`)'
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
require "$STYLE" 'Do not give a context-free command.'
require "$STYLE" 'For critical, high, and medium findings, use `Please` plus an action verb'
require "$STYLE" 'each requested change. Preserve suggestion grammar for low and nit guidance.'
for producer in "$ENGINE" "$ARTIFACTS" "$REVIEWER" "$REPRODUCTION" "$ADVERSARIAL" "$PR_SKILL" "$READONLY" "$IMPROVE" "$PR_HELPER" "$RUN_REVIEWER"; do
    require "$producer" 'asd-ste100-inspired'
done
for preset in "$IMPROVE" "$PR_SKILL"; do
    require "$preset" 'Use direct imperatives for internal steps.'
    require "$preset" 'Use concise `Please` requests for critical/high/medium changes; retain suggestion grammar for low/nit guidance.'
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
reject "$ARTIFACTS" 'Non-retryable write errors must reach `signup_flow`'
reject "$ENGINE" 'A state check before rotation would block that path.'
reject "$ENGINE" 'A missing-state-token test would cover this path.'
reject "$ENGINE" 'A timeout test can cover this path.'
reject "$ENGINE" 'friendly next step'
reject "$ARTIFACTS" 'Name `the fix` or `the corrected path` when a desired state could look like current behavior.'
reject "$ARTIFACTS" 'Use `the fix` by default.'
reject "$ARTIFACTS" 'Use `the corrected path` only when'
reject "$ARTIFACTS" 'The corrected path returns'
reject "$ENGINE" 'The corrected path checks'
reject "$ENGINE" 'The corrected path increments'
reject "$ARTIFACTS" 'Use the shared top-level parser in the module entry point. Add one offline entry-point test.'
reject "$ARTIFACTS" 'Please use the shared top-level parser in the module entry point, and add one offline entry-point test.'
reject "$ARTIFACTS" 'A concise finding can omit the requested-change sentence'
reject "$ADVERSARIAL" 'friendly next step'
reject "$ROOT/references/reviewer-prompt.md" 'Revalidate `open`, `resolved`, `reported`, `deferred`, and'
reject "$ENGINE" '- Prior feedback: none |'
reject "$ENGINE" '- Reproduction: off | skipped | candidates='
reject "$ENGINE" '- Adversarial: off |'
reject "$ENGINE" '- Tuning suggestion:'
reject "$ENGINE" '## Diagnoses'
reject "$ENGINE" 'Possible suggestions'
reject "$ENGINE" 'failed reproduction:'
reject "$PR_SKILL" 'failed reproduction'

bash "$ROOT/scripts/test-identifiers.sh"

printf 'test-report-language: all language contract checks passed\n'
