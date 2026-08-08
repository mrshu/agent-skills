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
implementation obligation, not by grammar. Do not split values governed by one
rule. Keep a constraint or exception with the action it limits.
Use `Please` plus an action verb for one obligation. For two or more
independently implementable obligations, use `**Requested actions**` and one
direct-action bullet per obligation. Preserve suggestion grammar for low and
nit guidance.
Prefer a direct verb with a concrete target, condition, or destination.
Do not give a context-free command.

Apply these rules to generated prose only. Preserve quoted external output,
code, JSON, commands, Markdown fences, and fixed machine-readable fields.
