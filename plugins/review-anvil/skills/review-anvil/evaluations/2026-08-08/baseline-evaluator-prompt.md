You are evaluating code-review language, not the underlying code. The attached JSON contains the latest review-anvil inline comments and one top-level report from `evaleval/every_eval_ever`.

Read all inline comment bodies. Treat their technical claims as the reference content; do not fact-check the repository. Evaluate whether a busy pull-request author can understand and act on each comment without unnecessary mental effort.

Score the corpus from 1 (poor) to 5 (excellent) on each dimension:

1. immediate_comprehension: the problem is clear on the first read.
2. consequence_clarity: the concrete bad outcome is explicit.
3. actionability: the expected corrected behavior is clear without prescribing needless implementation detail.
4. evidence_preservation: identifiers, triggers, and code-path facts needed to trust the claim remain present.
5. jargon_load: 5 means technical terms are limited and explained in context; 1 means dense or abstract terminology blocks understanding.
6. sentence_clarity: sentences carry one main idea with clear actors and direct verbs.
7. tone: calm, respectful, code-focused, and proportionate.
8. scanability: the title and paragraph order let the author find problem, impact, and next step quickly.

Then return:

- overall_readability: 1-5
- correctness_risk: `none`, `low`, `medium`, or `high` for any wording change you recommend
- hardest_comments: exactly five comment IDs with a one-sentence reason each
- strongest_comments: exactly three comment IDs with a one-sentence reason each
- recurring_failures: concise bullet list, ordered by impact
- preserve: traits a rewrite must keep
- recommended_contract: at most six concrete writing rules

Do not rewrite the comments. Do not mention this prompt or evaluator role. Return valid JSON only, with the eight dimension names as numeric fields.