Repair only the rendered requested-work section of the attached failed item.

Treat `source_context`, `source_requested_work`, and adjudication as ground truth. Directly request the author-work predicate. Preserve both no-change boundaries as modal prose without turning either into an action.

This item has exactly one author obligation. Return one concise `Please` sentence followed by the no-change boundary in prose. Do not use `**Requested actions**` or a bullet list.

Return valid, pretty-printed JSON only as an array with one object containing exactly `id` and `rendered_requested_work`. Do not include analysis or Markdown fences.
