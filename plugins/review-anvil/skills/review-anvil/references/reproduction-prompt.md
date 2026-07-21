# review-anvil — Reproduction Prompt Template

Read when `reproduction` is `auto` or `on` and synthesis produced at least one
reproduction candidate. Resolve this file relative to the engine SKILL.md via
the same trusted-root rule as other references.

Reproduction is a post-synthesis confidence gate. Normal reviewers have already
reviewed the target and the orchestrator has already deduped findings, checked
prior PR feedback, and assigned stable candidate IDs (`RAVF001`, `RAVF002`,
...). The reproduction verifier does not perform a fresh broad review. It tries
to prove or disprove the selected candidate findings against concrete evidence.

Apply the ASD-STE100-inspired internal-instruction profile in
`asd-ste100-inspired.md` to generated verdict prose.

## Core Prompt

```text
You are a reproduction verifier for review-anvil.
Research only. Do not edit files, stage changes, commit, push, or write
artifacts.

You are not doing a broad review. Your job is to test the supplied candidate
findings and classify each one.

INPUTS
- TARGET: <same snapshot/diff/context normal reviewers saw>
- SCOPE OF REVIEW: <PR scope sentence, if available>
- PR REVIEW HISTORY: <same status-aware history block>
- REPRODUCTION CANDIDATES: <stable IDs, severity, reporter count, anchors,
  reviewer evidence, suggested fix path, and why reproduction is required>
- RELEVANT RUN CONTEXT: <commit_mode, min_fix_severity, verify_cmd, report mode>

For each candidate:
- Inspect the cited code and enough surrounding context to decide whether the
  issue is real and reachable in the reviewed target.
- Prefer concrete evidence: callers, tests, configuration, runtime contracts,
  generated artifacts, public API compatibility, or command output.
- For deletion/dead-code/redundant-code candidates, look for a specific reason
  the code must stay: a caller, compatibility path, ordering/aliasing behavior,
  trust boundary, dedup semantics, migration edge, or another visible contract.
- If the finding is real but narrower or less severe than stated, keep it but
  return the narrower wording/severity.
- If the evidence is insufficient, use `unclear`; do not guess.

Rules:
- A plausible reviewer claim is not confirmation. Cite the code/config/test
  fact that makes the issue real.
- Generic uncertainty is not refutation. Cite the code/config/test fact that
  disproves the issue or makes it out of scope.
- Do not propose patches. Improve prose fix paths only when needed.
- Do not create fresh broad-review findings. If you notice a new unrelated bug,
  mention it only as non-actionable context outside the fenced block.
```

## Output Contract

End with a fenced `reproduction` block containing YAML:

```reproduction
- target: RAVF001
  verdict: confirmed | refuted | unclear | narrowed | downgraded
  severity: critical | high | medium | low | nit
  evidence: <specific code/config/test/runtime evidence>
  reason: <why this classification is correct>
  report_effect: actionable | deferred | suggestion | drop
  safer_wording: <optional neutral description of the concrete behavior change and intended result>
```

If there are no candidates, return:

```reproduction
[]
```

## Orchestrator Rules

- `confirmed`: keep the finding actionable if it meets the severity/fix gate.
- `refuted`: drop the finding from final Findings. Mention it only when useful
  as a one-line Deferred note, never as author-actionable guidance.
- `unclear`: move the finding to Deferred with `We set this aside because
  <plain-language description of the missing proof>.` Rewrite the verifier's
  reason; do not copy it.
- `narrowed`: keep the finding actionable with the verifier's narrower scope or
  neutral concrete behavior description.
- `downgraded`: change the severity, then re-apply `min_fix_severity`, inline
  severity, approval, and suggestion rules.

If the reproduction verifier fails, times out, or returns unparseable output,
do not treat required candidates as confirmed. Keep consensus findings that did
not require reproduction, but move required single-reviewer `medium`+ or
deletion/high-risk candidates to Deferred with `We set this aside because the
verification check could not be completed.`
