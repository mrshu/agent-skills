#!/usr/bin/env python3
"""Validate a review-anvil final clarity-pass bundle against frozen facts."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

POSITIVE_PADDED_ORDINAL = r"(?:00[1-9]|0[1-9][0-9]|[1-9][0-9]{2,})"
FINDING_ID_PATTERN = (
    rf"RAV-(?:RUN[1-9][0-9]*-)?R[1-9][0-9]*-F{POSITIVE_PADDED_ORDINAL}"
)
LEGACY_FINDING_ID_PATTERN = r"(?:RAVF[0-9]{3,}|F-[0-9]{3,})"
REPORT_ID_PATTERN = rf"(?:{FINDING_ID_PATTERN}|{LEGACY_FINDING_ID_PATTERN})"
REPORT_ID_RE = re.compile(
    rf"(?<![A-Za-z0-9-])({REPORT_ID_PATTERN})(?![A-Za-z0-9-])"
)
FINDING_ID_RE = re.compile(rf"(?<![A-Za-z0-9-])({FINDING_ID_PATTERN})(?![A-Za-z0-9-])")
MARKER_RE = re.compile(
    rf"<!--\s*review-anvil:\s*id=(?P<id>{FINDING_ID_PATTERN})\s+"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s*-->"
)
REPORT_ITEM_RE = re.compile(
    rf"^[-*]\s+\*\*(?P<title>.+?)\*\*"
    r"(?:\s+`(?P<location>[^`]+)`)?\s*[-—:]+\s*"
    rf"(?P<detail>.+?)\s+\(`(?P<id>{FINDING_ID_PATTERN})`\)\s+"
    r"<!--\s*review-anvil-report:\s*"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s*-->\s*$"
)
ANCHOR_KEYS = ("path", "start_line", "line", "side", "start_side")
METADATA_FIELDS = (
    "decision_reason",
    "result",
    "scope",
    "checks",
    "second_check",
    "earlier_feedback",
    "set_aside",
    "outside_scope",
    "run_details",
)


SEVERITY_RANK = {"nit": 0, "low": 1, "medium": 2, "high": 3, "critical": 4}
class InvalidBundle(ValueError):
    pass


def load_object(path: str, label: str) -> dict[str, Any]:
    try:
        value = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise InvalidBundle(f"cannot read {label}: {error}") from error
    if not isinstance(value, dict):
        raise InvalidBundle(f"{label} must be a JSON object")
    return value


def indexed_findings(canonical: dict[str, Any]) -> dict[str, dict[str, Any]]:
    findings = canonical.get("findings")
    if not isinstance(findings, list):
        raise InvalidBundle("canonical findings must be an array")
    indexed: dict[str, dict[str, Any]] = {}
    for finding in findings:
        if not isinstance(finding, dict) or not isinstance(finding.get("id"), str):
            raise InvalidBundle("each canonical finding must have a string id")
        finding_id = finding["id"]
        if FINDING_ID_RE.fullmatch(finding_id) is None:
            raise InvalidBundle(f"invalid canonical finding id {finding_id}")
        if finding_id in indexed:
            raise InvalidBundle(f"duplicate canonical finding {finding_id}")
        indexed[finding_id] = finding
    return indexed

def report_id_inventory(
    canonical: dict[str, Any], findings: dict[str, dict[str, Any]]
) -> set[str]:
    report_ids = canonical.get("report_ids")
    if not isinstance(report_ids, list) or not all(
        isinstance(finding_id, str) for finding_id in report_ids
    ):
        raise InvalidBundle("canonical report_ids must be an array of strings")
    if len(report_ids) != len(set(report_ids)):
        raise InvalidBundle("canonical report_ids must not contain duplicates")
    for finding_id in report_ids:
        if re.fullmatch(REPORT_ID_PATTERN, finding_id) is None:
            raise InvalidBundle(f"invalid canonical report id {finding_id}")
    missing_findings = set(findings) - set(report_ids)
    if missing_findings:
        raise InvalidBundle(
            "canonical report_ids omit findings " + ", ".join(sorted(missing_findings))
        )
    history_ids = {
        item.get("id")
        for item in (canonical.get("earlier_feedback") or [])
        if item.get("id")
    }
    extra_ids = set(report_ids) - set(findings)
    if extra_ids != history_ids:
        raise InvalidBundle("report_ids do not match identified earlier feedback")
    return set(report_ids)


def validate_report(report: Any, expected_ids: set[str]) -> None:
    if not isinstance(report, str):
        raise InvalidBundle("report_markdown must be a string")
    report_ids = REPORT_ID_RE.findall(report)
    for finding_id in report_ids:
        if finding_id not in expected_ids:
            raise InvalidBundle(f"unknown report finding {finding_id}")
    counts = Counter(report_ids)
    for finding_id, count in counts.items():
        if count > 1:
            raise InvalidBundle(f"report finding {finding_id} appears {count} times")
    if set(report_ids) != expected_ids:
        missing = sorted(expected_ids - set(report_ids))
        raise InvalidBundle(
            "report finding inventory mismatch; missing " + ", ".join(missing)
        )

def earlier_feedback_line(item: dict[str, Any]) -> str:
    line = f'- **{item["status"]}** — {item["text"]}'
    if item.get("url"):
        line += f' {item["url"]}'
    if item.get("id"):
        line += f' (`{item["id"]}`)'
    return line

def validate_metadata(
    canonical: dict[str, Any], rendered: dict[str, Any], report: str
) -> None:
    expected = {field: canonical.get(field) for field in METADATA_FIELDS}
    if rendered.get("metadata_inventory") != expected:
        raise InvalidBundle("metadata inventory changed")
    visible_values = [
        expected["decision_reason"],
        expected["result"],
        expected["scope"],
        expected["checks"],
        expected["second_check"],
        *(item.get("text") for item in (expected["earlier_feedback"] or [])),
        *(expected["set_aside"] or []),
        *(expected["outside_scope"] or []),
        *(expected["run_details"] or []),
    ]
    missing = [value for value in visible_values if value and value not in report]
    if missing:
        raise InvalidBundle(f"report omits frozen metadata: {missing[0]}")
    for item in expected["earlier_feedback"] or []:
        if report.splitlines().count(earlier_feedback_line(item)) != 1:
            raise InvalidBundle("earlier-feedback line changed")

def validate_report_items(
    report: str, rendered: dict[str, Any], findings: dict[str, dict[str, Any]]
) -> None:
    items = rendered.get("report_items")
    if not isinstance(items, list):
        raise InvalidBundle("report_items must be an array")
    seen: set[str] = set()
    for item in items:
        if not isinstance(item, dict) or not isinstance(item.get("id"), str):
            raise InvalidBundle("each report item must have a string id")
        finding_id = item["id"]
        if finding_id not in findings:
            raise InvalidBundle(f"unknown report item {finding_id}")
        if finding_id in seen:
            raise InvalidBundle(f"duplicate report item {finding_id}")
        seen.add(finding_id)
        finding = findings[finding_id]
        prior_feedback = finding.get("prior_feedback")
        if prior_feedback not in {None, "reintroduced"}:
            raise InvalidBundle(f"{finding_id} has invalid prior-feedback state")
        if item.get("prior_feedback") != prior_feedback:
            raise InvalidBundle(f"{finding_id} prior-feedback metadata changed")
        body = item.get("rendered_body")
        if not isinstance(body, str) or report.count(body) != 1:
            raise InvalidBundle(
                f"{finding_id} report item is not byte-identical in report_markdown"
            )
        if report.splitlines().count(body) != 1:
            raise InvalidBundle(
                f"{finding_id} report item is not a complete report line"
            )
        if FINDING_ID_RE.findall(body) != [finding_id]:
            raise InvalidBundle(f"{finding_id} report item has incorrect identity")
        if "\n" in body:
            raise InvalidBundle(
                f"{finding_id} report metadata must stay on the finding line"
            )
        shape = REPORT_ITEM_RE.fullmatch(body)
        if shape is None or shape.group("id") != finding_id:
            raise InvalidBundle(f"{finding_id} report item has invalid visible shape")
        expected_location = None
        report_path = finding.get("report_path")
        report_line = finding.get("report_line")
        if isinstance(report_path, str) and isinstance(report_line, int):
            start = finding.get("report_start_line")
            line_range = (
                f"{start}-{report_line}" if isinstance(start, int) else report_line
            )
            expected_location = f"{report_path}:{line_range}"
        if shape.group("location") != expected_location:
            raise InvalidBundle(f"{finding_id} report location changed")
        metadata = shape
        if prior_feedback == "reintroduced":
            reintroduced = body + "\n<!-- review-anvil: prior_feedback=reintroduced -->"
            if report.count(reintroduced) != 1:
                raise InvalidBundle(f"{finding_id} prior-feedback metadata changed")
        finding = findings[finding_id]
        if metadata.group("severity") != finding.get("severity"):
            raise InvalidBundle(f"{finding_id} report severity changed")
        if metadata.group("area") != finding.get("area"):
            raise InvalidBundle(f"{finding_id} report area changed")
    if seen != set(findings):
        missing = sorted(set(findings) - seen)
        raise InvalidBundle("report item inventory mismatch; missing " + ", ".join(missing))


def marker_from_body(body: Any) -> re.Match[str]:
    if not isinstance(body, str) or not body.rstrip():
        raise InvalidBundle("inline body is empty")
    final_line = body.rstrip().splitlines()[-1]
    marker = MARKER_RE.fullmatch(final_line)
    if marker is not None and "--" not in marker.group("area"):
        return marker
    embedded = MARKER_RE.search(body)
    if embedded is not None:
        raise InvalidBundle(
            f"{embedded.group('id')} metadata marker is not the final line"
        )
    raise InvalidBundle("inline metadata marker is missing or malformed")


def validate_inline(
    rendered: dict[str, Any],
    findings: dict[str, dict[str, Any]],
    inline_min_severity: Any,
) -> None:
    if inline_min_severity not in SEVERITY_RANK:
        raise InvalidBundle(f"invalid inline_min_severity {inline_min_severity}")
    inline_comments = rendered.get("inline_comments")
    if not isinstance(inline_comments, list):
        raise InvalidBundle("inline_comments must be an array")

    expected = {
        finding_id: finding
        for finding_id, finding in findings.items()
        if SEVERITY_RANK.get(finding.get("severity"), -1)
        >= SEVERITY_RANK[inline_min_severity]
        and isinstance(finding.get("path"), str)
        and isinstance(finding.get("line"), int)
    }
    seen: set[str] = set()
    for item in inline_comments:
        if not isinstance(item, dict):
            raise InvalidBundle("each inline comment must be an object")
        marker = marker_from_body(item.get("body"))
        finding_id = marker.group("id")
        if finding_id not in expected:
            raise InvalidBundle(f"unknown or unanchored inline finding {finding_id}")
        if finding_id in seen:
            raise InvalidBundle(f"duplicate inline finding {finding_id}")
        seen.add(finding_id)
        finding = expected[finding_id]

        if marker.group("severity") != finding.get("severity"):
            raise InvalidBundle(f"{finding_id} marker severity changed")
        if marker.group("area") != finding.get("area"):
            raise InvalidBundle(f"{finding_id} marker area changed")
        if item.get("severity") != finding.get("severity"):
            raise InvalidBundle(f"{finding_id} helper severity changed")
        for key in ANCHOR_KEYS:
            if item.get(key) != finding.get(key):
                raise InvalidBundle(f"{finding_id} inline {key} changed")
        if item.get("suggestion") != finding.get("suggestion"):
            raise InvalidBundle(f"{finding_id} safe suggestion changed")
        if item.get("prior_feedback") != finding.get("prior_feedback"):
            raise InvalidBundle(f"{finding_id} prior-feedback metadata changed")

    if seen != set(expected):
        missing = sorted(set(expected) - seen)
        raise InvalidBundle("inline finding inventory mismatch; missing " + ", ".join(missing))


def validate_predicates(
    rendered: dict[str, Any], findings: dict[str, dict[str, Any]]
) -> None:
    inventory = rendered.get("predicate_inventory")
    if not isinstance(inventory, list):
        raise InvalidBundle("predicate_inventory must be an array")
    seen: set[str] = set()
    for item in inventory:
        if not isinstance(item, dict) or not isinstance(item.get("id"), str):
            raise InvalidBundle("each predicate inventory row must have a string id")
        finding_id = item["id"]
        if finding_id not in findings:
            raise InvalidBundle(f"unknown predicate inventory finding {finding_id}")
        if finding_id in seen:
            raise InvalidBundle(f"duplicate predicate inventory finding {finding_id}")
        seen.add(finding_id)
        if item.get("requested_work") != findings[finding_id].get("requested_work"):
            raise InvalidBundle(f"{finding_id} requested-work inventory changed")
    if seen != set(findings):
        missing = sorted(set(findings) - seen)
        raise InvalidBundle(
            "predicate inventory mismatch; missing " + ", ".join(missing)
        )


def validate(canonical: dict[str, Any], rendered: dict[str, Any]) -> None:
    findings = indexed_findings(canonical)
    expected_report_ids = report_id_inventory(canonical, findings)
    expected_decision = canonical.get("decision")
    actual_decision = rendered.get("decision")
    if actual_decision != expected_decision:
        raise InvalidBundle(
            f"decision changed from {expected_decision} to {actual_decision}"
        )
    report = rendered.get("report_markdown")
    validate_metadata(canonical, rendered, report)
    validate_report(report, expected_report_ids)
    validate_report_items(report, rendered, findings)
    validate_inline(rendered, findings, canonical.get("inline_min_severity"))
    validate_predicates(rendered, findings)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(
            "usage: validate-clarity-output.py <canonical.json> <rendered.json>",
            file=sys.stderr,
        )
        return 2
    try:
        validate(load_object(argv[1], "canonical packet"), load_object(argv[2], "rendered bundle"))
    except InvalidBundle as error:
        print(f"clarity-output: {error}", file=sys.stderr)
        return 1
    print("clarity-output: valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
