#!/usr/bin/env python3
"""Validate a review-anvil final clarity-pass bundle against frozen facts."""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path
from urllib.parse import quote
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
HUMAN_REPORT_ITEM_RE = re.compile(
    rf"^[-*]\s+(?P<text>.+?)\s+<!--\s*review-anvil-report:\s*"
    rf"id=(?P<id>{FINDING_ID_PATTERN}|-)\s+"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s+"
    r"path=(?P<path>\S+)\s+start_line=(?P<start_line>\d+|-)\s+"
    r"line=(?P<line>\d+|-)\s+"
    r"disposition=(?P<disposition>active|deferred|outside)\s*-->\s*$"
)
HUMAN_REPORT_TABLE_ROW_RE = re.compile(
    r"^\|\s*(?P<visible_severity>Critical|High|Medium|Low|Nit)\s*\|\s*"
    r"(?P<location>(?:\\\||[^|\n])+?)\s*\|\s*"
    r"(?P<issue>(?:\\\||[^|\n])+?)\s*\|\s*"
    r"(?P<action>(?:\\\||[^|\n])+?)\s+"
    rf"<!--\s*review-anvil-report:\s*id=(?P<id>{FINDING_ID_PATTERN})\s+"
    r"severity=(?P<severity>critical|high|medium|low|nit)\s+"
    r"area=(?P<area>[A-Za-z0-9][A-Za-z0-9._/-]*)\s+"
    r"path=(?P<path>\S+)\s+start_line=(?P<start_line>\d+|-)\s+"
    r"line=(?P<line>\d+|-)\s+disposition=(?P<disposition>active)\s*-->"
    r"\s*\|\s*$"
)
ISSUES_TABLE_HEADER = "| Severity | Location | Issue | Suggested change |"
SUGGESTIONS_TABLE_HEADER = (
    "| Severity | Location | Suggestion | Suggested change |"
)
TABLE_SEPARATOR = "|---|---|---|---|"
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
REVIEW_FOOTER = (
    "_Reviewed with [review-anvil]"
    "(https://github.com/mrshu/agent-skills/#review-anvil)._"
)
COMPACT_DETAILS_RE = re.compile(
    r"<details>\n<summary>([^<\n]+)</summary>\n\n"
    r"([\s\S]*?)\n\n?</details>"
)
LEGACY_SUMMARY_RE = re.compile(
    r"^(?:\*\*(?:Changes requested|Looks good)\.\*\*|"
    r"\*\*(?:COMMENT|APPROVE)\b)",
    re.IGNORECASE,
)
COMPACT_SECTION_LABELS = frozenset(
    {
        "Issues and fixes",
        "Optional suggestions",
        "Earlier feedback",
        "Changes made",
        "Set aside",
        "Outside this change",
        "Review context",
    }
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

def structured_dispositions(canonical: dict[str, Any]) -> list[dict[str, Any]]:
    result = []
    for field, disposition in (
        ("set_aside", "deferred"),
        ("outside_scope", "outside"),
    ):
        for item in canonical.get(field) or []:
            if not isinstance(item, dict):
                continue
            result.append({**item, "disposition": disposition})
    return result


def report_location_tokens(finding: dict[str, Any]) -> tuple[str, str, str]:
    path = finding.get("report_path")
    line = finding.get("report_line")
    start = finding.get("report_start_line")
    return (
        quote(path, safe="._-") if isinstance(path, str) else "-",
        str(start) if isinstance(start, int) else "-",
        str(line) if isinstance(line, int) else "-",
    )
def escape_table_cell(value: str) -> str:
    return value.replace("|", r"\|")


def report_location_text(finding: dict[str, Any]) -> str:
    path = finding.get("report_path")
    line = finding.get("report_line")
    if not isinstance(path, str) or not isinstance(line, int):
        return "—"
    start = finding.get("report_start_line")
    line_range = (
        f"{start}-{line}" if isinstance(start, int) else str(line)
    )
    return f"`{escape_table_cell(path)}:{line_range}`"




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
    disposition_ids = {
        item.get("id") for item in structured_dispositions(canonical) if item.get("id")
    }
    extra_ids = set(report_ids) - set(findings)
    if extra_ids != history_ids | disposition_ids:
        raise InvalidBundle(
            "report_ids do not match identified history and dispositions"
        )
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
        *(item for item in (expected["set_aside"] or []) if isinstance(item, str)),
        *(item for item in (expected["outside_scope"] or []) if isinstance(item, str)),
        *(expected["run_details"] or []),
    ]
    missing = [value for value in visible_values if value and value not in report]
    if missing:
        raise InvalidBundle(f"report omits frozen metadata: {missing[0]}")
    for item in expected["earlier_feedback"] or []:
        if report.splitlines().count(earlier_feedback_line(item)) != 1:
            raise InvalidBundle("earlier-feedback line changed")

def compact_details_blocks(report: str) -> dict[str, str]:
    blocks = list(COMPACT_DETAILS_RE.finditer(report))
    if report.count("<details>") != len(blocks):
        raise InvalidBundle("details blocks must use separate summary lines")
    result: dict[str, str] = {}
    for block in blocks:
        label = block.group(1)
        if label not in COMPACT_SECTION_LABELS:
            raise InvalidBundle(f"unsupported compact report section {label}")
        if label in result:
            raise InvalidBundle(f"duplicate compact report section {label}")
        result[label] = block.group(2)
    return result


def validate_human_report_envelope(
    canonical: dict[str, Any],
    rendered: dict[str, Any],
    findings: dict[str, dict[str, Any]],
    report: str,
) -> None:
    stripped_report = report.rstrip()
    if (
        report.count(REVIEW_FOOTER) != 1
        or not stripped_report.endswith(REVIEW_FOOTER)
        or stripped_report.splitlines()[-1] != REVIEW_FOOTER
    ):
        raise InvalidBundle("review footer must be the final nonblank line")
    report_body = stripped_report[: -len(REVIEW_FOOTER)].rstrip()
    visible_report = re.sub(
        r"^<!--\s*review-anvil-marker:.*?-->\s*\n",
        "",
        report_body,
        count=1,
    ).lstrip("\n")
    blocks = compact_details_blocks(visible_report)
    summary, separator, _ = visible_report.partition("\n\n<details>\n")
    if (
        not separator
        or not summary.strip()
        or len(summary.strip().splitlines()) != 1
        or summary.lstrip().startswith("#")
    ):
        raise InvalidBundle(
            "human-summary report must start with one headingless visible summary line"
        )
    if LEGACY_SUMMARY_RE.search(summary.strip()):
        raise InvalidBundle(
            "human-summary report must use a natural outcome sentence"
        )
    remainder = COMPACT_DETAILS_RE.sub("", visible_report).strip()
    if remainder != summary.strip():
        raise InvalidBundle(
            "human-summary report may contain only the summary and collapsed sections"
        )

    context = blocks.get("Review context")
    if context is None:
        raise InvalidBundle("human-summary report must include Review context")

    dispositions = structured_dispositions(canonical)
    expected_sections = {
        "Issues and fixes": any(
            finding.get("severity") not in {"low", "nit"}
            for finding in findings.values()
        ),
        "Optional suggestions": any(
            finding.get("severity") in {"low", "nit"}
            for finding in findings.values()
        ),
        "Earlier feedback": bool(canonical.get("earlier_feedback")),
        "Set aside": any(
            item["disposition"] == "deferred" for item in dispositions
        ),
        "Outside this change": any(
            item["disposition"] == "outside" for item in dispositions
        ),
    }
    for label, needed in expected_sections.items():
        if needed and label not in blocks:
            raise InvalidBundle(f"human-summary report must include {label}")
        if not needed and label in blocks:
            raise InvalidBundle(f"human-summary report must omit empty {label}")
    rows_by_section = {
        "Issues and fixes": [],
        "Optional suggestions": [],
    }
    for item in rendered.get("report_items") or []:
        finding = findings.get(item.get("id"))
        if finding is None:
            continue
        label = (
            "Optional suggestions"
            if finding.get("severity") in {"low", "nit"}
            else "Issues and fixes"
        )
        rows_by_section[label].append(item.get("rendered_body"))
    for label, rows in rows_by_section.items():
        if not rows:
            continue
        header = (
            SUGGESTIONS_TABLE_HEADER
            if label == "Optional suggestions"
            else ISSUES_TABLE_HEADER
        )
        lines = blocks[label].splitlines()
        if lines[:2] != [header, TABLE_SEPARATOR]:
            raise InvalidBundle(
                f"human-summary report must use fixed {label} table header"
            )
        if lines[2:] != rows:
            raise InvalidBundle(f"{label} table rows changed")

    for item in rendered.get("disposition_items") or []:
        body = item.get("rendered_body")
        shape = HUMAN_REPORT_ITEM_RE.fullmatch(body or "")
        if shape is None:
            continue
        label = (
            "Set aside"
            if shape.group("disposition") == "deferred"
            else "Outside this change"
        )
        if body not in blocks.get(label, ""):
            raise InvalidBundle(f"disposition item must stay in {label}")

    earlier_feedback = canonical.get("earlier_feedback") or []
    if earlier_feedback:
        earlier_block = blocks.get("Earlier feedback", "")
        for item in earlier_feedback:
            if earlier_feedback_line(item) not in earlier_block:
                raise InvalidBundle(
                    "earlier-feedback lines must stay in Earlier feedback"
                )


def validate_report_items(
    report: str,
    rendered: dict[str, Any],
    findings: dict[str, dict[str, Any]],
    human_style: bool,
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
        if human_style:
            shape = HUMAN_REPORT_TABLE_ROW_RE.fullmatch(body)
            if (
                shape is None
                or shape.group("id") != finding_id
                or shape.group("disposition") != "active"
            ):
                raise InvalidBundle(
                    f"{finding_id} has invalid human-summary table row"
                )
            if shape.group("visible_severity").lower() != finding.get("severity"):
                raise InvalidBundle(f"{finding_id} visible severity changed")
            if shape.group("location").strip() != report_location_text(finding):
                raise InvalidBundle(f"{finding_id} visible report location changed")
            if not shape.group("issue").strip() or not shape.group("action").strip():
                raise InvalidBundle(f"{finding_id} table detail is empty")
            expected_path, expected_start, expected_line = report_location_tokens(
                finding
            )
            if (
                shape.group("path"),
                shape.group("start_line"),
                shape.group("line"),
            ) != (expected_path, expected_start, expected_line):
                raise InvalidBundle(f"{finding_id} report location changed")
        else:
            shape = REPORT_ITEM_RE.fullmatch(body)
            if shape is None or shape.group("id") != finding_id:
                raise InvalidBundle(
                    f"{finding_id} report item has invalid visible shape"
                )
            expected_location = None
            report_path = finding.get("report_path")
            report_line = finding.get("report_line")
            if isinstance(report_path, str) and isinstance(report_line, int):
                start = finding.get("report_start_line")
                line_range = (
                    f"{start}-{report_line}"
                    if isinstance(start, int)
                    else report_line
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

def validate_disposition_items(
    report: str,
    rendered: dict[str, Any],
    canonical: dict[str, Any],
    human_style: bool,
) -> None:
    if not human_style:
        return
    expected_items = structured_dispositions(canonical)
    items = rendered.get("disposition_items")
    if not isinstance(items, list) or len(items) != len(expected_items):
        raise InvalidBundle("disposition item inventory changed")
    for item, expected in zip(items, expected_items, strict=True):
        if not isinstance(item, dict) or item.get("id") != expected.get("id"):
            raise InvalidBundle("disposition item identity changed")
        body = item.get("rendered_body")
        if (
            not isinstance(body, str)
            or report.splitlines().count(body) != 1
            or "\n" in body
        ):
            raise InvalidBundle("disposition item is not a complete report line")
        shape = HUMAN_REPORT_ITEM_RE.fullmatch(body)
        expected_id = expected.get("id") or "-"
        if (
            shape is None
            or shape.group("id") != expected_id
            or shape.group("disposition") != expected["disposition"]
            or shape.group("severity") != expected.get("severity")
            or shape.group("area") != expected.get("area")
        ):
            raise InvalidBundle("disposition item metadata changed")
        if (
            shape.group("path"),
            shape.group("start_line"),
            shape.group("line"),
        ) != report_location_tokens(expected):
            raise InvalidBundle("disposition item location changed")


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
    report_style = canonical.get("report_style")
    if report_style not in {None, "human-summary"}:
        raise InvalidBundle(f"invalid report_style {report_style}")
    human_style = report_style == "human-summary"
    expected_decision = canonical.get("decision")
    actual_decision = rendered.get("decision")
    if actual_decision != expected_decision:
        raise InvalidBundle(
            f"decision changed from {expected_decision} to {actual_decision}"
        )
    report = rendered.get("report_markdown")
    validate_metadata(canonical, rendered, report)
    validate_report(report, expected_report_ids)
    validate_report_items(report, rendered, findings, human_style)
    validate_disposition_items(report, rendered, canonical, human_style)
    if human_style:
        validate_human_report_envelope(canonical, rendered, findings, report)
    validate_inline(
        rendered,
        findings,
        canonical.get("inline_min_severity"),
    )
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
