// page-helpers.js — injected into an Overleaf project tab.
//
// Registers window.__olCompile, which drives Overleaf's *internal* compile
// path from inside the already-authenticated page context:
//
//   POST /project/:id/compile           -> { status, outputFiles:[{path,url,build}], clsiServerId, ... }
//   GET  <outputFile.url>?clsiserverid= -> raw output.log / output.blg text
//
// Doing this from the page (rather than the bash wrapper) is what makes it
// work at all: the page holds the session cookie and the ol-csrfToken meta
// tag. The bash wrapper has neither.
//
// A compile of a real paper can take much longer than chrome-cdp's 15 s
// Runtime.evaluate ceiling, so the work is split into a fire-and-poll shape:
//   start()  -> kicks the compile off, returns immediately
//   poll()   -> cheap status read (no raw log text), called in a loop
//   raw(w)   -> returns the stored raw output.log / output.blg once done
// Each call stays well under the eval ceiling regardless of compile time.
//
// The namespace is deliberately __olCompile (not __overleaf) so this can
// coexist with the overleaf-comment skill's helpers in the same tab.

(() => {
  const meta = (name) => {
    const m = document.querySelector('meta[name="' + name + '"]');
    return m ? m.content : null;
  };

  // Project id, CSRF token and the user-content domain all live in <meta
  // name="ol-*"> tags on the editor page. projectId falls back to the URL.
  function ctx() {
    const projectId =
      meta("ol-project_id") ||
      (location.pathname.match(/\/project\/([0-9a-f]+)/) || [])[1] ||
      null;
    return {
      projectId,
      csrf: meta("ol-csrfToken"),
      // pdfDownloadDomain is the canonical user-content origin; fall back to
      // compilesUserContentDomain. Used only if a same-origin output fetch
      // does not return 200.
      pdfDomain:
        meta("ol-pdfDownloadDomain") ||
        meta("ol-compilesUserContentDomain") ||
        "",
    };
  }

  // Output files are served with a ?clsiserverid= query that pins the request
  // to the CLSI node that produced the build; without it a load-balanced
  // backend can 404.
  function outputUrl(url, clsiServerId, origin) {
    const sep = url.includes("?") ? "&" : "?";
    const q = clsiServerId
      ? sep + "clsiserverid=" + encodeURIComponent(clsiServerId)
      : "";
    return (origin || "") + url + q;
  }

  async function fetchText(url) {
    const r = await fetch(url, { credentials: "include" });
    return { http: r.status, text: r.status === 200 ? await r.text() : "" };
  }

  // Same-origin first (observed to work); fall back to the user-content
  // origin only if that is non-200.
  async function fetchOutput(file, clsiServerId, pdfDomain) {
    let res = await fetchText(outputUrl(file.url, clsiServerId, ""));
    if (res.http !== 200 && pdfDomain) {
      res = await fetchText(outputUrl(file.url, clsiServerId, pdfDomain));
    }
    return res;
  }

  async function runCompile(opts) {
    const { projectId, csrf, pdfDomain } = ctx();
    if (!projectId) return { error: "no project id found on this page" };
    if (!csrf) {
      return {
        error:
          "no ol-csrfToken on this page — session likely expired; reload Overleaf and log in",
      };
    }

    // "Recompile from scratch": drop the build cache before compiling.
    if (opts.clearCache) {
      try {
        await fetch("/project/" + projectId + "/output", {
          method: "DELETE",
          headers: { "X-Csrf-Token": csrf },
          credentials: "include",
        });
      } catch (e) {
        /* non-fatal; a stale cache just means a slower/again-dirty compile */
      }
    }

    const auto = opts.autoCompile === false ? "false" : "true";
    let resp;
    try {
      resp = await fetch(
        "/project/" + projectId + "/compile?auto_compile=" + auto,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Csrf-Token": csrf,
          },
          credentials: "include",
          body: JSON.stringify({
            rootDoc_id: null,
            draft: !!opts.draft,
            check: "silent",
            // A from-scratch run must not reuse incremental aux state.
            incrementalCompilesEnabled: !opts.clearCache,
            stopOnFirstError: !!opts.stopOnFirstError,
          }),
        },
      );
    } catch (e) {
      return { error: "compile request failed: " + String(e) };
    }
    if (resp.status === 401 || resp.status === 403) {
      return {
        error:
          "compile rejected (HTTP " +
          resp.status +
          ") — CSRF/session expired; reload the Overleaf tab",
      };
    }
    let j;
    try {
      j = await resp.json();
    } catch (e) {
      return { error: "compile response was not JSON (HTTP " + resp.status + ")" };
    }

    const clsiServerId = j.clsiServerId || null;
    const files = j.outputFiles || [];
    const byPath = (p) => files.find((f) => f.path === p);
    const logFile = byPath("output.log");
    const blgFile = byPath("output.blg");
    const pdfFile = byPath("output.pdf");

    // Overleaf's `status` reports whether the COMPILER RAN and produced a
    // PDF — NOT whether the source is error-free. "success" routinely comes
    // back alongside dozens of undefined-control-sequence errors. The real
    // error/warning verdict is parsed from the log downstream.
    const result = {
      done: true,
      http: resp.status,
      status: j.status,
      buildId: (logFile && logFile.build) || (pdfFile && pdfFile.build) || null,
      clsiServerId,
      compileGroup: j.compileGroup || null,
      stats: j.stats || null,
      timings: j.timings || null,
      hasLog: !!logFile,
      hasBlg: !!blgFile,
      hasPdf: !!pdfFile,
      rawLog: "",
      rawBlg: "",
    };

    if (logFile) {
      const r = await fetchOutput(logFile, clsiServerId, pdfDomain);
      result.logHttp = r.http;
      result.rawLog = r.text;
    }
    if (blgFile) {
      const r = await fetchOutput(blgFile, clsiServerId, pdfDomain);
      result.blgHttp = r.http;
      result.rawBlg = r.text;
    }
    result.logBytes = result.rawLog.length;
    result.blgBytes = result.rawBlg.length;
    return result;
  }

  // Fire-and-poll: kick the compile off and stash the eventual result on the
  // namespace. Returns synchronously so the eval call returns instantly.
  function start(opts) {
    const o = opts || {};
    const startedAt = Date.now();
    window.__olCompile._job = { done: false, startedAt };
    runCompile(o)
      .then((res) => {
        const ms = Date.now() - startedAt;
        window.__olCompile._job = res.error
          ? { done: true, ms, error: res.error }
          : Object.assign(res, { ms });
      })
      .catch((e) => {
        window.__olCompile._job = {
          done: true,
          ms: Date.now() - startedAt,
          error: String(e),
        };
      });
    return "STARTED";
  }

  // Cheap status read for the wrapper's poll loop. Strips the raw log blobs
  // so the eval payload stays tiny.
  function poll() {
    const j = window.__olCompile._job;
    if (!j) return JSON.stringify({ done: false, error: "no job started" });
    const { rawLog, rawBlg, ...rest } = j;
    return JSON.stringify(rest);
  }

  // Returns the stored raw text once the job is done. 'log' (default) or 'blg'.
  function raw(which) {
    const j = window.__olCompile._job || {};
    return (which === "blg" ? j.rawBlg : j.rawLog) || "";
  }

  // Fallback for --no-recompile: scrape Overleaf's rendered logs pane. Lossy
  // (Overleaf truncates long messages and only the last compile in THIS tab
  // is present), but needs no compile call. Full-fidelity logs require a
  // compile because the raw output.log URL is keyed by build id.
  function domEntries() {
    const out = [];
    for (const e of document.querySelectorAll(".log-entry")) {
      // Overleaf encodes the level on the header element's class
      // (log-entry-header-text-error / -warning / -typesetting), not on the
      // .log-entry container; fall back to the container for older builds.
      let level =
        (e.className.match(/log-entry-(error|warning|typesetting)/) || [])[1] ||
        "";
      if (!level) {
        const hdr = e.querySelector('[class*="log-entry-header-text-"]');
        if (hdr) {
          level =
            (hdr.className.match(/log-entry-header-text-(\w+)/) || [])[1] || "";
        }
      }
      const loc = (
        e.querySelector(".log-entry-header-link, .log-entry-location")
          ?.textContent || ""
      ).trim();
      const msg = (
        e.querySelector(".log-entry-content, .log-entry-content-raw, pre")
          ?.textContent || ""
      ).trim();
      if (!level && !msg) continue;
      out.push({ level, loc, msg });
    }
    return JSON.stringify(out);
  }

  window.__olCompile = { start, poll, raw, domEntries, ctx, _job: null };
})();

"olcompile helpers installed";
