You are a strict independent reviewer. Do not call tools. Read the complete attached skill and contract files.

Review only the inline-comment readability and author-work classification contract. It must make comments easier to scan while preserving every technical fact and every author obligation.

Required invariants:
- target behavior and required verification/documentation are explicit author requests;
- accepted current behavior, allowed implementation boundaries, and explicitly optional follow-ups remain modal prose;
- modal words alone never decide the class;
- mixed predicates are split; no fallback leaves required work implicit;
- a required purpose, result, or safety clause stays attached to the mechanism it constrains;
- accepted current behavior and optional follow-ups both have explicit standalone rendering paths.

Stress-test these source patterns:
1. `A mismatched-source test would cover this path.` Required verification, not optional.
2. `Unresolved keys can be reported after valid metrics are preserved.` Preserve valid metrics is author work; reporting unresolved keys afterward is permission.
3. `Expected 401 responses can keep their current handling.` Acceptable unchanged behavior.
4. `Support both tags and branches so a local failure cannot delete output.` One obligation containing the mechanism and output-safety result.
5. `A note plus this example would make the placement limit clear.` Both documentation items are requested work.
6. `Optionally add a benchmark.` Explicitly optional standalone modal prose.

Return:
- Verdict: approve or changes requested.
- Findings ordered by severity with exact rule quotations.
- A six-row table with expected classification and whether the complete attached rules force it unambiguously.
- Any contradiction, precedence gap, or readability regression.
If there are no material findings, say so explicitly.
