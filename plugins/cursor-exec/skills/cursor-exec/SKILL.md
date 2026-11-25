---
name: cursor-exec
description: Delegate code review, plan review, and exploration to Cursor Agent CLI. Use for an independent second opinion on code changes, plans, or architecture, or when asked to run Cursor Agent.
---

# Cursor Exec — Cross-Agent Delegation

Use Cursor Agent CLI for an independent review or focused exploration. Reserve
it for deliberate second opinions and quality gates, or when the user asks.

## Setup and boundaries

Use the standalone `agent` CLI (also installed as `cursor-agent` on some
systems), not the `cursor` editor command. Check `agent --help` and
`agent status` if the CLI or authentication is uncertain. See the [Cursor CLI
docs](https://cursor.com/docs/cli/overview) for installation and authentication.
Use the configured default model; pass `--model` only when the user requests a
specific model.

For reviews use `-p --mode ask --output-format text`. Cursor documents Ask mode
for exploration without file edits; `-p` alone can edit files and run allowed
commands. Do not add `--force`, `--yolo`, `--trust`, or `--approve-mcps` just
to make a review run. If headless mode reports that workspace trust is
required, trust it interactively or use `--trust` only after independently
choosing to trust that workspace. Ask mode and `--workspace` are not OS
isolation. If a strict read-only boundary is required, run the CLI in an
independently confined environment. Cursor's `--sandbox enabled` governs shell execution and
can allow workspace writes, so it is not a read-only filesystem guarantee.

## Reviews and exploration

Run from the project directory, or specify `--workspace <project-dir>`. Define
the exact scope and request actionable findings with file and line references.
Cursor has no equivalent to `codex review --base`; describe the comparison in
the prompt. For example:

```bash
# Review committed branch changes against the merge base with main
agent -p --mode ask --output-format text \
  'Review the changes from the merge base of main and HEAD to HEAD. Find correctness bugs and regressions. Return findings with file:line references; do not edit files.'

# Review staged, unstaged, and untracked work
agent -p --mode ask --output-format text \
  'Review all staged and unstaged changes and the contents of untracked files. Find correctness bugs and regressions. Return findings with file:line references; do not edit files.'

# Critique a plan or explore an area of the codebase
agent -p --mode ask --output-format text \
  'Review PLAN.md for gaps and edge cases. Give concrete, prioritized feedback; do not edit files.'
agent -p --mode ask --output-format text \
  'Explore src/api/ for correctness issues and simplification opportunities. Cite file:line references; do not edit files.'
```

Ask mode may not be able to run Git commands. If the reviewer cannot access the
requested comparison, prepare the diff outside Cursor and provide it in a
readable file along with the relevant source context. For uncommitted reviews,
include untracked file contents explicitly; ordinary `git diff` omits them.
Ask the reviewer to report inaccessible inputs and treat an incomplete review
as a failure, not a clean result. Protect and remove any temporary diff file
when it is no longer needed.

For non-interactive prompts, state that the read-only review is already
authorized, ask the reviewer to begin immediately and return its completed
findings, and do not answer a plan or confirmation handshake in automation.
Inspect exit status and output; report errors, empty output, or incomplete
reviews rather than treating them as a successful review.

For an orchestrated review, when the review-anvil wrapper is available from a
trusted skill install, it can capture output and apply a timeout:

```bash
bash <review-anvil-wrapper> out.md 600 -- \
  agent -p --mode ask --output-format text --workspace <project-dir> '<prompt>'
```

The wrapper is `plugins/review-anvil/skills/review-anvil/scripts/run-reviewer.sh`.
It writes stdout to `out.md`, stderr to `out.md.err`, and reports
`STATUS=ok|timeout|empty|failed`. `ok` only means the process produced output;
check that the reviewer actually inspected the requested inputs. The wrapper
does not impose a read-only boundary.
