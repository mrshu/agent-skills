Act as a strict technical-writing and code-review UX critic. Research only. Do not edit files.

The current review-anvil inline-comment contract preserves technical facts and structures each medium/high finding as title, mechanism/consequence paragraphs, then one `Please` sentence per requested action. A human flagged this sentence as too complex: `Files containing only intentionally skipped derived rows can stay explicit exclusions.` A clearer candidate is `Keep files that contain only intentionally skipped derived rows in the exclusions list.`

Representative current comments:

1. `**[high] publication** — --replace-existing deletes prior records before replacement preflight\n\nLines 601–602 remove the old files before save_evaluation_logs() validates and writes the new batch. Its rollback covers only files created by that call, so a later failure can leave the target without its prior records.\n\nPlease retain recoverable old files until every new write and route transition succeeds. A mid-write failure test across several routes would cover this path.`

2. `**[high] failure-accounting** — Score parsing happens before SourceConversionResult exists, and later row construction has no row-level error boundary\n\nOne malformed source value can stop every valid row without a source-row failure record.\n\nPlease add a narrow boundary that catches expected parsing and schema errors. Unexpected program or infrastructure errors can remain visible.`

3. `**[high] source-accounting** — An input file whose measured tasks all lack finite scores returns an empty list without a failure\n\nA directory made from those files then reports zero converted logs and exits successfully, so automation cannot distinguish total conversion loss.\n\nPlease put a file with measured but unconvertible tasks in the failure ledger. Files containing only intentionally skipped derived rows can stay explicit exclusions.`

Candidate intervention: prefer concrete actor-action-destination clauses over abstract state language; use consequence-focused titles; split mechanism and result; use one natural request sentence for one action and an adaptive `**Change requested**` bullet list for 2+ actions. This candidate must beat the current contract rather than being assumed better.

Return:
1. A diagnosis of remaining cognitive-load failures, quoting exact phrases.
2. A critique of the adaptive heading/list proposal for GitHub inline comments.
3. A recommended operational language contract.
4. Rewrites of all three comments that preserve every technical fact, condition, exception, identifier, and test boundary.
5. A blind evaluation design measuring correct defect restatement and requested-action recall.
6. Failure modes that should reject the iteration.

Do not give generic advice.