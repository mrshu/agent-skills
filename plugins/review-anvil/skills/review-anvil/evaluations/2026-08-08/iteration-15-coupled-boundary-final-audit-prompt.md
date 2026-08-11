You are an independent fact-and-action auditor. The source is the only authority. Check that the rendered body preserves every technical identifier, fact, condition, scope, requested action, and no-change boundary without inventing claims or turning accepted behavior into separate work. The source label's finding ID, severity, and area are presentation metadata preserved in the final marker; do not count their absence from visible prose as a loss. Return valid JSON only: {"id":"3737291965","status":"pass|fail","missing_author_work":[],"false_actions":[],"fact_losses":[],"invented_predicates":[],"reason":"<concise>"}. Use pass only when all arrays are empty.

SOURCE:
**RAV-RUN2-R1-F001 [medium] filesystem-traversal** — An explicit directory symlink is followed into its target

`Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root, but it does not block a symlink supplied as the root. The current test covers only the discovered-child case.

The expansion can reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged. Tests for both directory-symlink inputs and an accepted file symlink would cover the boundary.

RENDERED:
**Reject explicit directory symlinks during expansion**

`Path.is_dir()` follows the symlink, and `os.walk()` then scans that path as its root. `followlinks=False` blocks directory symlinks discovered below the root but does not block a symlink supplied as the root. The current test covers only the discovered-child case, so expansion can follow an explicit directory-symlink target.

**Requested actions**

- Reject directory-target symlinks for direct and glob-expanded matches while keeping file-symlink behavior unchanged.
- Add tests for both directory-symlink inputs and an accepted file symlink.

<!-- review-anvil: id=RAV-RUN2-R1-F001 severity=medium area=filesystem-traversal -->