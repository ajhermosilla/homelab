# Forgejo Actions CI Setup Plan — 2026-03-22

> **Status**: Ready to execute. Requires home access (Docker VM + NAS SSH).

## Goal

CI gates PR merges on Forgejo — physically cannot merge until lint + build pass. Cloudflare Pages deploy stays on GitHub Actions (triggered by mirror).

## Architecture

```text
[Developer] → push branch → [Forgejo]
                                │
                    ┌───────────┼───────────┐
                    ▼                       ▼
            Forgejo Actions          GitHub Mirror
            (PR gating)              (on merge to main)
                    │                       │
                    ▼                       ▼
            ┌──────────────┐       ┌──────────────┐
            │  Docker VM   │       │ GitHub       │
            │  Runner      │       │ Actions      │
            │  (lint+build)│       │ (deploy)     │
            └──────────────┘       └──────────────┘
                    │                       │
                    ▼                       ▼
            PR merge allowed        Cloudflare Pages
            (branch protection)     (docs.cronova.dev)
```

## Prerequisites

- [x] Forgejo 11.0 running on NAS (supports Actions)
- [x] Docker VM accessible via SSH (`docker-vm` alias)
- [x] Forgejo admin access (`augusto`)
- [ ] Forgejo `app.ini` updated with Actions config
- [ ] Runner registered and running on Docker VM
- [ ] `.forgejo/workflows/ci.yml` committed
- [ ] Branch protection rule on `main`

---

## Phase 1 — Enable Forgejo Actions (NAS, 15 min)

### 1.1 Find Forgejo config location

```bash
ssh nas "docker exec forgejo cat /data/gitea/conf/app.ini | grep -A5 '\[actions\]' || echo 'No [actions] section'"
```

### 1.2 Add Actions config

```bash
ssh nas "docker exec forgejo sh -c 'cat >> /data/gitea/conf/app.ini << EOF

[actions]
ENABLED = true
DEFAULT_ACTIONS_URL = https://github.com
EOF'"
```

### 1.3 Restart Forgejo

```bash
ssh nas "docker restart forgejo"
```

### 1.4 Verify Actions is enabled

Open <https://git.cronova.dev/-/admin/runners> — should show the runners admin page (empty).

---

## Phase 2 — Deploy Runner on Docker VM (20 min)

### 2.1 Create runner directory

```bash
ssh docker-vm "sudo mkdir -p /opt/forgejo-runner && sudo chown augusto:augusto /opt/forgejo-runner"
```

### 2.2 Generate registration token

Go to <https://git.cronova.dev/-/admin/runners> → **Create new runner** → copy the registration token.

Or via API:

```bash
FORGEJO_TOKEN=$(security find-generic-password -a forgejo -s forgejo-token -w) && curl -s -X POST "https://git.cronova.dev/api/v1/admin/runners/registration-token" -H "Authorization: token $FORGEJO_TOKEN" | jq -r '.token'
```

Save this token — needed in the next step.

### 2.3 Create Docker Compose for runner

Write this file locally, then scp to Docker VM:

```yaml
# /opt/forgejo-runner/docker-compose.yml
services:
  docker-in-docker:
    image: docker:dind
    container_name: forgejo-dind
    restart: unless-stopped
    privileged: true
    command: ["dockerd", "-H", "tcp://0.0.0.0:2375", "--tls=false"]
    environment:
      DOCKER_TLS_CERTDIR: ""
    volumes:
      - dind-data:/var/lib/docker
    networks:
      - runner-net
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2'
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  runner:
    image: code.forgejo.org/forgejo/runner:6.3.1
    container_name: forgejo-runner
    restart: unless-stopped
    depends_on:
      - docker-in-docker
    environment:
      DOCKER_HOST: tcp://docker-in-docker:2375
    volumes:
      - runner-data:/data
    networks:
      - runner-net
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  dind-data:
    name: forgejo-dind-data
  runner-data:
    name: forgejo-runner-data

networks:
  runner-net:
    name: runner-net
```

### 2.4 Deploy compose file

```bash
scp /tmp/forgejo-runner-compose.yml docker-vm:/opt/forgejo-runner/docker-compose.yml
```

### 2.5 Register the runner

```bash
ssh docker-vm "docker run --rm -v forgejo-runner-data:/data code.forgejo.org/forgejo/runner:6.3.1 forgejo-runner register --no-interactive --instance https://git.cronova.dev --token <REGISTRATION_TOKEN> --name docker-vm-runner --labels docker:docker://python:3.12-bookworm"
```

Replace `<REGISTRATION_TOKEN>` with the token from step 2.2.

### 2.6 Start the runner

```bash
ssh docker-vm "cd /opt/forgejo-runner && docker compose up -d"
```

### 2.7 Verify runner is online

Go to <https://git.cronova.dev/-/admin/runners> — should show `docker-vm-runner` as online.

---

## Phase 3 — Create Forgejo CI Workflow (local, 15 min)

### 3.1 Create the workflow file

The workflow uses direct tool installation (no third-party actions) for maximum compatibility:

```bash
mkdir -p .forgejo/workflows
```

File: `.forgejo/workflows/ci.yml`

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: docker
    container:
      image: python:3.12-bookworm
    steps:
      - uses: https://github.com/actions/checkout@v4

      - name: Install tools
        run: |
          apt-get update -qq && apt-get install -y -qq shellcheck > /dev/null
          pip install -q yamllint
          npm install -g markdownlint-cli2 > /dev/null 2>&1

      - name: Lint YAML
        run: |
          yamllint -d '{extends: default, rules: {line-length: {max: 200}, truthy: {check-keys: false}, comments-indentation: disable}}' docker/

      - name: Lint shell scripts
        run: |
          shellcheck -S error scripts/*.sh
          shellcheck -S error docker/shared/backup/restic-backup.sh docker/shared/backup/backup-env.sh docker/shared/backup/offsite-sync.sh docker/shared/backup/immich-db-backup.sh

      - name: Lint Markdown
        run: markdownlint-cli2 "docs/**/*.md"

      - name: Build MkDocs
        run: |
          pip install -q -r requirements-docs.txt
          mkdocs build --strict
```

### 3.2 Rename GitHub workflow to deploy-only

Rename `.github/workflows/ci.yml` to `.github/workflows/deploy.yml` and remove the lint job (Forgejo handles that now). Keep only the deploy job, triggered on push to main:

```yaml
name: Deploy

on:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: pip install -r requirements-docs.txt

      - name: Build MkDocs site
        run: mkdocs build --strict

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy site/ --project-name=homelab-docs
```

---

## Phase 4 — Branch Protection (Forgejo web UI, 15 min)

### 4.1 Add branch protection rule

Go to <https://git.cronova.dev/augusto/homelab/settings/branches>

Add rule for `main`:

- **Enable push whitelist**: unchecked (nobody pushes directly)
- **Enable status check**: checked
- **Status check patterns**: `lint` (matches the job name in `.forgejo/workflows/ci.yml`)
- **Enforce for admins**: checked (prevents yourself from bypassing)

### 4.2 Test the protection

Try merging a PR without CI passing — it should be blocked.

---

## Phase 5 — Test End-to-End (15 min)

### 5.1 Create a test PR

```bash
git checkout -b test/forgejo-ci
echo "# test" >> docs/blog/index.md
git add . && git commit -m "test: verify Forgejo Actions CI"
git push -u origin test/forgejo-ci
```

### 5.2 Create PR on Forgejo

```bash
FORGEJO_TOKEN=$(security find-generic-password -a forgejo -s forgejo-token -w) && curl -s -X POST "https://git.cronova.dev/api/v1/repos/augusto/homelab/pulls" -H "Authorization: token $FORGEJO_TOKEN" -H "Content-Type: application/json" -d '{"title":"test: verify Forgejo Actions CI","head":"test/forgejo-ci","base":"main"}'
```

### 5.3 Verify

- Check PR page — should show CI running
- Wait for CI to pass (green check)
- Try merging — should succeed only after green
- After merge, revert the test change

---

## Rollback Plan

### If runner doesn't work

```bash
ssh docker-vm "cd /opt/forgejo-runner && docker compose down"
```

Forgejo PRs will show "waiting for status check" but you can temporarily disable branch protection to merge.

### If Forgejo Actions causes issues

```bash
ssh nas "docker exec forgejo sh -c 'sed -i \"/\\[actions\\]/,+2d\" /data/gitea/conf/app.ini'"
ssh nas "docker restart forgejo"
```

### Full revert

1. Remove branch protection rule
2. Stop runner on Docker VM
3. Delete `.forgejo/workflows/`
4. Rename `.github/workflows/deploy.yml` back to `ci.yml`
5. Everything reverts to current GitHub-only CI

---

## Resource Impact

| Container | RAM | CPU | Host |
|-----------|-----|-----|------|
| forgejo-dind | 2GB limit | 2 CPU limit | Docker VM |
| forgejo-runner | 512MB limit | 0.5 CPU limit | Docker VM |

Docker VM has 9GB RAM, currently uses ~4GB with 36 containers. The runner adds ~2.5GB max during builds, leaving ~2.5GB headroom. Acceptable.

---

## Post-Setup Checklist

- [ ] Forgejo Actions enabled in app.ini
- [ ] Runner online at git.cronova.dev/-/admin/runners
- [ ] `.forgejo/workflows/ci.yml` committed
- [ ] `.github/workflows/ci.yml` renamed to `deploy.yml` (deploy only)
- [ ] Branch protection rule on `main` requiring `lint` check
- [ ] Test PR created, CI runs, merge gated
- [ ] Test PR merged after green, revert test change
- [ ] Verify GitHub Actions deploy still works after merge

---

## Future Improvements

- Add runner to Ansible automation for reproducibility
- Add runner healthcheck to Uptime Kuma
- Consider caching pip/npm installs in runner for faster builds
- Add the runner Docker Compose to the homelab repo under `docker/fixed/docker-vm/ci/`

---

## Execution Timeline

| Step | Time | When |
|------|------|------|
| Phase 1: Enable Actions | 15 min | Maintenance window |
| Phase 2: Deploy runner | 20 min | Maintenance window |
| Phase 3: Create workflow | 15 min | Can do now (local) |
| Phase 4: Branch protection | 15 min | After runner is online |
| Phase 5: Test | 15 min | After protection is set |
| **Total** | **~80 min** | |

**Phase 3 can be done now** — create the workflow files locally, commit, and deploy the runner during the maintenance window.
