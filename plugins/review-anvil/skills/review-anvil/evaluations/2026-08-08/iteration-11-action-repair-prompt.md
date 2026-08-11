Repair only the rendered requested-work section of each attached failed item.

Treat `source_context` and `source_requested_work` as ground truth. Use the audit findings as diagnostics and the adjudication as the final classification. Do not omit, merge, or invent a source predicate.

Render every author-work predicate as a direct request. Keep accepted current behavior, permissions, and allowed implementation boundaries as short modal prose after the action they constrain. Preserve every target, condition, scope, quantifier, purpose, result, safety clause, identifier, and modality. Prefer one concise `Please` sentence for one obligation. For two or more independently implementable obligations, use `**Requested actions**` and one direct-action bullet per obligation. Do not start a no-change boundary with an imperative.

Return valid, pretty-printed JSON only. The top-level value must be an array in input order. Each object must contain exactly `id` and `rendered_requested_work`. Do not include analysis or Markdown fences.
