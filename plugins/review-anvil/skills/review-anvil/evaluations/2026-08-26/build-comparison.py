#!/usr/bin/env python3
"""Build readable and blind old-versus-new clarity-pass comparisons."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path


def fenced_quote(text: str) -> str:
    return "\n".join("> " + line if line else ">" for line in text.rstrip().splitlines())



def visible_text(text: str) -> str:
    return re.sub(r"\s*<!--.*?-->", "", text, flags=re.S)
def randomized_pair(item_id: str, before: str, after: str) -> tuple[dict, dict]:
    after_is_a = hashlib.sha256(item_id.encode("utf-8")).digest()[0] % 2 == 0
    pair = {"id": item_id, "A": after if after_is_a else before, "B": before if after_is_a else after}
    key = {"id": item_id, "A": "after" if after_is_a else "before", "B": "before" if after_is_a else "after"}
    return pair, key


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("corpus")
    parser.add_argument("bundles")
    parser.add_argument("output_dir")
    args = parser.parse_args()

    corpus = json.loads(Path(args.corpus).read_text(encoding="utf-8"))["cases"]
    bundles = json.loads(Path(args.bundles).read_text(encoding="utf-8"))["cases"]
    bundle_by_id = {item["case_id"]: item["bundle"] for item in bundles}
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    markdown = [
        "# Historical review clarity comparison",
        "",
        "The before side is verbatim GitHub output from prior `evaleval/every_eval_ever` review-anvil runs. The after side is a clean final clarity pass over frozen facts; it did not inspect the reviewed repositories.",
        "",
    ]
    blind, key = [], []
    for case in corpus:
        case_id = case["case_id"]
        if case_id not in bundle_by_id:
            raise SystemExit(f"missing rendered bundle for {case_id}")
        bundle = bundle_by_id[case_id]
        markdown.extend(
            [
                f"## PR #{case['source']['pr']} — review {case['source']['review_id']}",
                "",
                f"Source: {case['source']['url']}",
                "",
                "### Before — top-level report",
                "",
                fenced_quote(case["before"]["report_markdown"]),
                "",
                "### After — top-level report",
                "",
                fenced_quote(bundle["report_markdown"]),
                "",
                "### Inline comments",
                "",
            ]
        )
        pair, pair_key = randomized_pair(
            f"{case_id}:report",
            visible_text(case["before"]["report_markdown"]),
            visible_text(bundle["report_markdown"]),
        )
        pair["kind"] = "top-level report"
        blind.append(pair)
        key.append(pair_key)

        before_by_finding = {
            item["finding_id"]: item for item in case["before"]["inline_comments"]
        }
        after_by_finding = {}
        for item in bundle["inline_comments"]:
            marker = item["body"].rstrip().splitlines()[-1]
            finding_id = marker.split("id=", 1)[1].split(" ", 1)[0]
            after_by_finding[finding_id] = item
        if set(before_by_finding) != set(after_by_finding):
            raise SystemExit(f"inline inventory mismatch for {case_id}")
        for finding_id in before_by_finding:
            before = before_by_finding[finding_id]
            after = after_by_finding[finding_id]
            markdown.extend(
                [
                    f"#### {finding_id} — `{before['path']}:{before['line']}`",
                    "",
                    "**Before**",
                    "",
                    fenced_quote(before["body"]),
                    "",
                    "**After**",
                    "",
                    fenced_quote(after["body"]),
                    "",
                ]
            )
            pair, pair_key = randomized_pair(
                f"{case_id}:inline:{finding_id}",
                visible_text(before["body"]),
                visible_text(after["body"]),
            )
            pair["kind"] = "inline comment"
            blind.append(pair)
            key.append(pair_key)

    if any("<!--" in item[side] for item in blind for side in ("A", "B")):
        raise SystemExit("blind corpus contains hidden metadata")
    (output_dir / "before-after.md").write_text("\n".join(markdown) + "\n", encoding="utf-8")
    (output_dir / "blind-corpus.json").write_text(
        json.dumps(
            {
                "instructions": "Judge A and B without inferring chronology. Score defect clarity, action recall, scanability, naturalness, and cognitive ease from 1 to 5. Fact or action loss is a hard failure. Choose A, B, or tie and explain any baseline win.",
                "items": blind,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    (output_dir / "blind-key.json").write_text(json.dumps({"items": key}, indent=2) + "\n", encoding="utf-8")
    print(f"built {len(corpus)} review comparisons and {len(blind)} blind pairs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
