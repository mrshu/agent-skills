---
name: gdocs-comment
description: Bulk-post anchored comments (with @-mentions) to a Google Doc from a JSON plan. Use when adding many Google Docs comments at once — checklist audits, doc reviews, structured feedback — that would otherwise mean clicking through the UI for each one. Drives an existing logged-in browser tab via the chrome-cdp skill.
---

# Google Docs bulk comment poster

Post N anchored Google Docs comments from a JSON plan. Each comment is attached to a unique substring of doc body text, optionally with `@-mentions` of collaborators. Uses the user's already-logged-in browser session via the [`chrome-cdp`](../../chrome-cdp) skill.

Break-even is around 5 comments — for fewer, type them directly in the doc.

## Prerequisites

1. **`chrome-cdp` skill** installed; the wrapper auto-discovers `cdp.mjs` (or set `$CDP_BIN`).
2. **Chrome / Brave / Edge** running with remote debugging enabled.
3. **Google Doc tab open** in that browser, **logged in**, with **comment permission** on the doc.
4. **Node.js 22+** (uses built-in WebSocket / Unix-socket APIs).

## Usage

```bash
# 1. find the doc tab
${CLAUDE_PLUGIN_ROOT}/skills/gdocs-comment/gdocs-comment --list

# 2. post a plan (target prefix from `cdp list`)
${CLAUDE_PLUGIN_ROOT}/skills/gdocs-comment/gdocs-comment 312C822D plan.json

# or supply the document URL — the wrapper picks the matching tab
${CLAUDE_PLUGIN_ROOT}/skills/gdocs-comment/gdocs-comment --url https://docs.google.com/document/d/<id>/edit plan.json

# validate the plan without posting
${CLAUDE_PLUGIN_ROOT}/skills/gdocs-comment/gdocs-comment --dry-run plan.json
```

## Plan format

A JSON array of `{anchor, text, mentions?}`:

```json
[
  {
    "anchor": "training sessions",
    "text": "Detail optional training for participants — content, schedule, who runs it.",
    "mentions": ["jakub.krcho@gmail.com", "mirokohut13@gmail.com"]
  },
  {
    "anchor": "Accommodation can be easily arranged through common online platforms",
    "text": "Please add an explicit list of hotels at different price levels + a youth/hostel option."
  }
]
```

- `anchor` — substring of doc body to attach the comment to. The skill uses Find & Replace's *Next* button, so the **first** match in the doc is selected; pick a substring unique enough to land where you want.
- `text` — comment body. Multi-line is fine via `\n` in the JSON string.
- `mentions` — optional list of emails. They are prepended to the comment as `+email@…` chips; Google Docs auto-resolves them and sends notifications.

## Output

Per-item results stream to stdout:

```
[1/3] anchor: training sessions
  ✓ posted
[2/3] anchor: nonexistent text in doc
  ERROR: anchor not found in doc (0 matches): "nonexistent text in doc"
```

Summary + identity preflight + any failure diagnostics go to stderr.

**Exit codes:**
- `0` = all OK
- `1` = at least one item FAILed (or the daemon connection failed, or there's an unsent comment draft open at startup that we refuse to clobber)
- `2` = usage / plan-validation error
- `75` = `EX_TEMPFAIL` — the tab is still hidden after `Page.bringToFront`. Manually foreground the browser window and re-run.

**Residual plan:** if any items failed, the wrapper writes `<plan>.residual.json` containing just those items. Retry with `gdocs-comment <target> <plan>.residual.json` after fixing whatever caused the failures (e.g. anchor text wasn't unique enough, or the doc shifted).

## How the anchoring works

Google Docs renders text on a canvas; the DOM Selection API doesn't reflect the doc's internal cursor. To get a *real* text selection that a comment can attach to, the skill:

1. Opens **Find & Replace** (⌘⇧H / Ctrl⇧H) — keyboard chord, no UI text needed.
2. Types your `anchor`. Incremental search runs inside the dialog and selects the **first** match in the doc as you type.
3. Parses the dialog's "N of M" counter (works in `of` / `z` / `von` / `sur` …). If `M == 0`, the item fails immediately as "anchor not found in doc". If the counter is unreadable (unsupported locale), the item fails closed rather than risk a mis-anchored comment.
4. Asserts there is exactly **one** primary-action button in the dialog (Material's `WizButtonFilled`) — *as a redesign tripwire only*. The script deliberately does **not** click it: incremental search has already selected match #1, and clicking "Next" would advance the selection past it for any non-unique anchor.
5. Closes the dialog via the **X** icon and polls until `visibility:hidden` (Material dialogs persist in the DOM with `visibility:hidden`).
6. Opens the comment dialog with ⌘⌥M / Ctrl⌥M (sends raw `'m'` + Cmd/Ctrl + Alt — Chrome composes the modified key so the chord works on every platform).
7. Types `+email@…` mentions then the comment body; Google Docs auto-converts the `+email` prefix into a real mention chip on submit.
8. Clicks the primary action button in the active draft container (`.docos-docoview-active .jfk-button-action` — language-agnostic) and polls until the draft textarea disappears.

Every step that has a UI postcondition (dialog closed, draft closed, anchor matched) verifies that postcondition before advancing, and re-issues the click between polls. Steps that don't — typing into an input, dispatching a keyboard chord — fall back to short fixed sleeps.

## Limitations

- **One-shot comments only** — no replies, no resolving threads.
- **First match wins** — make anchors specific enough to land where you want, or use longer substrings.
- **Tab must be in the foreground** — Chrome only delivers `Input.dispatchKeyEvent` / `Input.dispatchMouseEvent` to foregrounded tabs, and throttles timers on hidden tabs. The script calls `Page.bringToFront` and then exits with code 75 if `document.hidden` is still true (re-run after foregrounding).
- **Refuses to start on top of a human draft** — if you have your own unsent comment draft open in the doc when you start, the script exits 1 without touching anything. (`ensureClean` between items uses the same Cancel button that would discard your draft.)
- **Pegged to Google's current Docs UI** — relies on stable structural class names (`appsDocsUiWizFindandreplacedialogContainer`, `docos-docoview-active`, `jfk-button-action`, Material `WizButtonFilled`). Resilient to UI-text changes (any locale) but a major redesign would need re-targeting.
- **Posts under whichever account the tab is logged in as** — the wrapper prints `posting as Google account: <email>` (best effort) before running so you can verify.
- **Don't type or click in the doc while a run is in progress.**
