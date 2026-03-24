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

## Invocation Rules

Follow these rules exactly to avoid empty or lost output:

1. **Never use `--permission-mode plan`.** It redirects output to an internal plan file instead of stdout, producing empty or 1-line output. Use `--allowedTools` to restrict tools instead.
2. **Always add `2>&1`** at the end of the command to capture stderr alongside stdout.
3. **Always use `--max-turns`** to prevent the sub-claude from exhausting all turns on tool calls without producing a text response. Use `--max-turns 3` for reviews, `--max-turns 5` for deep digs, or `--tools "" --max-turns 1` for prompt-only (no file access).
4. **When using `--allowedTools`, pipe the prompt via stdin** — `--allowedTools` is a variadic flag that consumes all subsequent positional arguments, including the prompt. Use `echo 'prompt' | claude -p ...` or `< /tmp/prompt.txt`.
5. **When NOT using `--allowedTools`, pass the prompt as a positional argument** — `claude -p --max-turns 3 'prompt'` works fine.
6. **Write long prompts to a temp file** and pass via stdin redirect (`< /tmp/claude-prompt.txt`). Do not use inline HEREDOCs like `$(cat <<'EOF'...)` — they break in the Bash tool's shell handling.
7. **Use `run_in_background: true`** on the Bash tool call, then retrieve output with `TaskOutput`. Reviews routinely exceed the 120s Bash timeout.
8. **Always use `--no-session-persistence`** to avoid littering the user's session history with sub-agent sessions.

## Commands

### Code Review

Use `claude -p` (print mode) for non-interactive review. When using `--allowedTools`, the prompt **must** be piped via stdin:

```bash
# Review current branch against main
echo 'Review the changes on this branch compared to main. Run `git diff main...HEAD` to see the full diff. Be a strict reviewer: check for correctness, edge cases, security issues, and code clarity. Reference specific files and lines.' \
  | claude -p --max-turns 3 --no-session-persistence --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1

# Review only uncommitted changes
echo 'Review all uncommitted changes (run `git diff` and `git diff --cached`). Check for correctness, edge cases, and code clarity. Be specific with file:line references.' \
  | claude -p --max-turns 3 --no-session-persistence --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1
```

For simpler reviews without tool restrictions, pass the prompt directly:

```bash
# Review with a specific focus (no --allowedTools, prompt as positional arg)
claude -p --max-turns 3 --no-session-persistence \
  'Review the changes on this branch vs main. Focus specifically on error handling and security. Run `git diff main...HEAD` to see the diff.' \
  2>&1
```

### Custom Prompted Review

```bash
# Review a plan or design document
echo 'Review the plan in PLAN.md. Be a strict critic: identify gaps, missing edge cases, and over-engineering. Suggest concrete improvements.' \
  | claude -p --max-turns 3 --no-session-persistence --allowedTools "Read" "Glob" "Grep" 2>&1

# Deep exploration for blind spots
echo 'Explore the codebase for inconsistencies, dead code, and simplification opportunities. Focus on the src/api/ directory.' \
  | claude -p --max-turns 5 --no-session-persistence --allowedTools "Read" "Glob" "Grep" 2>&1
```

### Prompt-Only Review (No File Access)

When the sub-claude doesn't need to read files (e.g., you're passing the diff inline):

```bash
# Write the prompt to a temp file first
cat > /tmp/claude-prompt.txt << 'EOF'
Review this diff for correctness, edge cases, and clarity:

<diff content here>
EOF

# Run with no tools — forces a single-turn text response
claude -p --tools "" --max-turns 1 --no-session-persistence < /tmp/claude-prompt.txt 2>&1
```

### Iterative Review

Run review in a loop until all issues are resolved:

```bash
# First pass
echo 'Review the changes on this branch compared to main. Run `git diff main...HEAD`. List all problems.' \
  | claude -p --max-turns 3 --no-session-persistence --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1

# Fix the issues, then re-run
echo 'Review the changes on this branch compared to main. Run `git diff main...HEAD`. List remaining problems.' \
  | claude -p --max-turns 3 --no-session-persistence --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1

# Repeat until the review comes back clean
```

## Workflow Patterns

### Pre-push Quality Gate

After completing implementation and before pushing:

1. Run the review (pipe prompt via stdin when using --allowedTools)
2. Read the review output carefully
3. Fix any issues raised
4. Re-run the review until clean
5. Push

### Plan Counter-Review

When drafting an implementation plan:

1. Write the plan
2. Run `echo 'Review the plan in PLAN.md. Be very strict.' | claude -p --max-turns 3 --no-session-persistence --allowedTools "Read" "Glob" "Grep" 2>&1`
3. Revise the plan based on feedback
4. Re-run until claude agrees with the plan
5. Proceed with implementation

### Deep Dig

When exploring a codebase area for quality improvements:

```bash
# Broad exploration
echo 'Do a deep dig of src/. Find blind spots, interesting things to fix, and things to simplify. Be specific with file:line references.' \
  | claude -p --max-turns 5 --no-session-persistence --allowedTools "Read" "Glob" "Grep" 2>&1

# Follow up on specific findings
echo 'Look deeper at the error handling pattern in src/api/client.ts. Is the retry logic correct? What happens on timeout?' \
  | claude -p --max-turns 3 --no-session-persistence --allowedTools "Read" "Glob" "Grep" 2>&1
```

## Options

| Flag | Purpose |
|---|---|
| `-p, --print` | Non-interactive mode — print response and exit (required for delegation) |
| `--model <model>` | Override model (e.g., `--model sonnet`, `--model opus`) |
| `--max-turns <n>` | Limit tool-use turns. Use 1 for prompt-only, 3 for reviews, 5 for deep digs |
| `--tools ""` | Disable all tools — forces a single-turn text response |
| `--allowedTools "..."` | Restrict to specific tools. **Variadic flag — must pipe prompt via stdin when used** |
| `--no-session-persistence` | Don't save the sub-agent session to disk |

## Known Limitations

- **Timeouts.** Reviews routinely take 30-120+ seconds. Use `run_in_background: true` on the Bash tool call and retrieve output with `TaskOutput`.
- **Nested sessions.** If Claude Code detects it is already running inside another Claude Code session (via the `CLAUDE_CODE` env var), it will refuse to start. This happens when the parent process sets that variable. If you hit this, the skill cannot be used in that environment.
- **`--allowedTools` is variadic.** It consumes all subsequent positional arguments. When using it, always pipe the prompt via stdin (`echo '...' | claude -p ...`).
- **Long prompts.** Do not pass prompts longer than ~500 chars inline. Write to a temp file and use `< /tmp/claude-prompt.txt` stdin redirect.

## Anti-Patterns — Do NOT Do These

```bash
# BAD: --permission-mode plan causes empty stdout
claude -p --permission-mode plan 'Review...'

# BAD: --allowedTools eats the positional prompt — prompt is lost
claude -p --allowedTools "Read Glob Grep" 'Review...'

# BAD: No --max-turns — sub-claude may exhaust turns on tool calls
claude -p 'Review...'

# BAD: HEREDOC expansion — breaks in Bash tool shell
claude -p "$(cat <<'EOF'
long prompt here
EOF
)"

# BAD: Missing 2>&1 — stderr errors are invisible
claude -p --max-turns 3 'Review...'
```

## Tips

- **Be pointed in prompts.** Vague prompts get vague reviews. Tell claude exactly what to focus on and what format you want the response in.
- **Use `--allowedTools`** for read-only reviews instead of `--permission-mode plan`.
- **Pipe the prompt** when using `--allowedTools` — it's a variadic flag that eats positional args.
- **Iterate.** Don't treat the first review as final — run it again after fixes to catch regressions or new issues.
- **Model override.** Use `--model sonnet` for faster reviews, `--model opus` for deeper analysis.
- **Background long reviews.** Use `run_in_background: true` and retrieve with `TaskOutput` to avoid timeout issues.
