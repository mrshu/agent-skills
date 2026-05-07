#!/usr/bin/env python3
"""Plan-validation and residual-emission helpers for the overleaf-comment skill.

Two subcommands:

    plan_tools.py validate <plan.json> <work-out.tsv>
        Validate the plan and emit a tab-separated work list:
          OPEN<TAB><file-display><TAB><JS-string-literal-of-file>
          POST<TAB><line-number><TAB><JS-string-literal-of-text>
        Both string literals are produced by json.dumps(), so they are safe
        to concatenate directly into a JS expression.

    plan_tools.py residual <residual-ndjson> <out-plan.json>
        Read an NDJSON file (one {"file", "line", "text"} object per line)
        and write it as a proper indented JSON array plan that can be
        re-fed into the wrapper.

Errors go to stderr prefixed with "overleaf-comment:" and produce a non-zero
exit code (2 for validation problems, 3 for I/O problems).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _die(msg: str, code: int = 2) -> None:
    print(f"overleaf-comment: {msg}", file=sys.stderr)
    sys.exit(code)


def _validate_item(i: int, it: object) -> tuple[str, int, str]:
    if not isinstance(it, dict):
        _die(f"item {i} is not an object")
    for k in ("file", "line", "text"):
        if k not in it:
            _die(f"item {i} missing key: {k}")
    file_val, line_val, text_val = it["file"], it["line"], it["text"]
    if not isinstance(file_val, str) or not file_val:
        _die(f"item {i}: file must be a non-empty string")
    # bool is a subclass of int — exclude it explicitly.
    if not isinstance(line_val, int) or isinstance(line_val, bool) or line_val < 1:
        _die(f"item {i}: line must be an integer >= 1")
    if not isinstance(text_val, str) or not text_val.strip():
        _die(f"item {i}: text must be a non-empty string")
    return file_val, line_val, text_val


def cmd_validate(plan_path: str, work_path: str) -> None:
    try:
        plan = json.loads(Path(plan_path).read_text())
    except Exception as e:
        _die(f"invalid plan JSON: {e}")
    if not isinstance(plan, list):
        _die("plan must be a JSON array")

    items = [_validate_item(i, it) for i, it in enumerate(plan)]

    lines: list[str] = []
    prev_file: str | None = None
    for file_val, line_val, text_val in items:
        if file_val != prev_file:
            lines.append(f"OPEN\t{file_val}\t{json.dumps(file_val)}")
            prev_file = file_val
        lines.append(f"POST\t{line_val}\t{json.dumps(text_val)}")

    Path(work_path).write_text("\n".join(lines) + ("\n" if lines else ""))
    print(f"plan: {len(plan)} items", file=sys.stderr)


def cmd_residual(ndjson_path: str, out_path: str) -> None:
    try:
        raw = Path(ndjson_path).read_text()
    except OSError as e:
        _die(f"could not read residual NDJSON: {e}", code=3)

    items: list[dict] = []
    for n, line in enumerate(raw.splitlines(), 1):
        if not line.strip():
            continue
        try:
            items.append(json.loads(line))
        except Exception as e:
            _die(f"residual NDJSON line {n} is not valid JSON: {e}", code=3)

    try:
        with open(out_path, "w") as g:
            json.dump(items, g, indent=2, ensure_ascii=False)
            g.write("\n")
    except OSError as e:
        _die(f"could not write residual plan: {e}", code=3)


def main(argv: list[str]) -> None:
    if len(argv) < 2:
        _die("usage: plan_tools.py {validate|residual} ARGS...", code=2)
    cmd = argv[1]
    if cmd == "validate":
        if len(argv) != 4:
            _die("usage: plan_tools.py validate <plan.json> <work-out.tsv>", code=2)
        cmd_validate(argv[2], argv[3])
    elif cmd == "residual":
        if len(argv) != 4:
            _die("usage: plan_tools.py residual <residual-ndjson> <out-plan.json>", code=2)
        cmd_residual(argv[2], argv[3])
    else:
        _die(f"unknown subcommand: {cmd}", code=2)


if __name__ == "__main__":
    main(sys.argv)
