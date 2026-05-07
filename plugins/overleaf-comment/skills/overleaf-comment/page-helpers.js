// page-helpers.js — injected into the Overleaf project tab.
// Defines window.__overleaf with: post(), openFile(), dismissModals(),
// activeUser(), uiLanguage(). All async functions return a string starting
// with "OK: ", "FAIL: ", or "RELOADED: ".
//
// The bash wrapper drives the loop one item at a time so each cdp eval stays
// well under chrome-cdp's 15-second Runtime.evaluate ceiling.

(() => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  // Scope all DOM queries that look for buttons by name to a panel so we
  // don't accidentally click a Cancel/Reload/Comment button somewhere else
  // in Overleaf's chrome (rename modal, share dialog, billing CTA…).
  const REVIEW_PANEL_SEL =
    ".review-panel-add-comment, .review-panel-new-thread, .review-panel-redesign-popup";
  function findInPanelOrDoc(selectorOrPredicate) {
    const panel = document.querySelector(REVIEW_PANEL_SEL);
    const root = panel || document;
    if (typeof selectorOrPredicate === "string") {
      return root.querySelector(selectorOrPredicate);
    }
    return [...root.querySelectorAll("button")].find(selectorOrPredicate);
  }

  // The main editing surface: prefer the editor inside Overleaf's IDE panel
  // and fall back to any .cm-content (e.g. when the IDE shell hasn't fully
  // mounted yet). This avoids accidentally driving the comment-textarea's
  // own CodeMirror or the diff/history view.
  function getView() {
    const cm =
      document.querySelector(".ide-react-editor-panel .cm-content") ||
      document.querySelector(".cm-editor.cm-focused .cm-content") ||
      document.querySelector(".cm-content");
    return cm && cm.cmView && cm.cmView.view;
  }

  // Tree items mix the file icon ("description"), the filename, and a "more_vert"
  // menu glyph when hovered/selected. Read the inner `.item-name` element when
  // present; fall back to whole textContent.
  const itemText = (i) => {
    const inner = i.querySelector(".item-name, [class*='item-name']");
    return (inner ? inner.textContent : i.textContent).trim();
  };

  // Compute the basename, splitting on both / and \ so plans authored on Windows
  // also work.
  function basenameOf(name) {
    const parts = name.split(/[\\/]/);
    return parts[parts.length - 1];
  }

  // Dismiss the "Out of sync" modal. Returns "reloaded" if a reload was
  // triggered (caller must re-inject helpers, since the page navigates).
  async function dismissModals() {
    const reload = [...document.querySelectorAll("button")].find(
      (b) => b.offsetParent && b.textContent.trim() === "Reload editor",
    );
    if (reload) {
      reload.click();
      return "reloaded";
    }
    return "ok";
  }

  // Strict file-tree match. Exact-basename first; fall back to
  // separator-bounded suffix only when the user supplied a path-like name and
  // exactly one tree item matches. Plain `endsWith(basename)` is rejected
  // because `intro.tex` would silently target `myintro.tex`.
  function findTreeItem(name) {
    const basename = basenameOf(name);
    const items = [...document.querySelectorAll('[role="treeitem"]')];
    const exact = items.filter((i) => itemText(i) === basename);
    if (exact.length === 1) return exact[0];
    if (exact.length > 1) return { ambiguous: exact };

    if (name.includes("/") || name.includes("\\")) {
      // Path-suffix fallback: only match items whose displayed name ends with
      // a separator + the requested basename. (No bare-equality fallback —
      // exact match was already tried above.)
      const sepEnd = items.filter((i) => {
        const t = itemText(i);
        return t.endsWith("/" + basename) || t.endsWith("\\" + basename);
      });
      if (sepEnd.length === 1) return sepEnd[0];
      if (sepEnd.length > 1) return { ambiguous: sepEnd };
    }
    return null;
  }

  // Probe the active Overleaf account, if Overleaf exposes it. Returns null
  // when none of the known signals are present (Overleaf can change these,
  // so callers must tolerate null).
  function activeUser() {
    // 1) Overleaf's MetaProvider sets a meta tag on initial render.
    const meta = document.querySelector('meta[name="ol-user"]');
    if (meta && meta.content) {
      try {
        const parsed = JSON.parse(meta.content);
        return parsed.email || parsed.first_name || null;
      } catch (_) {}
    }
    // 2) Some Overleaf builds expose window.user.
    if (window.user && (window.user.email || window.user.first_name)) {
      return window.user.email || window.user.first_name;
    }
    // 3) Newer dashboards have an avatar with a `data-` attribute.
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
    return (
      document.querySelector('[role="treeitem"][aria-selected="true"]') ||
      document.querySelector('[role="treeitem"].selected') ||
      document.querySelector('[role="treeitem"][aria-current="true"]')
    );
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
    // (A full path-walk would be more precise but the overhead is negligible.)
    if (!target) {
      const collapsed = [...document.querySelectorAll('[role="treeitem"][aria-expanded="false"]')];
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
        // Wait for the toolbar Add-comment button to actually be available
        // (instead of a fixed sleep). The Overleaf review-panel toolbar
        // re-binds asynchronously after a file swap, and on a slow build
        // the previous fixed 1.2 s wasn't always enough. Polling means
        // we wait exactly as long as needed and no more.
        for (let j = 0; j < 30; j++) {
          await sleep(80);
          if (await ensureAddCommentVisible({ probeOnly: true })) break;
        }
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
  // collapsed it, click the "More editor toolbar items" toggle first so the
  // button is rendered into a visible popover. Returns the visible button
  // or null. With { probeOnly: true } the function does not toggle the
  // overflow popover (so it can be polled cheaply during settling).
  async function ensureAddCommentVisible(opts) {
    const probeOnly = !!(opts && opts.probeOnly);
    let visible = [...document.querySelectorAll('button[aria-label="Add comment"]')].find(
      (b) => !isButtonDisabled(b),
    );
    if (visible) return visible;
    if (probeOnly) return null;

    const overflowToggle = document.querySelector(
      'button[aria-label*="More editor" i], .ol-cm-toolbar-overflow-toggle',
    );
    if (overflowToggle && overflowToggle.getAttribute("aria-expanded") !== "true") {
      overflowToggle.click();
      for (let i = 0; i < 25; i++) {
        await sleep(80);
        visible = [...document.querySelectorAll('button[aria-label="Add comment"]')].find(
          (b) => !isButtonDisabled(b),
        );
        if (visible) return visible;
      }
    }
    return null;
  }

  // Dismiss any half-open comment dialog before / after a failed post so the
  // next iteration starts clean. Scoped to the review-panel container so we
  // do not click a stray Cancel button in some other Overleaf modal.
  function closeOpenCommentDialog() {
    const cancel = findInPanelOrDoc(
      (b) => b.offsetParent && b.textContent.trim() === "Cancel",
    );
    if (cancel) cancel.click();
  }

  // Distinguish between common causes of "Add comment unavailable" so the
  // operator gets actionable diagnosis instead of a panic message.
  function diagnoseAddCommentUnavailable() {
    const addBtns = [...document.querySelectorAll('button[aria-label="Add comment"]')];
    if (addBtns.length === 0) {
      // No button in DOM at all — strongest signal that this Overleaf project
      // doesn't expose comment-creation (free-tier, viewer-only share,
      // archived).
      return "FAIL: comments are not available on this project (free-tier without comments, viewer-only share, or archived)";
    }
    if (addBtns.every((b) => b.disabled || b.getAttribute("aria-disabled") === "true")) {
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

    await sleep(400);
    const addBtn = await ensureAddCommentVisible();
    if (!addBtn) return diagnoseAddCommentUnavailable();
    addBtn.click();

    // Poll for the textarea to appear.
    let ta = null;
    for (let i = 0; i < 25; i++) {
      await sleep(80);
      ta = document.querySelector("textarea.review-panel-add-comment-textarea");
      if (ta) break;
    }
    if (!ta) {
      closeOpenCommentDialog();
      return "FAIL: comment textarea did not appear";
    }

    ta.focus();
    const setter = Object.getOwnPropertyDescriptor(
      HTMLTextAreaElement.prototype,
      "value",
    ).set;
    setter.call(ta, text);
    ta.dispatchEvent(new Event("input", { bubbles: true }));

    // Search Submit/Cancel buttons within the review panel only — Overleaf
    // renders many other buttons in the page chrome whose text might also
    // be "Comment" or "Cancel", and a global query would misroute clicks.
    const findSubmit = () =>
      findInPanelOrDoc((b) => b.offsetParent && b.textContent.trim() === "Comment");

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
    // either be a no-op (best case) or, on the version of Overleaf where
    // Cancel doubles as a delete-after-save affordance, discard the saved
    // comment. Report a yellow-flag FAIL and let the operator decide.
    for (let i = 0; i < 15; i++) {
      await sleep(80);
      if (!document.querySelector("textarea.review-panel-add-comment-textarea")) {
        return "OK: line " + line;
      }
    }
    return "FAIL: textarea did not close after submit — comment may have landed server-side; verify before retrying";
  }

  window.__overleaf = { post, openFile, dismissModals, activeUser, uiLanguage };
})();

"overleaf helpers installed";
