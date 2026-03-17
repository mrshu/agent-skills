---
name: claude-exec
description: Delegate code review, plan review, and exploration to Claude Code CLI. Use when you need an independent second opinion on code changes, plans, or architecture — or when asked to run claude review/exec.
---

# Claude Exec — Cross-Agent Delegation

Delegate review and exploration tasks to **Claude Code CLI** for an independent second opinion. Claude acts as a strict counter-reviewer that catches blind spots you might miss.

## When to Use

Use this skill when:
- You have finished implementing a feature or fix and want an independent review before committing/pushing
- The user explicitly asks to run `claude` for review, or to "get claude's opinion"
- You have written or revised a plan and want a counter-review
- You want to explore the codebase for blind spots, simplification opportunities, or quality issues
- You need a second opinion on architecture or design decisions

**Do NOT use this skill** for tasks where you are confident in the output and the user hasn't asked for a second opinion. Reserve it for quality gates and deliberate review steps.

## Commands

### Code Review

Use `claude -p` (print mode) for non-interactive review:

```bash
# Review current branch against main
claude -p 'Review the changes on this branch compared to main. Run `git diff main...HEAD` to see the full diff. Be a strict reviewer: check for correctness, edge cases, security issues, and code clarity. Reference specific files and lines.'

# Review only uncommitted changes
claude -p 'Review all uncommitted changes (run `git diff` and `git diff --cached`). Check for correctness, edge cases, and code clarity. Be specific with file:line references.'

# Review with a specific focus
claude -p 'Review the changes on this branch vs main. Focus specifically on error handling and security. Run `git diff main...HEAD` to see the diff.'
```

### Custom Prompted Review

Use `claude -p` for reviews that go beyond standard code review — plan reviews, architecture critique, or targeted analysis:

```bash
# Review a plan or design document
claude -p 'Review the plan in PLAN.md. Be a strict critic: identify gaps, missing edge cases, and over-engineering. Suggest concrete improvements.'

# Targeted code analysis
claude -p 'Look at the authentication middleware in src/auth/. Are there any security concerns? What about rate limiting and session handling?'

# Deep exploration for blind spots
claude -p 'Explore the codebase for inconsistencies, dead code, and simplification opportunities. Focus on the src/api/ directory.'

# Review specific files
claude -p 'Review src/handlers/webhook.ts for correctness, error handling, and clarity. Be pointed in your response — list problems with file:line references.'
```

### Iterative Review

Run review in a loop until all issues are resolved:

```bash
# First pass
claude -p 'Review the changes on this branch compared to main. Run `git diff main...HEAD`. List all problems.'

# Fix the issues, then re-run
claude -p 'Review the changes on this branch compared to main. Run `git diff main...HEAD`. List remaining problems.'

# Repeat until the review comes back clean
```

For plans, iterate with `claude -p`:

```bash
claude -p 'Review the plan in PLAN.md and list remaining problems.'
# Revise the plan based on feedback, then re-run until agreed
```

## Workflow Patterns

### Pre-push Quality Gate

After completing implementation and before pushing:

1. Run `claude -p 'Review changes on this branch vs main...'`
2. Read the review output carefully
3. Fix any issues raised
4. Re-run the review until clean
5. Push

### Plan Counter-Review

When drafting an implementation plan:

1. Write the plan
2. Run `claude -p 'Review the plan in PLAN.md. Be very strict: identify gaps, missing edge cases, wrong assumptions, and over-engineering.'`
3. Revise the plan based on feedback
4. Re-run until claude agrees with the plan
5. Proceed with implementation

### Deep Dig

When exploring a codebase area for quality improvements:

```bash
# Broad exploration
claude -p 'Do a deep dig of src/. Find blind spots, interesting things to fix, and things to simplify. Be specific with file:line references.'

# Follow up on specific findings
claude -p 'Look deeper at the error handling pattern in src/api/client.ts. Is the retry logic correct? What happens on timeout?'
```

## Options

| Flag | Purpose |
|---|---|
| `-p, --print` | Non-interactive mode — print response and exit (required for delegation) |
| `--model <model>` | Override model (e.g., `--model sonnet`, `--model opus`) |
| `--permission-mode plan` | Read-only mode — claude can read files but not edit (safer for reviews) |
| `--allowedTools "Bash(git:*) Read Glob Grep"` | Restrict to read-only tools for pure review |
| `--dangerously-skip-permissions` | Skip permission prompts (only in trusted sandboxes) |

### Safe Review Mode

For pure review where Claude should only read, not modify:

```bash
claude -p --permission-mode plan 'Review the changes on this branch vs main. Run `git diff main...HEAD`.'
```

## Tips

- **Be pointed in prompts.** Vague prompts get vague reviews. Tell claude exactly what to focus on and what format you want the response in.
- **Use `--permission-mode plan`** for read-only reviews to prevent accidental edits.
- **Iterate.** Don't treat the first review as final — run it again after fixes to catch regressions or new issues.
- **Model override.** Use `--model sonnet` for faster reviews, `--model opus` for deeper analysis.
