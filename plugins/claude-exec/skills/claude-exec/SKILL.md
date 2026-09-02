---
name: claude-exec
description: Delegate code review, plan review, and exploration to Claude Code CLI. Use when you need an independent second opinion on code changes, plans, or architecture — or when asked to run claude review/exec.
---

# Claude Exec — Cross-Agent Delegation

Delegate review and exploration tasks to an **independent Claude sub-agent** for a second opinion. The sub-agent acts as a strict counter-reviewer that catches blind spots you might miss.

## When Not to Use

Skip this skill when you are confident in the output and the user hasn't asked for a second opinion. Reserve it for quality gates and deliberate review steps.

## How It Works

> **In Claude Code, ALWAYS use the Agent tool. Do not shell out to `claude -p`.** The Bash-`claude -p` path is the cross-agent fallback for environments without the Agent tool (Codex CLI, Cursor, OpenCode, …) — it is NOT a shortcut from inside Claude Code itself.

**If the Agent tool is available** (Claude Code): use it. The Agent tool streams output natively (the user sees progress as the sub-agent works, with no buffering), has **no artificial `--max-turns` ceiling**, and inherits the running session's environment without spawning a new claude process. The CLI fallback has none of those properties.

**If the Agent tool is NOT available** (Codex CLI, other non-Claude environments): fall back to `claude -p` via the Bash tool. See the [CLI Fallback](#cli-fallback) section for the correct invocation pattern.

---

## Agent Tool (Preferred)

### Invocation Rules

1. **Set `subagent_type` to `"general-purpose"`** — this gives the sub-agent access to Read, Glob, Grep, and Bash for exploring the codebase.
2. **Include "research only" in the prompt** when you want a review without modifications. Tell the sub-agent explicitly not to edit files.
3. **Use `run_in_background: true`** on the Agent tool call if you have other work to do while the review runs.

### Commands

#### Code Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review branch changes"
  prompt: "You are a strict code reviewer. Review the changes on this branch compared to main. Run `git diff main...HEAD` to see the full diff. Check for correctness, edge cases, security issues, and code clarity. Reference specific files and lines. Research only: do not edit any files."
```

#### Uncommitted Changes Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review uncommitted changes"
  prompt: "You are a strict code reviewer. Review all uncommitted changes (run `git diff` and `git diff --cached`). Check for correctness, edge cases, and code clarity. Be specific with file:line references. Research only: do not edit any files."
```

#### Plan Review

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Review implementation plan"
  prompt: "You are a strict plan reviewer. Read the plan in PLAN.md. Be a strict critic: identify gaps, missing edge cases, wrong assumptions, and over-engineering. Suggest concrete improvements. Research only: do not edit any files."
```

#### Deep Dig / Exploration

```
Agent tool call:
  subagent_type: "general-purpose"
  description: "Deep codebase exploration"
  prompt: "Explore the codebase for inconsistencies, dead code, and simplification opportunities. Focus on the src/ directory. Be specific with file:line references. Research only: do not edit any files."
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
| `prompt` | The review instructions |
| `run_in_background: true` | Run review while you continue other work |
| `model` | Optional override; the sub-agent otherwise inherits the session's model, which is the right default for a review |

---

## CLI Fallback

Use this when the Agent tool is not available (e.g., Codex, other non-Claude environments).

### Invocation Rules

1. **Never use `--permission-mode plan`.** It redirects output to an internal plan file instead of stdout, producing empty or 1-line output. Use `--permission-mode dontAsk` for non-interactive locked-down runs: allowed/read-only actions proceed, and anything else is denied instead of prompting.
2. **Use `--tools` to restrict built-in tools; use `--allowedTools` to auto-approve the permitted commands.** `--allowedTools` does not define the available built-in tool set by itself. Pair both flags when a fallback reviewer may read files or run safe commands.
3. **Set `--max-turns` as a backstop, never as an effort estimate.** A sub-claude that hits the turn cap mid-investigation returns "Reached max turns" with no findings — its entire run is wasted, which is strictly worse than letting it take longer. Task-sized caps keep biting in practice, and even 20 was hit in production by review-anvil reviewers reading callers and tests around a diff. So:
   - **Prompt-only review (no file access)**: `--tools "" --max-turns 1` — the one case where a tight cap is correct.
   - **Anything that explores files** (diff review, codebase exploration): `--max-turns 100`. This is a runaway-loop backstop that should never bind on legitimate work. Bound the run's *duration* with a wall-clock watchdog (Rule 10), not with turns.
   - There's no cost to a generous ceiling that's never hit; there's total cost to a tight one that is.
4. **Pin `--output-format text` while the caller expects a Markdown report.** JSON and stream-json are useful for future telemetry, but wrappers that read the final answer from stdout must opt into the text contract explicitly.
5. **When using `--allowedTools`, pipe the prompt via stdin** — `--allowedTools` is a variadic flag that consumes all subsequent positional arguments, including the prompt. Use `echo 'prompt' | claude -p ...`.
6. **When NOT using `--allowedTools`, pass the prompt as a positional argument** — `--allowedTools` is the flag that makes stdin necessary. Keep the generous turn backstop for file-exploring reviews.
7. **Always add `2>&1`** at the end of the command to capture stderr alongside stdout.
8. **Always use `--no-session-persistence`** to avoid littering the user's session history with sub-agent sessions.
9. **Write long prompts to a temp file** and pass via stdin redirect (`< /tmp/claude-prompt.txt`). Do not use inline HEREDOCs like `$(cat <<'EOF'...)` — they break in some shell environments.
10. **Never background a bare `claude -p ... > out.md 2>&1` and wait on the file.** In `-p` text mode nothing is printed until the final answer, so the output file sits at 0 bytes whether the run is working, hung, or dead — a production review-anvil run waited many minutes on exactly that. Run it under a watchdog with a hard timeout, check the exit status afterwards, and **treat an empty output file as an explicit failure**, not something to keep waiting on. The review-anvil engine ships the canonical wrapper (`review-anvil/scripts/run-reviewer.sh`: hard timeout → TERM/KILL, `STATUS=ok|timeout|empty|failed` classification, stderr kept in `<out>.err`); reuse it, or replicate its contract with `timeout <secs> claude -p ...` plus an exit-status and non-empty-output check.

### Commands

```bash
# Branch / PR diff review
echo 'Review the changes on this branch compared to main. Run `git diff main...HEAD` to see the full diff. Be a strict reviewer: check for correctness, edge cases, security issues, and code clarity. Reference specific files and lines.' \
  | claude -p --max-turns 100 --no-session-persistence \
    --permission-mode dontAsk --output-format text \
    --tools "Bash,Read,Glob,Grep" \
    --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1

# Quick focused review
echo 'Review the changes on this branch vs main. Focus on error handling and security. Run `git diff main...HEAD`.' \
  | claude -p --max-turns 100 --no-session-persistence \
    --permission-mode dontAsk --output-format text \
    --tools "Bash,Read,Glob,Grep" \
    --allowedTools "Bash(git:*)" "Read" "Glob" "Grep" 2>&1

# Prompt-only review — no file access, single-turn response
claude -p --tools "" --max-turns 1 --no-session-persistence \
  --permission-mode dontAsk --output-format text \
  'Review this diff for correctness...' 2>&1
```

### CLI Options

| Flag | Purpose |
|---|---|
| `-p, --print` | Non-interactive mode — print response and exit (required for delegation) |
| `--model <model>` | Optional model override; omit to use the CLI default |
| `--max-turns <n>` | Turn-cap backstop. Use 1 for prompt-only, 100 for anything that explores files (see Invocation Rule 3) |
| `--tools "..."` | Restrict the available built-in tools; use `""` to disable all tools |
| `--allowedTools "..."` | Auto-approve matching tool uses. **Variadic — must pipe prompt via stdin when used** |
| `--permission-mode dontAsk` | Non-interactive locked-down mode: deny anything outside the allowed/read-only path instead of prompting |
| `--output-format text` | Explicitly emit the Markdown/text report expected by the wrapper |
| `--no-session-persistence` | Don't save the sub-agent session to disk |

---

## Workflow Patterns

Use the review as a gate: run it before pushing code or acting on a plan, fix or revise what it raises, and re-run until it comes back clean.

## Tips

- **Use "research only"** in the prompt to prevent the sub-agent from editing files during review.
- **Run in parallel.** Multiple independent reviews can run simultaneously (Agent tool: multiple calls in one message; CLI: multiple background processes).
