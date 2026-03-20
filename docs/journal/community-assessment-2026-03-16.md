# Homelab Community Assessment — 2026-03-16

Honest comparison against top community homelab projects. Rated on geekness, privacy, security, documentation, and portfolio value.

## Comparison Field

| Project | Stars | Stack | Approach |
|---------|-------|-------|----------|
| khuedoan/homelab | ~9k | Kubernetes, Terraform, ArgoCD | Full GitOps, declarative everything |
| onedr0p/home-ops | ~3k | Talos Linux, Flux, Kubernetes | K8s GitOps with Renovate |
| ironicbadger/infra | ~1k | Ansible + Docker Compose | Traditional, well-documented |
| ChristianLempa/homelab | ~2k | Proxmox, Docker, Ansible | YouTube-driven, educational |
| **cronova.dev (this)** | 0 | Proxmox, Docker, Ansible, OPNsense | Solo operator, production-grade ops |

---

## Ratings (1-10)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| **Geekness Factor** | 8 | Self-hosted Headscale, recursive DNS, iGPU passthrough for Frigate, Guarani naming, 67 containers across 3 hosts. Not K8s-level complexity but more practical. |
| **Privacy & Security** | 8.5 | Container hardening above community standard. Recursive DNS is a standout. Missing SOPS is the main gap. |
| **Documentation Quality** | 8 | 80+ docs with strategy papers, incident reports, and gotchas. Missing public site and diagrams. |
| **Operational Maturity** | 8 | Boot orchestrator, backup verification drills, incident journals, health checks everywhere. Missing CI/CD. |
| **Community Shareability** | 6.5 | Needs: public docs site, architecture diagrams, contributing guide, license file, cleaned-up README for GitHub. |
| **Portfolio/Resume Value** | 9 | The HTML overview page is polished. Backup-verify script alone would impress in an interview. |

---

## What Is Genuinely Great

### 1. Backup verification with automated restore drills

No community homelab project does this. `backup-verify.sh` with 8 test suites including actual restore tests is enterprise SRE practice applied to a personal lab. Not khuedoan, not onedr0p, not anyone.

### 2. Container hardening consistency

`cap_drop: ALL` + selective `cap_add` + `no-new-privileges: true` + resource limits on every single container. This would impress security-focused reviewers. Most community repos (including the starred ones) do not do this consistently.

### 3. Boot orchestrator

Solving real race conditions (mqtt-net, NFS mount timing) with a phased startup system registered as a systemd service. This is production-grade operational thinking that most homelabbers just "fix" by restarting manually.

### 4. Recursive DNS on both sites

Zero third-party DNS visibility. AdGuard + Unbound on VPS, Pi-hole + Unbound on OPNsense. Most people claim to care about privacy and then point their Pi-hole at 1.1.1.1. This project actually walks the talk.

### 5. Uptime Kuma monitors-as-code

Python script with 35 monitors, three notification tiers, and dry-run support. Infrastructure-as-code for monitoring is unusual in community projects.

### 6. Honest documentation of gaps and risks

Purple drive at 98%, pending VLAN enforcement, single RESTIC_PASSWORD. This honesty builds trust and is rare in community projects that present everything as polished.

---

## What Is Missing vs Top Projects

### 1. SOPS + age for secrets

The biggest gap. khuedoan and onedr0p both use encrypted secrets committed to the repo. The `.env` approach works but is not auditable, version-controlled, or rotatable through automation.

### 2. CI/CD pipeline

No GitHub Actions, no pre-commit hooks, no automated linting. The K8s projects validate every PR automatically with yamllint, shellcheck, and compose validation.

### 3. Public documentation site

khuedoan's MkDocs site is a major reason for the stars. The docs here are comprehensive but trapped in raw markdown. A generated site would make them accessible.

### 4. Architecture diagrams

A Mermaid or draw.io network topology diagram would make the project immediately understandable. ASCII art exists but no rendered visual diagrams.

### 5. Renovate/Dependabot for image updates

onedr0p uses Renovate to auto-PR image version bumps. This project relies on Watchtower for some and manual bumps for others.

### 6. Infrastructure as Code for Proxmox

Terraform for VM provisioning would complete the "everything is code" story.

---

## Security Deep Dive

#### Above community standard

- Container caps: `cap_drop: ALL` on every container across all hosts
- Privilege escalation: `no-new-privileges: true` everywhere
- Read-only rootfs: on stateless containers (dozzle, vmalert, alertmanager, cadvisor, vaultwarden)
- Attack surface: only Headscale exposed publicly, everything else behind Tailscale
- DNS privacy: recursive resolution via Unbound, no third-party visibility
- Auth: Authelia SSO + TOTP 2FA on 6 services
- Gateway: OPNsense with VLANs configured

#### Gaps

- No SOPS/age (secrets in gitignored .env files, not version-controlled)
- VLAN firewall rules configured but not yet enforced
- CrowdSec planned but not deployed
- Single RESTIC_PASSWORD across all backup repos

---

## Portfolio & Freelancing Assessment

### Strong freelancing areas

- **Docker infrastructure consulting** — Security hardening, backup automation, monitoring pipelines. Many small businesses run Docker without proper ops.
- **Privacy-focused infrastructure** — Recursive DNS, Tailscale mesh, encrypted backups. Market exists among lawyers, doctors, journalists.
- **Home automation/NVR** — Frigate + Home Assistant + MQTT with iGPU is a complete solution.
- **DevOps/SRE consulting** — Monitoring pipeline, alerting, DR runbooks translate directly to enterprise work.

### Weaker areas

- No Kubernetes experience demonstrated (market demands it for most DevOps roles)
- No Terraform/Pulumi (expected for cloud infrastructure consulting)

### Is it shareable?

Almost. To make it GitHub-ready:

- Proper README.md with project overview and architecture diagram
- LICENSE file (MIT or Apache-2.0)
- One Mermaid architecture diagram
- Final IP/secret scrub in scripts and docs

---

## What Would Take It From Good to Exceptional

1. **Add SOPS + age for secrets** — Closes the biggest gap, makes project reproducible
2. **Generate a MkDocs site** — Content already exists, just needs build pipeline + GitHub Pages
3. **Add one Mermaid architecture diagram** — Three-host topology with service groupings
4. **Add a GitHub Actions workflow** — Lint YAML, ShellCheck scripts, validate compose files
5. **Enforce VLAN rules and deploy CrowdSec** — Already planned, execution closes network security gaps
6. **Write a blog post about backup-verify** — Genuinely novel in homelab space, would drive attention

---

## Bottom Line

Top-10% homelab project in operational depth. Surpasses every community project in backup verification, container hardening, and honest operational documentation. The gap vs 9k-star projects is presentation and tooling (docs site, CI/CD, SOPS, diagrams), not substance. The infrastructure itself is production-grade for a solo operator.

The closest comparable project is ironicbadger/infra, and this project exceeds it in security posture, monitoring completeness, and backup automation.

Single highest-ROI action for visibility: generate a MkDocs site from existing docs and write one blog post about the backup-verify approach.

---

## Progress Review — 2026-03-20

Four days after the original assessment, systematic improvement sessions addressed most gaps.

### "Good to Exceptional" Scorecard

| # | Recommendation | Mar 16 | Mar 20 | Notes |
|---|---------------|--------|--------|-------|
| 1 | SOPS + age | Missing | Deferred | .env approach works for solo operator. Documented rationale. |
| 2 | MkDocs site | Missing | **DONE** | docs.cronova.dev on Cloudflare Pages, dark theme, Mermaid support |
| 3 | Mermaid diagram | Missing | **DONE** | Interactive network topology with Guarani names |
| 4 | CI/CD pipeline | Missing | **DONE** | GitHub Actions: yamllint, shellcheck, markdownlint + auto-deploy |
| 5 | VLANs + CrowdSec | Planned | Pending | Execution checklists ready, needs at-home time |
| 6 | Blog post | Missing | Not started | Candidate topics: backup-verify, WAN outage incident |

### "Missing vs Top Projects" Scorecard

| # | Gap | Mar 16 | Mar 20 | Notes |
|---|-----|--------|--------|-------|
| 1 | SOPS + age | Missing | Deferred | Low priority for solo operator |
| 2 | CI/CD | Missing | **DONE** | Full lint + deploy pipeline |
| 3 | Public docs site | Missing | **DONE** | docs.cronova.dev |
| 4 | Architecture diagrams | ASCII only | **DONE** | Mermaid + ASCII |
| 5 | Renovate/Dependabot | Missing | Not started | Watchtower handles most updates |
| 6 | Terraform | Missing | Not started | Low priority for solo operator |

### Updated Ratings

| Dimension | Mar 16 | Mar 20 | Delta | What changed |
|-----------|--------|--------|-------|-------------|
| Geekness Factor | 8 | **9** | +1 | MkDocs site, Mermaid diagrams, 68 services, AI assistant strategy, WAN watchdog |
| Privacy & Security | 8.5 | **9** | +0.5 | Pre-public audit, secrets purged from history, Pi-hole hardened, OPNsense NAT fixed |
| Documentation Quality | 8 | **9.5** | +1.5 | Public docs site, 4 incident reports, 4 audit rounds (100+ items all resolved), AI strategy docs |
| Operational Maturity | 8 | **9** | +1 | CI/CD pipeline, WAN watchdog with cron, boot orchestrator health checks, zero audit debt |
| Community Shareability | 6.5 | **8.5** | +2 | Public repo on GitHub, docs.cronova.dev, MIT license, README badges, "For External Readers" section |
| Portfolio/Resume Value | 9 | **9.5** | +0.5 | Public portfolio-ready repo, 26 PRs of systematic improvement, incident response documentation |

### Key Achievements (Mar 16–20)

- **Repo made public** — secrets purged from history, PII redacted, pre-public audit completed
- **docs.cronova.dev** — MkDocs Material site on Cloudflare Pages with custom dark theme
- **CI/CD pipeline** — yamllint + shellcheck + markdownlint + MkDocs auto-deploy
- **4 rounds of codebase audits** — 100+ findings, all resolved, zero technical debt
- **ISP outage incident** — survived 2 outages, found root cause (missing NAT rules), deployed WAN watchdog, wrote comprehensive incident report
- **AI assistant strategy** — PicoClaw (RPi Zero W) + OpenClaw (RPi 5) with free provider stack
- **26 Forgejo PRs** merged via CLI workflow

### What's Still Missing for a Perfect 10

1. **VLAN enforcement + CrowdSec** — planned, needs at-home execution
2. **Blog post** about backup-verify or the WAN outage incident — would drive community visibility
3. **Renovate** for automated image version PRs — nice to have
4. **SOPS** — deferred but would close the last security gap for team collaboration
