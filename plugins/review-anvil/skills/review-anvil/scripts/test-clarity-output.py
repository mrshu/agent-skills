#!/usr/bin/env python3
"""Behavioral tests for the final clarity-pass artifact validator."""

from __future__ import annotations

import copy
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate-clarity-output.py"

CANONICAL = {
    "decision": "COMMENT",
    "report_ids": ["RAV-RUN2-R1-F003", "RAV-RUN2-R1-F005"],
    "inline_min_severity": "medium",
    "decision_reason": "Two conversion problems remain.",
    "result": "Publication is unsafe until both are fixed.",
    "scope": "CLI and metric conversion.",
    "checks": "Two concerns checked.",
    "second_check": "off",
    "earlier_feedback": [],
    "set_aside": [],
    "outside_scope": [],
    "run_details": [],
    "findings": [
        {
            "id": "RAV-RUN2-R1-F003",
            "severity": "medium",
            "area": "cli",
            "path": "every_eval_ever/cli.py",
            "line": 383,
            "side": "RIGHT",
            "requested_work": [
                "Use the shared top-level parser in the module entry point.",
                "Add one offline entry-point test.",
            ],
            "report_path": "every_eval_ever/cli.py",
            "report_line": 383,
            "suggestion": None,
        },
        {
            "id": "RAV-RUN2-R1-F005",
            "severity": "medium",
            "area": "input-validation",
            "path": "every_eval_ever/converters/alpaca_eval/adapter.py",
            "start_line": 300,
            "line": 302,
            "side": "RIGHT",
            "start_side": "RIGHT",
            "report_path": "every_eval_ever/converters/alpaca_eval/adapter.py",
            "report_start_line": 300,
            "report_line": 302,
            "requested_work": [
                "Validate populated numeric cells as finite values within their metric rules.",
                "Enter invalid rows in SourceConversionResult.",
            ],
            "suggestion": "validate_metric_row(row)\nresult.add_validated(row)",
        },
    ],
}

RENDERED = {
    "decision": "COMMENT",
    "metadata_inventory": {
        "decision_reason": "Two conversion problems remain.",
        "result": "Publication is unsafe until both are fixed.",
        "scope": "CLI and metric conversion.",
        "checks": "Two concerns checked.",
        "second_check": "off",
        "earlier_feedback": [],
        "set_aside": [],
        "outside_scope": [],
        "run_details": [],
    },
    "report_markdown": """# Review result

**COMMENT** — Two conversion problems remain.

Publication is unsafe until both are fixed.

<details><summary>Run details</summary>
CLI and metric conversion.
Two concerns checked.
off
</details>

## Needs attention

- **The module entry point builds the old argument namespace** `every_eval_ever/cli.py:383` — Conversion fails before it starts. Use the shared parser and cover the entry point offline. (`RAV-RUN2-R1-F003`) <!-- review-anvil-report: severity=medium area=cli -->
- **Invalid populated metrics bypass row-level handling** `every_eval_ever/converters/alpaca_eval/adapter.py:300-302` — They can abort publication. Validate them before construction and record invalid rows. (`RAV-RUN2-R1-F005`) <!-- review-anvil-report: severity=medium area=input-validation -->
""",
    "report_items": [
        {
            "id": "RAV-RUN2-R1-F003",
            "rendered_body": "- **The module entry point builds the old argument namespace** `every_eval_ever/cli.py:383` — Conversion fails before it starts. Use the shared parser and cover the entry point offline. (`RAV-RUN2-R1-F003`) <!-- review-anvil-report: severity=medium area=cli -->",
        },
        {
            "id": "RAV-RUN2-R1-F005",
            "rendered_body": "- **Invalid populated metrics bypass row-level handling** `every_eval_ever/converters/alpaca_eval/adapter.py:300-302` — They can abort publication. Validate them before construction and record invalid rows. (`RAV-RUN2-R1-F005`) <!-- review-anvil-report: severity=medium area=input-validation -->",
        },
    ],
    "inline_comments": [
        {
            "path": "every_eval_ever/cli.py",
            "line": 383,
            "side": "RIGHT",
            "severity": "medium",
            "body": """**The module entry point builds the old argument namespace**

The changed handler reads missing fields and fails before conversion.

**What to change**

- Use the shared top-level parser in the module entry point.
- Add one offline entry-point test.

<!-- review-anvil: id=RAV-RUN2-R1-F003 severity=medium area=cli -->""",
        },
        {
            "path": "every_eval_ever/converters/alpaca_eval/adapter.py",
            "start_line": 300,
            "line": 302,
            "side": "RIGHT",
            "start_side": "RIGHT",
            "severity": "medium",
            "body": """**Invalid populated metrics bypass row-level handling**

They can omit the headline metric or abort strict JSON publication.

**What to change**

- Validate populated numeric cells as finite values within their metric rules.
- Enter invalid rows in `SourceConversionResult`.

<!-- review-anvil: id=RAV-RUN2-R1-F005 severity=medium area=input-validation -->""",
            "suggestion": "validate_metric_row(row)\nresult.add_validated(row)",
        },
    ],
    "predicate_inventory": [
        {
            "id": "RAV-RUN2-R1-F003",
            "requested_work": [
                "Use the shared top-level parser in the module entry point.",
                "Add one offline entry-point test.",
            ],
        },
        {
            "id": "RAV-RUN2-R1-F005",
            "requested_work": [
                "Validate populated numeric cells as finite values within their metric rules.",
                "Enter invalid rows in SourceConversionResult.",
            ],
        },
    ],
}


class ClarityOutputValidatorTests(unittest.TestCase):
    maxDiff = None

    def validate(self, rendered: dict, canonical: dict | None = None) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            canonical_path = root / "canonical.json"
            rendered_path = root / "rendered.json"
            canonical_path.write_text(json.dumps(canonical or CANONICAL), encoding="utf-8")
            rendered_path.write_text(json.dumps(rendered), encoding="utf-8")
            return subprocess.run(
                ["python3", str(VALIDATOR), str(canonical_path), str(rendered_path)],
                check=False,
                capture_output=True,
                text=True,
            )

    def assert_rejected(self, rendered: dict, diagnostic: str) -> None:
        result = self.validate(rendered)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(diagnostic, result.stderr)

    def test_accepts_complete_fact_preserving_bundle(self) -> None:
        result = self.validate(RENDERED)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "clarity-output: valid\n")

    def test_accepts_human_summary_with_hidden_metadata(self) -> None:
        deferred = {
            "id": "RAV-RUN2-R1-F006",
            "severity": "low",
            "area": "runtime",
            "text": "The runtime path could not be confirmed.",
            "reason": "The failing path needs a reproducible case.",
        }
        canonical = {
            "decision": "COMMENT",
            "report_ids": ["RAV-RUN2-R1-F003", deferred["id"]],
            "report_style": "human-summary",
            "inline_min_severity": "medium",
            "decision_reason": "One issue needs attention.",
            "result": "The CLI entry point fails before conversion.",
            "scope": "CLI conversion.",
            "checks": "One concern checked.",
            "second_check": "off",
            "earlier_feedback": [],
            "set_aside": [deferred],
            "outside_scope": [],
            "run_details": [],
            "findings": [
                {
                    "id": "RAV-RUN2-R1-F003",
                    "severity": "medium",
                    "area": "cli",
                    "report_path": "every_eval_ever/cli.py",
                    "report_line": 383,
                    "path": "every_eval_ever/cli.py",
                    "line": 392,
                    "side": "RIGHT",
                    "requested_work": [
                        "Use the shared parser in the module entry point.",
                        "Add one offline test covering parser defaults.",
                    ],
                    "suggestion": None,
                }
            ],
        }
        report_item = (
            "- The CLI entry point still uses the old parser. "
            "<!-- review-anvil-report: id=RAV-RUN2-R1-F003 severity=medium "
            "area=cli path=every_eval_ever%2Fcli.py start_line=- line=383 "
            "disposition=active -->"
        )
        disposition_item = (
            "- I set one runtime concern aside because it needs a reproducible case. "
            "<!-- review-anvil-report: id=RAV-RUN2-R1-F006 severity=low "
            "area=runtime path=- start_line=- line=- disposition=deferred -->"
        )
        metadata_inventory = {
            field: canonical[field]
            for field in (
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
        }
        rendered = {
            "decision": "COMMENT",
            "metadata_inventory": metadata_inventory,
            "report_markdown": (
                "The CLI entry point still builds the old arguments and fails "
                "before conversion.\n\n"
                "<details>\n<summary>Issues and fixes</summary>\n\n"
                f"{report_item}\n\n"
                "</details>\n\n"
                "<details>\n<summary>Set aside</summary>\n\n"
                f"{disposition_item}\n\n"
                "</details>\n\n"
                "<details>\n<summary>Review context</summary>\n\n"
                "One issue needs attention.\n"
                "The CLI entry point fails before conversion.\n"
                "CLI conversion.\nOne concern checked.\noff\n\n"
                "_Reviewed with [review-anvil]"
                "(https://github.com/mrshu/agent-skills/#review-anvil)._\n\n"
                "</details>"
            ),
            "report_items": [
                {"id": "RAV-RUN2-R1-F003", "rendered_body": report_item}
            ],
            "disposition_items": [
                {"id": deferred["id"], "rendered_body": disposition_item}
            ],
            "inline_comments": [
                {
                    "path": "every_eval_ever/cli.py",
                    "line": 392,
                    "side": "RIGHT",
                    "severity": "medium",
                    "body": (
                        "This entry point still builds the old argument namespace, "
                        "so the handler reads missing fields and fails before conversion.\n\n"
                        "Switch it to the shared parser and add one offline "
                        "test covering the defaults.\n\n"
                        "<!-- review-anvil: id=RAV-RUN2-R1-F003 "
                        "severity=medium area=cli -->"
                    ),
                }
            ],
            "predicate_inventory": [
                {
                    "id": "RAV-RUN2-R1-F003",
                    "requested_work": canonical["findings"][0]["requested_work"],
                }
            ],
        }
        result = self.validate(rendered, canonical)
        self.assertEqual(result.returncode, 0, result.stderr)
        canonical["decision"] = "APPROVE"
        rendered["decision"] = "APPROVE"
        result = self.validate(rendered, canonical)
        self.assertEqual(result.returncode, 0, result.stderr)
        footerless = copy.deepcopy(rendered)
        footerless["report_markdown"] = footerless["report_markdown"].replace(
            "\n_Reviewed with [review-anvil]"
            "(https://github.com/mrshu/agent-skills/#review-anvil)._\n",
            "\n",
        )
        result = self.validate(footerless, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("review footer must stay in Review context", result.stderr)

        headed = copy.deepcopy(rendered)
        headed["report_markdown"] = "# Review\n\n" + headed["report_markdown"]
        result = self.validate(headed, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("one headingless visible summary line", result.stderr)
        legacy_summary = copy.deepcopy(rendered)
        legacy_summary["report_markdown"] = legacy_summary[
            "report_markdown"
        ].replace(
            "The CLI entry point still builds the old arguments and fails "
            "before conversion.",
            "**Changes requested.** I found 3 issues.",
        )
        result = self.validate(legacy_summary, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must use a natural outcome sentence", result.stderr)

        stray_prose = copy.deepcopy(rendered)
        stray_prose["report_markdown"] = stray_prose["report_markdown"].replace(
            "</details>\n\n<details>",
            "</details>\n\nExtra visible review status.\n\n<details>",
            1,
        )
        result = self.validate(stray_prose, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("only the summary and collapsed sections", result.stderr)
        unknown_section = copy.deepcopy(rendered)
        unknown_section["report_markdown"] = unknown_section[
            "report_markdown"
        ].replace(
            "<details>\n<summary>Review context</summary>",
            "<details>\n<summary>Review details (3 findings)</summary>\n\n"
            "Visible count.\n\n</details>\n\n"
            "<details>\n<summary>Review context</summary>",
        )
        result = self.validate(unknown_section, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsupported compact report section", result.stderr)
        combined_tag = copy.deepcopy(rendered)
        combined_tag["report_markdown"] = combined_tag["report_markdown"].replace(
            "<details>\n<summary>Issues and fixes</summary>",
            "<details><summary>Issues and fixes</summary>",
        )
        result = self.validate(combined_tag, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("details blocks must use separate summary lines", result.stderr)

        misplaced = copy.deepcopy(rendered)
        misplaced["report_markdown"] = misplaced["report_markdown"].replace(
            f"{report_item}\n\n</details>",
            "No report item here.\n\n</details>",
        )
        misplaced["report_markdown"] = misplaced["report_markdown"].replace(
            "\n_Reviewed with [review-anvil]",
            f"\n{report_item}\n\n_Reviewed with [review-anvil]",
            1,
        )
        result = self.validate(misplaced, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must stay in Issues and fixes", result.stderr)

    def test_accepts_headingless_zero_finding_human_summary(self) -> None:
        canonical = {
            "decision": "APPROVE",
            "report_ids": [],
            "report_style": "human-summary",
            "inline_min_severity": "medium",
            "decision_reason": "No material issues remain.",
            "result": "This looks ready to merge.",
            "scope": "The reviewed change.",
            "checks": "Checks passed.",
            "second_check": "off",
            "earlier_feedback": [],
            "set_aside": [],
            "outside_scope": [],
            "run_details": [],
            "findings": [],
        }
        rendered = {
            "decision": "APPROVE",
            "metadata_inventory": {
                field: canonical[field]
                for field in (
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
            },
            "report_markdown": (
                "This looks ready to merge.\n\n"
                "<details>\n<summary>Review context</summary>\n\n"
                "No material issues remain.\n"
                "This looks ready to merge.\n"
                "The reviewed change.\n"
                "Checks passed.\n"
                "off\n\n"
                "_Reviewed with [review-anvil]"
                "(https://github.com/mrshu/agent-skills/#review-anvil)._\n\n"
                "</details>"
            ),
            "report_items": [],
            "disposition_items": [],
            "inline_comments": [],
            "predicate_inventory": [],
        }
        result = self.validate(rendered, canonical)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_accepts_known_history_id_outside_finding_inventory(self) -> None:
        canonical = copy.deepcopy(CANONICAL)
        earlier = [
            {
                "id": "RAV-RUN1-R1-F009",
                "status": "fixed",
                "text": "Fixed earlier item.",
                "url": "https://example.invalid/fixed",
            },
            {
                "id": "RAVF007",
                "status": "stale",
                "text": "Stale earlier item.",
                "url": "https://example.invalid/stale",
            },
        ]
        canonical["report_ids"].extend(item["id"] for item in earlier)
        canonical["earlier_feedback"] = earlier
        rendered = copy.deepcopy(RENDERED)
        rendered["metadata_inventory"]["earlier_feedback"] = earlier
        rendered["report_markdown"] += (
            "\n<details><summary>Earlier review comments</summary>\n"
            "- **fixed** — Fixed earlier item. https://example.invalid/fixed "
            "(`RAV-RUN1-R1-F009`)\n"
            "- **stale** — Stale earlier item. https://example.invalid/stale "
            "(`RAVF007`)\n</details>\n"
        )
        result = self.validate(rendered, canonical)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_missing_earlier_feedback_url(self) -> None:
        canonical = copy.deepcopy(CANONICAL)
        earlier = {
            "id": "RAV-RUN1-R1-F009",
            "status": "fixed",
            "text": "Fixed earlier item.",
            "url": "https://example.invalid/fixed",
        }
        canonical["report_ids"].append(earlier["id"])
        canonical["earlier_feedback"] = [earlier]
        rendered = copy.deepcopy(RENDERED)
        rendered["metadata_inventory"]["earlier_feedback"] = [earlier]
        rendered["report_markdown"] += (
            "\n- **fixed** — Fixed earlier item. (`RAV-RUN1-R1-F009`)\n"
        )
        result = self.validate(rendered, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("earlier-feedback line changed", result.stderr)

    def test_rejects_swapped_earlier_feedback_statuses(self) -> None:
        canonical = copy.deepcopy(CANONICAL)
        earlier = [
            {
                "id": "RAV-RUN1-R1-F009",
                "status": "fixed",
                "text": "First item.",
                "url": "https://example.invalid/first",
            },
            {
                "id": "RAV-RUN1-R1-F010",
                "status": "author-resolved",
                "text": "Second item.",
                "url": "https://example.invalid/second",
            },
        ]
        canonical["report_ids"].extend(item["id"] for item in earlier)
        canonical["earlier_feedback"] = earlier
        rendered = copy.deepcopy(RENDERED)
        rendered["metadata_inventory"]["earlier_feedback"] = earlier
        rendered["report_markdown"] += (
            "\n- **author-resolved** — First item. https://example.invalid/first "
            "(`RAV-RUN1-R1-F009`)\n"
            "- **fixed** — Second item. https://example.invalid/second "
            "(`RAV-RUN1-R1-F010`)\n"
        )
        result = self.validate(rendered, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("earlier-feedback line changed", result.stderr)

    def test_accepts_anchored_low_without_inline_comment(self) -> None:
        canonical = copy.deepcopy(CANONICAL)
        low = {
            "id": "RAV-RUN2-R1-F006",
            "severity": "low",
            "area": "docs",
            "path": "docs/cli.md",
            "line": 7,
            "report_path": "docs/cli.md",
            "report_line": 7,
            "side": "RIGHT",
            "requested_work": ["The help can name the timeout default."],
            "suggestion": None,
        }
        canonical["findings"].append(low)
        canonical["report_ids"].append(low["id"])
        rendered = copy.deepcopy(RENDERED)
        body = "- **CLI help omits the timeout default** `docs/cli.md:7` — The help can name the timeout default. (`RAV-RUN2-R1-F006`) <!-- review-anvil-report: severity=low area=docs -->"
        rendered["report_markdown"] += "\n" + body
        rendered["report_items"].append({"id": low["id"], "rendered_body": body})
        rendered["predicate_inventory"].append(
            {"id": low["id"], "requested_work": low["requested_work"]}
        )
        result = self.validate(rendered, canonical)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_accepts_reintroduced_prior_feedback_metadata(self) -> None:
        canonical = copy.deepcopy(CANONICAL)
        canonical["findings"][0]["prior_feedback"] = "reintroduced"
        rendered = copy.deepcopy(RENDERED)
        rendered["report_items"][0]["prior_feedback"] = "reintroduced"
        rendered["inline_comments"][0]["prior_feedback"] = "reintroduced"
        body = rendered["report_items"][0]["rendered_body"]
        rendered["report_markdown"] = rendered["report_markdown"].replace(
            body, body + "\n<!-- review-anvil: prior_feedback=reintroduced -->"
        )
        result = self.validate(rendered, canonical)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_accepts_inline_anchor_without_report_location(self) -> None:
        canonical = copy.deepcopy(CANONICAL)
        canonical["findings"][0].pop("report_path")
        canonical["findings"][0].pop("report_line")
        rendered = copy.deepcopy(RENDERED)
        old = rendered["report_items"][0]["rendered_body"]
        new = old.replace(" `every_eval_ever/cli.py:383`", "")
        rendered["report_items"][0]["rendered_body"] = new
        rendered["report_markdown"] = rendered["report_markdown"].replace(old, new)
        result = self.validate(rendered, canonical)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_accepts_anchored_low_when_threshold_is_low(self) -> None:
        canonical = copy.deepcopy(CANONICAL)
        canonical["inline_min_severity"] = "low"
        low = {
            "id": "RAV-RUN2-R1-F006",
            "severity": "low",
            "area": "docs",
            "path": "docs/cli.md",
            "line": 7,
            "report_path": "docs/cli.md",
            "report_line": 7,
            "side": "RIGHT",
            "requested_work": ["The help can name the timeout default."],
            "suggestion": None,
        }
        canonical["findings"].append(low)
        canonical["report_ids"].append(low["id"])
        rendered = copy.deepcopy(RENDERED)
        report_body = "- **CLI help omits the timeout default** `docs/cli.md:7` — The help can name the timeout default. (`RAV-RUN2-R1-F006`) <!-- review-anvil-report: severity=low area=docs -->"
        rendered["report_markdown"] += "\n" + report_body
        rendered["report_items"].append(
            {"id": low["id"], "rendered_body": report_body}
        )
        rendered["inline_comments"].append(
            {
                "path": "docs/cli.md",
                "line": 7,
                "side": "RIGHT",
                "severity": "low",
                "body": "**CLI help omits the timeout default**\n\nThe help can name the timeout default.\n\n<!-- review-anvil: id=RAV-RUN2-R1-F006 severity=low area=docs -->",
            }
        )
        rendered["predicate_inventory"].append(
            {"id": low["id"], "requested_work": low["requested_work"]}
        )
        result = self.validate(rendered, canonical)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_missing_reintroduced_prior_feedback_metadata(self) -> None:
        canonical = copy.deepcopy(CANONICAL)
        canonical["findings"][0]["prior_feedback"] = "reintroduced"
        result = self.validate(RENDERED, canonical)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("prior-feedback metadata changed", result.stderr)

    def test_rejects_metadata_inventory_drift(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["metadata_inventory"]["checks"] = "One concern checked."
        self.assert_rejected(rendered, "metadata inventory changed")

    def test_rejects_metadata_omitted_from_report(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["report_markdown"] = rendered["report_markdown"].replace(
            "CLI and metric conversion.", "Conversion."
        )
        self.assert_rejected(rendered, "report omits frozen metadata")

    def test_rejects_report_marker_on_new_line(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        old = rendered["report_items"][0]["rendered_body"]
        new = old.replace(
            " <!-- review-anvil-report:", "\n<!-- review-anvil-report:"
        )
        rendered["report_items"][0]["rendered_body"] = new
        rendered["report_markdown"] = rendered["report_markdown"].replace(old, new)
        self.assert_rejected(rendered, "report item is not a complete report line")

    def test_rejects_missing_report_finding(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["report_markdown"] = rendered["report_markdown"].replace(
            "- **Invalid populated metrics bypass row-level handling**",
            "- **Metrics**",
        ).replace(" (`RAV-RUN2-R1-F005`)", "")
        self.assert_rejected(rendered, "report finding inventory mismatch")

    def test_rejects_duplicate_report_finding(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["report_markdown"] += "\nDuplicate: RAV-RUN2-R1-F003\n"
        self.assert_rejected(rendered, "report finding RAV-RUN2-R1-F003 appears 2 times")

    def test_rejects_unknown_report_finding(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["report_markdown"] += "\nUnknown: RAV-RUN2-R1-F999\n"
        self.assert_rejected(rendered, "unknown report finding RAV-RUN2-R1-F999")

    def test_rejects_report_item_that_is_not_byte_identical(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["report_items"][0]["rendered_body"] = rendered["report_items"][0][
            "rendered_body"
        ].replace("offline", "without network access")
        self.assert_rejected(
            rendered,
            "RAV-RUN2-R1-F003 report item is not byte-identical in report_markdown",
        )

    def test_rejects_report_location_drift(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        old = rendered["report_items"][0]["rendered_body"]
        new = old.replace("every_eval_ever/cli.py:383", "every_eval_ever/cli.py:384")
        rendered["report_items"][0]["rendered_body"] = new
        rendered["report_markdown"] = rendered["report_markdown"].replace(old, new)
        self.assert_rejected(rendered, "RAV-RUN2-R1-F003 report location changed")


    def test_rejects_missing_report_metadata(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["report_markdown"] = rendered["report_markdown"].replace(
            " <!-- review-anvil-report: severity=medium area=cli -->", ""
        )
        rendered["report_items"][0]["rendered_body"] = rendered["report_items"][0][
            "rendered_body"
        ].replace(" <!-- review-anvil-report: severity=medium area=cli -->", "")
        self.assert_rejected(rendered, "report item has invalid visible shape")

    def test_rejects_extra_prose_after_report_item(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        body = rendered["report_items"][0]["rendered_body"]
        rendered["report_markdown"] = rendered["report_markdown"].replace(
            body, body + " extra prose"
        )
        self.assert_rejected(
            rendered,
            "report item is not a complete report line",
        )

    def test_rejects_report_metadata_drift(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["report_markdown"] = rendered["report_markdown"].replace(
            "severity=medium area=cli", "severity=low area=cli", 1
        )
        rendered["report_items"][0]["rendered_body"] = rendered["report_items"][0][
            "rendered_body"
        ].replace("severity=medium area=cli", "severity=low area=cli")
        self.assert_rejected(rendered, "RAV-RUN2-R1-F003 report severity changed")
    def test_rejects_decision_drift(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["decision"] = "APPROVE"
        self.assert_rejected(rendered, "decision changed from COMMENT to APPROVE")

    def test_rejects_unquoted_report_identity(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        old = rendered["report_items"][0]["rendered_body"]
        new = old.replace(
            "(`RAV-RUN2-R1-F003`)", "(RAV-RUN2-R1-F003)"
        )
        rendered["report_items"][0]["rendered_body"] = new
        rendered["report_markdown"] = rendered["report_markdown"].replace(old, new)
        self.assert_rejected(rendered, "report item has invalid visible shape")

    def test_rejects_inline_anchor_drift(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["inline_comments"][0]["line"] = 384
        self.assert_rejected(rendered, "RAV-RUN2-R1-F003 inline line changed")

    def test_rejects_inline_metadata_drift(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["inline_comments"][0]["body"] = rendered["inline_comments"][0]["body"].replace(
            "severity=medium", "severity=low"
        )
        self.assert_rejected(rendered, "RAV-RUN2-R1-F003 marker severity changed")

    def test_rejects_requested_work_inventory_drift(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["predicate_inventory"][0]["requested_work"].pop()
        self.assert_rejected(rendered, "RAV-RUN2-R1-F003 requested-work inventory changed")

    def test_rejects_safe_suggestion_loss(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["inline_comments"][1].pop("suggestion")
        self.assert_rejected(rendered, "RAV-RUN2-R1-F005 safe suggestion changed")

    def test_rejects_nonterminal_inline_marker(self) -> None:
        rendered = copy.deepcopy(RENDERED)
        rendered["inline_comments"][0]["body"] += "\n\nExtra prose"
        self.assert_rejected(rendered, "RAV-RUN2-R1-F003 metadata marker is not the final line")


if __name__ == "__main__":
    unittest.main()
