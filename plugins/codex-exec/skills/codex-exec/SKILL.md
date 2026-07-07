---
name: codex-exec
description: Delegate code review, plan review, and exploration to Codex CLI. Use when you need an independent second opinion on code changes, plans, or architecture — or when asked to run codex review/exec.
---

# Codex Exec — Cross-Agent Delegation

Delegate review and exploration tasks to **Codex CLI** for an independent second opinion. Codex acts as a strict counter-reviewer that catches blind spots you might miss.

## When to Use

Use this skill when:
- You have finished implementing a feature or fix and want an independent review before committing/pushing
- The user explicitly asks to run `codex exec`, `codex review`, or to "get codex's opinion"
- You have written or revised a plan and want a counter-review
- You want to explore the codebase for blind spots, simplification opportunities, or quality issues
- You need a second opinion on architecture or design decisions

**Do NOT use this skill** for tasks where you are confident in the output and the user hasn't asked for a second opinion. Reserve it for quality gates and deliberate review steps.

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
  codex exec --ephemeral --sandbox read-only -C <project-dir> '<prompt>'
```

`<review-anvil-wrapper>` is
`plugins/review-anvil/skills/review-anvil/scripts/run-reviewer.sh` from a
trusted skill install. The wrapper writes reviewer stdout to `out.md`, stderr
to `out.md.err`, and prints `STATUS=ok|timeout|empty|failed` for the caller.

For normal review-anvil reviewer prompts, enable output-contract validation:

```bash
REVIEW_ANVIL_REQUIRE_FINDINGS=1 bash <review-anvil-wrapper> out.md 600 -- \
  codex exec --ephemeral --sandbox read-only -C <project-dir> '<prompt>'
```

This additionally returns `STATUS=protocol` when the final response is only a
plan/confirmation request or does not end with the required fenced findings
block. The orchestrator retries that specific failure once with a corrective
non-interactive prefix; it must not answer the model's confirmation request.

### Iterative Review

Run review in a loop until all issues are resolved:

```bash
# First pass
codex review --base main

# Fix the issues codex found, then re-run
codex review --base main

# Repeat until the review comes back clean
```

For plans, iterate with `codex exec`:

```bash
codex exec 'Review the plan in PLAN.md and list remaining problems.'
# Revise the plan based on feedback, then re-run until agreed
```

## Workflow Patterns

### Pre-push Quality Gate

After completing implementation and before pushing:

1. Run `codex review --base main`
2. Read the review output carefully
3. Fix any issues raised
4. Re-run the review until clean
5. Push

### Plan Counter-Review

When drafting an implementation plan:

1. Write the plan
2. Run `codex exec 'Review the plan in PLAN.md. Be very strict: identify gaps, missing edge cases, wrong assumptions, and over-engineering.'`
3. Revise the plan based on feedback
4. Re-run until codex agrees with the plan
5. Proceed with implementation

### Deep Dig

When exploring a codebase area for quality improvements:

```bash
# Broad exploration
codex exec 'Do a deep dig of src/. Find blind spots, interesting things to fix, and things to simplify. Be specific with file:line references.'

# Follow up on specific findings
codex exec 'Look deeper at the error handling pattern in src/api/client.ts. Is the retry logic correct? What happens on timeout?'
```

## Tips

- **Be pointed in prompts.** Vague prompts get vague reviews. Tell codex exactly what to focus on and what format you want the response in.
- **Use `--base main`** for branch reviews, `--uncommitted` for work-in-progress checks.
- **Iterate.** Don't treat the first review as final — run it again after fixes to catch regressions or new issues.
- **Model override.** Use `-m <model>` to pick a specific model for the review if needed: `codex review --base main -m o3`.
