#!/usr/bin/env python3
"""Read a repository's root review rules without executing repository code."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys


RULES_PATH = ".review-anvil-rules.md"
MAX_BYTES = 128 * 1024
OBJECT_ID = re.compile(r"(?:[0-9a-f]{40}|[0-9a-f]{64})\Z")


class RulesError(Exception):
    """The selected policy source could not be read reliably."""


def run(command: list[str]) -> bytes:
    result = subprocess.run(
        command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=30, check=False,
    )
    if result.returncode:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise RulesError(detail[:1000] or f"{command[0]} exited {result.returncode}")
    return result.stdout


def git(repo: str, *args: str) -> bytes:
    # These object reads do not run hooks, worktree filters, or repository tools.
    return run(["git", "-C", repo, *args])


def repository_root(repo: str) -> str:
    root = git(repo, "rev-parse", "--show-toplevel").decode("utf-8").rstrip("\n")
    return str(Path(root).resolve(strict=True))


def object_id(value: object) -> str:
    if not isinstance(value, str) or not OBJECT_ID.fullmatch(value):
        raise RulesError("expected a full commit, tree, or blob SHA")
    return value


def regular_blob(mode: str, kind: str) -> None:
    if mode not in {"100644", "100755"} or kind != "blob":
        raise RulesError(f"{RULES_PATH} must be a regular file, not {mode} {kind}")


def git_rules(args: argparse.Namespace, source: dict) -> bytes | None:
    root = repository_root(args.repo)
    source["repository"] = root
    revision = git(
        root, "rev-parse", "--verify", "--end-of-options",
        f"{args.revision}^{{commit}}",
    ).decode("ascii").strip()
    source["revision"] = object_id(revision)
    entry = git(root, "ls-tree", "-z", "--full-tree", revision, "--", RULES_PATH)
    if not entry:
        return None
    metadata, name = entry.rstrip(b"\0").split(b"\t", 1)
    mode, kind, blob = metadata.decode("ascii").split()
    if name != RULES_PATH.encode():
        raise RulesError("Git returned a different rules path")
    regular_blob(mode, kind)
    blob = object_id(blob)
    size = int(git(root, "cat-file", "-s", blob))
    if size > MAX_BYTES:
        raise RulesError(f"{RULES_PATH} exceeds {MAX_BYTES} bytes")
    return git(root, "cat-file", "blob", blob)


def worktree_rules(args: argparse.Namespace, source: dict) -> bytes | None:
    root = repository_root(args.repo)
    source["repository"] = root
    path = Path(root) / RULES_PATH
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    except FileNotFoundError:
        return None
    with os.fdopen(fd, "rb") as handle:
        if not stat.S_ISREG(os.fstat(handle.fileno()).st_mode):
            raise RulesError(f"{RULES_PATH} must be a regular file")
        return handle.read(MAX_BYTES + 1)


def github_json(host: str, endpoint: str) -> dict:
    result = json.loads(run([
        "gh", "api", "--hostname", host, "-H", "Accept: application/vnd.github+json",
        endpoint,
    ]))
    if not isinstance(result, dict):
        raise RulesError("GitHub returned a non-object response")
    return result


def github_rules(args: argparse.Namespace, source: dict) -> bytes | None:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.-]*(?::[0-9]+)?", args.host):
        raise RulesError("--host must be a GitHub hostname")
    if (
        not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9_.-]+", args.repo)
        or args.repo.rsplit("/", 1)[-1] in {".", ".."}
    ):
        raise RulesError("--repo must be owner/name")
    revision = object_id(args.revision)
    source["repository"] = f"https://{args.host}/{args.repo}"
    source["revision"] = revision
    prefix = f"repos/{args.repo}/git"
    commit = github_json(args.host, f"{prefix}/commits/{revision}")
    if commit.get("sha") != revision:
        raise RulesError("GitHub returned a different commit")
    tree_sha = object_id(commit["tree"]["sha"])
    tree = github_json(args.host, f"{prefix}/trees/{tree_sha}")
    if tree.get("sha") != tree_sha or tree.get("truncated") is not False:
        raise RulesError("GitHub returned a different or incomplete root tree")
    entries = tree.get("tree")
    if not isinstance(entries, list) or any(
        not isinstance(entry, dict) or not isinstance(entry.get("path"), str)
        for entry in entries
    ):
        raise RulesError("GitHub returned an invalid root tree")
    matches = [entry for entry in entries if entry.get("path") == RULES_PATH]
    if not matches:
        return None
    if len(matches) != 1:
        raise RulesError("GitHub returned duplicate rules paths")
    entry = matches[0]
    regular_blob(entry.get("mode"), entry.get("type"))
    blob_sha = object_id(entry.get("sha"))
    if entry.get("size", 0) > MAX_BYTES:
        raise RulesError(f"{RULES_PATH} exceeds {MAX_BYTES} bytes")
    blob = github_json(args.host, f"{prefix}/blobs/{blob_sha}")
    if blob.get("sha") != blob_sha or blob.get("encoding") != "base64":
        raise RulesError("GitHub returned a different blob or unsupported encoding")
    if not isinstance(blob.get("content"), str):
        raise RulesError("GitHub returned invalid blob content")
    # GitHub wraps base64 in newlines. Validate the remaining alphabet strictly.
    encoded = "".join(blob["content"].split())
    if len(encoded) > 4 * ((MAX_BYTES + 2) // 3):
        raise RulesError(f"{RULES_PATH} exceeds {MAX_BYTES} bytes")
    return base64.b64decode(encoded, validate=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="kind", required=True)
    for kind in ("git", "worktree", "github"):
        command = commands.add_parser(kind)
        command.add_argument("--repo", required=True)
        if kind != "worktree":
            command.add_argument("--revision", required=True)
        if kind == "github":
            command.add_argument("--host", default="github.com")
    args = parser.parse_args()
    source = {
        "kind": args.kind, "repository": args.repo, "path": RULES_PATH,
        "revision": getattr(args, "revision", None), "sha256": None,
    }
    try:
        resolver = {"git": git_rules, "worktree": worktree_rules, "github": github_rules}[args.kind]
        raw = resolver(args, source)
        content = None
        if raw is not None:
            if len(raw) > MAX_BYTES:
                raise RulesError(f"{RULES_PATH} exceeds {MAX_BYTES} bytes")
            content = raw.decode("utf-8")
            if "\0" in content:
                raise RulesError(f"{RULES_PATH} contains NUL bytes")
            source["sha256"] = hashlib.sha256(raw).hexdigest()
        result = {"status": "absent" if raw is None else "present", "source": source, "content": content}
        exit_code = 0
    except (RulesError, OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        message = str(error)
        result = {"status": "unavailable", "source": source, "content": None, "error": message}
        print(f"resolve-repository-rules: {message}", file=sys.stderr)
        exit_code = 2
    print(json.dumps(result, ensure_ascii=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
