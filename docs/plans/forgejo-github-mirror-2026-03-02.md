# Forgejo → GitHub Push Mirror for DR

> **Status**: Completed 2026-03-02. Mirror active on GitHub.

**Date**: 2026-03-02
**Status**: Completed (2026-03-15) — SSH push mirrors active, sync-on-commit, 8h interval
**Goal**: Automatic push mirror from Forgejo (git.cronova.dev) to GitHub for disaster recovery

## Overview

Forgejo has built-in push mirror support. On every push to Forgejo, it automatically runs `git push --mirror` to GitHub. Periodic sync (8h) acts as a safety net.

**What's mirrored**: branches, tags, commits (all git refs)
**What's NOT mirrored**: issues, PRs, wikis, releases, labels, metadata

GitHub becomes **read-only** — any direct changes there get overwritten by the next sync.

## Repos to Mirror

| Forgejo Repo | GitHub Repo | Visibility |
|---|---|---|
| `augusto/homelab` | `ajhermosilla/homelab` | Public or private |
| `augusto/notes` | `ajhermosilla/notes` | **Private** (personal session notes) |

## Step 1: Create GitHub Repos

Create two empty repos under `ajhermosilla` on GitHub. Do NOT initialize with README, .gitignore, or license — they must be completely empty.

```bash
# Using GitHub CLI
gh repo create ajhermosilla/homelab --public --description "Homelab infrastructure-as-code"
gh repo create ajhermosilla/notes --private --description "Session notes"
```

## Step 2: Create GitHub Fine-Grained Token

1. Go to: GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Create token:
   - **Name**: `forgejo-mirror`
   - **Expiration**: 1 year (set reminder to rotate)
   - **Repository access**: Only select `homelab` and `notes`
   - **Permissions**: Contents (Read and write), Metadata (Read)
3. Save token in Vaultwarden

Alternative: Classic token with `repo` scope (simpler, no expiry option).

## Step 3: Add Push Mirrors on Forgejo

### Via Web UI

For each repo (`homelab`, `notes`):

1. Go to `https://git.cronova.dev/augusto/<repo>/settings`
2. Navigate to **Mirror Settings** section
3. Fill in:
   - **Remote URL**: `https://github.com/ajhermosilla/<repo>.git`
   - **Username**: `ajhermosilla`
   - **Password**: the GitHub token
   - Check **"Sync when new commits are pushed"**
4. Click **Add Push Mirror**

### Via Forgejo API

```bash
# Set variables
FORGEJO_TOKEN="<your-forgejo-token>"
GITHUB_TOKEN="<your-github-token>"

# Add push mirror for homelab
curl -s -X POST "https://git.cronova.dev/api/v1/repos/augusto/homelab/push_mirrors" \
  -H "Authorization: token $FORGEJO_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "remote_address": "https://github.com/ajhermosilla/homelab.git",
    "remote_username": "ajhermosilla",
    "remote_password": "'"$GITHUB_TOKEN"'",
    "interval": "8h",
    "sync_on_commit": true
  }'

# Add push mirror for notes
curl -s -X POST "https://git.cronova.dev/api/v1/repos/augusto/notes/push_mirrors" \
  -H "Authorization: token $FORGEJO_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "remote_address": "https://github.com/ajhermosilla/notes.git",
    "remote_username": "ajhermosilla",
    "remote_password": "'"$GITHUB_TOKEN"'",
    "interval": "8h",
    "sync_on_commit": true
  }'
```

## Step 4: Verify

Push a commit to Forgejo and confirm it appears on GitHub within seconds.

```bash
# Trigger manual sync via API (note: push_mirrors-sync, NOT mirror-sync)
curl -s -X POST "https://git.cronova.dev/api/v1/repos/augusto/homelab/push_mirrors-sync" \
  -H "Authorization: token $FORGEJO_TOKEN"

# Check on GitHub
gh repo view ajhermosilla/homelab --json pushedAt --jq '.pushedAt'
```

## Gotchas

- **Force push**: Push mirrors use `--mirror` (force push). Treat GitHub as read-only.
- **GitHub repos must be empty**: Do NOT use `--add-readme` when creating. The first mirror push overwrites everything.
- **Token expiration**: Fine-grained tokens expire (max 1 year). Set a calendar reminder to rotate. Classic tokens can be set to never expire.
- **Silent failures**: When token expires, mirrors fail silently. Check `last_error` field on the push mirror API response.
- **Repos must exist first**: Forgejo will not create GitHub repos — create them before adding mirrors.
- **`notes` repo must be private**: Contains personal session notes with sanitized work content.
- **Archived repos skip sync**: Don't archive repos on Forgejo if you want mirroring to continue.
- **No branch filtering needed**: Leave empty for DR — mirror everything.
- **GPG signatures**: Preserved automatically. Upload GPG key (`8AFCB80F4AC0B02B`) to GitHub for green "Verified" badges.
- **Manual sync endpoint**: Use `push_mirrors-sync` (NOT `mirror-sync` — that's for pull mirrors).

## Forgejo Mirror Config (optional)

Default settings in `app.ini` are fine. Can be set via environment variables in compose:

```text
FORGEJO__mirror__ENABLED=true
FORGEJO__mirror__DEFAULT_INTERVAL=8h
FORGEJO__mirror__MIN_INTERVAL=10m
```
