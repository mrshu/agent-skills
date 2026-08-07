# Review-anvil readability research

## Corpus boundary

GitHub returned no review-anvil comments for 2026-08-08 UTC. The committed
corpus therefore uses the latest available run from 2026-08-07 UTC: 22 inline
comments across PRs #190, #197, #203, #204, #223, #226, #227, and #235, plus
the top-level report on #230. `corpus.json` preserves the exact text, anchors,
timestamps, and URLs.

## Measured baseline

Excluding the fixed finding label, the 22 inline comments average 54.3 words
and 3.8 sentences. The median is 51 words; the maximum is 82. Nine comments
contain a sentence longer than 20 words. Length alone is not the main failure:
several shorter comments still require rereading because they compress several
identifiers, conditions, and abstract data-model terms into one clause.

Repeated strengths to preserve:

- stable severity, area, and provenance labels;
- exact flags, fields, paths, functions, and trigger conditions;
- calm code-focused tone;
- concrete consequences such as data loss, duplicate identities, wrong paths,
  missing reports, and leaked credentials;
- fix guidance expressed as required behavior rather than a full design.

Repeated readability costs:

- abstract labels such as “source grain,” “score coverage,” “identity input,”
  and “schema deferral” appear before the concrete failure;
- a sentence often asks the reader to track two conditions, two identifiers,
  and a contrast at once;
- the expected behavior is sometimes stated through hedged constructions such
  as “A small follow-up could…” instead of naming the desired result;
- code terms are precise but are not always tied immediately to their role;
- some titles describe an implementation fact instead of the author-visible
  failure, so readers must read the whole body to learn why it matters.

## Evidence-backed guidance

1. Google’s code-review guidance says comments should address the code, explain
   the reason, label severity, and balance explicit direction with leaving the
   implementation to the author. This supports retaining evidence and outcome
   guidance without prescribing a patch.
   <https://google.github.io/eng-practices/review/reviewer/comments.html>
2. Google’s technical-writing course recommends one idea per sentence, short
   sentences, direct verbs, and removing extra words. It also warns that a
   split sentence can remain unclear if the underlying idea order is wrong.
   <https://developers.google.com/tech-writing/one/short-sentences>
3. Google’s active-voice guidance uses actor → verb → target because readers
   otherwise spend effort reconstructing who does what. For review comments,
   the actor is usually a function, field, command, or request path.
   <https://developers.google.com/tech-writing/one/active-voice>
4. Rahman, Codabux, and Roy studied 466,000 code-change-request comments from
   182 GitHub projects. Their classifier found author confusion after 24% of
   comments; unclear comments correlated with longer resolution and discussion.
   Lack of clarity and unclear rationale were the most common traits.
   <https://2025.msrconf.org/details/msr-2025-technical-papers/44/Investigating-the-Understandability-of-Review-Comments-on-Code-Change-Requests>
5. Bosu, Greiler, and Bird analyzed 1.5 million Microsoft review comments and
   found that review usefulness depends on the content and context of the
   feedback, not merely its presence. The result supports preserving concrete
   functional evidence while simplifying presentation.
   <https://www.microsoft.com/en-us/research/publication/characteristics-of-useful-code-reviews-an-empirical-study-at-microsoft/>
6. Nielsen Norman Group’s web-reading research reports that readers scan rather
   than read linearly and that concise, scannable text improves measured
   usability. GitHub inline comments should therefore front-load the failure
   and keep support in a predictable order.
   <https://www.nngroup.com/articles/how-users-read-on-the-web/>

## Experimental hypotheses

### H1 — Problem, impact, outcome recipe

A positive three-part recipe will outperform a prohibition list:

1. **Problem:** name the code behavior and trigger in one sentence.
2. **Impact:** name the concrete result in one or two sentences.
3. **Outcome:** state the corrected behavior in one sentence; add a test only
   when it defines an important boundary.

The title must state the failure, not an abstract category. This iteration does
not impose a hard character limit because exact identifiers can be long and
precision is a correctness requirement.

### H2 — Reduce concept introductions

Limit each sentence to one relationship between code concepts. Introduce a code
term only when the sentence says what role it has in the failure. Use one
minimal example when a path, count, or state transition is otherwise hard to
visualize.

### H3 — Evidence-first compression

Separate evidence needed to trust the finding from investigation history. Keep
the trigger, affected value, and bad result. Remove line-number narration,
review-process terms, repeated category labels, and test advice that does not
clarify the behavioral boundary.

## Evaluation design

- Generate each candidate from the same frozen corpus with fresh GPT-5.6 OMP
  agents that receive only the candidate language contract and source comments.
- Preserve complete IDs, severity, area, technical claim, anchors, and all facts
  needed to verify the claim.
- Randomize candidate order and labels for pairwise evaluation.
- Use fresh GPT-5.6 OMP evaluators with no tools, skills, rules, or session.
- Score immediate comprehension, consequence clarity, actionability, evidence,
  jargon load, sentence clarity, tone, and scanability separately.
- Reject an iteration if it improves readability by dropping a trigger,
  condition, identifier, consequence, or important valid-behavior boundary.
