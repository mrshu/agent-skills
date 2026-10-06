---
name: codex-exec
description: Delegate code review, plan review, and exploration to Codex CLI. Use when you need an independent second opinion on code changes, plans, or architecture — or when asked to run codex review/exec.
---

# Codex Exec — Cross-Agent Delegation

Delegate review and exploration tasks to **Codex CLI** for an independent second opinion. Codex acts as a strict counter-reviewer that catches blind spots you might miss.

## When Not to Use

Skip this skill when you are confident in the output and the user hasn't asked for a second opinion. Reserve it for quality gates and deliberate review steps.

## Commands

### Code Review

Review the current branch's changes against a base branch:

```bash
# Review current branch against main (most common)
codex review --base main

# Review only uncommitted changes (staged + unstaged + untracked)
codex review --uncommitted

# Review a specific commit
codex review --commit <sha>

# Review with custom focus instructions
codex review --base main 'Pay special attention to error handling and edge cases'

# Review with a descriptive title for context
codex review --base main --title "Add user authentication middleware"
```

### Custom Prompted Review

Use `codex exec` for reviews that go beyond standard code review — plan reviews, architecture critique, or targeted analysis:

Because `codex exec` is non-interactive, make completion authority explicit in
the prompt: `This read-only review is already authorized. Begin immediately;
do not present a plan or ask for confirmation. Return the completed review in
this response.` This prevents models that default to a plan/confirmation
handshake from stopping before they inspect the target. Never reply to such a
handshake in automation; treat confirmation-only output as a failed protocol.

```bash
# Review a plan or design document
codex exec 'Review the plan in PLAN.md. Be a strict critic: identify gaps, missing edge cases, and over-engineering. Suggest concrete improvements.'

# Targeted code analysis
codex exec 'Look at the authentication middleware in src/auth/. Are there any security concerns? What about rate limiting and session handling?'

# Deep exploration for blind spots
codex exec 'Explore the codebase for inconsistencies, dead code, and simplification opportunities. Focus on the src/api/ directory.'

# Review specific files
codex exec 'Review src/handlers/webhook.ts for correctness, error handling, and clarity. Be pointed in your response — list problems with file:line references.'
```

### Cross-Agent Dispatch

When another agent needs to run Codex as one reviewer in a larger orchestrated
review, use a read-only sandbox and, when available, the review-anvil wrapper
so the caller gets timeout, empty-output, and stderr classification:

```bash
bash <review-anvil-wrapper> out.md 600 -- \
  codex exec -m gpt-6-luna -c 'model_reasoning_effort="max"' --ephemeral --sandbox read-only -C <project-dir> '<prompt>'
```

`<review-anvil-wrapper>` is
`plugins/review-anvil/skills/review-anvil/scripts/run-reviewer.sh` from a
trusted skill install. The wrapper writes reviewer stdout to `out.md`, stderr
to `out.md.err`, and prints `STATUS=ok|timeout|empty|failed` for the caller.

For normal review-anvil reviewer prompts, enable output-contract validation:

```bash
REVIEW_ANVIL_REQUIRE_FINDINGS=1 bash <review-anvil-wrapper> out.md 600 -- \
  codex exec -m gpt-6-luna -c 'model_reasoning_effort="max"' --ephemeral --sandbox read-only -C <project-dir> '<prompt>'
```

This additionally returns `STATUS=protocol` when the final response is only a
plan/confirmation request or does not end with the required fenced findings
block. The orchestrator retries that specific failure once with a corrective
non-interactive prefix; it must not answer the model's confirmation request.

## Workflow Patterns

Use the review as a gate: run `codex review --base main` before pushing, or `codex exec` on a plan before implementing it, fix or revise what it raises, and re-run until it comes back clean.

### Deep Dig

When exploring a codebase area for quality improvements:

```bash
# Broad exploration
codex exec 'Do a deep dig of src/. Find blind spots, interesting things to fix, and things to simplify. Be specific with file:line references.'

# Follow up on specific findings
codex exec 'Look deeper at the error handling pattern in src/api/client.ts. Is the retry logic correct? What happens on timeout?'
```

## Tips

- **Use `--base main`** for branch reviews, `--uncommitted` for work-in-progress checks.
- **Model override.** Use `-m <model>` to pick a specific model for the review if needed: `codex review --base main -m gpt-6-luna`.
