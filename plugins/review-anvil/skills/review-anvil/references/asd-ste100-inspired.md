# ASD-STE100-Inspired Language Contract

Apply this contract to generated review-anvil prose at every layer. This includes
reviewer findings, verifier verdicts, reports, comments, presets, and
helper-authored messages.

This is **ASD-STE100-inspired, not ASD-STE100 compliant**. Formal compliance
also requires the official controlled dictionary and approved meanings.

- Use sentences of 20 words or fewer when practical. Split long sentences.
- State one fact or action in each sentence. State conditions before actions.
- Use short, everyday words and direct verbs. Use one term for one meaning.
- State evidence, limits, and next actions directly. Avoid vague qualifiers.
- Do not rewrite code identifiers, quoted diagnostics, URLs, or required protocol/schema tokens.

## Internal Instructions

Use active voice or a direct imperative. Name the actor when it matters.

## Author-Facing Reports and Comments

Use short active declarative sentences for problems and evidence.
For critical, high, and medium findings, group requested work by cohesive
implementation obligation, not by grammar. Classify every source predicate
before rendering it. Target behavior and required verification or
documentation are author work. Accepted current behavior, allowed
implementation boundaries, and explicitly optional follow-ups are no-change
boundaries. Apply the omission counterfactual only after that classification.
Source intent outranks modal grammar; `can`, `could`, and `would` do not make
target behavior optional. Classify every predicate in a sentence that mixes
author work with a no-change boundary. Keep a required purpose, result, or
safety clause with the action it constrains. Never turn acceptable unchanged
behavior, a permission, an exception, or an explicitly optional follow-up
into a separate action bullet. When accepted current behavior directly
constrains a requested change, keep it in that action sentence using
`without changing …` or `while keeping … unchanged`. Use short modal prose
after the action if one sentence would be dense. Preserve other accepted
current behavior and standalone optional follow-ups as standalone modal prose.
Treat a required source-backed test or document change as author work unless
it is explicitly optional.
Default to starting required work with its action verb. Keep one or two
cohesive obligations in one short prose paragraph. For three or more
independently implementable obligations, use one direct-action bullet per
obligation. A deliberate collaborative request may use a courtesy wrapper
sparingly when coordination or tone benefits. Never use one as a stock opener
throughout a review. Use question grammar only for a genuinely unresolved
choice. Preserve suggestion grammar for low and nit guidance.
Prefer a direct verb with a concrete target, condition, or destination.
Do not give a context-free command.

Apply these rules to generated prose only. Preserve quoted external output,
code, JSON, commands, Markdown fences, and fixed machine-readable fields.
