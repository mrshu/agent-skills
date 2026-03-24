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
2. **Always use `--max-turns`** to prevent the sub-claude from exhausting all turns on tool calls without producing a text response. Use `--max-turns 3` for reviews, `--max-turns 5` for deep digs, or `--tools "" --max-turns 1` for prompt-only (no file access).
3. **When using `--allowedTools`, pipe the prompt via stdin** — `--allowedTools` is a variadic flag that consumes all subsequent positional arguments, including the prompt. Use `echo 'prompt' | claude -p ...` or `< /tmp/prompt.txt`.
4. **When NOT using `--allowedTools`, pass the prompt as a positional argument** — `claude -p --max-turns 3 'prompt'` works fine.
5. **Write long prompts to a temp file** and pass via stdin redirect (`< /tmp/claude-prompt.txt`). Do not use inline HEREDOCs like `$(cat <<'EOF'...)` — they break in the Bash tool's shell handling.
6. **Always add `2>&1`** at the end of the command to capture stderr alongside stdout.
7. **Always use `--no-session-persistence`** to avoid littering the user's session history with sub-agent sessions.

## Streaming Output

Reviews routinely take 30-120+ seconds. To show incremental progress instead of making the user wait:

1. **Run with `run_in_background: true`** on the Bash tool call.
2. **Poll with `TaskOutput`** using `block: false` every 10-15 seconds to retrieve new output since the last check.
3. **Show partial output to the user** each time you poll — summarize or quote what the sub-claude has produced so far.
4. **When the task completes**, do a final `TaskOutput` call to get the remaining output.

This gives the user visibility into the review as it progresses, without any extra tools in the pipeline.

## Commands

### Code Review

```bash
# Review current branch against main (with --allowedTools, prompt via stdin)
echo 'Review the changes on this branch compared to main. Run `git diff main...HEAD` to see the full diff. Be a strict reviewer: check for correctness, edge cases, security issues, and code clarity. Reference specific files and lines.' \
  | claude -p --max-turns 3 --no-session-persistence \
    --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1

# Review only uncommitted changes
echo 'Review all uncommitted changes (run `git diff` and `git diff --cached`). Check for correctness, edge cases, and code clarity. Be specific with file:line references.' \
  | claude -p --max-turns 3 --no-session-persistence \
    --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1
```

For simpler reviews without tool restrictions, pass the prompt directly:

```bash
# No --allowedTools needed — prompt as positional arg
claude -p --max-turns 3 --no-session-persistence \
  'Review the changes on this branch vs main. Focus on error handling and security. Run `git diff main...HEAD`.' \
  2>&1
```

### Custom Prompted Review

```bash
# Review a plan or design document
echo 'Review the plan in PLAN.md. Be a strict critic: identify gaps, missing edge cases, and over-engineering. Suggest concrete improvements.' \
  | claude -p --max-turns 3 --no-session-persistence \
    --allowedTools "Read" "Glob" "Grep" 2>&1

# Deep exploration for blind spots
echo 'Explore the codebase for inconsistencies, dead code, and simplification opportunities. Focus on the src/api/ directory.' \
  | claude -p --max-turns 5 --no-session-persistence \
    --allowedTools "Read" "Glob" "Grep" 2>&1
```

### Prompt-Only Review (No File Access)

When passing content inline (e.g., a diff):

```bash
# Write the prompt to a temp file
cat > /tmp/claude-prompt.txt << 'EOF'
Review this diff for correctness, edge cases, and clarity:

<diff content here>
EOF

# Run with no tools — single-turn text response
claude -p --tools "" --max-turns 1 --no-session-persistence \
  < /tmp/claude-prompt.txt 2>&1
```

### Iterative Review

```bash
# First pass
echo 'Review the changes on this branch compared to main. Run `git diff main...HEAD`. List all problems.' \
  | claude -p --max-turns 3 --no-session-persistence \
    --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1

# Fix issues, then re-run until clean
```

## Workflow Patterns

### Pre-push Quality Gate

After completing implementation and before pushing:

1. Run the review with `run_in_background: true`
2. Poll `TaskOutput` with `block: false` every 10-15s, showing partial output to the user
3. When complete, read the full review output
4. Fix any issues raised
5. Re-run the review until clean
6. Push

### Plan Counter-Review

1. Write the plan
2. Run the review with `--allowedTools "Read" "Glob" "Grep"`
3. Revise the plan based on feedback
4. Re-run until claude agrees with the plan
5. Proceed with implementation

### Deep Dig

```bash
echo 'Do a deep dig of src/. Find blind spots, interesting things to fix, and things to simplify. Be specific with file:line references.' \
  | claude -p --max-turns 5 --no-session-persistence \
    --allowedTools "Read" "Glob" "Grep" 2>&1
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

- **Nested sessions.** If Claude Code detects it is already running inside another Claude Code session (via the `CLAUDE_CODE` env var), it will refuse to start.
- **`--allowedTools` is variadic.** It consumes all subsequent positional arguments. When using it, always pipe the prompt via stdin.
- **Long prompts.** Write to a temp file and use `< /tmp/claude-prompt.txt` stdin redirect. Do not use inline HEREDOCs.

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

# BAD: Foreground without timeout increase — will timeout and lose output
# Instead, use run_in_background: true and poll with TaskOutput
```

## Tips

- **Be pointed in prompts.** Vague prompts get vague reviews. Tell claude exactly what to focus on and what format you want the response in.
- **Use `--allowedTools`** for read-only reviews instead of `--permission-mode plan`.
- **Pipe the prompt** when using `--allowedTools` — it's a variadic flag that eats positional args.
- **Poll for progress.** Use `run_in_background: true` + `TaskOutput` with `block: false` to show incremental output.
- **Iterate.** Don't treat the first review as final — run it again after fixes to catch regressions or new issues.
- **Model override.** Use `--model sonnet` for faster reviews, `--model opus` for deeper analysis.
