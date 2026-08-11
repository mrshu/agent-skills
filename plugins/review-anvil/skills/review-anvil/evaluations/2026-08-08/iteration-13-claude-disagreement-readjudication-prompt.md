Re-adjudicate three action-lock disagreements under the production contract. Research only; do not rewrite. The following contract examples are authoritative interpretations, not optional hints:

1. “Add a no-match check. It can stop before existing-output discovery or publication.” requests the check but permits its stopping point. Do not turn the permitted point into a separate “Stop before…” action.
2. “Unresolved keys can be reported after valid metrics are preserved” mixes required preservation with an allowed reporting follow-up. Make preservation explicit; do not request reporting.
3. If construction currently fails after files are written, “Complete output can stage before publication” is author work. “Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming” preserves two allowed boundaries; do not turn either into an action.

For each row, decide whether the candidate follows the applicable authoritative interpretation. A semicolon may keep a permitted stopping point with its required check. A separate direct action to preserve valid metrics is required by example 2. Modal prose for rejection-until-atomic and streaming validation is required by example 3.

Return valid JSON only:
{"items":[{"id":123,"status":"pass|fail","reason":"one sentence tied to an authoritative example"}],"pass_count":0,"fail_count":0}
Return every ID exactly once. No Markdown fences or text outside JSON.

ROWS:
[
  {
    "id": 3737383919,
    "source": "**RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run\n\nA nonempty filter with no matches instead exits successfully with zero logs.\n\nPlease require one or more values to block the first path. A no-match check can stop before existing-output discovery or publication.",
    "candidate": "**RAV-RUN3-R1-F001 [medium] cli** — A bare `--models` parses as an empty list, which disables filtering and starts the full source run\n\nA nonempty filter with no matches instead exits successfully with zero logs.\n\n**Requested actions**\n\n- Require one or more `--models` values to block the bare-flag full-run path.\n- Add a no-match check; it can stop before existing-output discovery or publication."
  },
  {
    "id": 3737449070,
    "source": "**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds\n\nA finite custom key does not prove that direction.\n\nPlease use source metric specs or an operator-supplied definition to establish the semantics. Unresolved keys can be reported after the valid metrics are preserved.",
    "candidate": "**RAV-RUN1-R1-F005 [medium] metric-semantics** — When a result key has no matching metric spec, the converter assumes higher-is-better and publishes no verified scale or bounds\n\nA finite custom key does not prove that direction.\n\n**Requested actions**\n\n- Use source metric specs or an operator-supplied definition to establish semantics for result keys without matching metric specs.\n- Preserve valid metrics.\n\nAfter valid metrics are preserved, unresolved keys can be reported."
  },
  {
    "id": 3725913004,
    "source": "**RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.\n\nComplete output can stage before publication. Existing logical output can be rejected until replacement is atomic, with sidecar validation kept streaming.",
    "candidate": "**RAV-RUN2-R1-F001 [high] instance-publication** — Instance mode passes a sidecar basename where the schema requires a canonical datastore path. Construction fails after aggregate and sidecar files are written.\n\nPlease stage complete output before publication. Existing logical output can be rejected until replacement is atomic, and sidecar validation can remain streaming."
  }
]
