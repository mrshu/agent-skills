#!/usr/bin/env python3
"""Exercise repository-rule snapshots with real Git and a network-free gh stub."""

from __future__ import annotations

import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


HELPER = Path(__file__).with_name("resolve-repository-rules.py")
RULES = ".review-anvil-rules.md"
MAX_BYTES = 128 * 1024
GH_STUB = """#!/usr/bin/env python3
import json
import os
import sys

with open(os.environ['RULES_TEST_GH_LOG'], 'a') as log:
    log.write(json.dumps(sys.argv[1:]) + '\\n')
with open(os.environ['RULES_TEST_GH_RESPONSES']) as source:
    responses = json.load(source)
endpoint = next((arg for arg in sys.argv[1:] if arg.startswith('repos/')), '')
response = responses.get(endpoint)
if response is None:
    print('unexpected gh endpoint: ' + endpoint, file=sys.stderr)
    sys.exit(99)
sys.stdout.write(response.get('stdout', ''))
sys.stderr.write(response.get('stderr', ''))
sys.exit(response.get('exit', 0))
"""


class RepositoryRulesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="repository-rules-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.env = os.environ.copy()
        self.env.update({
            "GIT_AUTHOR_NAME": "Repository Rules Test",
            "GIT_AUTHOR_EMAIL": "rules-test@example.invalid",
            "GIT_COMMITTER_NAME": "Repository Rules Test",
            "GIT_COMMITTER_EMAIL": "rules-test@example.invalid",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
        })
        self.git("init", "-q")
        (self.repo / "source.txt").write_text("fixture\n")
        self.initial = self.commit()

        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.gh_log = self.root / "gh.jsonl"
        self.responses_file = self.root / "gh-responses.json"
        stub = self.bin / "gh"
        stub.write_text(GH_STUB)
        stub.chmod(0o755)
        self.env.update({
            "PATH": str(self.bin) + os.pathsep + self.env["PATH"],
            "RULES_TEST_GH_LOG": str(self.gh_log),
            "RULES_TEST_GH_RESPONSES": str(self.responses_file),
        })

    def git(self, *args, input=None):
        result = subprocess.run(
            ["git", "-C", str(self.repo), *args], input=input,
            capture_output=True, env=self.env, check=True,
        )
        return result.stdout.decode().strip()

    def commit(self):
        self.git("add", "--all")
        self.git(
            "-c", "commit.gpgsign=false", "commit", "-q", "-F", "-",
            input=(
                b"test: update repository rules fixture\n\n"
                b"Previously the fixture represented an earlier snapshot; this\n"
                b"commit records the inputs for repository-rule resolution.\n\n"
                b"- Record fixture files for snapshot assertions\n"
            ),
        )
        return self.git("rev-parse", "HEAD")

    def invoke(self, *args, success=True):
        result = subprocess.run(
            [sys.executable, str(HELPER), *map(str, args)],
            capture_output=True, text=True, env=self.env, timeout=15,
        )
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            self.fail(f"helper did not return JSON: {result.stdout!r}; {result.stderr!r}: {exc}")
        if success:
            self.assertEqual(result.returncode, 0, result.stderr or payload)
            self.assertIn(payload["status"], ("present", "absent"))
        else:
            self.assertNotEqual(result.returncode, 0, payload)
            self.assertEqual(payload["status"], "unavailable")
            self.assertTrue(payload.get("error"), payload)
        return payload

    def assert_snapshot(self, actual, *, kind, revision, content, repository=None):
        self.assertEqual(actual["status"], "present" if content is not None else "absent")
        self.assertEqual(actual["content"], content)
        source = actual["source"]
        self.assertEqual(source["kind"], kind)
        self.assertEqual(source["repository"], repository or str(self.repo.resolve()))
        self.assertEqual(source["path"], RULES)
        self.assertEqual(source["revision"], revision)
        self.assertEqual(
            source["sha256"],
            hashlib.sha256(content.encode()).hexdigest() if content is not None else None,
        )

    def test_git_preserves_exact_content_and_resolves_root_from_subdirectory(self):
        content = "# Rules\r\n\r\nUse tenant queries.  \r\nUnicode: žluťoučký\n"
        (self.repo / RULES).write_bytes(content.encode())
        revision = self.commit()
        nested = self.repo / "nested"
        nested.mkdir()
        (nested / RULES).write_text("Wrong nested rules\n")
        actual = self.invoke("git", "--repo", nested, "--revision", "HEAD")
        self.assert_snapshot(actual, kind="git", revision=revision, content=content)

    def test_git_keeps_base_policy_after_head_edits_and_deletion(self):
        content = "# BASE-01\nPreserve tenant isolation.\n"
        path = self.repo / RULES
        path.write_text(content)
        base = self.commit()
        path.write_text("# Different head policy\n")
        self.commit()
        for state in ("head-edited", "head-deleted"):
            with self.subTest(state=state):
                if state == "head-deleted":
                    path.unlink()
                    self.commit()
                actual = self.invoke("git", "--repo", self.repo, "--revision", base)
                self.assert_snapshot(actual, kind="git", revision=base, content=content)

    def test_git_absence_does_not_use_new_worktree_rules(self):
        (self.repo / RULES).write_text("Pending rules must not become base policy.\n")
        actual = self.invoke("git", "--repo", self.repo, "--revision", self.initial)
        self.assert_snapshot(actual, kind="git", revision=self.initial, content=None)

    def test_git_does_not_change_worktree_or_index(self):
        (self.repo / RULES).write_text("# Original\n")
        base = self.commit()
        (self.repo / "source.txt").write_text("staged change\n")
        self.git("add", "source.txt")
        (self.repo / "source.txt").write_text("additional unstaged change\n")
        (self.repo / RULES).write_text("# Pending\n")
        before = (
            self.git("status", "--porcelain=v1"),
            self.git("diff", "--cached", "--binary"),
            self.git("diff", "--binary"),
        )
        self.invoke("git", "--repo", self.repo, "--revision", base)
        after = (
            self.git("status", "--porcelain=v1"),
            self.git("diff", "--cached", "--binary"),
            self.git("diff", "--binary"),
        )
        self.assertEqual(before, after)

    def test_git_missing_revision_is_unavailable(self):
        self.invoke("git", "--repo", self.repo, "--revision", "missing-branch", success=False)

    def test_git_symlink_policy_is_unavailable(self):
        outside = self.root / "outside.md"
        outside.write_text("Private content outside repository.\n")
        (self.repo / RULES).symlink_to(outside)
        self.commit()
        self.invoke("git", "--repo", self.repo, "--revision", "HEAD", success=False)

    def test_git_directory_policy_is_unavailable(self):
        path = self.repo / RULES
        path.mkdir()
        (path / "rules.md").write_text("Nested file\n")
        self.commit()
        self.invoke("git", "--repo", self.repo, "--revision", "HEAD", success=False)

    def test_git_invalid_utf8_and_oversized_policy_are_unavailable(self):
        for content in (b"\xff", b"x" * (MAX_BYTES + 1)):
            with self.subTest(size=len(content)):
                (self.repo / RULES).write_bytes(content)
                revision = self.commit()
                self.invoke("git", "--repo", self.repo, "--revision", revision, success=False)

    def test_empty_and_maximum_size_policies_are_present(self):
        for content in ("", "x" * MAX_BYTES):
            with self.subTest(size=len(content)):
                (self.repo / RULES).write_text(content)
                revision = self.commit()
                actual = self.invoke("git", "--repo", self.repo, "--revision", revision)
                self.assert_snapshot(actual, kind="git", revision=revision, content=content)

    def test_worktree_uses_pending_content_and_repository_root(self):
        path = self.repo / RULES
        path.write_text("# Committed\n")
        self.commit()
        path.write_text("# Staged\n")
        self.git("add", RULES)
        content = "# Pending\nUnicode: λ\n"
        path.write_text(content)
        nested = self.repo / "nested"
        nested.mkdir()
        actual = self.invoke("worktree", "--repo", nested)
        self.assert_snapshot(actual, kind="worktree", revision=None, content=content)

    def test_worktree_absence_includes_pending_deletion(self):
        path = self.repo / RULES
        path.write_text("# Committed\n")
        self.commit()
        path.unlink()
        actual = self.invoke("worktree", "--repo", self.repo)
        self.assert_snapshot(actual, kind="worktree", revision=None, content=None)

    def test_worktree_symlink_and_directory_are_unavailable(self):
        path = self.repo / RULES
        outside = self.root / "outside.md"
        outside.write_text("Outside rules\n")
        path.symlink_to(outside)
        self.invoke("worktree", "--repo", self.repo, success=False)
        path.unlink()
        path.mkdir()
        self.invoke("worktree", "--repo", self.repo, success=False)

    def test_worktree_invalid_utf8_and_oversized_policy_are_unavailable(self):
        for content in (b"\xff", b"x" * (MAX_BYTES + 1)):
            with self.subTest(size=len(content)):
                (self.repo / RULES).write_bytes(content)
                self.invoke("worktree", "--repo", self.repo, success=False)

    def remote_fixture(
        self, content=b"# REMOTE-01\nPreserve isolation.\n", *,
        revision=None, repository="acme/reviewed",
    ):
        revision = revision or "a" * 40
        tree = "b" * len(revision)
        blob = "c" * len(revision)
        self.remote_revision = revision
        self.remote_repository = repository
        self.commit_endpoint = f"repos/{repository}/git/commits/{revision}"
        self.tree_endpoint = f"repos/{repository}/git/trees/{tree}"
        self.blob_endpoint = f"repos/{repository}/git/blobs/{blob}"
        return {
            self.commit_endpoint: {"sha": revision, "tree": {"sha": tree}},
            self.tree_endpoint: {
                "sha": tree, "truncated": False,
                "tree": [{"path": RULES, "mode": "100644", "type": "blob", "sha": blob, "size": len(content)}],
            },
            self.blob_endpoint: {
                "sha": blob, "encoding": "base64", "size": len(content),
                "content": base64.b64encode(content).decode(),
            },
        }

    def remote(self, fixtures, *, success=True):
        responses = {
            endpoint: {"stdout": json.dumps(value)}
            for endpoint, value in fixtures.items()
        }
        self.responses_file.write_text(json.dumps(responses))
        return self.invoke(
            "github", "--host", "github.example.com", "--repo", self.remote_repository,
            "--revision", self.remote_revision, success=success,
        )

    def test_github_accepts_repository_names_starting_with_punctuation(self):
        for name in (".github", "_internal", "-tools"):
            with self.subTest(name=name):
                repository = f"acme/{name}"
                content = "# Repository rules\n"
                actual = self.remote(self.remote_fixture(
                    content.encode(), repository=repository,
                ))
                self.assert_snapshot(
                    actual, kind="github", revision=self.remote_revision,
                    content=content,
                    repository=f"https://github.example.com/{repository}",
                )

    def test_github_rejects_path_traversal_repository_names(self):
        for repository in ("acme/.", "acme/..", "acme/../other"):
            with self.subTest(repository=repository):
                self.invoke(
                    "github", "--repo", repository, "--revision", "a" * 40,
                    success=False,
                )
        self.assertFalse(self.gh_log.exists())

    def test_github_uses_requested_repository_revision_and_host(self):
        content = "# REMOTE-01\r\nKeep exact content.  \r\n"
        actual = self.remote(self.remote_fixture(content.encode()))
        self.assert_snapshot(
            actual, kind="github", revision=self.remote_revision, content=content,
            repository="https://github.example.com/acme/reviewed",
        )
        calls = [json.loads(line) for line in self.gh_log.read_text().splitlines()]
        self.assertEqual(len(calls), 3)
        for call in calls:
            self.assertEqual(call[0], "api")
            self.assertEqual(call[call.index("--hostname") + 1], "github.example.com")

    def test_github_missing_root_path_is_absent(self):
        fixtures = self.remote_fixture()
        fixtures[self.tree_endpoint]["tree"] = [
            {"path": "nested", "mode": "040000", "type": "tree", "sha": "d" * 40},
        ]
        actual = self.remote(fixtures)
        self.assert_snapshot(
            actual, kind="github", revision=self.remote_revision, content=None,
            repository="https://github.example.com/acme/reviewed",
        )
        calls = self.gh_log.read_text().splitlines()
        self.assertEqual(len(calls), 2, "absent policy must not require a blob request")

    def test_github_404_is_unavailable_not_absent(self):
        fixtures = self.remote_fixture()
        responses = {endpoint: {"stdout": json.dumps(value)} for endpoint, value in fixtures.items()}
        responses[self.tree_endpoint] = {"exit": 1, "stderr": "gh: Not Found (HTTP 404)\n"}
        self.responses_file.write_text(json.dumps(responses))
        self.invoke(
            "github", "--host", "github.example.com", "--repo", "acme/reviewed",
            "--revision", self.remote_revision, success=False,
        )

    def test_github_symlink_and_directory_policies_are_unavailable(self):
        for mode, kind in (("120000", "blob"), ("040000", "tree")):
            with self.subTest(mode=mode):
                fixtures = self.remote_fixture()
                fixtures[self.tree_endpoint]["tree"][0].update(mode=mode, type=kind)
                self.remote(fixtures, success=False)

    def test_github_truncated_or_malformed_tree_is_unavailable(self):
        for invalid in ("truncated", "no-tree", "wrong-type", "missing-path"):
            with self.subTest(invalid=invalid):
                fixtures = self.remote_fixture()
                if invalid == "truncated":
                    fixtures[self.tree_endpoint]["truncated"] = True
                elif invalid == "no-tree":
                    del fixtures[self.tree_endpoint]["tree"]
                elif invalid == "wrong-type":
                    fixtures[self.tree_endpoint]["tree"] = {}
                else:
                    fixtures[self.tree_endpoint]["tree"] = [{}]
                self.remote(fixtures, success=False)

    def test_github_rejects_response_for_different_commit(self):
        fixtures = self.remote_fixture()
        fixtures[self.commit_endpoint]["sha"] = "f" * 40
        self.remote(fixtures, success=False)

    def test_github_invalid_utf8_and_oversized_policy_are_unavailable(self):
        for content in (b"\xff", b"x" * (MAX_BYTES + 1)):
            with self.subTest(size=len(content)):
                self.remote(self.remote_fixture(content), success=False)

    def test_github_invalid_base64_is_unavailable(self):
        fixtures = self.remote_fixture()
        fixtures[self.blob_endpoint]["content"] = "invalid!base64"
        self.remote(fixtures, success=False)

    def test_github_accepts_full_sha256_revision(self):
        content = "# Rules\n"
        actual = self.remote(self.remote_fixture(content.encode(), revision="a" * 64))
        self.assert_snapshot(
            actual, kind="github", revision=self.remote_revision, content=content,
            repository="https://github.example.com/acme/reviewed",
        )


if __name__ == "__main__":
    unittest.main()
