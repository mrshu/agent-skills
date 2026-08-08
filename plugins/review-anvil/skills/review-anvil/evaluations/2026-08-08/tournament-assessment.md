# Blind tournament — baseline and iterations 1–3

Three fresh GPT-5.6 OMP agents ranked the baseline and all three generated
iterations. Candidate labels differed for Sol, Luna, and Terra. The original
comment was supplied separately as the technical reference.

| Evaluator | Baseline wins | Iteration 1 | Iteration 2 | Iteration 3 | Recommendation |
|---|---:|---:|---:|---:|---|
| GPT-5.6 Sol | 22 | 0 | 0 | 0 | baseline |
| GPT-5.6 Luna | 22 | 0 | 0 | 0 | baseline |
| GPT-5.6 Terra | 21 | 0 | 0 | 0 | baseline |

The tournament is intentionally stricter than the pairwise readability tests.
It made fact safety a prerequisite and used the original wording as the source
of truth. All generated candidates paraphrased or omitted at least one source
relationship in most comments, so the baseline won before readability could
decide the result.

This does not negate the 66/66 readability win for iteration 1 or the aggregate
wins for iterations 2 and 3. It identifies the remaining load-bearing failure:
free paraphrase is too lossy for technical review comments. The final hardening
step must therefore permit structure edits but prohibit lexical rewriting of
technical clauses. A candidate must retain an exact phrase for every locked
fact, while it may reorder clauses, split sentences, and remove only true
repetition or review-process narration.
