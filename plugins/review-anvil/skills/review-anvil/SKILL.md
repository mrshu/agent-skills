---
name: review-anvil
description: Iteratively refine code via N rounds of parallel subagent review and orchestrator-applied fixes. Use when the user says "let's do three rounds", "fix/review loop", "back-and-forth review", "iterative review", or asks to harden a change with multiple rounds of codex/claude review. Configurable rounds, agent count/mix, focus, and target.
---

# review-anvil — Iterative Multi-Agent Fix/Review Loop

Wrap a code change in **N rounds of parallel reviewer subagents + orchestrator-applied fixes**. Each round = (parallel review by M agents) → (you synthesize findings) → (you apply fixes, commit) → next round.

## How to Use

(parameters, parsing — Task 3)

## Default Mix Policy

(table — Task 3)

## Loop Mechanics

(6-step round procedure — Task 4)

## Reviewer Prompt Template

(context + task blocks — Task 5)

## Output Format

(final report + per-round status — Task 6)

## Edge Cases

(failure handling, target detection, parse fallback — Task 6)
