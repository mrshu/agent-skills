I could not execute the test suite (bash denied in this mode), so I verified the new `require` assertions by reading the files — all eight target strings exist verbatim, so the suite passes on presence grounds. Everything below is from reading the full contract, the source corpus that produced the stress cases, and the test script.

## Verdict: `changes requested`

---

### P0-1 — The counterfactual captures preservation predicates, contradicting the file's own preservation rules

`references/report-artifacts.md:81-83`, `SKILL.md:511`, `references/reviewer-prompt.md:202-204`

**Evidence.** The new rule is unconditional: "Apply an omission counterfactual to **every** proposed post-change behavior. If omitting it leaves the reported defect or a required boundary unresolved, it is author work." It sits eleven lines above `report-artifacts.md:92-93` ("A preservation constraint, permission, carve-out, exception, or already-correct behavior is not a separate obligation") and `:71` ("Use modal prose for behavior that may remain unchanged"). Nothing states which rule wins.

Apply it to the file's own standalone-permission example at `:231`, `Unresolved keys can be reported after the valid metrics are preserved.` `SKILL.md:511` mandates per-predicate classification of compound sentences. Predicate two is *the valid metrics are preserved*; omit it and valid metrics are dropped, so a required boundary is unresolved → author work → must appear as an explicit request. The contract shows it as prose. The rule and the example now disagree about the same sentence.

Same failure on stress case 3. The corpus source is `Sidecar validation and hashing must stay streaming for WILD's size.` Omit it and WILD-size inputs load into memory — a required boundary unresolved → the written rule yields the bullet `- Keep sidecar validation and hashing streaming.`, which `asd-ste100-inspired.md:29` forbids outright and `scripts/test-report-language.sh:232-234` rejects for the sibling cases.

**Consequence.** Direct false-action risk against invariant 2, on two of the six stress cases, from the durable contract alone.

**Fix.** Make author work a conjunction, not necessity alone. Replace `report-artifacts.md:81-82` with:

```
Apply an omission counterfactual to every predicate that proposes behavior the
code does not have today. If omitting that new behavior leaves the reported
defect or a required limit unresolved, it is author work.
A predicate that describes behavior the code already has is never author work,
even when omitting it would break a limit. Keep it as modal prose.
```

Mirror the second sentence in `SKILL.md:511` and `reviewer-prompt.md:202-204`. This resolves all six cases: `must stay streaming` and `the valid metrics are preserved` are existing behavior → prose; `report unresolved keys` is new but unnecessary → prose; the rest are new and necessary → actions.

### P0-2 — The new "true no-change boundary" example manufactures an unsupported preservation claim and strips a necessary condition

`references/report-artifacts.md:216-225`, pinned by `scripts/test-report-language.sh:154`

**Evidence.** The corpus source for stress case 4 is:

> `Symlinks, roots, and populated targets can fail by default until replacement has an explicit ownership manifest.`

The example renders it as bullet `- Fail by default for symlinks, roots, and populated targets.` plus prose `Replacement can remain blocked until it has an explicit ownership manifest.`, captioned "Preserve only a true no-change boundary".

Three problems. (a) There is no preservation predicate in the source at all — the adapter currently *deletes* the tree, so nothing is "blocked" today. Labelling invented new behavior a no-change boundary contradicts `:84-86`, which allows `remain` as a preservation cue "only when the source says that behavior is already acceptable." (b) `remain blocked` is a claim with no source fact, which `:61` says to delete and `:130` says to repair by restoring the source sentence verbatim. (c) The `until ...` condition is dropped from the bullet, but `:117` specifies the bullet shape as "Direct verb, target, and **necessary condition** or destination." The same defect appears in the first new example: `- Validate numeric fields as finite values under their metric rules.` (`:211`) drops `before result construction`, which is present in the source and in every good candidate in the corpus.

**Consequence.** The most imitated part of the contract teaches agents to fabricate a preservation sentence out of a condition clause and to drop conditions from bullets. Because `test-report-language.sh:153-154` pins both bullet strings, the wrong text is now regression-locked.

**Fix.** Restore the conditions and drop the fabricated prose:

```md
**Requested actions**

- Validate numeric fields as finite values under their metric rules before result construction.
- Enter invalid rows in `SourceConversionResult`.
- Use the batch publisher for new or empty targets.
- Fail by default for symlinks, roots, and populated targets until replacement has an explicit ownership manifest.
```

Then illustrate a *real* no-change boundary with a source that has one — stress case 3 works: bullets for staging and rejection, prose `Sidecar validation and hashing must stay streaming for WILD's size.` Update `test-report-language.sh:153-154` to the corrected strings and add `reject "$ARTIFACTS" 'Replacement can remain blocked'`.

### P1-1 — `required boundary` collides with `modal boundary`, which must never become an action

`SKILL.md:511` and `:513`; `report-artifacts.md:82`; `reviewer-prompt.md:203`

**Evidence.** `SKILL.md:511` says an unresolved "required boundary" makes a predicate author work. `SKILL.md:513`, the next paragraph, says "Keep a modal implementation boundary as modal prose." The word `boundary` already carries four meanings in this contract: `modal boundary` (`report-artifacts.md:77`), `exact test boundary` (`:118`), `failure boundary` (`:162`), and now `no-change boundary` (`:216`) and `required boundary`. None is defined. `asd-ste100-inspired.md:12` requires "Use one term for one meaning" — this change violates the style contract it extends. The same rule also says `reported failure` in `SKILL.md:511` but `reported defect` in the other two files.

**Consequence.** An agent reading `SKILL.md:511-513` cannot tell whether a modal boundary counts as a "required boundary"; if it does, every boundary becomes an action bullet.

**Fix.** Use `required limit` (or `safety limit`) for the counterfactual test, reserve `boundary` for the modal-prose concept, and standardize on `reported defect` in all four files.

### P1-2 — The heading promises a compound-modal example; the contract contains none

`references/report-artifacts.md:206-213`

**Evidence.** The heading reads "Apply the counterfactual to each predicate in a compound modal sentence:" and is followed by two output bullets. No compound sentence appears in the block — nor anywhere else in the contract. The actual mixed-class example (`Legacy snapshots can leave this typed value unset and mark the missing content`, one constraint plus one action in one sentence) exists **only** in `evaluations/2026-08-08/iteration-9-rewrite-prompt.md:11` and `iteration-9-fact-action-evaluator-prompt.md:8`, which are dated per-iteration artifacts not loaded at runtime. The commit message claims "Add compound-modal examples for hidden author work"; the contract got none.

More broadly, both new examples show only the output. Every other example in the file (`:170-178`, `:183-189`, `:194-204`) shows the finding label and diagnosis, so the reader can see the input. Here the discriminating decision — why `Enter invalid rows` becomes a bullet while `Replacement can remain blocked` stays prose — is unlearnable from the page.

**Consequence.** Stress case 2, the only genuinely mixed-class sentence, has a rule but no worked example in anything a clean agent reads.

**Fix.** Add the case-2 pair to `report-artifacts.md` with source and output visible:

```md
Source: `Legacy snapshots can leave this typed value unset and mark the missing content.`
`leave ... unset` is existing accepted behavior. `mark the missing content` is new
behavior that the defect needs. Split the sentence:

Please mark the missing content in legacy snapshots.
Legacy snapshots can leave this typed value unset.
```

Add a matching `require` for the source line.

### P1-3 — The preservation cue list omits the exact words the stress cases use

`references/report-artifacts.md:84-86`

**Evidence.** The list is `remain`, `keep`, `leave`, `unchanged`, `still`. Stress case 3's source uses `must stay streaming` / `remains streaming`; stress case 6's uses `are preserved`. Neither `stay` nor `preserve`/`preserved` is listed, so both true constraints fall through the cue test into the counterfactual, which then classifies them as author work (P0-1).

**Fix.** Extend to `remain`, `remains`, `stay`, `keep`, `leave`, `preserve`, `continue`, `unchanged`, `still` — and note that the list is illustrative, not exhaustive.

### P2-1 — No negative tests for the false-action risks this change creates

`scripts/test-report-language.sh:150-157`

**Evidence.** All eight new assertions are `require` string-presence checks. This suite encodes false-action prevention through `reject` (`:232-236` blocks `- Keep empty optional cells allowed.`, `- Report unresolved keys after the valid metrics are preserved.`, and so on). The change adds a rule that creates three new bad outputs and guards none of them.

**Fix.** Add:

```bash
reject "$ARTIFACTS" '- Keep sidecar validation and hashing streaming.'
reject "$ARTIFACTS" '- Preserve the valid metrics.'
reject "$ARTIFACTS" '- Leave this typed value unset.'
require "$ARTIFACTS" 'A predicate that describes behavior the code already has is never author work'
```

### P2-2 — `SKILL.md:497` models a preservation bullet the new rule now appears to bless

`SKILL.md:497`, required by `scripts/test-report-language.sh:164`

The canonical inline example contains `- Keep timed-out attempts eligible for retry.` — a preservation predicate in an action bullet, which `asd-ste100-inspired.md:29` forbids and `test-report-language.sh:232-234` rejects elsewhere. This tension predates the commit, but the new counterfactual now supplies a reading that justifies it ("omitting it leaves a required boundary unresolved"), so an agent will treat it as sanctioned precedent. Either move it to prose after the bullets or add one line stating why retry eligibility is a required behavior change rather than a preservation constraint.

### P2-3 — The rule is now duplicated in four files with four wordings

`SKILL.md:511`, `report-artifacts.md:81-86`, `reviewer-prompt.md:202-204`, `asd-ste100-inspired.md:28`

Each restates the counterfactual differently (`failure` vs `defect`; predicate-level in two files, behavior-level in two). `report-artifacts.md:73-108` is now 36 unbroken lines of classification prose carrying nine near-synonyms — `preservation constraint`, `no-change constraint`, `no-change boundary`, `modal boundary`, `modal implementation boundary`, `permitted behavior`, `standalone permission`, `allowed follow-up`, `carve-out`. Consider a short `### Classifying requested predicates` subsection with one definition list as the single source of truth, and reduce the other three files to a pointer plus the one-line rule. Also note `:83` is a single long line in an otherwise hard-wrapped file.

---

## Are the six stress cases classified correctly by the written rules?

| # | Case | Classified correctly? |
|---|---|---|
| 1 | enter invalid rows in `SourceConversionResult` | **Yes** as author work; the example bullet drops `before result construction` (P0-2) |
| 2 | mark missing content while legacy values remain unset | **Yes** — `leave` is a listed cue, `mark` fails the counterfactual; but no example in the contract (P1-2) |
| 3 | reject existing output while sidecar validation stays streaming | **No.** Rejection is correctly author work; `must stay streaming` is wrongly captured as author work because `stay` is not a cue (P1-3) and the counterfactual has no preservation exemption (P0-1) |
| 4 | fail by default for symlinks, roots, populated targets until a manifest exists | **Classification yes, rendering no** — the condition is stripped and a fictitious preservation sentence is invented (P0-2) |
| 5 | restrict tolerance to scale classification plus a strict pre-publication check | **Yes, but fragile.** Both are new and necessary. The counterfactual tests one predicate at a time, and the strict check alone arguably resolves the defect, so `Tolerance can support scale classification only` can be read as a boundary. The new-behavior clause in the P0-1 fix removes the ambiguity |
| 6 | `Unresolved keys can be reported after the valid metrics are preserved.` | **Not reliably optional.** The `can be reported` predicate stays optional, but per-predicate classification pulls `the valid metrics are preserved` into author work, contradicting the example at `:231` (P0-1) |

Net: two of six (3 and 6) are misclassified by the contract as written, one (4) is misrendered, and one (5) is correct but underdetermined. The P0-1 fix — restricting the counterfactual to predicates proposing behavior the code does not have today — corrects 3, 5, and 6 together; P0-2 corrects 1 and 4.
