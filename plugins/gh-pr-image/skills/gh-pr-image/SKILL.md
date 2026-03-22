---
name: gh-pr-image
description: Upload local images to a GitHub PR description or comment without committing them to the repo. Use when creating PRs that need before/after screenshots, visual diffs, or any embedded images.
---

# gh-pr-image — Upload Images to GitHub PRs

Upload local images (screenshots, diagrams, visual diffs) to a GitHub PR description without committing them to the repository. Uses GitHub release assets as a CDN — the only fully scriptable, CLI-only approach that works for private repos.

## Why This Exists

GitHub has **no public API** for uploading images to PR descriptions. The drag-and-drop upload in the web UI uses an undocumented endpoint (`/upload/policies/assets`) that requires browser session cookies — it cannot be called with an API token.

The available workarounds and their trade-offs:

| Approach | Works from CLI? | Private repos? | Downsides |
|---|---|---|---|
| Commit images to repo | Yes | Yes | Bloats the repo, images live forever in git history |
| Drag-and-drop on web | No | Yes | Manual, breaks CLI workflow |
| External host (S3, imgur) | Yes | N/A | Requires separate service, images may expire |
| Browser automation (gh-attach) | Partially | Yes | Requires Playwright + browser login session |
| **Release assets (this skill)** | **Yes** | **Yes** | Creates a prerelease tag in the repo |

## How It Works

1. Create a prerelease with the image files attached as assets
2. Extract the `browser_download_url` for each asset
3. Embed the URLs in the PR body using standard markdown

Release asset URLs are accessible to anyone with repo read access, making them work correctly in private repo PR descriptions.

## Usage

### Upload images and update a PR description

```bash
# Variables
REPO="owner/repo"              # or auto-detect from current directory
PR_NUMBER=137
TAG="pr-${PR_NUMBER}-images"   # one tag per PR keeps things organized

# 1. Create prerelease with images attached
gh release create "$TAG" \
  /tmp/before.png /tmp/after.png \
  --repo "$REPO" \
  --title "PR #${PR_NUMBER} screenshots" \
  --notes "Image assets for PR #${PR_NUMBER}." \
  --prerelease

# 2. Get the asset URLs
BEFORE_URL=$(gh api "repos/$REPO/releases/tags/$TAG" \
  --jq '.assets[] | select(.name=="before.png") | .browser_download_url')
AFTER_URL=$(gh api "repos/$REPO/releases/tags/$TAG" \
  --jq '.assets[] | select(.name=="after.png") | .browser_download_url')

# 3. Use in PR body
gh pr edit "$PR_NUMBER" --body "$(cat <<EOF
## Summary
Description here.

## Before
![Before]($BEFORE_URL)

## After
![After]($AFTER_URL)
EOF
)"
```

### Upload a single image and get the URL

```bash
REPO="owner/repo"
TAG="pr-assets-$(date +%Y%m%d%H%M%S)"
FILE=/tmp/screenshot.png

gh release create "$TAG" "$FILE" \
  --repo "$REPO" \
  --title "PR screenshots" \
  --notes "Image hosting for PRs." \
  --prerelease

URL=$(gh api "repos/$REPO/releases/tags/$TAG" \
  --jq ".assets[0].browser_download_url")

echo "![screenshot]($URL)"
```

### Add images to an existing release tag

If you want to reuse a single release as a persistent image store:

```bash
TAG="pr-assets"

# First time: create the release
gh release create "$TAG" \
  --repo "$REPO" \
  --title "PR image assets" \
  --notes "Persistent image hosting for PR descriptions." \
  --prerelease

# Subsequent uploads: add to existing release
gh release upload "$TAG" /tmp/new-screenshot.png --repo "$REPO"

URL=$(gh api "repos/$REPO/releases/tags/$TAG" \
  --jq '.assets[] | select(.name=="new-screenshot.png") | .browser_download_url')
```

## Cleanup

Prerelease tags can be cleaned up after PRs are merged:

```bash
# Delete a specific PR's image release
gh release delete "pr-137-images" --yes --cleanup-tag

# List all image releases
gh release list | grep "pr-.*-images"
```

## Requirements

- `gh` CLI, authenticated (`gh auth status`)
- Write access to the repository (to create releases)

## Tips

- Use `--prerelease` so image-hosting releases don't appear as real releases
- Name tags with the PR number (`pr-137-images`) for easy cleanup
- Asset names must be unique within a release — use descriptive filenames
- For private repos, asset URLs require GitHub authentication to download, which is automatic when viewed in a PR description by someone with repo access
