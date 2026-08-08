# Iteration 5 assessment — reader-first requested work

## Question

Can the selected `104debc` contract make requested work more direct—especially
phrases such as “can stay explicit exclusions”—without changing technical
facts, scope, or behavioral boundaries?

## Design

- Frozen baseline: the 22 production comments selected at `104debc`.
- Clean generator: GPT-5.6 Sol with no session, tools, skills, or rules.
- Blind evaluators: independent GPT-5.6 Sol, Luna, and Terra agents. Candidate
  labels were randomized per comment.
- Fact gate: every identifier, trigger, condition, exception, relationship,
  quantifier, diagnostic modality, and requested obligation had to remain.
- Readability gate: defect clarity, requested-action recall, scanability,
  naturalness, and cognitive ease.
- Design criticism: three clean OMP agents independently reviewed the proposed
  contract. Claude CLI was also attempted, but its API authentication failed
  before it produced a critique.

## Iterations

1. Forced one `Please` sentence per requested action. This made every action
   visible but created repetitive, robotic lists and sometimes split one rule
   into several apparent obligations.
2. Added a `**Requested actions**` list for multi-action findings. Readability
   improved, but grammar-based splitting could still separate one coherent
   validation rule.
3. Grouped by cohesive implementation obligation rather than sentence or
   clause. Kept conditions and exceptions with the action they constrain.
4. Restored exact source scope phrases after the fact gate exposed unsafe
   narrowing in otherwise clearer rewrites.

## Final results

All three fact evaluators marked all three randomized versions fact-safe for
all 22 comments: **66/66 judgments for the candidate and 66/66 for each
comparison version**.

Across 66 blind readability judgments comparing the final candidate with the
`104debc` baseline:

| Result | Count |
|---|---:|
| Candidate wins | 39 |
| Baseline wins | 5 |
| Ties | 22 |

Mean scores on the five-point scale:

| Version | Defect clarity | Action recall | Scanability | Naturalness | Cognitive ease |
|---|---:|---:|---:|---:|---:|
| `104debc` baseline | 4.970 | 4.455 | 4.379 | 4.758 | 4.394 |
| Iteration 5 | 4.970 | 4.939 | 4.879 | 4.848 | 4.864 |

Defect clarity stayed equal. The candidate gained most in requested-action
recall (+0.484), scanability (+0.500), and cognitive ease (+0.470).

## Representative change

Before:

> A file with measured but unconvertible tasks can enter the failure ledger.
> Files containing only intentionally skipped derived rows can stay explicit
> exclusions.

After:

> **Requested actions**
>
> - Put a file with measured but unconvertible tasks in the failure ledger.
> - Keep files containing only intentionally skipped derived rows as explicit
>   exclusions.

The final wording states who or what changes, preserves “intentionally skipped
derived rows,” and leaves no ambiguity about whether the text is a request or
current behavior.

## Decision

Keep the iteration. It improves the reader-visible action boundary while
preserving the already-selected problem → consequence structure and private
fact lock.

Production rules now require:

- one concise `Please` sentence for one obligation;
- `**Requested actions**` plus one direct-action bullet per independently
  implementable obligation;
- grouping by implementation obligation, not grammar;
- conditions and exceptions attached to the actions they constrain;
- exact source wording for scope and collection phrases;
- no invented tests, destinations, actors, or already-implemented fixes.

## Limits and next check

The final comparison reused the fixed 22-comment source corpus so it measures
language changes rather than finding selection. A later genuinely unseen PR
corpus should test whether the same action grouping generalizes to new domains.
The local GitHub reads identified unseen historical candidates, but no unseen
holdout result is claimed here.
