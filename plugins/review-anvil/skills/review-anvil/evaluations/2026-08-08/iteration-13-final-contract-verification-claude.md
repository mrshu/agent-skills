I read the diff, `SKILL.md`, both references, the language tests, the assessment, and both prior review files.

**Verification of the seven items**

| Ask | Status |
|---|---|
| Every rendered predicate mapped + bucketed | Mostly — rules 7–8 (`action-lock-audit.md:60-67`) + `:123-124` cover invented modal boundaries and accepted behavior; the verdict *procedure* and the scope boundary were not updated with them (A3, A5) |
| Auditors told to copy opaque IDs verbatim | Yes — `action-lock-audit.md:39-41`, inside the auditor block that `:37` scopes |
| Per-row validation, per-row fail-closed | Yes — `action-lock-audit.md:126-136`, consistent with `SKILL.md:517,553` |
| Emitted body byte-identical to audited body | Asserted in three places, but collides with the fallback path (A4) |
| Verified exact source suggestions preserved | Yes — `SKILL.md:503`, plus `iteration-13-assessment.md:218,223` |
| Assessment no longer mixes ranking scales, records fixes | Yes — `iteration-13-assessment.md:166-167`, `:192-209`; totals re-check clean (75, 72, 94, 47, 25) |
| report-artifacts formatting consistent | Yes — B6 fixed at `references/report-artifacts.md:26-31` |

## Critical

none

## Important

**A3 — The verdict procedure is still source-keyed, so the new rendered→source direction has no gate step.**
`references/action-lock-audit.md:69-73` is unchanged: "build an internal predicate ledger for each item. Quote every **source** predicate, classify it, and point to its exact rendered phrase… Return `pass` only when every ledger row is mapped correctly." Ledger rows are source predicates, so an invented rendered predicate produces no ledger row and the stated pass condition is satisfiable with the invention present. Rule 8 (`:64-67`) and `:121` still close the outcome, but the procedure the auditor actually executes before returning a verdict — and the one the language contract pins (`scripts/test-report-language.sh:214-215`) — was not extended to rendered-only rows. This is the same shape as the prior review's I6: the consequence is defined, the detection probability is not raised. Fix: require one ledger row per rendered predicate too, and pass only when both directions are mapped.

**A4 — "Byte-identical audited body" contradicts the exact-source fallback, which by construction was never audited.**
`references/action-lock-audit.md:155-157` ("The body written to `.inline.json` must be byte-identical to the audited `rendered_body`"), `SKILL.md:515` ("Write only the byte-identical audited body to `.inline.json`"), and `references/report-artifacts.md:28-30` ("every complete draft body must pass that gate before it enters `.inline.json`") are all unconditional. The fail-safe immediately above at `action-lock-audit.md:150-153` and at `SKILL.md:517` writes restored exact source requested-work prose for a row that *failed or was unverifiable* — a body that neither passed the gate nor equals any audited `rendered_body`. Read literally, an agent must either drop that finding (forbidden by `SKILL.md:517`, "Never omit the finding") or ship the failed audited body. The rule needs an explicit carve-out ("except a row restored to exact source prose under the fail-safe, which is emitted verbatim and forces COMMENT").

**A5 — Rule 7 has no scope exclusion, so label, evidence, and permitted code sketches are unmatched rendered predicates.**
`action-lock-audit.md:60-63` requires mapping *every* rendered predicate in the complete body, including "other factual claims", and `:64-65` says record an unmatched non-action claim in `fact_losses`. The auditor only receives `source_context` ("exact title and diagnostic prose") and `source_requested_work` (`:20-23`), and `:29-31` forbids sending "unrelated evidence or report sections". But `SKILL.md:501,507` require the body to open with `**<complete-id> [<severity>] <area>**` and permit "a short code sketch"; `references/report-artifacts.md` requires evidence tokens verbatim (`:24`). None of those are predicates in the two supplied fields, so a conforming body yields spurious `fact_losses` → fail → repair churn, and on a second wave → exact-source fallback plus `approval_allowed: false` (`SKILL.md:531,533`). This is the inverse of the `3652735574` incident the fix was written for, and the branch has no in-domain run to show the rate. Fix: exempt the bold label, severity/area, ID, verbatim evidence tokens, and an illustrative code sketch from rule 7, or add them to the frozen inputs.

## Minor

- **B7** — `references/action-lock-audit.md:123-124` and `:64-66` overload `fact_losses` with two opposite defects (a dropped source fact and an invented rendered fact). Repair consumers (`:140-142`, `SKILL.md:517`) read the union without any signal of direction, so an invention entry can be repaired by *adding* the fact. A fourth array, or a required direction prefix in `repair_instructions`, would remove the ambiguity.
- **B8** — The bucket half of the A1 fix has no language-contract assertion. `scripts/test-report-language.sh:195` pins `Map every rendered predicate`, but nothing pins `:64-66`/`:123-124`; `:218` only requires the schema key `"fact_losses"`, which predates the fix. `iteration-13-assessment.md:207` ("Language-contract assertions cover the fixes") is therefore slightly overstated.
- **B9** — Retired `rendered_requested_work` has no regression guard, although the script uses `reject` for exactly this (`scripts/test-report-language.sh:31-36,70,269,282-296`). The field is gone from the shipped files (verified: no matches outside `evaluations/`), so a `reject "$ACTION_LOCK" 'rendered_requested_work'` would lock C2 shut.
- **B10** — `action-lock-audit.md:129` ("Do not coerce an ID's type or value") makes a type-only echo mismatch fatal per row. Canonicalizing at dispatch (`:15-16`) constrains only the input side, so the observed integer-vs-string split (`iteration-13-production-path-action-reaudit-sol.json:12` vs `-claude.json:4`) would still make *every* row unverifiable when both auditors retype numerically-keyed IDs. Production `RAV-…` IDs are unaffected; evaluation harnesses keyed on GitHub comment IDs are not, and the accepted cost is not written down anywhere.
- **B11** — `SKILL.md:503` places the preservation clause *before* the exclusion list ("Do not include suggestions for design fixes, cross-file edits, deleted lines…"), with no subordinating language, so "preserve that exact source suggestion" can read as an override. `references/report-artifacts.md:283,324` — the voice source `SKILL.md:507` sends the renderer to — still only says to omit unsafe suggestion blocks and has no preservation counterpart.
- **B12** — New lines in `references/action-lock-audit.md` break the file's fill style: `:31`, `:133`, `:155` exceed 80 columns (only two pre-existing lines do, `:43`, `:140`), and appended sentences at `:29`, `:39`, `:133` run into the preceding paragraph without a blank line, merging four distinct rules into two blocks (`:27-31`, `:35-41`). Same class as the resolved B6, in the other file.
- **B13** — `iteration-13-assessment.md:192-209` records the fixes but never states that nothing from either review remains open, which was B5's ask, and omits that the recheck's six Minor items were also addressed. Related: `:118-120` still presents the suggestion-block loss as an unremediated limit with no pointer to the new `SKILL.md:503` rule.

## Verdict

**Keep the branch.** A1, A2, and B1–B6 are genuinely fixed in the files: rules 7–8 are predicate-based with a bucket for invention (`action-lock-audit.md:60-67,123-124`); the auditor block itself now carries the verbatim-ID instruction (`:39-41`); validation salvages well-formed sibling rows while treating protocol errors as per-row fallbacks (`:126-136`), matching `SKILL.md:517,553`; byte-identity is asserted (`SKILL.md:515`, `action-lock-audit.md:155-157`); suggestion preservation exists as a rule and as scheduled work (`SKILL.md:503`, `iteration-13-assessment.md:218,223`); the 104–22–15 cross-scale total is gone with an explicit non-summing note (`:166-167`); and `report-artifacts.md:26-31` matches the file's section spacing. The 14 new `require` literals at `scripts/test-report-language.sh:185-198` all correspond to single-line text present in the current files under `grep -Fq` semantics — I did not run the script, per your instruction.

Nothing here is blocking. A4 is the one to fix first: it is a one-clause scoping edit on the fail-closed path, where a literal reading pushes an agent toward either omitting a finding or shipping a failed body. A5 next, since it decides whether the full-body audit is affordable on the in-domain corpus run that is Best option 2.
