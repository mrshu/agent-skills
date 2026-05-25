#!/usr/bin/env python3
"""Normalize Overleaf/pdfTeX + biber build logs into a standardized format.

Reads the raw ``output.log`` (and optionally ``output.blg``) that the page
helper fetched from Overleaf and emits either JSON or compiler-style text.

The canonical output is JSON: a list of ``{level, file, line, message,
source}`` entries plus a ``compile`` summary. ``--format compiler`` renders
the same entries as greppable ``file:line: level: message`` lines for humans
and editor integrations.

Design notes / deliberate conservatism:
  * The actionable signals — message text and the ``l.<n>`` / ``on input
    line <n>`` line number — are extracted with tight regexes that do not
    depend on log line-wrapping.
  * File attribution walks pdfTeX's ``(file ... )`` nesting, but only pushes
    when the token after ``(`` looks like a real source file (known
    extension). This skips page markers ``[12]``, counters ``(\\count188)``
    and hbox-content parens like ``(+20)``. It is best-effort: a stray ``)``
    inside content can still mis-pop, so ``file`` may be approximate while
    ``line`` stays exact.
  * biber/BibTeX diagnostics are tagged ``bib-error`` / ``bib-warning`` and
    never dressed up as ordinary LaTeX line errors.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import OrderedDict

# --- file-stack tracking ---------------------------------------------------

# Only treat "(token" as opening a real source file when the token carries a
# known TeX-ish extension; everything else (page numbers, counters, dimen
# echoes) is ignored so it cannot corrupt the stack.
_SOURCE_EXT = (
    "tex|sty|cls|bib|bbl|aux|def|cfg|clo|fd|ldf|dfu|enc|out|toc|lof|lot|"
    "nav|snm|vrb|bst|cnf|map|mkii|mkiv"
)
_OPEN_FILE = re.compile(r"\((\.?/?[^()\s{}]*\.(?:" + _SOURCE_EXT + r"))")


def _basename(path: str) -> str:
    # Overleaf logs paths relative to the compile root; keep them readable but
    # drop the synthetic /compile/ prefix some builds emit.
    p = path.lstrip("./")
    if p.startswith("compile/"):
        p = p[len("compile/"):]
    return p


class FileTracker:
    """Best-effort current-source-file tracker driven by pdfTeX parens."""

    def __init__(self) -> None:
        self.stack: list[str] = []
        # The first file opened is the compile root (e.g. acl_latex.tex). We
        # fall back to it when the stack underflows — stray content parens
        # like "(level 2)" pop without a matching push, so the stack drains
        # mid-document. Defaulting to the root attributes body diagnostics to
        # the main source instead of "?", which is both more useful and, for
        # the common case, correct.
        self.root: str | None = None

    def feed(self, line: str) -> None:
        # Walk the line left to right, pushing on recognized file-opens and
        # popping on ')'. We scan a flattened sequence of events in order.
        events: list[tuple[int, str]] = []
        for m in _OPEN_FILE.finditer(line):
            events.append((m.start(), "push:" + _basename(m.group(1))))
        for m in re.finditer(r"\)", line):
            events.append((m.start(), "pop"))
        for _, ev in sorted(events, key=lambda e: e[0]):
            if ev == "pop":
                if self.stack:
                    self.stack.pop()
            else:
                name = ev[len("push:"):]
                if self.root is None:
                    self.root = name
                self.stack.append(name)

    @property
    def current(self) -> str | None:
        return self.stack[-1] if self.stack else self.root


# --- pdfTeX log parsing ----------------------------------------------------

_LINE_NO = re.compile(r"^l\.(\d+)")
_MACRO = re.compile(r"(\\[A-Za-z@]+)\s*$")

_WARN_INPUT_LINE = re.compile(r"on input line (\d+)")
_BOX = re.compile(
    r"^(Overfull|Underfull|Loose|Tight) \\([hv])box "
    r".*?(?:at lines (\d+)--\d+|detected at line (\d+)|while \\output is active)"
)
# Warnings AND package "Info" chatter share a prefix grammar; we match both
# and classify by whether the line says "Info:" so callers can drop the noise.
_GENERIC_DIAG = re.compile(
    r"^(?:(?:LaTeX|pdfTeX|LuaTeX|XeTeX)(?: Font)? (?:Warning|Info)"
    r"|(?:Package|Class|Module) \S+ (?:Warning|Info)"
    r"|pdfTeX warning)"
)
# Wrapped package diagnostics continue on lines that start with a "(pkgname)"
# gutter — distinct from a "(/path/file.sty" file-open, which must NOT be
# slurped into the message.
_CONT_GUTTER = re.compile(r"^\([A-Za-z][\w@.\-]*\)")


def parse_latex_log(text: str, source: str = "output.log") -> list[dict]:
    lines = text.split("\n")
    tracker = FileTracker()
    entries: list[dict] = []
    i = 0
    n = len(lines)

    while i < n:
        line = lines[i]

        # --- errors: a line beginning with "! " ---------------------------
        if line.startswith("!"):
            message = line[1:].strip().rstrip(".")
            # Scan forward for the offending macro (last \cmd on a context
            # line) and the l.<n> source line. TeX prints a few context lines
            # between the "!" and the "l.<n>" marker.
            macro = None
            line_no = None
            j = i + 1
            limit = min(n, i + 25)
            while j < limit:
                lj = lines[j]
                mline = _LINE_NO.match(lj)
                if mline:
                    line_no = int(mline.group(1))
                    break
                mm = _MACRO.search(lj.rstrip())
                if mm and lj.lstrip().startswith(("<", "<*>", "<recently", "<argument", "<inserted", "<to be")):
                    macro = mm.group(1)
                j += 1
            if macro and "control sequence" in message.lower():
                message = f"{message} ({macro})"
            entries.append({
                "level": "error",
                "file": tracker.current,
                "line": line_no,
                "message": message,
                "source": source,
            })
            tracker.feed(line)
            i += 1
            continue

        # --- box (typesetting) warnings -----------------------------------
        mbox = _BOX.match(line)
        if mbox:
            line_no = mbox.group(3) or mbox.group(4)
            entries.append({
                "level": "typesetting",
                "file": tracker.current,
                "line": int(line_no) if line_no else None,
                "message": line.strip(),
                "source": source,
            })
            tracker.feed(line)
            i += 1
            continue

        # --- generic warnings + package Info chatter ----------------------
        if _GENERIC_DIAG.match(line):
            buf = [line.strip()]
            k = i + 1
            while k < n and _CONT_GUTTER.match(lines[k].lstrip()):
                buf.append(lines[k].strip())
                k += 1
            joined = re.sub(r"\s+", " ", " ".join(buf))
            mno = _WARN_INPUT_LINE.search(joined)
            entries.append({
                "level": "info" if "Info:" in line else "warning",
                "file": tracker.current,
                "line": int(mno.group(1)) if mno else None,
                "message": joined,
                "source": source,
            })
            tracker.feed(line)
            i = k
            continue

        tracker.feed(line)
        i += 1

    return entries


# --- biber / BibTeX log parsing -------------------------------------------

_BIB_LINE_FILE = re.compile(r"---line (\d+) of file (\S+)")

# Overleaf wraps log-entry locations in bidi control chars (U+202A..U+202E,
# U+2066..U+2069); strip them before parsing "path, line".
_BIDI = re.compile(r"[‪-‮⁦-⁩]")
_DOM_LOC = re.compile(r"^(.*?)(?:,\s*(\d+))?\s*$")


def parse_dom_entries(text: str) -> list[dict]:
    """Normalize the DOM logs-pane scrape (domEntries()) into entries.

    Input is the JSON ``[{level, loc, msg}]`` array produced by the page
    helper. Lossy by nature (Overleaf truncates long messages), used only on
    the ``--no-recompile`` path where no raw build artifact is available.
    """
    rows = json.loads(text) if text.strip() else []
    entries: list[dict] = []
    for r in rows:
        loc = _BIDI.sub("", r.get("loc") or "").strip()
        m = _DOM_LOC.match(loc)
        file_ = (m.group(1).strip() or None) if m else (loc or None)
        line = int(m.group(2)) if (m and m.group(2)) else None
        entries.append({
            "level": r.get("level") or "info",
            "file": file_,
            "line": line,
            "message": re.sub(r"\s+", " ", (r.get("msg") or "").strip()),
            "source": "dom",
        })
    return entries


def parse_biber_log(text: str, source: str = "output.blg") -> list[dict]:
    entries: list[dict] = []
    for line in text.split("\n"):
        s = line.strip()
        if not s:
            continue
        level = None
        if s.startswith(("ERROR -", "FATAL -")) or s.startswith("I couldn't"):
            level = "bib-error"
        elif s.startswith(("WARN -", "Warning--")):
            level = "bib-warning"
        if not level:
            continue
        mlf = _BIB_LINE_FILE.search(s)
        entries.append({
            "level": level,
            "file": mlf.group(2) if mlf else None,
            "line": int(mlf.group(1)) if mlf else None,
            "message": s,
            "source": source,
        })
    return entries


# --- dedup / summary -------------------------------------------------------

def dedup(entries: list[dict]) -> list[dict]:
    seen: "OrderedDict[tuple, dict]" = OrderedDict()
    for e in entries:
        key = (e["level"], e.get("file"), e.get("line"), e["message"])
        if key in seen:
            seen[key]["count"] += 1
        else:
            row = dict(e)
            row["count"] = 1
            seen[key] = row
    return list(seen.values())


def summarize(entries: list[dict]) -> dict:
    out = {"errors": 0, "warnings": 0, "typesetting": 0, "info": 0, "bib": 0}
    for e in entries:
        c = e.get("count", 1)
        lvl = e["level"]
        if lvl == "error":
            out["errors"] += c
        elif lvl == "warning":
            out["warnings"] += c
        elif lvl == "typesetting":
            out["typesetting"] += c
        elif lvl == "info":
            out["info"] += c
        elif lvl.startswith("bib"):
            out["bib"] += c
    return out


# --- rendering -------------------------------------------------------------

def render_compiler(entries: list[dict], compile_meta: dict, summary: dict) -> str:
    out = []
    for e in entries:
        loc = e.get("file") or "?"
        if e.get("line"):
            loc += f":{e['line']}"
        mult = f" [x{e['count']}]" if e.get("count", 1) > 1 else ""
        out.append(f"{loc}: {e['level']}: {e['message']}{mult}")
    pages = (compile_meta or {}).get("pages")
    tail = f" ({pages} pages)" if pages else ""
    out.append(
        f"summary: {summary['errors']} errors, {summary['warnings']} warnings, "
        f"{summary['typesetting']} typesetting, {summary['info']} info, {summary['bib']} bib"
        f"  [status={compile_meta.get('status', '?')}]{tail}"
    )
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--log", help="path to raw output.log")
    ap.add_argument("--blg", help="path to raw output.blg")
    ap.add_argument("--dom", help="path to DOM logs-pane scrape JSON (--no-recompile path)")
    ap.add_argument("--meta", help="path to compile-status JSON (from poll())")
    ap.add_argument("--format", choices=["json", "compiler"], default="json")
    ap.add_argument("--info", action="store_true",
                    help="include low-value Package/Font 'Info:' lines (off by default)")
    ap.add_argument("--errors-only", action="store_true",
                    help="show only errors (LaTeX + bib)")
    ap.add_argument("--no-dedup", action="store_true",
                    help="keep every identical entry instead of collapsing with a count")
    ap.add_argument("--raw-tail", type=int, default=0, metavar="N",
                    help="include the last N lines of output.log in JSON output")
    args = ap.parse_args()

    raw_log = ""
    entries: list[dict] = []
    if args.log and os.path.exists(args.log):
        with open(args.log, encoding="utf-8", errors="replace") as fh:
            raw_log = fh.read()
        entries += parse_latex_log(raw_log)
    if args.blg and os.path.exists(args.blg):
        with open(args.blg, encoding="utf-8", errors="replace") as fh:
            entries += parse_biber_log(fh.read())
    if args.dom and os.path.exists(args.dom):
        with open(args.dom, encoding="utf-8", errors="replace") as fh:
            entries += parse_dom_entries(fh.read())

    compile_meta = {}
    if args.meta and os.path.exists(args.meta):
        try:
            with open(args.meta, encoding="utf-8") as fh:
                j = json.load(fh)
            stats = j.get("stats") or {}
            compile_meta = {
                "status": j.get("status"),
                "buildId": j.get("buildId"),
                "pages": stats.get("pdf-pages") or stats.get("pdfPages"),
                "timings": j.get("timings"),
                "hasPdf": j.get("hasPdf"),
            }
        except Exception:
            compile_meta = {}

    # Default view is errors + warnings + typesetting + bib. Package "Info:"
    # chatter (dozens of lines per compile) is dropped unless --info; with
    # --errors-only everything but errors is filtered for fast triage.
    if args.errors_only:
        entries = [e for e in entries if e["level"] in ("error", "bib-error")]
    elif not args.info:
        entries = [e for e in entries if e["level"] != "info"]

    if not args.no_dedup:
        entries = dedup(entries)
    else:
        for e in entries:
            e.setdefault("count", 1)

    # pdfTeX always prints the page count on a successful run; use it when the
    # compile-stats payload didn't carry one.
    if not compile_meta.get("pages") and raw_log:
        mp = re.search(r"Output written on \S+ \((\d+) pages?", raw_log)
        if mp:
            compile_meta["pages"] = int(mp.group(1))

    summary = summarize(entries)
    compile_meta = dict(compile_meta)
    compile_meta.update(summary)

    if args.format == "compiler":
        print(render_compiler(entries, compile_meta, summary))
    else:
        payload = {"compile": compile_meta, "entries": entries}
        if args.raw_tail > 0 and raw_log:
            payload["rawTail"] = "\n".join(raw_log.split("\n")[-args.raw_tail:])
        print(json.dumps(payload, indent=2, ensure_ascii=False))

    # One-line verdict to stderr (in both formats) and an exit code the
    # wrapper can pass straight through: non-zero iff there are real errors
    # (LaTeX or bib), so callers can branch without re-parsing.
    bib_errors = sum(e.get("count", 1) for e in entries if e["level"] == "bib-error")
    err_total = summary["errors"] + bib_errors
    status = compile_meta.get("status")
    print(
        f"parse_log: {summary['errors']} errors, {summary['warnings']} warnings, "
        f"{summary['typesetting']} typesetting, {summary['info']} info, {summary['bib']} bib"
        + (f" [status={status}]" if status else ""),
        file=sys.stderr,
    )
    return 1 if err_total > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
