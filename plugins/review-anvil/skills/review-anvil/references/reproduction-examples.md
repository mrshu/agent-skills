# review-anvil — Reproduction Policy Examples

These examples are the canonical regression set for the reproduction gate in
the engine SKILL.md. They are intentionally small and deterministic: each case
describes the raw synthesized finding shape, whether it should enter the
batched reproduction verifier, and the final user-visible effect.

Run `scripts/test-reproduction-policy.sh` after changing the reproduction
policy, report fields, or verifier prompt.

| Case | Raw Finding Shape | Reproduction Candidate? | Verdict | Final Effect With `reproduction=auto` | Final Effect With `reproduction=off` | Why It Matters |
|---|---|---:|---|---|---|---|
| `single-reviewer-false-positive` | One reviewer raises a `medium` parser/doc claim that code evidence refutes. | yes | `refuted` | dropped | deferred: reproduction disabled | Removes plausible-but-wrong review noise before it reaches a PR. |
| `live-doc-drift` | One reviewer raises a `medium` docs/metadata drift claim; evidence confirms only a narrower live-doc issue. | yes | `narrowed` | actionable with narrower wording | deferred: reproduction disabled | Preserves a real issue while avoiding overbroad guidance. |
| `historical-doc-false-positive` | One reviewer cites archival design docs that are not current user-facing behavior. | no | none | dropped: out of scope | dropped: out of scope | Scope/artifact filtering should avoid spending verifier budget on archival provenance. |
| `dependency-doc-drift` | One reviewer finds live README/frontmatter dependency requirements out of sync with helper preflight. | yes | `confirmed` | actionable | deferred: reproduction disabled | Confirms a user-facing documentation defect with code evidence. |
| `delete-needed-compat-shim` | Reviewers propose deleting apparently redundant compatibility code. | yes | `refuted` | dropped | deferred: reproduction disabled | Deletion findings need extra skepticism even with reviewer confidence. |
| `delete-confirmed-dead-code` | Reviewers propose deleting code with no callers or contract, then tests must still gate the cut in `per_fix`. | yes | `confirmed` | actionable | deferred: reproduction disabled | Reproduction can approve the plan, but execution still protects `per_fix`. |
| `downgrade-to-low` | One reviewer raises a `medium` claim that is real but only a minor docs/style mismatch. | yes | `downgraded` | suggestion | deferred: reproduction disabled | Prevents low-impact items from crossing the auto-fix/actionable threshold. |
| `unclear-runtime-contract` | One reviewer raises a `high` runtime claim that cannot be confirmed from code/config/tests. | yes | `unclear` | deferred: failed reproduction | deferred: reproduction disabled | Makes uncertainty explicit instead of pretending confidence. |
| `consensus-medium-non-risk` | Two independent reviewers raise the same `medium` ordinary bug with concrete evidence. | no | none | actionable | actionable | Consensus should not pay the reproduction tax unless risk flags apply. |
| `low-nit-style` | One reviewer raises a `low` or `nit` style issue. | no | none | suggestion | suggestion | Low-priority feedback should not spend verifier budget. |
| `low-simplification` | One reviewer raises a `low` simplification that does not remove runtime/public-surface behavior. | no | none | suggestion | suggestion | Low-priority simplification should not bypass the low/nit skip rule. |
| `previously-dismissed` | A finding semantically matches dismissed PR feedback. | no | none | deferred: previously dismissed | deferred: previously dismissed | Dismissed-check filtering happens before reproduction. |
| `verifier-unavailable` | A required candidate exists but the reproduction verifier fails or returns unparseable output. | yes | verifier failure | deferred: verifier unavailable | deferred: reproduction disabled | A broken confidence gate must not silently promote findings. |

The examples deliberately include positive and negative cases. Reproduction is
for uncertain material claims, destructive/high-risk guidance, and
orchestrator uncertainty. It is not a second broad review pass, not a substitute
for dismissed-feedback handling, and not a reason to re-check every low-priority
note.
