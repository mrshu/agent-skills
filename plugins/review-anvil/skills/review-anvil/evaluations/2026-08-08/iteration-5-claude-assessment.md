# Iteration 5 — Claude Opus judge

## Method

Claude Code CLI 2.1.226 ran Claude Opus as a prompt-only, one-turn judge with
no tools or session persistence. It received the frozen, randomized
iteration-five fact and readability corpora and the same evaluator rubrics used
by the GPT-5.6 Sol, Luna, and Terra judges. Claude did not receive the label key,
model chronology, or version names.

Both CLI runs exited successfully. Their stderr files were empty.

## Fact preservation

Claude marked every randomized candidate fact-safe:

| Candidate label | Fact-safe judgments |
|---|---:|
| A | 22/22 |
| B | 22/22 |
| C | 22/22 |

It reported no fact losses. Its summary specifically confirmed preservation of
IDs, severities, mechanisms, quantifiers, diagnostic modality, file/row/run
scope, error-class boundaries, conditions, exceptions, and test boundaries.

## Readability

After decoding the per-comment randomized labels:

| Outcome | Count |
|---|---:|
| `104debc` baseline wins | 9 |
| Iteration-five `v4` wins | 6 |
| Ties | 7 |

Mean five-point scores:

| Version | Defect clarity | Action recall | Scanability | Naturalness | Cognitive ease |
|---|---:|---:|---:|---:|---:|
| `104debc` baseline | 4.182 | 3.818 | 3.818 | 4.091 | 3.909 |
| Iteration-five `v4` | 4.182 | 4.227 | 3.955 | 3.727 | 3.864 |

Claude agreed that the explicit action format materially improves requested-
action recall. It preferred `v4` when bullets exposed a real second deliverable,
especially a test that the baseline softened as “would cover this path.”

Claude preferred the baseline when `v4` turned an exception, permission, or
preservation of existing behavior into another imperative bullet. In those
cases, the heading implied extra author work and reduced naturalness. It also
preferred a separate constraint sentence over a semicolon appended to a long
request.

## Interpretation

This result qualifies the earlier three-judge recommendation rather than
invalidating it:

- Sol, Luna, and Terra collectively preferred `v4` in 39 of 66 judgments,
  preferred the baseline in 5, and tied 22.
- Claude preferred `v4` in 6 of 22, preferred the baseline in 9, and tied 7.
- Across all four judges, the totals are 45 `v4` wins, 14 baseline wins, and 29
  ties.
- All four fact gates found no material fact loss.

The strongest next contract is therefore hybrid:

1. Use `**Requested actions**` only for independently implementable work the
   author must perform.
2. Make required tests explicit actions instead of “would cover” commentary.
3. Do not turn a carve-out, allowed behavior, or no-change preservation into a
   separate action bullet.
4. Keep such constraints attached to the action they limit, or state them as
   short modal prose immediately after that action.

The current production contract intends this obligation-based grouping, but
the generated `v4` corpus shows that examples and negative checks need to make
the no-op distinction harder for generators to miss.
