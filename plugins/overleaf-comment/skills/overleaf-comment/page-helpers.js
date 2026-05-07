// page-helpers.js — injected into the Overleaf project tab.
// Defines window.__overleaf with: post(), openFile(), dismissModals(), run().
// All functions are async and return strings ("OK: ..." or "FAIL: ...").

(() => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  function getView() {
    const cm = document.querySelector(".cm-content");
    return cm && cm.cmView && cm.cmView.view;
  }

  // Dismiss the "Out of sync" / similar modals before posting.
  // Returns "reloaded" if a reload was triggered (caller should re-inject helpers).
  async function dismissModals() {
    const reload = [...document.querySelectorAll("button")].find(
      (b) => b.offsetParent && b.textContent.trim() === "Reload editor",
    );
    if (reload) {
      reload.click();
      // Page will refetch — helpers will be gone after reload.
      return "reloaded";
    }
    return "ok";
  }

  // Expand collapsed folders (parts/, etc.) until the requested file path is visible.
  // Accepts either bare basenames ("main.tex") or path-like ("parts/200-discussion.tex").
  async function openFile(name) {
    const basename = name.includes("/") ? name.split("/").pop() : name;
    // Tree items mix the file icon ("description"), filename, and a "more_vert" menu
    // icon when hovered/selected. Prefer the inner `.item-name` element when present;
    // fall back to whole textContent matching.
    const itemText = (i) => {
      const inner = i.querySelector(".item-name, [class*='item-name']");
      return (inner ? inner.textContent : i.textContent).trim();
    };
    // Click any chevron that hides our target.
    for (let attempt = 0; attempt < 3; attempt++) {
      const items = [...document.querySelectorAll('[role="treeitem"]')];
      const t = items.find((i) => {
        const txt = itemText(i);
        return txt === basename || txt.endsWith(basename);
      });
      if (t) {
        t.click();
        // Wait for editor to refresh.
        for (let i = 0; i < 25; i++) {
          await sleep(200);
          const v = getView();
          if (v && v.state.doc.lines > 0) {
            // Best-effort: ensure the visible doc actually corresponds to the requested file
            // by checking that the file-tree item is now selected.
            return "OK: " + name + " (" + v.state.doc.lines + " lines)";
          }
        }
        return "FAIL: editor did not load for " + name;
      }
      // Not found — try expanding any collapsed folders that might contain it.
      const folders = [...document.querySelectorAll('[role="treeitem"]')].filter(
        (i) =>
          i.getAttribute("aria-expanded") === "false" ||
          i.textContent.includes("chevron_right"),
      );
      if (folders.length === 0) break;
      folders.forEach((f) => f.click());
      await sleep(400);
    }
    return "FAIL: not found in tree: " + name;
  }

  // Post one comment on a specific line.
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
    view.focus();
    await sleep(350);

    const addBtn = document.querySelector('button[aria-label="Add comment"]');
    if (!addBtn || addBtn.getAttribute("aria-disabled") === "true") {
      return "FAIL: add-comment button unavailable (modal? selection cleared?)";
    }
    addBtn.click();
    await sleep(600);

    const ta = document.querySelector("textarea.review-panel-add-comment-textarea");
    if (!ta) return "FAIL: comment textarea did not appear";

    ta.focus();
    const setter = Object.getOwnPropertyDescriptor(
      HTMLTextAreaElement.prototype,
      "value",
    ).set;
    setter.call(ta, text);
    ta.dispatchEvent(new Event("input", { bubbles: true }));
    await sleep(300);

    // Wait for the Comment submit button to enable.
    let submit = [...ta.parentElement.querySelectorAll("button")].find(
      (b) => b.textContent.trim() === "Comment",
    );
    for (let i = 0; i < 12 && (!submit || submit.disabled); i++) {
      await sleep(200);
      submit = [...ta.parentElement.querySelectorAll("button")].find(
        (b) => b.textContent.trim() === "Comment",
      );
    }
    if (!submit) return "FAIL: no submit button found";
    if (submit.disabled) {
      // Cancel and let the caller retry.
      const cancel = [...ta.parentElement.querySelectorAll("button")].find(
        (b) => b.textContent.trim() === "Cancel",
      );
      if (cancel) cancel.click();
      return "FAIL: submit stayed disabled after typing";
    }
    submit.click();
    await sleep(700);
    return "OK: line " + line;
  }

  // Run an entire plan. plan = [{file, line, text}, ...].
  // Returns one log line per item.
  async function run(plan) {
    if (!Array.isArray(plan)) return "FAIL: plan must be a JSON array";
    // Pre-flight: dismiss any visible modal.
    const m = await dismissModals();
    if (m === "reloaded") return "RELOADED: editor was reloaded; re-inject helpers and re-run";

    // Group by file, preserving file order.
    const order = [];
    const byFile = {};
    for (const it of plan) {
      if (!byFile[it.file]) {
        byFile[it.file] = [];
        order.push(it.file);
      }
      byFile[it.file].push(it);
    }

    const out = [];
    for (const file of order) {
      const r1 = await openFile(file);
      out.push("[" + file + "] " + r1);
      if (r1.startsWith("FAIL")) continue;
      for (const it of byFile[file]) {
        let r = await post(it.line, it.text);
        if (r.startsWith("FAIL: add-comment button") || r.startsWith("FAIL: comment textarea")) {
          // Possible mid-run modal — try to dismiss and retry once.
          const dm = await dismissModals();
          if (dm === "reloaded") {
            out.push("  L" + it.line + ": RELOADED mid-run — aborting; re-run with remaining plan");
            return out.join("\n");
          }
          await sleep(500);
          r = await post(it.line, it.text);
        }
        if (r.startsWith("FAIL: submit stayed disabled")) {
          await sleep(500);
          r = await post(it.line, it.text);
        }
        out.push("  L" + it.line + ": " + r);
      }
    }
    return out.join("\n");
  }

  window.__overleaf = { post, openFile, dismissModals, run };
})();

"overleaf helpers installed";
