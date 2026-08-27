#!/usr/bin/env python3
"""Extract frozen clarity packets from selected historical review-anvil reports."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

FINDING_ID = r"RAV-(?:RUN[1-9][0-9]*-)?R[1-9][0-9]*-F(?:00[1-9]|0[1-9][0-9]|[1-9][0-9]{2,})"
PLAN_ID = r"RAV-(?:RUN[1-9][0-9]*-)?R[1-9][0-9]*-P(?:00[1-9]|0[1-9][0-9]|[1-9][0-9]{2,})"
SEVERITY = r"critical|high|medium|low|nit"
BULLET_RE = re.compile(
    rf"^- \*\*(?P<id>{FINDING_ID}) \[(?P<severity>{SEVERITY})\] (?P<area>.+?)\*\*"
    r"(?: `(?P<location>[^`]+)`)? — (?P<body>.+)$"
)
TABLE_RE = re.compile(
    rf"^\|\s*(?P<id>{FINDING_ID})\s*\|\s*(?P<severity>{SEVERITY})\s*\|"
    r"\s*(?P<area>.*?)\s*\|\s*`(?P<location>[^`]+)`\s*\|\s*(?P<body>.*?)\s*\|$"
)
PLAN_RE = re.compile(
    rf"^- \*\*\[(?P<severity>{SEVERITY})\] (?P<area>.+?)\*\* — (?P<body>.+) "
    rf"\(`(?P<plan>{PLAN_ID})`; covers `(?P<finding>{FINDING_ID})`\)$"
)
INLINE_ID_RE = re.compile(rf"^\*\*(?P<id>{FINDING_ID}) \[(?:{SEVERITY})\].*?\*\*", re.M)
HEADER_RE = re.compile(r"^\*\*(?P<name>Review decision|Result|Scope|Checks|Second check):\*\* (?P<value>.+)$", re.M)


def section(body: str, heading: str) -> str:
    marker = f"## {heading}\n"
    if marker not in body:
        return ""
    remainder = body.split(marker, 1)[1]
    return remainder.split("\n## ", 1)[0].strip()


def parse_location(location: str | None) -> tuple[str | None, int | None]:
    if not location or ":" not in location:
        return None, None
    path, raw_line = location.rsplit(":", 1)
    if not raw_line.isdigit():
        return None, None
    return path, int(raw_line)


def parse_findings(report: str) -> list[dict]:
    noticed = section(report, "What I noticed")
    findings: list[dict] = []
    for line in noticed.splitlines():
        match = BULLET_RE.match(line) or TABLE_RE.match(line)
        if not match:
            continue
        data = match.groupdict()
        diagnosis = re.sub(r"\s*\(inline\)$", "", data["body"]).strip()
        path, line_number = parse_location(data.get("location"))
        findings.append(
            {
                "id": data["id"],
                "severity": data["severity"],
                "area": re.sub(r"[^A-Za-z0-9._/-]+", "-", data["area"].strip()).strip("-"),
                "title": diagnosis.split(". ", 1)[0].rstrip("."),
                "source_context": diagnosis,
                "fact_lock": [
                    diagnosis,
                    *(
                        [f"Report location: {path}:{line_number}."]
                        if path and line_number
                        else []
                    ),
                ],
                "requested_work": [],
                "report_path": path,
                "report_line": line_number,
                "suggestion": None,
            }
        )
    plans: dict[str, str] = {}
    for line in report.splitlines():
        match = PLAN_RE.match(line)
        if match:
            plans[match.group("finding")] = match.group("body").strip()
    for finding in findings:
        if finding["id"] in plans:
            finding["requested_work"] = [plans[finding["id"]]]
    return findings


def parse_inline_id(body: str) -> str | None:
    match = INLINE_ID_RE.search(body)
    return match.group("id") if match else None


def extract_run_details(report: str) -> list[str]:
    match = re.search(
        r"<summary>Run details</summary>\s*(?P<body>.*?)\s*</details>",
        report,
        re.S,
    )
    if not match:
        return []
    return [line[2:] for line in match.group("body").splitlines() if line.startswith("- ")]

def extract_earlier_feedback(report: str) -> list[dict]:
    raw = section(report, "Earlier review comments")
    if raw in {"", "None."}:
        return []
    bullets = [line[2:] for line in raw.splitlines() if line.startswith("- ")]
    if bullets:
        return [{"status": "reported", "text": text} for text in bullets]
    return [{"status": "reported", "text": raw}]


def verify_body(row: dict, label: str) -> None:
    expected = row.get("body_sha256")
    actual = hashlib.sha256(row["body"].encode()).hexdigest()
    if expected != actual:
        raise SystemExit(f"{label} body checksum mismatch")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_snapshot")
    parser.add_argument("output")
    args = parser.parse_args()

    snapshot_path = Path(args.source_snapshot)
    snapshot_bytes = snapshot_path.read_bytes()
    snapshot = json.loads(snapshot_bytes)
    repository = snapshot["metadata"]["repository"]
    cases = []

    for report in snapshot["reviews"]:
        review_id = report["review_id"]
        verify_body(report, f"review {review_id}")
        headers = {
            match.group("name"): match.group("value")
            for match in HEADER_RE.finditer(report["body"])
        }
        decision_match = re.match(
            r"(?P<event>APPROVE|COMMENT) — (?P<reason>.+)",
            headers["Review decision"],
        )
        if not decision_match:
            raise SystemExit(f"cannot parse review decision for {review_id}")
        findings = parse_findings(report["body"])
        finding_by_id = {finding["id"]: finding for finding in findings}
        before_inline = []
        for source_row in report["inline_comments"]:
            verify_body(source_row, f"inline {source_row['id']}")
            row = {
                key: value
                for key, value in source_row.items()
                if key != "body_sha256"
            }
            finding_id = row.get("finding_id") or parse_inline_id(row["body"])
            if not finding_id or finding_id not in finding_by_id:
                raise SystemExit(
                    f"cannot match inline {row['id']} in review {review_id}"
                )
            row["finding_id"] = finding_id
            before_inline.append(row)
            finding = finding_by_id[finding_id]
            finding["path"] = row["path"]
            finding["line"] = row["line"]
            finding["side"] = "RIGHT"
            finding["source_context"] += "\n\n" + row["body"]
            paragraphs = [
                paragraph.strip()
                for paragraph in row["body"].split("\n\n")
                if paragraph.strip()
            ]
            for evidence in paragraphs[1:-1]:
                if evidence not in finding["fact_lock"]:
                    finding["fact_lock"].append(evidence)
            if len(paragraphs) >= 2:
                inline_requested_work = paragraphs[-1]
                if inline_requested_work not in finding["requested_work"]:
                    finding["requested_work"].append(inline_requested_work)
        earlier = section(report["body"], "Earlier review comments")
        report_ids = [finding["id"] for finding in findings]
        for history_id in re.findall(FINDING_ID, earlier):
            if history_id not in report_ids:
                report_ids.append(history_id)
        cases.append(
            {
                "case_id": f"every_eval_ever-pr-{report['pr']}-review-{review_id}",
                "source": {
                    "repository": repository,
                    "pr": report["pr"],
                    "review_id": review_id,
                    "url": report["url"],
                    "submitted_at": report["submitted_at"],
                    "body_sha256": report["body_sha256"],
                },
                "before": {
                    "report_markdown": report["body"],
                    "inline_comments": before_inline,
                },
                "packet": {
                    "decision": decision_match.group("event"),
                    "report_ids": report_ids,
                    "report_style": "human-summary",
                    "inline_min_severity": "medium",
                    "decision_reason": decision_match.group("reason"),
                    "result": headers.get("Result", ""),
                    "scope": headers.get("Scope", ""),
                    "checks": headers.get("Checks", ""),
                    "second_check": headers.get("Second check", ""),
                    "earlier_feedback": extract_earlier_feedback(report["body"]),
                    "findings": findings,
                    "set_aside": [],
                    "outside_scope": [],
                    "run_details": extract_run_details(report["body"]),
                },
            }
        )

    output = {
        "metadata": {
            "source_snapshot": snapshot_path.name,
            "source_snapshot_sha256": hashlib.sha256(snapshot_bytes).hexdigest(),
        },
        "cases": cases,
    }
    Path(args.output).write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(f"extracted {len(cases)} reviews from verified source snapshot")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
