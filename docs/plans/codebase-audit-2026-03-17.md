# Codebase Audit Round 3 — 2026-03-17

Deep code and documentation review across Docker configs, Ansible/scripts, and docs quality. Excludes items already in audit rounds 1-2.

## Summary

| Area | HIGH | MEDIUM | LOW | Total |
|------|------|--------|-----|-------|
| Docker configs | 5 | 14 | 16 | 35 |
| Ansible + scripts | 7 | 11 | 8 | 26 |
| Documentation | 6 | 11 | 10 | 27 |
| **Total** | **18** | **36** | **34** | **88** |

---

## HIGH Priority

### Docker

| # | Finding | File | Fix |
|---|---------|------|-----|
| D1 | VPS Pi-hole DNS port 53 on 0.0.0.0 — open resolver, amplification attack vector | docker/vps/networking/pihole/docker-compose.yml:33 | Bind to 127.0.0.1 and Tailscale IP only |
| D2 | Headscale/DERP both bind STUN port 3478/udp — conflict | docker/vps/networking/headscale + derp | Remove STUN from Headscale or change port |
| D3 | Home Assistant uses unversioned `stable` tag | docker/fixed/docker-vm/automation/docker-compose.yml:11 | Pin to specific version |
| D4 | Frigate uses unversioned `stable` tag | docker/fixed/docker-vm/security/docker-compose.yml:66 | Pin to specific version |
| D5 | cAdvisor severely outdated (v0.33.0 from 2020) | docker/fixed/docker-vm/monitoring/docker-compose.yml:202 | Update to v0.49+ |

### Ansible + Scripts

| # | Finding | File | Fix |
|---|---------|------|-----|
| A1 | NUT playbook defaults deploy if `-e` flags forgotten | ansible/playbooks/nut.yml:37-39 | Add assert task like pihole.yml |
| A2 | NUT playbook leaks passwords in Ansible logs | ansible/playbooks/nut.yml:114,135 | Add `no_log: true` |
| A3 | Tailscale auth key visible in Ansible logs | ansible/playbooks/tailscale.yml:66, rpi5-setup.yml:71 | Add `no_log: true` |
| A4 | Pi-hole Ansible uses `pihole/pihole:latest` | ansible/playbooks/pihole.yml:94 | Add version variable |
| A5 | backup.yml unquoted variable expansion | ansible/playbooks/backup.yml:131-137 | Quote or use arrays |
| A6 | offsite-sync.sh uses `eval` for variable validation | docker/shared/backup/offsite-sync.sh:67 | Use `printenv "$var"` |
| A7 | restic-backup.sh unquoted `$EXCLUDE_ARGS` | docker/shared/backup/restic-backup.sh:62 | Use array approach |

### Documentation

| # | Finding | File | Fix |
|---|---------|------|-----|
| X1 | README says "Stirling-PDF" — actual is BentoPDF | README.md:29,72,106 | Replace all references |
| X2 | README container counts wrong (says 30+, actual 65+) | README.md:10,52-54 | Update counts |
| X3 | VPS architecture lists DERP/changedetection/Restic as "Planned" — all deployed | docs/architecture/vps-architecture.md:43-49 | Move to Active |
| X4 | Mermaid diagram: Immich labeled "mbyja" — should be "vera" | docs/architecture/network-topology.md:34 | Fix to vera |
| X5 | Mermaid diagram: Paperless labeled "kuatia" — should be "aranduka" | docs/architecture/network-topology.md:33 | Fix to aranduka |
| X6 | docs/README.md index missing 10+ recent documents | docs/README.md | Add missing entries |

---

## MEDIUM Priority

### Docker

| # | Finding | File | Fix |
|---|---------|------|-----|
| D6 | Mosquitto healthcheck leaks MQTT password via docker inspect | automation/docker-compose.yml:81 | Use non-auth healthcheck |
| D7 | VPS Pi-hole missing caps (only NET_ADMIN, needs 5 more) | vps/networking/pihole/docker-compose.yml:46 | Align with Docker VM Pi-hole |
| D8 | Authelia missing backup sidecar (TOTP data at risk) | auth/docker-compose.yml | Add restic sidecar |
| D9 | cAdvisor mounts entire root filesystem | monitoring/docker-compose.yml:227 | Document as accepted risk |
| D10 | Paperless secrets lack `:?` fail-fast | documents/docker-compose.yml:48,51 | Add `:?` validation |
| D11 | Immich DB_PASSWORD lacks `:?` fail-fast | photos/docker-compose.yml:40,175 | Add `:?` validation |
| D12 | Frigate WebRTC 8555 on 0.0.0.0 | security/docker-compose.yml:101 | Document as intentional |
| D13 | Syncthing Web UI 8384 on 0.0.0.0 (no auth) | nas/storage/docker-compose.yml:101 | Bind to 127.0.0.1 |
| D14 | VPS restic-rest 8000 on 0.0.0.0 | vps/backup/docker-compose.yml:35 | Bind to localhost/Tailscale |
| D15 | offsite-sync installs packages at every start | nas/backup/docker-compose.yml:92-93 | Custom image |
| D16 | headscale-backup installs sqlite at every start | ansible/playbooks/headscale.yml:248 | Custom image |
| D17 | DERP image is third-party `fredliang/derper:1.0` | vps/networking/derp/docker-compose.yml:7 | Verify or rebuild from source |
| D18 | Uptime Kuma `1.23` — no patch pin | vps/monitoring/docker-compose.yml:12 | Pin to 1.23.x |
| D19 | Multiple env vars missing `:?` validation across stacks | Various | Add `:?` to all secrets |

### Ansible + Scripts

| # | Finding | File | Fix |
|---|---------|------|-----|
| A8 | common.yml disables root login — would lock out Proxmox | ansible/playbooks/common.yml:76-79 | Exclude proxmox from play |
| A9 | update.yml runs `docker volume prune -f` — can delete data | ansible/playbooks/update.yml:107 | Gate behind flag |
| A10 | caddy.yml uses `copy` with Jinja2 — should use `template` | ansible/playbooks/caddy.yml:42-72 | Use template module |
| A11 | docker-compose-deploy.yml copies .env.example without substituting | ansible/playbooks/docker-compose-deploy.yml:250 | Add validation |
| A12 | backup-env.sh only backs up Docker VM (not NAS/VPS) | docker/shared/backup/backup-env.sh:10 | Accept parameter |
| A13 | immich-db-backup.sh still uses grep for JSON | docker/shared/backup/immich-db-backup.sh:73 | Use jq |
| A14 | restic-backup.sh line 95 uses grep for counting | docker/shared/backup/restic-backup.sh:95 | Use jq length |
| A15 | Multiple playbooks: docker compose `changed_when: true` wrong | Various | Parse stdout or use module |
| A16 | Glances on NAS: pid:host + docker socket, no read_only | nas/monitoring/docker-compose.yml:16 | Add read_only:true |
| A17 | homelab-recovery.sh missing set -e (intentional?) | scripts/homelab-recovery.sh:15 | Document the choice |
| A18 | backup-env.sh no check for missing stacks directory | docker/shared/backup/backup-env.sh:10-11 | Add directory check |

### Documentation

| # | Finding | File | Fix |
|---|---------|------|-----|
| X7 | Mobile homelab doc still shows RPi 5 in diagrams | docs/architecture/mobile-homelab.md | Strip RPi 5 content |
| X8 | Hardware doc says 5 VPS services — actual 12 | docs/architecture/hardware.md:287 | Update count |
| X9 | Authelia protection list includes Jellyfin — excluded in practice | docs/architecture/services.md:142 | Remove Jellyfin |
| X10 | DNS architecture says VPS fallback is Pi-hole — it's AdGuard | docs/strategy/dns-architecture.md:157 | Fix to AdGuard |
| X11 | Guarani naming: okẽ.cronova.dev listed — actual is auth.cronova.dev | docs/reference/guarani-naming-convention.md:78 | Fix subdomain |
| X12 | Security hardening says "only Headscale exposed" — multiple services public | docs/strategy/security-hardening.md:22 | Update attack surface |
| X13 | Secrets management doc describes SOPS/age not in use | docs/strategy/secrets-management.md | Add current-state note |
| X14 | DR doc references wrong VPS compose paths | docs/strategy/disaster-recovery.md:38 | Update paths |
| X15 | Architecture review doc frozen at Jan 2026 — highly stale | docs/architecture/architecture-review.md | Archive with header |
| X16 | VPS architecture directory tree outdated | docs/architecture/vps-architecture.md:106-120 | Update tree |
| X17 | No "For External Readers" section in README | README.md | Add brief section |

---

## LOW Priority (34 items)

### Docker (16)

Backup sidecars missing healthchecks (all 7), depends_on without condition (3), Jellyfin backup label without sidecar, Watchtower missing network declaration, Samba config not :ro, Forgejo missing watchtower label, services.md wrong images (4), Grafana admin password no `:?`.

### Ansible + Scripts (8)

git force:yes with ignore_errors, backup-verify.sh code duplication, dotfiles.yml requires local SSH key, nas-prep-env.sh prints password, openclaw.yml no version pin, nfs-server.yml wrong module, no --help in boot orchestrator, backup-notify.sh exits on curl failure.

### Documentation (10)

Container counts 33→35, Samba image discrepancy, Guarani names missing for *arr stack, duplicate row numbers in services.md, Immich listed on NAS (it's Docker VM), mobile-homelab.md broken path, domain-strategy.md stale plans, DNS upstream recommendation stale, Javya/Katupyry undocumented, Documents stack wrong port.

---

## Recommended Fix Order

### Batch 1 — Security (remote, do ASAP)
- D1: VPS Pi-hole open resolver
- D2: STUN port conflict
- D7: VPS Pi-hole missing caps

### Batch 2 — Public-facing fixes (local)
- X1-X2: README (Stirling-PDF, counts)
- X4-X5: Mermaid diagram names
- X6: docs/README.md index

### Batch 3 — Reliability (local)
- D3-D4: Pin HA and Frigate versions
- D5: Update cAdvisor
- D8: Authelia backup sidecar
- A1-A3: Ansible secret leaks

### Batch 4 — Hardening (local)
- D10-D11, D19: `:?` env validation
- D13-D14: Bind ports to localhost
- A8: Proxmox root login exclusion

### Batch 5 — Docs cleanup (local)
- X3, X7-X17: Stale content and inconsistencies
