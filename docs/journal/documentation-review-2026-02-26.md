# Homelab Documentation Review — 2026-02-26

Deep review of documentation quality compared to community standards. Budget context: ~USD 1,000.

---

## What's Working Well

**Repo structure is better than 90% of homelab repos.** The `docker/fixed/{host}/{stack}/`, `ansible/`, `docs/`, `scripts/` layout follows top-starred repos (khuedoan/homelab, ChristianLempa/homelab). Most homelabbers dump everything flat or don't version-control at all.

**The Guarani naming convention is genuinely cool.** Cultural identity > generic server names. The README explains it upfront. One refinement: explicitly state the rule — "user-facing services get Guarani names, infrastructure keeps English names."

**The IaC approach is solid.** Docker Compose files for every service, Ansible playbooks for provisioning, scripts for backup verification. The compose files are the most trustworthy source of truth about what's deployed.

**The showcase tier (README, services.md, hardware.md) is competitive** with well-known homelab repos after the 2026-02-26 overhaul. The ASCII diagram, Guarani names table, and tech stack summary would do well on r/homelab.

**For ~$1,000, running 40+ services is impressive.** Most r/homelab posts with similar service counts run $3-5K+ in hardware. The repurposed 2013 Mini-ITX NAS running 11 containers is peak homelab resourcefulness.

---

## What Needs Work

### 1. Operational Docs Are Dangerously Outdated

The two-tier strategy (showcase + operational) has a fatal flaw: the showcase tier got all the love, and the operational tier is frozen from January planning.

| Document | Problem |
|----------|---------|
| `disaster-recovery.md` | **Wrong procedures.** Uses tar+gz to `/mnt/nas/backups/` — actual system uses Restic REST. SSH usernames wrong (`admin` instead of `linuxuser`/`augusto`). References SnapRAID on a system without it. Stops Vaultwarden hourly for backups (the backup container handles this). Following this during an emergency wastes critical time. |
| `monitoring-strategy.md` | **Monitors phantom services.** Lists Pi-hole on VPS, changedetection, Restic REST on VPS — none exist. No mention of VictoriaMetrics/Grafana (Papa). Missing monitors for 15+ deployed services. |
| `setup-runbook.md` | **Deploys a different homelab.** Clones from `github.com` (actual: Forgejo). Deploys Pi-hole/DERP on VPS (not real). Camera IPs in VLAN 10 range (actual: main LAN). Missing phases for 8+ deployed services. |
| `fixed-homelab.md` | **Worst offender.** NAS "Pending setup" (active for weeks). Docker VM shows 12 services (actual: 20+). Lists Frigate under NAS (runs on Docker VM). Backup strategy section describes tar+gz cron jobs that don't exist. |

This is the #1 mistake the community warns about: impressive-looking docs that are wrong when you actually need them.

### 2. RAM Inconsistency

| Source | Docker VM RAM |
|--------|--------------|
| README.md | 7GB |
| hardware.md | 7GB |
| fixed-homelab.md | 9GB |
| MEMORY.md | 9GB |

Pick one number (9GB is the Proxmox allocation) and use it everywhere.

### 3. No Visual Network Diagram

ASCII diagrams are fine for a README, but the community standard is a Draw.io or Excalidraw diagram showing physical connections, VLANs with CIDR, Tailscale overlay, and security zones. Store the `.drawio` source + exported PNG in Git.

### 4. No Cost Breakdown

The community loves cost transparency. Adding approximate prices to the purchase history table makes the ~$1,000 story concrete and shareable.

### 5. Missing Architecture Decision Records (ADRs)

Short docs explaining *why* you chose Caddy over Traefik, Headscale over vanilla Tailscale, OpenVINO over Coral TPU, etc. The `architecture-review.md` touches on this but doesn't commit to the format.

### 6. CLAUDE.md Is Stale

"Suggested Structure" shows a flat layout that doesn't match reality. No mention of Forgejo. Secrets management stuck at "Consider: SOPS, age" — either do it or drop it.

### 7. Docs Accessibility When Infra Is Down

Forgejo runs on the homelab. If the NAS dies, the DR runbook dies with it. Push to GitHub as a mirror — the community considers this the cardinal sin.

---

## Scorecard

| Document | Accuracy | Structure | Completeness | Readability | Score |
|----------|----------|-----------|-------------|------------|-------|
| README.md | 7 | 9 | 8 | 9 | **7.5/10** |
| docs/README.md | 8 | 8 | 7 | 8 | **7/10** |
| services.md | 6 | 9 | 8 | 8 | **8/10** |
| hardware.md | 6 | 7 | 8 | 7 | **6.5/10** |
| fixed-homelab.md | 3 | 7 | 5 | 6 | **4/10** |
| disaster-recovery.md | 2 | 8 | 4 | 7 | **3/10** |
| monitoring-strategy.md | 3 | 7 | 4 | 7 | **3.5/10** |
| setup-runbook.md | 3 | 7 | 4 | 7 | **3/10** |
| CLAUDE.md | 5 | 7 | 5 | 8 | **5/10** |

---

## Community Comparison

| Criteria | Community Standard | This Homelab | Grade |
|----------|-------------------|--------------|-------|
| Repo structure | Organized by host/stack | Excellent | A |
| IaC (Compose, Ansible) | Code as documentation | Strong | A |
| README as showcase | Hardware + services + diagram | Good after overhaul | B+ |
| Network diagram | Draw.io/Excalidraw with VLANs | ASCII only | C |
| DR runbook accuracy | Tested, correct procedures | Wrong procedures/paths | F |
| Service inventory | Complete, current | Good but some stale statuses | B |
| Monitoring docs | Matches actual monitors | Monitors phantom services | F |
| Naming convention | Consistent, documented | Guarani — unique, well-documented | A |
| Budget documentation | Cost per component | No prices listed | D |
| Secrets handling | SOPS/Vault/sealed secrets | .env files only | C |
| Docs accessible offline | Git on external host | Forgejo only (on the homelab) | C+ |
| Backup verification | Regular tested restores | Script exists, unclear if executed | B- |

---

## Priority Fixes (in order)

1. **Rewrite `disaster-recovery.md`** — The document that saves you at 2 AM. Must use Restic paths, correct SSH users, real backup schedules. Drop SnapRAID/Start9 fiction.
2. **Rewrite `fixed-homelab.md`** — Or archive as `fixed-homelab-v1-plan.md`. It actively contradicts reality.
3. **Rewrite `monitoring-strategy.md`** — Replace phantom services with actual VictoriaMetrics+Grafana stack.
4. **Update `services.md` statuses** — Flip "Config ready" to "Active" for deployed services. 5-minute fix.
5. **Standardize Docker VM RAM** — 9GB everywhere.
6. **Create a proper network diagram** — Draw.io, commit `.drawio` + PNG.
7. **Push homelab repo to GitHub as a mirror** — DR docs must survive infra failure.

---

## Community Best Practices Reference

### Gold Standard Homelab Repos

- [khuedoan/homelab](https://github.com/khuedoan/homelab) (~8k stars) — Fully automated, MkDocs site, feature badges
- [ChristianLempa/homelab](https://github.com/ChristianLempa/homelab) (~2k stars) — Config-focused, per-service directories
- [h0bbel/homelab](https://github.com/h0bbel/homelab) — Enterprise-style RCAR document, three-tier design model

### Documentation Tools Used by the Community

- **BookStack** — Most recommended self-hosted wiki (Shelves/Books/Chapters/Pages)
- **Obsidian** — Local-first, bidirectional linking, massive plugin ecosystem
- **Plain Markdown in Git** — Zero dependencies, version controlled, survives infra failures
- **MkDocs + Material** — Static site generator for publishing docs from Git
- **Draw.io / Excalidraw** — Network diagrams (store source + PNG in Git)
- **NetBox** — DCIM/IPAM for network-heavy setups

### Key Community Rules

1. **Documentation must be accessible when infrastructure is down** — Git on external host, printable DR copy
2. **Document the WHY, not just the WHAT** — Compose files document the what; notes should explain decisions
3. **DR runbook is the most important document** — Test it regularly
4. **Anything that survives longer than a weekend gets documented** — Temporary setups become ghost configurations
5. **Never store credentials in docs** — Document WHERE credentials are stored, not the credentials themselves

---

*This review was conducted on 2026-02-26 as a benchmark. The scaffolding is excellent — repo structure, IaC, naming convention, and showcase docs are competitive. The operational docs that matter when things break are the weakest part. Closing that gap is the next milestone.*
