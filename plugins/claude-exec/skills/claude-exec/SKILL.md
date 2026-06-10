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

> **In Claude Code, ALWAYS use the Agent tool. Do not shell out to `claude -p`.** The Bash-`claude -p` path is the cross-agent fallback for environments without the Agent tool (Codex CLI, Cursor, OpenCode, …) — it is NOT a shortcut from inside Claude Code itself.

**If the Agent tool is available** (Claude Code): use it. The Agent tool streams output natively (the user sees progress as the sub-agent works, with no buffering), has **no artificial `--max-turns` ceiling**, and inherits the running session's environment without spawning a new claude process. The CLI fallback has none of those properties.

**If the Agent tool is NOT available** (Codex CLI, other non-Claude environments): fall back to `claude -p` via the Bash tool. See the [CLI Fallback](#cli-fallback) section for the correct invocation pattern.

---

## Agent Tool (Preferred)

### Invocation Rules

1. **Set `subagent_type` to `"general-purpose"`** — this gives the sub-agent access to Read, Glob, Grep, and Bash for exploring the codebase.
2. **Include "research only" in the prompt** when you want a review without modifications. Tell the sub-agent explicitly not to edit files.
3. **Be specific in prompts.** Tell the sub-agent exactly what to review, what to focus on, and what format you want the output in. Vague prompts get vague reviews.
4. **Use `run_in_background: true`** on the Agent tool call if you have other work to do while the review runs.

### Commands

#### Code Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review branch changes"
  prompt: "You are a strict code reviewer. Review the changes on this branch compared to main. Run `git diff main...HEAD` to see the full diff. Check for correctness, edge cases, security issues, and code clarity. Reference specific files and lines. IMPORTANT: Research only — do not edit any files."
```

#### Uncommitted Changes Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review uncommitted changes"
  prompt: "You are a strict code reviewer. Review all uncommitted changes (run `git diff` and `git diff --cached`). Check for correctness, edge cases, and code clarity. Be specific with file:line references. IMPORTANT: Research only — do not edit any files."
```

#### Plan Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review implementation plan"
  prompt: "You are a strict plan reviewer. Read the plan in PLAN.md. Be a strict critic: identify gaps, missing edge cases, wrong assumptions, and over-engineering. Suggest concrete improvements. IMPORTANT: Research only — do not edit any files."
```

#### Deep Dig / Exploration

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Deep codebase exploration"
  prompt: "Explore the codebase for inconsistencies, dead code, and simplification opportunities. Focus on the src/ directory. Be specific with file:line references. IMPORTANT: Research only — do not edit any files."
```

#### Parallel Reviews

Use multiple Agent calls in a single message for independent reviews:

```
Agent call 1:
  description: "Review API changes"
  prompt: "Review changes in src/api/ on this branch vs main..."

Agent call 2:
  description: "Review test coverage"
  prompt: "Check test coverage for changes on this branch vs main..."
```

### Options

| Parameter | Purpose |
|---|---|
| `subagent_type: "general-purpose"` | Gives sub-agent access to Read, Glob, Grep, Bash |
| `description` | Short label shown to the user (3-5 words) |
| `prompt` | The review instructions — be specific |
| `run_in_background: true` | Run review while you continue other work |
| `model: "sonnet"` or `model: "opus"` | Override model for speed vs depth |

---

## CLI Fallback

Use this when the Agent tool is not available (e.g., Codex, other non-Claude environments).

### Invocation Rules

1. **Never use `--permission-mode plan`.** It redirects output to an internal plan file instead of stdout, producing empty or 1-line output. Use `--allowedTools` to restrict tools instead.
2. **Set `--max-turns` as a backstop, never as an effort estimate.** A sub-claude that hits the turn cap mid-investigation returns "Reached max turns" with no findings — its entire run is wasted, which is strictly worse than letting it take longer. Task-sized caps keep biting in practice: the default 8 in some setups is far too low, and even 20 was hit in production by review-anvil reviewers reading callers and tests around a diff. So:
   - **Prompt-only review (no file access)**: `--tools "" --max-turns 1` — the one case where a tight cap is correct.
   - **Anything that explores files** (diff review, codebase exploration): `--max-turns 100`. This is a runaway-loop backstop that should never bind on legitimate work, set explicitly only because some host setups default to 8. Bound the run's *duration* with a wall-clock watchdog (Rule 8), not with turns.
   - There's no cost to a generous ceiling that's never hit; there's total cost to a tight one that is.
3. **When using `--allowedTools`, pipe the prompt via stdin** — `--allowedTools` is a variadic flag that consumes all subsequent positional arguments, including the prompt. Use `echo 'prompt' | claude -p ...`.
4. **When NOT using `--allowedTools`, pass the prompt as a positional argument** — `claude -p --max-turns 20 'prompt'` works fine.
5. **Always add `2>&1`** at the end of the command to capture stderr alongside stdout.
6. **Always use `--no-session-persistence`** to avoid littering the user's session history with sub-agent sessions.
7. **Write long prompts to a temp file** and pass via stdin redirect (`< /tmp/claude-prompt.txt`). Do not use inline HEREDOCs like `$(cat <<'EOF'...)` — they break in some shell environments.
8. **Never background a bare `claude -p ... > out.md 2>&1` and wait on the file.** In `-p` text mode nothing is printed until the final answer, so the output file sits at 0 bytes whether the run is working, hung, or dead — a production review-anvil run waited many minutes on exactly that. Run it under a watchdog with a hard timeout, check the exit status afterwards, and **treat an empty output file as an explicit failure**, not something to keep waiting on. The review-anvil engine ships the canonical wrapper (`review-anvil/scripts/run-reviewer.sh`: hard timeout → TERM/KILL, `STATUS=ok|timeout|empty|failed` classification, stderr kept in `<out>.err`); reuse it, or replicate its contract with `timeout <secs> claude -p ...` plus an exit-status and non-empty-output check.

### Commands

```bash
# Branch / PR diff review — generous turn backstop, duration bounded by
# the watchdog (Rule 8), not by turns
echo 'Review the changes on this branch compared to main. Run `git diff main...HEAD` to see the full diff. Be a strict reviewer: check for correctness, edge cases, security issues, and code clarity. Reference specific files and lines.' \
  | claude -p --max-turns 100 --no-session-persistence \
    --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1

# Quick focused review — same backstop; a tight cap saves nothing and
# can throw the whole run away
claude -p --max-turns 100 --no-session-persistence \
  'Review the changes on this branch vs main. Focus on error handling and security. Run `git diff main...HEAD`.' \
  2>&1

# Prompt-only review — no file access, single-turn response
claude -p --tools "" --max-turns 1 --no-session-persistence \
  'Review this diff for correctness...' 2>&1
```

### CLI Anti-Patterns

```bash
# BAD: --permission-mode plan causes empty stdout
claude -p --permission-mode plan 'Review...'

# BAD: --allowedTools eats the positional prompt — prompt is lost
claude -p --allowedTools "Read Glob Grep" 'Review...'

# BAD: No --max-turns — some host setups default the cap to 8, which
# cuts a real review off mid-investigation
claude -p 'Review...'

# BAD: --max-turns sized to the task — any cap the run actually hits
# throws away the entire investigation ("Reached max turns", no findings).
# Caps are runaway backstops (100), not effort estimates (3, 20)
claude -p --max-turns 3 'Review this PR's full diff and synthesize findings'

# BAD: running claude -p from inside Claude Code itself — spawns a new
# claude process when the Agent tool would have streamed natively and
# had no max-turns limit
# (in Claude Code, use the Agent tool with subagent_type "general-purpose")

# BAD: HEREDOC expansion — breaks in Bash tool shell
claude -p "$(cat <<'EOF'
long prompt here
EOF
)"

# BAD: Missing 2>&1 — stderr errors are invisible
claude -p --max-turns 3 'Review...'

# BAD: backgrounded with output redirected to a file and no timeout —
# text mode prints nothing until the final answer, so a hung run and a
# working run both look like a 0-byte file; there is no signal to act on
claude -p --max-turns 20 ... < prompt.txt > out.md 2>&1 &
# (wrap in a watchdog instead — see Invocation Rule 8)
```

### CLI Options

| Flag | Purpose |
|---|---|
| `-p, --print` | Non-interactive mode — print response and exit (required for delegation) |
| `--model <model>` | Override model (e.g., `--model sonnet`, `--model opus`) |
| `--max-turns <n>` | Turn-cap backstop. Use 1 for prompt-only, 100 for anything that explores files (see Invocation Rule 2) |
| `--tools ""` | Disable all tools — forces a single-turn text response |
| `--allowedTools "..."` | Restrict to specific tools. **Variadic — must pipe prompt via stdin when used** |
| `--no-session-persistence` | Don't save the sub-agent session to disk |

---

## Workflow Patterns

### Pre-push Quality Gate

1. Run the review (Agent tool or CLI)
2. Read the review output carefully
3. Fix any issues raised
4. Re-run the review until clean
5. Push

### Plan Counter-Review

1. Write the plan
2. Run the review
3. Revise the plan based on feedback
4. Re-run until the reviewer agrees with the plan
5. Proceed with implementation

### Iterative Review

1. Run review
2. Fix issues found
3. Run another review to check remaining problems
4. Repeat until clean

## Tips

- **Be pointed in prompts.** Tell the reviewer exactly what to focus on and what format you want the response in.
- **Use "research only"** in the prompt to prevent the sub-agent from editing files during review.
- **Run in parallel.** Multiple independent reviews can run simultaneously (Agent tool: multiple calls in one message; CLI: multiple background processes).
- **Iterate.** Don't treat the first review as final — run it again after fixes to catch regressions.
- **Model override.** Use `sonnet` for faster reviews, `opus` for deeper analysis.
