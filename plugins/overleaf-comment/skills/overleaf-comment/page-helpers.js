// page-helpers.js — injected into the Overleaf project tab.
// Defines window.__overleaf with: post(), openFile(), dismissModals().
// All functions are async and return a string starting with "OK: " or "FAIL: ".
//
// The bash wrapper drives the loop one item at a time so each cdp eval stays
// well under chrome-cdp's 15-second Runtime.evaluate ceiling.

(() => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

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
      const sepEnd = items.filter((i) => {
        const t = itemText(i);
        return t.endsWith("/" + basename) || t.endsWith("\\" + basename) || t === basename;
      });
      if (sepEnd.length === 1) return sepEnd[0];
      if (sepEnd.length > 1) return { ambiguous: sepEnd };
    }
    return null;
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

    if (!target) return "FAIL: not found in tree: " + name;
    if (target.ambiguous) {
      return "FAIL: ambiguous match for " + name + " — " + target.ambiguous.length + " tree items match";
    }

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
        // Settle: let Overleaf's review-panel toolbar rebind to the new
        // file's selection state before a post() reads the Add-comment
        // button. Empirically the toolbar takes ~1 s to re-bind after a
        // file swap; without this settle, the first post() after each open
        // can hang while waiting for the button to enable.
        await sleep(1200);
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
  // button is rendered into a visible popover. Returns the visible
  // button or null.
  async function ensureAddCommentVisible() {
    let visible = [...document.querySelectorAll('button[aria-label="Add comment"]')].find(
      (b) => !isButtonDisabled(b),
    );
    if (visible) return visible;

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
  // next iteration starts clean.
  function closeOpenCommentDialog() {
    const cancel = [...document.querySelectorAll("button")].find(
      (b) => b.offsetParent && b.textContent.trim() === "Cancel",
    );
    if (cancel) cancel.click();
  }

  async function post(line, text) {
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
    if (!addBtn) {
      return "FAIL: add-comment button unavailable (selection cleared, modal in flight, or comments disabled for this project)";
    }
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

    // Search Submit/Cancel buttons from the document — Overleaf renders them
    // as siblings of the textarea container, not inside ta.parentElement.
    const findSubmit = () =>
      [...document.querySelectorAll("button")].find(
        (b) => b.offsetParent && b.textContent.trim() === "Comment",
      );

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
    // submit). If it lingers, surface as failure rather than a misleading OK.
    for (let i = 0; i < 15; i++) {
      await sleep(80);
      if (!document.querySelector("textarea.review-panel-add-comment-textarea")) {
        return "OK: line " + line;
      }
    }
    closeOpenCommentDialog();
    return "FAIL: textarea did not close after submit";
  }

  window.__overleaf = { post, openFile, dismissModals };
})();

"overleaf helpers installed";
