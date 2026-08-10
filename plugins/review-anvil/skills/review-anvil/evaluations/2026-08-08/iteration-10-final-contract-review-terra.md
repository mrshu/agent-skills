Working...
## Verdict: approve

No material findings. The attached rules make inline comments more scan-friendly without weakening technical facts or author obligations.

| Source pattern | Expected classification | Forced unambiguously? |
|---|---|---|
| `A mismatched-source test would cover this path.` | Required verification; explicit author-work request. | Yes |
| `Unresolved keys can be reported after valid metrics are preserved.` | Preserve valid metrics = author work. Reporting unresolved keys afterward = no-change permission. | Yes |
| `Expected 401 responses can keep their current handling.` | Accepted current behavior; standalone modal prose, not an action. | Yes |
| `Support both tags and branches so a local failure cannot delete output.` | One cohesive author obligation. Keep the output-safety result attached to the support mechanism. | Yes |
| `A note plus this example would make the placement limit clear.` | Two required documentation obligations; both must be explicit author requests. | Yes |
| `Optionally add a benchmark.` | Explicitly optional follow-up; standalone modal prose, not an action. | Yes |

## Findings

None.

The contract directly covers the required invariants:

- **Classification precedes rendering:** “**Classify every source predicate before rendering it**” and “**Apply the omission counterfactual only after that classification.**”
- **Author work cannot remain implicit:** “**Do not emit until every author-work predicate appears as an explicit request.**”
- **Modal wording is not decisive:** “**Source intent outranks modal grammar**” and “**`can`, `could`, and `would` do not make that work optional.**”
- **Mixed predicates must split:** “**Split every sentence that mixes author work with a no-change boundary. Classify each predicate separately; do not preserve an unsplit fallback.**”
- **Mechanism and safety result remain coupled:** “**Extract its smallest actor-action-target change without detaching a purpose, result, or safety clause that constrains that change.**”
- **Accepted behavior has a standalone path:** “**Preserve accepted current behavior as standalone modal prose.**”
- **Optional follow-ups have a standalone path:** “**Preserve a standalone optional follow-up as standalone modal prose after the required request, or after the consequence when no request exists.**”
- **Required tests and documentation remain author work:** “**A required source-backed test is author work**” and “**Treat source-backed verification or documentation stated to cover, demonstrate, clarify, or make a required boundary clear as author work unless it is explicitly optional.**”

The rules also include direct examples for the critical ambiguity cases:

- “**The test remains author work because the reviewer presents it as verification, even if the source says it ‘would cover’ the path.**”
- “**Please preserve valid metrics … After valid metrics are preserved, unresolved keys can be reported.**”

No contradiction, precedence gap, or readability regression found in the attached inline-comment classification and rendering contract.


Wall time: 65.91 seconds