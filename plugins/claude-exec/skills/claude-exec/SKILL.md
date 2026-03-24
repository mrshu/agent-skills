---
name: claude-exec
description: Delegate code review, plan review, and exploration to Claude Code CLI. Use when you need an independent second opinion on code changes, plans, or architecture — or when asked to run claude review/exec.
---

# Claude Exec — Cross-Agent Delegation

Delegate review and exploration tasks to an **independent Claude sub-agent** for a second opinion. The sub-agent acts as a strict counter-reviewer that catches blind spots you might miss.

## When to Use

Use this skill when:
- You have finished implementing a feature or fix and want an independent review before committing/pushing
- The user explicitly asks to run `claude` for review, or to "get claude's opinion"
- You have written or revised a plan and want a counter-review
- You want to explore the codebase for blind spots, simplification opportunities, or quality issues
- You need a second opinion on architecture or design decisions

**Do NOT use this skill** for tasks where you are confident in the output and the user hasn't asked for a second opinion. Reserve it for quality gates and deliberate review steps.

## How It Works

Use the **Agent tool** to spawn a sub-agent. The Agent tool handles streaming output natively — the user sees progress as the sub-agent works, with no timeout or buffering issues.

**Do NOT use `claude -p` via the Bash tool.** The Bash tool buffers all stdout and only shows output when the command completes. For long reviews (30-120+ seconds), this means the user sees nothing until it's done, and output is lost on timeout.

## Invocation Rules

1. **Use the Agent tool**, not the Bash tool with `claude -p`.
2. **Set `subagent_type` to `"general-purpose"`** — this gives the sub-agent access to Read, Glob, Grep, and Bash for exploring the codebase.
3. **Include "research only" in the prompt** when you want a review without modifications. Tell the sub-agent explicitly not to edit files.
4. **Be specific in prompts.** Tell the sub-agent exactly what to review, what to focus on, and what format you want the output in. Vague prompts get vague reviews.
5. **Use `run_in_background: true`** on the Agent tool call if you have other work to do while the review runs.

## Commands

### Code Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review branch changes"
  prompt: "You are a strict code reviewer. Review the changes on this branch compared to main. Run `git diff main...HEAD` to see the full diff. Check for correctness, edge cases, security issues, and code clarity. Reference specific files and lines. IMPORTANT: Research only — do not edit any files."
```

### Uncommitted Changes Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review uncommitted changes"
  prompt: "You are a strict code reviewer. Review all uncommitted changes (run `git diff` and `git diff --cached`). Check for correctness, edge cases, and code clarity. Be specific with file:line references. IMPORTANT: Research only — do not edit any files."
```

### Plan Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review implementation plan"
  prompt: "You are a strict plan reviewer. Read the plan in PLAN.md. Be a strict critic: identify gaps, missing edge cases, wrong assumptions, and over-engineering. Suggest concrete improvements. IMPORTANT: Research only — do not edit any files."
```

### Deep Dig / Exploration

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Deep codebase exploration"
  prompt: "Explore the codebase for inconsistencies, dead code, and simplification opportunities. Focus on the src/ directory. Be specific with file:line references. IMPORTANT: Research only — do not edit any files."
```

### Focused File Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review specific file"
  prompt: "Review src/handlers/webhook.ts for correctness, error handling, and clarity. Be pointed — list problems with file:line references. IMPORTANT: Research only — do not edit any files."
```

## Workflow Patterns

### Pre-push Quality Gate

After completing implementation and before pushing:

1. Spawn a sub-agent to review changes on the branch vs main
2. Read the review output (streams as the sub-agent works)
3. Fix any issues raised
4. Re-run the review until clean
5. Push

### Plan Counter-Review

1. Write the plan
2. Spawn a sub-agent to review the plan
3. Revise the plan based on feedback
4. Re-run until the sub-agent agrees with the plan
5. Proceed with implementation

### Iterative Review

1. Spawn review sub-agent
2. Fix issues found
3. Spawn another review sub-agent to check remaining problems
4. Repeat until clean

### Parallel Reviews

Use multiple Agent calls in a single message for independent reviews:

```
Agent call 1:
  description: "Review API changes"
  prompt: "Review changes in src/api/ on this branch vs main..."

Agent call 2:
  description: "Review test coverage"
  prompt: "Check test coverage for changes on this branch vs main..."
```

## Options

| Parameter | Purpose |
|---|---|
| `subagent_type: "general-purpose"` | Gives sub-agent access to Read, Glob, Grep, Bash |
| `description` | Short label shown to the user (3-5 words) |
| `prompt` | The review instructions — be specific |
| `run_in_background: true` | Run review while you continue other work |
| `model: "sonnet"` or `model: "opus"` | Override model for speed vs depth |

## Anti-Patterns — Do NOT Do These

```
# BAD: Using claude -p via Bash tool — output buffers until completion,
# user sees nothing for 30-120+ seconds, output lost on timeout
Bash tool: claude -p 'Review...'

# BAD: Vague prompt — gets a vague review
Agent tool: prompt: "Review the code"

# BAD: Not saying "research only" — sub-agent may edit files
Agent tool: prompt: "Review and fix any issues"
```

## Tips

- **Be pointed in prompts.** Tell the sub-agent exactly what to focus on and what format you want the response in.
- **Use "research only"** in the prompt to prevent the sub-agent from editing files during review.
- **Run in parallel.** Multiple independent reviews can run simultaneously as separate Agent calls.
- **Iterate.** Don't treat the first review as final — run it again after fixes to catch regressions.
- **Model override.** Use `model: "sonnet"` for faster reviews, `model: "opus"` for deeper analysis.
