## Verification of the seven fixes

| Ask (verification IDs) | Status in the current tree |
|---|---|
| Bidirectional source/rendered ledgers (A3) | Fixed — `references/action-lock-audit.md:76-80` ("build source-to-rendered and rendered-to-source predicate ledgers… `pass` only when both ledgers are complete and mapped correctly"); pinned at `scripts/test-report-language.sh:199,223-224` |
| Direction-specific invention vs. fact-loss buckets (B7) | Fixed — rule 8 at `action-lock-audit.md:70-74`, restated at `:132-134`, new `invented_predicates` array at `:119`, `pass` gate updated to "all four issue arrays" at `:129` and `:138-139` |
| Full source material + formatting-metadata scope (A5) | Fixed — freeze extended to titles, diagnostics, evidence phrases and source code/suggestion fragments at `action-lock-audit.md:9-13` and `SKILL.md:515`; label/Markdown exemption at `action-lock-audit.md:68`; `source_context` may confirm rendered evidence/code at `:30-31` |
| Byte identity with fallback exemption (A4) | Fixed in all three places — `action-lock-audit.md:166-169`, `SKILL.md:515`, `references/report-artifacts.md:28-31` |
| Canonical nonnumeric audit IDs + verbatim echo (B10) | Fixed — `action-lock-audit.md:16-18` (`AUDIT:` prefix for digits-only IDs), `:42-43` (opaque, never reformat), `:138-140` (no type coercion, per-row protocol errors) |
| Safe suggestion preservation in engine and voice reference (B11) | Fixed — `SKILL.md:503` now subordinates preservation to "every safety exclusion in the next sentence"; counterpart added at `report-artifacts.md:65-66` |
| Assessment disclosure and review history (B13) | Mostly — `evaluations/2026-08-08/iteration-13-assessment.md:196-219` records all three reviews and the fixes, and `:121-123` now points the suggestion-block loss at the new rule; residual gaps below |

Downstream enforcement of the fallback is real, not just prose: `skills/review-anvil-pr/scripts/pr-helper.sh:1476-1483` downgrades `APPROVE` when `approval_allowed == false`, which `SKILL.md:531,533` now set after a fallback.

## Critical

none

## Important

**`references/action-lock-audit.md:29` — the sentence carrying the whole-body audit rationale is truncated mid-clause.**
The line reads `Do not extract or summarize a request-only subset. The auditors need the whole` and then runs straight into `Use \`source_context\` only to resolve antecedents…` at `:30` with no object, no period, and no blank line. The intended object (the complete rendered body) is missing, and the paragraph now merges a renderer-facing input rule with an auditor-facing scope rule. This is the same defect class the branch fixed as `iteration-13-assessment.md:200-202` (a literal ellipsis truncating the low/nit severity rule), in the file that defines the gate. The language contract does not catch it: `scripts/test-report-language.sh:190` pins only the first sentence. The normative requirement survives elsewhere (`action-lock-audit.md:25` `"rendered_body": "<exact complete inline body>"`, rule 7 at `:64`, `SKILL.md:515`), so this is a documentation defect rather than a contract hole — but it ships in a prompt-source reference.

## Minor

- **`references/action-lock-audit.md:150-152` vs. `:70-74`** — repair is constrained to leave "the title, diagnosis, evidence, severity, complete ID" unchanged, but the new `invented_predicates` bucket routes source-free *evidence* claims to a failed verdict. A row that fails only on invented evidence has no permitted repair, so it burns the second wave and lands on exact-source fallback plus forced COMMENT. Safe direction, unnecessary cost; either exempt invented evidence from the no-change list or say explicitly that removing a source-free evidence predicate is the repair.
- **`evaluations/2026-08-08/iteration-13-assessment.md:215`** — "Language-contract assertions cover these invariants" is broader than the script. Pinned: ledgers (`test-report-language.sh:199,223-224`), metadata exemption (`:201`), ID echo (`:196,202`), row validation (`:197`), byte identity/exemption (`:203-204`), suggestions (`:193,205-206`). Not pinned: the bucket *rules* at `action-lock-audit.md:70-74,132-134` (only the schema key `"invented_predicates"` at `test-report-language.sh:200`), and the extended freeze sentence at `action-lock-audit.md:10-12` / `SKILL.md:515` ("the exact evidence and code fragments that the body may retain").
- **`evaluations/2026-08-08/iteration-13-assessment.md:196-219`** — the section states what the branch now does but never states that nothing from the three reviews remains open, and does not record the disposition of the recheck's and verification's Minor items (B7–B13). That was the outstanding half of B13.
- **`evaluations/2026-08-08/iteration-13-final-contract-finalcheck-claude.md` and `.md.err`** — both are zero bytes (aborted run), untracked, and referenced by neither `iteration-13-assessment.md:246-262` nor any other file, while `iteration-13-final-contract-finalcheck-prompt.md` is present. Rerun or drop the empty pair before committing the evaluation set.
- **`references/action-lock-audit.md:150`** — 100 columns, the only line in the file over 80 (B12's fill-style point; the paragraph-merge half is folded into the Important finding above). Also `:23` describes `source_context` as "`<exact source prose used by the rendered body>`" while `:10-12` requires it to carry code and suggestion fragments — "prose" undersells the field.

## Verdict

Keep the branch. A3–A5 and B7–B13 are all implemented in the shipped files, with matching `require`/`reject` assertions for the load-bearing ones, and the fallback path is enforced end-to-end into `pr-helper.sh`. Fix `action-lock-audit.md:29` before committing — it is a one-line completion in the gate's own reference, and the current text reads as a mid-sentence cut. The remaining items are documentation and evidence-hygiene cleanups; none blocks the branch. I did not run `scripts/test-report-language.sh` (research-only); I spot-checked the 20 new literals at `:184-210` against the current files under `grep -Fq` semantics and all are present.
