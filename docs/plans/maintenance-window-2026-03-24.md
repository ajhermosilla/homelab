# Maintenance Window — 2026-03-24 (Tonight)

> **Estimated time**: ~2 hours + overnight SMART test
> **Best time**: After family is asleep (minimize internet disruption risk)

## Pre-Flight Checklist

- [ ] Family not streaming/gaming (OPNsense watchdog deploy briefly affects routing)
- [ ] MacBook on home WiFi (LAN access needed)
- [ ] USB-Gigabit adapter ready (fallback if Tailscale drops during OPNsense work)
- [ ] KeePassXC open (Forgejo token, OPNsense password)
- [ ] Phone hotspot ready (emergency internet if something breaks)

---

## Task 1 — Deploy Watchdog + NAT Emergency to OPNsense (15 min)

**Risk**: LOW — additive script, doesn't modify existing config
**Impact if fails**: watchdog silently doesn't run (current behavior)
**Rollback**: `ssh root@192.168.0.1 "cp /root/wan_watchdog.sh.bak /root/wan_watchdog.sh"`

### Steps

```bash
# 1. Backup current script
ssh root@192.168.0.1 "cp /root/wan_watchdog.sh /root/wan_watchdog.sh.bak"

# 2. Deploy new files
scp scripts/wan_watchdog.sh root@192.168.0.1:/root/wan_watchdog.sh
scp scripts/nat_emergency.conf root@192.168.0.1:/root/nat_emergency.conf

# 3. Verify deployment
ssh root@192.168.0.1 "head -2 /root/wan_watchdog.sh && wc -l /root/wan_watchdog.sh && cat /root/nat_emergency.conf"

# Expected: line 2 mentions "NAT", 131 lines, 3 NAT rules

# 4. Test (WAN is up — should check NAT and exit silently)
ssh root@192.168.0.1 "/root/wan_watchdog.sh && echo 'OK — exited cleanly'"

# 5. Verify NAT still working
ssh root@192.168.0.1 "pfctl -sn | grep nat"

# 6. Verify internet not disrupted
ping -c 2 8.8.8.8
```

### Verification

- [ ] Script deployed (131 lines)
- [ ] nat_emergency.conf deployed (3 rules)
- [ ] Test run exits cleanly
- [ ] NAT rules still present
- [ ] Internet still working

---

## Task 2 — Set Up Forgejo Actions CI + Branch Protection (80 min)

**Risk**: MEDIUM — new infrastructure (runner on Docker VM), branch protection change
**Impact if fails**: PRs can't merge until protection rule is removed
**Rollback**: Remove branch protection rule in Forgejo web UI, stop runner

### Phase 2.1 — Enable Forgejo Actions (NAS, 10 min)

```bash
# Check current config
ssh nas "docker exec forgejo cat /data/gitea/conf/app.ini | grep -A5 '\[actions\]' || echo 'No [actions] section'"

# Add Actions config
ssh nas "docker exec forgejo sh -c 'cat >> /data/gitea/conf/app.ini << EOF

[actions]
ENABLED = true
DEFAULT_ACTIONS_URL = https://github.com
EOF'"

# Restart Forgejo
ssh nas "docker restart forgejo"

# Wait and verify
sleep 15
ssh nas "docker ps --filter name=forgejo --format '{{.Status}}'"
```

**Verify**: Open <https://git.cronova.dev/-/admin/runners> — should show runners admin page.

**Risk**: Forgejo restart causes ~15s downtime for git operations
**Rollback**: Remove [actions] section from app.ini, restart forgejo

### Phase 2.2 — Deploy Runner on Docker VM (20 min)

```bash
# Create runner directory
ssh docker-vm "sudo mkdir -p /opt/forgejo-runner && sudo chown augusto:augusto /opt/forgejo-runner"
```

**Get registration token** — go to <https://git.cronova.dev/-/admin/runners> → Create new runner → copy token.

Or via API:

```bash
FORGEJO_TOKEN=$(security find-generic-password -a forgejo -s forgejo-token -w) && curl -s -X POST "https://git.cronova.dev/api/v1/admin/runners/registration-token" -H "Authorization: token $FORGEJO_TOKEN" | jq -r '.token'
```

**Create compose file locally** then scp:

```bash
cat > /tmp/forgejo-runner-compose.yml << 'COMPOSE'
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
COMPOSE

scp /tmp/forgejo-runner-compose.yml docker-vm:/opt/forgejo-runner/docker-compose.yml
```

**Register runner** (replace `<TOKEN>` with registration token):

```bash
ssh docker-vm "docker run --rm -v forgejo-runner-data:/data code.forgejo.org/forgejo/runner:6.3.1 forgejo-runner register --no-interactive --instance https://git.cronova.dev --token <TOKEN> --name docker-vm-runner --labels docker:docker://python:3.12-bookworm"
```

**Start runner**:

```bash
ssh docker-vm "cd /opt/forgejo-runner && docker compose up -d"
```

**Verify**: <https://git.cronova.dev/-/admin/runners> — should show `docker-vm-runner` as online.

**Risk**: Runner images may fail to pull (network/registry issues)
**Rollback**: `ssh docker-vm "cd /opt/forgejo-runner && docker compose down"`

### Phase 2.3 — Create Forgejo CI Workflow (10 min)

```bash
mkdir -p .forgejo/workflows
```

Create `.forgejo/workflows/ci.yml`:

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

Rename GitHub workflow to deploy-only:

```bash
git mv .github/workflows/ci.yml .github/workflows/deploy.yml
```

Edit `.github/workflows/deploy.yml` — remove lint job, keep only deploy job, change trigger to push only.

Commit, push, create PR — verify Forgejo CI runs on the PR.

**Risk**: Workflow syntax error blocks all future PRs
**Rollback**: Delete `.forgejo/workflows/`, revert `.github/workflows/deploy.yml` → `ci.yml`

### Phase 2.4 — Branch Protection (5 min)

Go to <https://git.cronova.dev/augusto/homelab/settings/branches>

Add rule for `main`:

- **Enable status check**: checked
- **Status check patterns**: `CI / lint`
- **Enforce for admins**: checked

**Risk**: If CI is broken, can't merge any PRs
**Rollback**: Uncheck "Enable status check" in branch settings

### Phase 2.5 — Test End-to-End (10 min)

```bash
# Create test branch
git checkout -b test/forgejo-ci
echo "" >> docs/blog/index.md
git add . && git commit -m "test: verify Forgejo Actions CI"
git push -u origin test/forgejo-ci

# Create PR via API
FORGEJO_TOKEN=$(security find-generic-password -a forgejo -s forgejo-token -w) && curl -s -X POST "https://git.cronova.dev/api/v1/repos/augusto/homelab/pulls" -H "Authorization: token $FORGEJO_TOKEN" -H "Content-Type: application/json" -d '{"title":"test: verify Forgejo Actions CI","head":"test/forgejo-ci","base":"main"}'
```

**Verify**:

- [ ] PR page shows CI running
- [ ] CI passes (green check)
- [ ] Merge is blocked until CI passes
- [ ] After green, merge works

Then revert the test change:

```bash
git checkout main && git pull
git revert HEAD --no-edit
git checkout -b fix/revert-test && git push -u origin fix/revert-test
# Create PR, wait for CI, merge
```

---

## Task 3 — Start 8TB SMART Test (5 min, runs overnight)

**Risk**: ZERO — read-only test, no writes to disk
**Impact**: NAS disk I/O slightly higher during test (~14 hours)

```bash
# Check drive is present
ssh nas "sudo smartctl -i /dev/sdc | head -10"

# Run extended SMART test (14 hours for 8TB)
ssh nas "sudo smartctl -t long /dev/sdc"

# Note the estimated completion time
ssh nas "sudo smartctl -l selftest /dev/sdc | head -5"
```

**Check tomorrow morning**:

```bash
ssh nas "sudo smartctl -l selftest /dev/sdc"
ssh nas "sudo smartctl -A /dev/sdc | grep -E 'Reallocated|Current_Pending|Offline_Uncorrectable'"
```

**Decision point**:

- All zeros + test passes → drive healthy, proceed with repartition
- Any non-zero → drive degrading, use Failing Drive plan

---

## Execution Order (tonight)

| # | Task | Time | Risk | Internet Disruption |
|---|------|------|------|---------------------|
| 1 | Deploy watchdog to OPNsense | 15 min | LOW | Brief (scp + test) |
| 2.1 | Enable Forgejo Actions | 10 min | LOW | 15s Forgejo restart |
| 2.2 | Deploy runner on Docker VM | 20 min | MEDIUM | None |
| 2.3 | Create CI workflow + commit | 10 min | LOW | None |
| 2.4 | Branch protection | 5 min | LOW | None |
| 2.5 | Test end-to-end | 10 min | LOW | None |
| 3 | Start 8TB SMART test | 5 min | ZERO | None |
| **Total** | | **~75 min** | | |

## Emergency Contacts

If something breaks badly:

- **OPNsense locked out**: `ssh root@192.168.0.1` (SSH key auth) or console via Proxmox
- **No internet**: plug USB-Gigabit into switch, `ssh root@192.168.0.1 "configctl interface reconfigure wan"`
- **Forgejo broken**: `ssh nas "docker restart forgejo"`
- **Docker VM issues**: `ssh docker-vm` via Tailscale or `ssh augusto@192.168.0.10` via LAN
- **Abort entire maintenance**: leave Tasks 2.3-2.5 for another day, undo Task 2.1 if needed

## Post-Maintenance Verification

```bash
# All services running
ssh docker-vm "docker ps --format '{{.Names}}' | wc -l"  # expect 36+
ssh nas "docker ps --format '{{.Names}}' | wc -l"  # expect 19+

# Watchdog working
ssh root@192.168.0.1 "cat /var/log/wan_watchdog.log | tail -3"

# Forgejo Actions runner online
# Check https://git.cronova.dev/-/admin/runners

# 8TB SMART test running
ssh nas "sudo smartctl -l selftest /dev/sdc | head -5"

# Internet working
ping -c 2 8.8.8.8
```
