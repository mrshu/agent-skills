// page-helpers.js — injected into the Overleaf project tab.
// Defines window.__overleaf with: post(), openFile(), dismissModals(),
// activeUser(), uiLanguage(). All async functions return a string starting
// with "OK: ", "FAIL: ", or "RELOADED: ".
//
// The bash wrapper drives the loop one item at a time so each cdp eval stays
// well under chrome-cdp's 15-second Runtime.evaluate ceiling.
//
// All Overleaf-specific selectors and English UI strings are gathered in the
// SEL and TXT objects below. When Overleaf ships a redesign, this is the
// only block that should need updating.

(() => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  // CSS selectors that target Overleaf's React UI. Each entry includes a
  // fallback chain (current → historical) so a one-class rename isn't an
  // instant break.
  const SEL = {
    // The main editor surface (CodeMirror 6 inside the IDE panel).
    editor:
      ".ide-react-editor-panel .cm-content, .cm-editor.cm-focused .cm-content, .cm-content",
    // The new-comment review panel — used to scope Cancel/Submit lookups.
    reviewPanel:
      "form.review-panel-entry-content, .review-panel-add-comment, " +
      ".review-panel-new-thread, .review-panel-redesign-popup",
    // The textarea inside the review panel.
    commentTextarea:
      "textarea.review-panel-add-comment-textarea, form.review-panel-entry-content textarea",
    // File-tree items.
    treeItem: '[role="treeitem"]',
    treeItemName: ".item-name, [class*='item-name']",
    activeTreeItem:
      '[role="treeitem"][aria-selected="true"], [role="treeitem"].selected, [role="treeitem"][aria-current="true"]',
    // The Add-comment toolbar button. The exact `aria-label="Add comment"`
    // is the current Overleaf string; the second alternative handles a
    // plausible rename to "Add a comment" without matching unrelated
    // labels like "Resolved comments" (which the loose `*="comment" i`
    // would).
    addComment:
      'button[aria-label="Add comment"], button[aria-label^="Add" i][aria-label*="comment" i]',
    // The "More editor toolbar items" overflow toggle.
    overflowToggle:
      'button[aria-label*="More editor" i], .ol-cm-toolbar-overflow-toggle',
  };

  // English strings from Overleaf's UI. Out-of-locale tabs surface a
  // single warning at the wrapper preflight; the helpers themselves
  // assume English.
  const TXT = {
    submit: "Comment",
    cancel: "Cancel",
    reload: "Reload editor",
  };

  // Scope DOM queries for Submit/Cancel buttons to the review-panel form
  // so a stray button in some other Overleaf modal can't be misclicked.
  function findInPanel(predicate) {
    const panel = document.querySelector(SEL.reviewPanel);
    if (!panel) return null;
    return [...panel.querySelectorAll("button")].find(predicate);
  }

  function getView() {
    const cm = document.querySelector(SEL.editor);
    return cm && cm.cmView && cm.cmView.view;
  }

  // Tree items mix the file icon ("description"), the filename, and a
  // "more_vert" menu glyph when hovered/selected. Read the inner
  // `.item-name` element when present; fall back to whole textContent.
  const itemText = (i) => {
    const inner = i.querySelector(SEL.treeItemName);
    return (inner ? inner.textContent : i.textContent).trim();
  };

  // Compute the basename, splitting on both / and \ so plans authored on
  // Windows also work.
  function basenameOf(name) {
    const parts = name.split(/[\\/]/);
    return parts[parts.length - 1];
  }

  // Dismiss the "Out of sync" modal. Returns "reloaded" if a reload was
  // triggered (caller must re-inject helpers, since the page navigates).
  async function dismissModals() {
    const reload = [...document.querySelectorAll("button")].find(
      (b) => b.offsetParent && b.textContent.trim() === TXT.reload,
    );
    if (reload) {
      reload.click();
      return "reloaded";
    }
    return "ok";
  }

  // Strict file-tree match. Exact-basename first; fall back to a
  // separator-bounded suffix only when the user supplied a path-like name
  // and exactly one tree item matches. Plain `endsWith(basename)` is
  // rejected because `intro.tex` would silently target `myintro.tex`.
  function findTreeItem(name) {
    const basename = basenameOf(name);
    const items = [...document.querySelectorAll(SEL.treeItem)];
    const exact = items.filter((i) => itemText(i) === basename);
    if (exact.length === 1) return exact[0];
    if (exact.length > 1) return { ambiguous: exact };

    if (name.includes("/") || name.includes("\\")) {
      const sepEnd = items.filter((i) => {
        const t = itemText(i);
        return t.endsWith("/" + basename) || t.endsWith("\\" + basename);
      });
      if (sepEnd.length === 1) return sepEnd[0];
      // If multiple still match, treat as not-found rather than reporting
      // a separate "ambiguous" status — exact match was already tried, and
      // post-cleanup of multiple sibling files of the same basename in a
      // path-supplied plan is rare enough that "not found" is honest.
    }
    return null;
  }

  // Probe the active Overleaf account, if Overleaf exposes it. Returns null
  // when none of the known signals yield a usable identifier. Display label
  // only — the cookie sent on the comment-create POST is what actually
  // authorises the post; keep these in mind as best-effort observation.
  function activeUser() {
    // 1) Overleaf's MetaProvider sets a meta tag on initial render.
    const meta = document.querySelector('meta[name="ol-user"]');
    if (meta && meta.content) {
      try {
        const parsed = JSON.parse(meta.content);
        const id = parsed.email || parsed.first_name;
        if (id) return id;
      } catch (_) {}
    }
    // 2) Some Overleaf builds expose window.user.
    if (window.user && (window.user.email || window.user.first_name)) {
      return window.user.email || window.user.first_name;
    }
    // 3) Newer dashboards have an avatar with a data- attribute.
    const avatar = document.querySelector(
      '[data-user-email], [data-test-selector="avatar"]',
    );
    if (avatar && avatar.dataset && avatar.dataset.userEmail) {
      return avatar.dataset.userEmail;
    }
    return null;
  }

  // Detect the UI language. Overleaf's React app sets <html lang>. If non-
  // English, the helpers' English-string matchers ("Comment", "Cancel",
  // "Reload editor", aria-label="Add comment") will not work.
  function uiLanguage() {
    return (document.documentElement.lang || "").slice(0, 2).toLowerCase();
  }

  // Find the tree item that the file tree currently marks active. May be
  // null if no file is selected (rare).
  function activeTreeItem() {
    return document.querySelector(SEL.activeTreeItem);
  }

  function activeTreeItemMatches(basename) {
    const a = activeTreeItem();
    if (!a) return false;
    return itemText(a) === basename;
  }

  // Open `name` in the editor. Verifies the editor actually swapped to the
  // target file; does NOT return OK on a stale view.
  async function openFile(name) {
    let target = findTreeItem(name);

    // If not found, try expanding all currently-collapsed folders once.
    if (!target) {
      const collapsed = [
        ...document.querySelectorAll(SEL.treeItem + '[aria-expanded="false"]'),
      ];
      for (const f of collapsed) {
        f.click();
        await sleep(120);
      }
      target = findTreeItem(name);
    }

    if (target && target.ambiguous) {
      return "FAIL: ambiguous match for " + name + " — " + target.ambiguous.length + " tree items match";
    }
    if (!target) return "FAIL: not found in tree: " + name;

    const basename = basenameOf(name);

    // Already open?
    if (activeTreeItemMatches(basename)) {
      const v = getView();
      if (v && v.state.doc.lines > 0) {
        return "OK: " + name + " (" + v.state.doc.lines + " lines, already open)";
      }
    }

    // Snapshot a content marker, click, then wait for the editor to actually
    // swap. We require both that the document changes AND that the file tree
    // marks the target file active — Overleaf marks the tree item active
    // immediately on click while the CodeMirror view re-binds
    // asynchronously, so the active flag alone reports OK on a stale view.
    const before = getView();
    const beforeMarker = before
      ? before.state.doc.line(1).text + "|" + before.state.doc.lines
      : "";

    target.click();

    let lastLines = null;
    for (let i = 0; i < 50; i++) {
      await sleep(150);
      const v = getView();
      if (!v) continue;
      lastLines = v.state.doc.lines;
      const marker = v.state.doc.line(1).text + "|" + v.state.doc.lines;
      if (marker !== beforeMarker && activeTreeItemMatches(basename)) {
        // No fixed settle here. post()'s own polling loop (after it
        // dispatches a selection — which is when Add-comment can actually
        // become enabled) absorbs the toolbar-rebind delay. On a fast
        // machine the first post() runs ~800 ms sooner; on a slow one the
        // wall-clock is unchanged.
        return "OK: " + name + " (" + v.state.doc.lines + " lines)";
      }
    }
    return (
      "FAIL: editor did not swap to " +
      name +
      (lastLines ? " (still showing " + lastLines + " lines)" : "")
    );
  }

  // Probe whether a button reads as disabled in any of the conventions
  // Overleaf might use. A zero-sized / hidden button is treated as
  // unavailable: Overleaf's CodeMirror toolbar dynamically collapses lower-
  // priority buttons (including "Add comment") into a "More editor toolbar
  // items" overflow menu when the editor pane is narrow, leaving the
  // original button in the DOM but with width 0 and offsetParent null.
  function isButtonDisabled(b) {
    if (!b) return true;
    if (b.disabled === true) return true;
    if (b.getAttribute("aria-disabled") === "true") return true;
    if (b.classList.contains("disabled")) return true;
    if (b.offsetParent === null) return true;
    const r = b.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) return true;
    return false;
  }

  // Reveal the visible "Add comment" button. If the toolbar overflow has
  // collapsed it, click the "More editor toolbar items" toggle first so
  // the button is rendered into a visible popover. Returns the visible
  // button or null.
  async function ensureAddCommentVisible() {
    const findAddBtn = () =>
      [...document.querySelectorAll(SEL.addComment)].find((b) => !isButtonDisabled(b));

    let visible = findAddBtn();
    if (visible) return visible;

    const overflowToggle = document.querySelector(SEL.overflowToggle);
    if (overflowToggle && overflowToggle.getAttribute("aria-expanded") !== "true") {
      overflowToggle.click();
      for (let i = 0; i < 25; i++) {
        await sleep(80);
        visible = findAddBtn();
        if (visible) return visible;
      }
    }
    return null;
  }

  // Dismiss any half-open comment dialog so the next iteration starts clean.
  // Strictly scoped to the review-panel container — if the panel is not in
  // the DOM there is nothing for us to dismiss, and clicking a stray Cancel
  // button elsewhere on the page would do real harm.
  function closeOpenCommentDialog() {
    const cancel = findInPanel(
      (b) => b.offsetParent && b.textContent.trim() === TXT.cancel,
    );
    if (cancel) cancel.click();
  }

  // Distinguish between common causes of "Add comment unavailable" so the
  // operator gets actionable diagnosis. Mirrors isButtonDisabled (so the
  // toolbar-overflow case — button present but `offsetParent === null` —
  // is classified correctly rather than "selection cleared").
  function diagnoseAddCommentUnavailable() {
    const addBtns = [...document.querySelectorAll(SEL.addComment)];
    if (addBtns.length === 0) {
      return "FAIL: comments are not available on this project (free-tier without comments, viewer-only share, or archived)";
    }
    if (addBtns.every(isButtonDisabled)) {
      // All candidate buttons are unavailable in some way. Distinguish the
      // common subcases.
      const allHidden = addBtns.every(
        (b) => b.offsetParent === null || b.getBoundingClientRect().width === 0,
      );
      if (allHidden) {
        return "FAIL: add-comment button is hidden (collapsed in toolbar overflow and not reachable, or editor pane too narrow)";
      }
      return "FAIL: add-comment button present but disabled — selection may have been cleared, or Overleaf is in a non-comment-capable mode (e.g. compare/history)";
    }
    if (uiLanguage() && uiLanguage() !== "en") {
      return (
        "FAIL: add-comment button not findable; Overleaf UI language is '" +
        uiLanguage() +
        "', this skill requires English UI"
      );
    }
    return "FAIL: add-comment button unavailable (selection cleared or modal in flight)";
  }

  async function post(line, text) {
    // Re-check for an "Out of sync" modal that may have appeared since the
    // wrapper's pre-flight check. If we click Reload editor, the page
    // navigates and the helpers are wiped — the wrapper detects this and
    // bails with EX_TEMPFAIL.
    if ((await dismissModals()) === "reloaded") {
      return "RELOADED: editor reloaded mid-run";
    }

    const view = getView();
    if (!view) return "FAIL: no editor view";
    if (line < 1 || line > view.state.doc.lines) {
      return "FAIL: line " + line + " out of range (doc has " + view.state.doc.lines + ")";
    }
    const ln = view.state.doc.line(line);
    if (ln.text.trim().length === 0) {
      return "FAIL: line " + line + " is blank — Overleaf cannot anchor a comment";
    }
    view.dispatch({
      selection: { anchor: ln.from, head: ln.to },
      scrollIntoView: true,
    });
    // NOTE: deliberately do NOT call view.focus() here. Calling focus()
    // closes Overleaf's toolbar-overflow popover (which is dismissed on
    // focus-out), which then collapses the Add-comment button before we can
    // click it.

    // Poll for an Add-comment button. The budget covers both the
    // selection-aware enable (~50–100 ms after dispatch) and the
    // toolbar-rebind after a fresh openFile (~1 s). Replaces a fixed
    // 400 ms sleep + 30-iter poll with a single 50-iter × 100 ms = 5 s
    // budget that adapts to actual latency.
    let addBtn = null;
    for (let i = 0; i < 50; i++) {
      await sleep(100);
      addBtn = await ensureAddCommentVisible();
      if (addBtn) break;
    }
    if (!addBtn) return diagnoseAddCommentUnavailable();
    addBtn.click();

    // Poll for the textarea to appear.
    let ta = null;
    for (let i = 0; i < 25; i++) {
      await sleep(80);
      ta = document.querySelector(SEL.commentTextarea);
      if (ta) break;
    }
    if (!ta) {
      // No textarea opened — there is no dialog state to clean up.
      return "FAIL: comment textarea did not appear";
    }

    ta.focus();
    const setter = Object.getOwnPropertyDescriptor(
      HTMLTextAreaElement.prototype,
      "value",
    ).set;
    setter.call(ta, text);
    ta.dispatchEvent(new Event("input", { bubbles: true }));

    // Search Submit/Cancel within the review panel — Overleaf renders
    // other buttons in the page chrome whose text might also be "Comment"
    // or "Cancel". A global query would misroute clicks.
    const findSubmit = () =>
      findInPanel((b) => b.offsetParent && b.textContent.trim() === TXT.submit);

    let submit = findSubmit();
    for (let i = 0; i < 20 && isButtonDisabled(submit); i++) {
      await sleep(100);
      submit = findSubmit();
    }
    if (!submit) {
      closeOpenCommentDialog();
      return "FAIL: no submit button found";
    }
    if (isButtonDisabled(submit)) {
      closeOpenCommentDialog();
      return "FAIL: submit stayed disabled after typing";
    }
    submit.click();

    // Wait until the textarea is gone (Overleaf removes it on successful
    // submit). On lingering textarea, do NOT click Cancel: Submit fired,
    // the comment may already have landed server-side, and Cancel could
    // either be a no-op or, in some Overleaf versions, discard the saved
    // comment. Report a yellow-flag FAIL and let the operator decide.
    for (let i = 0; i < 15; i++) {
      await sleep(80);
      if (!document.querySelector(SEL.commentTextarea)) {
        return "OK: line " + line;
      }
    }
    return "FAIL: textarea did not close after submit — comment may have landed server-side; verify before retrying";
  }

  // One-shot startup probe: returns the active user, the UI language, and
  // whether the tab is currently hidden — bundled so the wrapper can read
  // all three signals in a single cdp eval round-trip.
  function preflight() {
    return {
      user: activeUser(),
      lang: uiLanguage(),
      hidden: document.hidden,
    };
  }

  window.__overleaf = { post, openFile, dismissModals, activeUser, uiLanguage, preflight };
})();

"overleaf helpers installed";
