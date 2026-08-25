#!/usr/bin/env python3
"""Inspect a locally cloned PR before running untrusted code.

The script reads runtime configuration from the base ref, compares the PR head
against that base ref, and exits 2 when the PR changes files that control how
dependency installation, lint, tests, containers, or CI run. It is intentionally
stdlib-only so the sandbox wrapper can run it before any project dependency
installation.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


FLAG_PATTERNS: tuple[tuple[str, str], ...] = (
    (".github/workflows/**", "GitHub Actions workflow"),
    (".github/actions/**", "GitHub Actions local action"),
    (".circleci/**", "CircleCI configuration"),
    (".buildkite/**", "Buildkite configuration"),
    (".gitlab-ci.yml", "GitLab CI configuration"),
    ("Jenkinsfile", "Jenkins pipeline"),
    (".gitmodules", "Git submodule configuration"),
    (".lfsconfig", "Git LFS configuration"),
    (".gitattributes", "Git attributes or filters"),
    (".envrc", "direnv execution hook"),
    ("Dockerfile", "container build definition"),
    ("**/Dockerfile", "container build definition"),
    ("*.Dockerfile", "container build definition"),
    ("**/*.Dockerfile", "container build definition"),
    ("docker-compose.yml", "container orchestration definition"),
    ("docker-compose.yaml", "container orchestration definition"),
    ("compose.yml", "container orchestration definition"),
    ("compose.yaml", "container orchestration definition"),
    ("**/docker-compose.yml", "container orchestration definition"),
    ("**/docker-compose.yaml", "container orchestration definition"),
    ("**/compose.yml", "container orchestration definition"),
    ("**/compose.yaml", "container orchestration definition"),
    ("package.json", "Node package scripts or dependencies"),
    ("**/package.json", "Node package scripts or dependencies"),
    ("package-lock.json", "Node dependency lockfile"),
    ("**/package-lock.json", "Node dependency lockfile"),
    ("npm-shrinkwrap.json", "Node dependency lockfile"),
    ("**/npm-shrinkwrap.json", "Node dependency lockfile"),
    ("pnpm-lock.yaml", "pnpm dependency lockfile"),
    ("**/pnpm-lock.yaml", "pnpm dependency lockfile"),
    ("yarn.lock", "Yarn dependency lockfile"),
    ("**/yarn.lock", "Yarn dependency lockfile"),
    (".npmrc", "npm install configuration"),
    ("**/.npmrc", "npm install configuration"),
    ("pyproject.toml", "Python build configuration"),
    ("**/pyproject.toml", "Python build configuration"),
    ("setup.py", "Python setup script"),
    ("**/setup.py", "Python setup script"),
    ("setup.cfg", "Python setup configuration"),
    ("**/setup.cfg", "Python setup configuration"),
    ("requirements*.txt", "Python dependency requirements"),
    ("**/requirements*.txt", "Python dependency requirements"),
    ("constraints*.txt", "Python dependency constraints"),
    ("**/constraints*.txt", "Python dependency constraints"),
    ("poetry.lock", "Poetry lockfile"),
    ("**/poetry.lock", "Poetry lockfile"),
    ("Pipfile", "Pipenv dependency configuration"),
    ("**/Pipfile", "Pipenv dependency configuration"),
    ("Pipfile.lock", "Pipenv lockfile"),
    ("**/Pipfile.lock", "Pipenv lockfile"),
    ("tox.ini", "tox execution configuration"),
    ("**/tox.ini", "tox execution configuration"),
    ("noxfile.py", "nox execution configuration"),
    ("**/noxfile.py", "nox execution configuration"),
    ("Cargo.toml", "Rust package configuration"),
    ("**/Cargo.toml", "Rust package configuration"),
    ("Cargo.lock", "Rust dependency lockfile"),
    ("**/Cargo.lock", "Rust dependency lockfile"),
    ("go.mod", "Go module configuration"),
    ("**/go.mod", "Go module configuration"),
    ("go.sum", "Go dependency checksums"),
    ("**/go.sum", "Go dependency checksums"),
    ("Makefile", "make execution configuration"),
    ("**/Makefile", "make execution configuration"),
    ("makefile", "make execution configuration"),
    ("**/makefile", "make execution configuration"),
    ("Taskfile.yml", "task runner configuration"),
    ("Taskfile.yaml", "task runner configuration"),
    ("**/Taskfile.yml", "task runner configuration"),
    ("**/Taskfile.yaml", "task runner configuration"),
    (".tool-versions", "toolchain version selection"),
    ("**/.tool-versions", "toolchain version selection"),
    (".node-version", "Node version selection"),
    ("**/.node-version", "Node version selection"),
    (".python-version", "Python version selection"),
    ("**/.python-version", "Python version selection"),
    ("mise.toml", "toolchain version selection"),
    (".mise.toml", "toolchain version selection"),
    ("**/mise.toml", "toolchain version selection"),
    ("**/.mise.toml", "toolchain version selection"),
    ("devbox.json", "development environment definition"),
    ("**/devbox.json", "development environment definition"),
    ("flake.nix", "Nix flake"),
    ("shell.nix", "Nix shell"),
    ("**/flake.nix", "Nix flake"),
    ("**/shell.nix", "Nix shell"),
    ("Brewfile", "Homebrew dependency definition"),
    ("**/Brewfile", "Homebrew dependency definition"),
    ("scripts/install*", "installation script"),
    ("scripts/setup*", "setup script"),
    ("scripts/bootstrap*", "bootstrap script"),
    ("scripts/test*", "test runner script"),
    ("scripts/ci/**", "CI helper script"),
)


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    cp = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if check and cp.returncode != 0:
        raise SystemExit(
            f"pr_inspect: git {' '.join(args)} failed: "
            f"{(cp.stderr or cp.stdout).strip()}"
        )
    return cp


def path_exists(repo: Path, ref: str, path: str) -> bool:
    return git(repo, "cat-file", "-e", f"{ref}:{path}", check=False).returncode == 0


def read_text(repo: Path, ref: str, path: str) -> str | None:
    cp = git(repo, "show", f"{ref}:{path}", check=False)
    if cp.returncode != 0:
        return None
    return cp.stdout


def changed_files(repo: Path, base_ref: str, head_ref: str) -> list[str]:
    cp = git(
        repo,
        "diff",
        "--name-only",
        "--diff-filter=ACDMRTUXB",
        base_ref,
        head_ref,
    )
    return [line.strip() for line in cp.stdout.splitlines() if line.strip()]


def flag_for(path: str) -> str | None:
    normalized = path.strip("/")
    for pattern, reason in FLAG_PATTERNS:
        if fnmatch.fnmatch(normalized, pattern):
            return reason
    return None


def base_file_list(repo: Path, base_ref: str) -> set[str]:
    cp = git(repo, "ls-tree", "-r", "--name-only", base_ref)
    return {line.strip() for line in cp.stdout.splitlines() if line.strip()}


def any_base_path(files: set[str], *paths: str) -> bool:
    return any(path in files for path in paths)


def package_json_runtime(repo: Path, base_ref: str, files: set[str]) -> dict[str, str] | None:
    if "package.json" not in files:
        return None
    raw = read_text(repo, base_ref, "package.json")
    if raw is None:
        return None
    try:
        package = json.loads(raw)
    except json.JSONDecodeError:
        return {
            "kind": "node",
            "install": "npm install",
            "lint": "",
            "test": "npm test",
            "default_image": "docker.io/library/node:22-bookworm",
            "warning": "base package.json could not be parsed; using npm defaults",
        }

    package_manager = str(package.get("packageManager", ""))
    scripts = package.get("scripts") if isinstance(package.get("scripts"), dict) else {}

    if "pnpm-lock.yaml" in files or package_manager.startswith("pnpm@"):
        runner = "pnpm"
        install = "corepack enable && pnpm install --frozen-lockfile"
    elif "yarn.lock" in files or package_manager.startswith("yarn@"):
        runner = "yarn"
        install = "corepack enable && yarn install --immutable"
    elif "package-lock.json" in files or "npm-shrinkwrap.json" in files:
        runner = "npm"
        install = "npm ci"
    else:
        runner = "npm"
        install = "npm install"

    lint = f"{runner} run lint" if "lint" in scripts else ""
    test = f"{runner} test" if "test" in scripts else ""
    return {
        "kind": "node",
        "install": install,
        "lint": lint,
        "test": test,
        "default_image": "docker.io/library/node:22-bookworm",
        "warning": "",
    }


def python_runtime(files: set[str]) -> dict[str, str] | None:
    requirements = sorted(
        path
        for path in files
        if path == "requirements.txt"
        or (path.startswith("requirements-") and path.endswith(".txt"))
    )
    if any_base_path(files, "pyproject.toml", "setup.py", "setup.cfg") or requirements:
        if "uv.lock" in files:
            install = "python -m pip install uv && uv sync --frozen"
            test = "uv run pytest"
        elif requirements:
            install = f"python -m pip install -r {requirements[0]}"
            test = "python -m pytest"
        else:
            install = "python -m pip install -e ."
            test = "python -m pytest"
        return {
            "kind": "python",
            "install": install,
            "lint": "",
            "test": test,
            "default_image": "docker.io/library/python:3.12-bookworm",
            "warning": "",
        }
    return None


def rust_runtime(files: set[str]) -> dict[str, str] | None:
    if "Cargo.toml" not in files:
        return None
    return {
        "kind": "rust",
        "install": "",
        "lint": "cargo clippy --all-targets --all-features -- -D warnings",
        "test": "cargo test",
        "default_image": "docker.io/library/rust:1-bookworm",
        "warning": "",
    }


def go_runtime(files: set[str]) -> dict[str, str] | None:
    if "go.mod" not in files:
        return None
    return {
        "kind": "go",
        "install": "go mod download",
        "lint": "",
        "test": "go test ./...",
        "default_image": "docker.io/library/golang:1.24-bookworm",
        "warning": "",
    }


def make_runtime(files: set[str]) -> dict[str, str] | None:
    if not any_base_path(files, "Makefile", "makefile"):
        return None
    return {
        "kind": "make",
        "install": "",
        "lint": "",
        "test": "make test",
        "default_image": "docker.io/library/ubuntu:24.04",
        "warning": "",
    }


def detect_runtime(repo: Path, base_ref: str) -> dict[str, str]:
    files = base_file_list(repo, base_ref)
    for detector in (
        lambda: package_json_runtime(repo, base_ref, files),
        lambda: python_runtime(files),
        lambda: rust_runtime(files),
        lambda: go_runtime(files),
        lambda: make_runtime(files),
    ):
        runtime = detector()
        if runtime:
            return runtime
    return {
        "kind": "unknown",
        "install": "",
        "lint": "",
        "test": "",
        "default_image": "docker.io/library/ubuntu:24.04",
        "warning": "no runtime command detected from the base ref; pass --cmd or explicit command parts",
    }


def parse_bool(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "y", "on"}


def render_text(payload: dict[str, Any]) -> str:
    lines = [
        f"base_ref: {payload['base_ref']}",
        f"head_ref: {payload['head_ref']}",
        f"is_fork: {str(payload['is_fork']).lower()}",
        f"changed_files: {len(payload['changed_files'])}",
        f"runtime: {payload['runtime']['kind']}",
    ]
    command_parts = [
        payload["runtime"].get("install", ""),
        payload["runtime"].get("lint", ""),
        payload["runtime"].get("test", ""),
    ]
    command = " && ".join(part for part in command_parts if part)
    lines.append(f"command: {command or '(none)'}")
    if payload["flagged_files"]:
        lines.append("flagged_files:")
        for item in payload["flagged_files"]:
            lines.append(f"  - {item['path']} ({item['reason']})")
    else:
        lines.append("flagged_files: none")
    warning = payload["runtime"].get("warning")
    if warning:
        lines.append(f"warning: {warning}")
    return "\n".join(lines) + "\n"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True, type=Path)
    parser.add_argument("--base-ref", required=True)
    parser.add_argument("--head-ref", default="HEAD")
    parser.add_argument("--is-fork", default="false")
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args(argv)

    if not args.repo.is_dir():
        raise SystemExit(f"pr_inspect: repo path does not exist: {args.repo}")

    files = changed_files(args.repo, args.base_ref, args.head_ref)
    flagged = [
        {"path": path, "reason": reason}
        for path in files
        for reason in [flag_for(path)]
        if reason
    ]
    payload: dict[str, Any] = {
        "base_ref": args.base_ref,
        "head_ref": args.head_ref,
        "is_fork": parse_bool(args.is_fork),
        "changed_files": files,
        "flagged_files": flagged,
        "safe_to_boot": not flagged,
        "runtime": detect_runtime(args.repo, args.base_ref),
    }

    if args.as_json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        sys.stdout.write(render_text(payload))
    return 2 if flagged else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
