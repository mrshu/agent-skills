#!/usr/bin/env python3
"""Build readable and blind old-versus-new clarity-pass comparisons."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

JUDGE_PREAMBLE = """You are judging user-visible pull-request review language. Three pairs contain each complete review (top-level summary plus all inline comments); the remaining pairs compare individual inline comments. A/B order is randomized independently. Do not infer chronology. Hidden machine metadata is removed and must not affect scoring.

Read every complete pair. For complete-review pairs, judge action completeness across the report and its inline comments together; a summary may intentionally point to inline details. Apply a hard gate for user-visible technical facts, requested actions, conditions, boundaries, and required verification. Then score A and B from 1 to 5 on defect clarity, action recall, scanability, naturalness, cognitive ease, and plain-language simplicity. Judge actual wording and content, not only headings or Markdown. Prefer language a thoughtful human reviewer would naturally write. Preserve baseline wins and ties.

Return raw JSON only: {"rows":[{"id":"...","A":{"fact_safe":true,"defect_clarity":1,"action_recall":1,"scanability":1,"naturalness":1,"cognitive_ease":1,"plain_language":1},"B":{...},"choice":"A|B|tie","evidence":"..."}]}. Return every ID exactly once."""


def fenced_quote(text: str) -> str:
    return "\n".join("> " + line if line else ">" for line in text.rstrip().splitlines())


def visible_text(text: str) -> str:
    return re.sub(r"\s*<!--.*?-->", "", text, flags=re.S)


def randomized_pair(item_id: str, before: str, after: str) -> tuple[dict, dict]:
    after_is_a = hashlib.sha256(item_id.encode("utf-8")).digest()[0] % 2 == 0
    pair = {
        "id": item_id,
        "A": after if after_is_a else before,
        "B": before if after_is_a else after,
    }
    key = {
        "id": item_id,
        "A": "after" if after_is_a else "before",
        "B": "before" if after_is_a else "after",
    }
    return pair, key


def inline_by_finding(items: list[dict]) -> dict[str, dict]:
    result = {}
    for item in items:
        finding_id = item.get("finding_id")
        if not finding_id:
            marker = item["body"].rstrip().splitlines()[-1]
            finding_id = marker.split("id=", 1)[1].split(" ", 1)[0]
        result[finding_id] = item
    return result

def complete_review(report: str, inline_items: dict[str, dict]) -> str:
    comments = "\n\n".join(
        visible_text(item["body"]) for item in inline_items.values()
    )
    return visible_text(report) + "\n\nInline comments:\n\n" + comments


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("corpus")
    parser.add_argument("bundles")
    parser.add_argument("output_dir")
    parser.add_argument("--baseline-bundles")
    args = parser.parse_args()

    corpus = json.loads(Path(args.corpus).read_text(encoding="utf-8"))["cases"]
    bundles = json.loads(Path(args.bundles).read_text(encoding="utf-8"))["cases"]
    bundle_by_id = {item["case_id"]: item["bundle"] for item in bundles}
    baseline_by_id = {}
    if args.baseline_bundles:
        baseline = json.loads(
            Path(args.baseline_bundles).read_text(encoding="utf-8")
        )["cases"]
        baseline_by_id = {item["case_id"]: item["bundle"] for item in baseline}
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    markdown = [
        "# Human review language comparison",
        "",
        (
            "The before side is the current clarity-pass output. The after side "
            "uses the same frozen facts with the human-summary language contract."
            if baseline_by_id
            else "The before side is the historical GitHub output."
        ),
        "",
    ]
    blind, key = [], []
    for case in corpus:
        case_id = case["case_id"]
        if case_id not in bundle_by_id:
            raise SystemExit(f"missing rendered bundle for {case_id}")
        bundle = bundle_by_id[case_id]
        baseline_bundle = baseline_by_id.get(case_id)
        before_report = (
            baseline_bundle["report_markdown"]
            if baseline_bundle
            else case["before"]["report_markdown"]
        )
        before_inline = (
            baseline_bundle["inline_comments"]
            if baseline_bundle
            else case["before"]["inline_comments"]
        )
        markdown.extend(
            [
                f"## PR #{case['source']['pr']} — review {case['source']['review_id']}",
                "",
                f"Source: {case['source']['url']}",
                "",
                "### Before — top-level report",
                "",
                fenced_quote(before_report),
                "",
                "### After — top-level report",
                "",
                fenced_quote(bundle["report_markdown"]),
                "",
                "### Inline comments",
                "",
            ]
        )
        before_by_finding = inline_by_finding(before_inline)
        after_by_finding = inline_by_finding(bundle["inline_comments"])
        if set(before_by_finding) != set(after_by_finding):
            raise SystemExit(f"inline inventory mismatch for {case_id}")
        pair, pair_key = randomized_pair(
            f"{case_id}:complete",
            complete_review(before_report, before_by_finding),
            complete_review(bundle["report_markdown"], after_by_finding),
        )
        pair["kind"] = "complete review"
        blind.append(pair)
        key.append(pair_key)

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
    blind_payload = {
        "instructions": "Judge A and B without inferring chronology. Score defect clarity, action recall, scanability, naturalness, cognitive ease, and plain-language simplicity from 1 to 5. Fact or action loss is a hard failure. Choose A, B, or tie and explain any baseline win.",
        "items": blind,
    }
    blind_json = json.dumps(blind_payload, indent=2) + "\n"
    (output_dir / "blind-corpus.json").write_text(blind_json, encoding="utf-8")
    (output_dir / "readability-judge-prompt.md").write_text(
        JUDGE_PREAMBLE + "\n\n" + blind_json,
        encoding="utf-8",
    )
    (output_dir / "blind-key.json").write_text(json.dumps({"items": key}, indent=2) + "\n", encoding="utf-8")
    print(f"built {len(corpus)} review comparisons and {len(blind)} blind pairs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
