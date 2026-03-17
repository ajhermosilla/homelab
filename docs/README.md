# Documentation Index

All homelab documentation, organized by category.

## Architecture

Core infrastructure documentation — what runs where, hardware specs, network topology.

| Document | Description |
|----------|-------------|

| [services.md](architecture/services.md) | Definitive service inventory (40+ services, ports, dependencies, Guarani names) |
| [hardware.md](architecture/hardware.md) | Device specs, Tailscale IPs, power budget, storage strategy |
| [fixed-homelab.md](architecture/fixed-homelab.md) | Fixed site: Proxmox, Docker VM (33 containers), NAS (19 containers), OPNsense |
| [mobile-homelab.md](architecture/mobile-homelab.md) | Portable kit (MacBook + Beryl AX + phone) |
| [vps-architecture.md](architecture/vps-architecture.md) | VPS infrastructure (Headscale, Caddy, monitoring) |
| [network-topology.md](architecture/network-topology.md) | Network diagrams and connectivity |
| [architecture-review.md](architecture/architecture-review.md) | Design decisions and gap analysis |

## Guides

Setup and operational guides — how to deploy, configure, and maintain.

| Document | Description |
|----------|-------------|

| [setup-runbook.md](guides/setup-runbook.md) | Full first-time setup (7 phases) |
| [deployment-order.md](guides/deployment-order.md) | Service dependencies and startup order |
| [proxmox-setup.md](guides/proxmox-setup.md) | Proxmox VE installation and VM creation |
| [opnsense-setup.md](guides/opnsense-setup.md) | OPNsense router/firewall configuration |
| [nas-guide.md](guides/nas-guide.md) | NAS setup guide (Debian, Docker, storage) |
| [nfs-setup.md](guides/nfs-setup.md) | NFS exports for Frigate recordings |
| [vlan-design.md](guides/vlan-design.md) | VLAN segmentation (Management, IoT, Guest) |
| [caddy-config.md](guides/caddy-config.md) | Caddy reverse proxy patterns |
| [nut-config.md](guides/nut-config.md) | UPS graceful shutdown (NUT) |
| [backup-test-procedure.md](guides/backup-test-procedure.md) | Monthly backup verification |
| [mobile-homelab-kit.md](guides/mobile-homelab-kit.md) | Mobile kit packing and travel setup |
| [uptime-kuma-setup-2026-01-19.md](guides/uptime-kuma-setup-2026-01-19.md) | Uptime Kuma deployment |
| [nas-app-deployment.md](guides/nas-app-deployment.md) | NAS application deployment guide |
| [incident-2026-03-05-isp-outage.md](guides/incident-2026-03-05-isp-outage.md) | ISP outage incident report |
| [incident-2026-03-05-frigate-crash.md](guides/incident-2026-03-05-frigate-crash.md) | Frigate crash incident report |

## Strategy

Design decisions and policies — why things are done a certain way.

| Document | Description |
|----------|-------------|

| [domain-strategy.md](strategy/domain-strategy.md) | cronova.dev DNS and domain plan |
| [certificate-strategy.md](strategy/certificate-strategy.md) | TLS certificates (DNS-01 Cloudflare) |
| [dns-architecture.md](strategy/dns-architecture.md) | DNS resolution flow (Pi-hole, AdGuard, Cloudflare) |
| [monitoring-strategy.md](strategy/monitoring-strategy.md) | VictoriaMetrics + Grafana metrics, Uptime Kuma monitors, ntfy alerts |
| [disaster-recovery.md](strategy/disaster-recovery.md) | Restic backup procedures, recovery scenarios, verification schedule |
| [secrets-management.md](strategy/secrets-management.md) | Credential handling (.env, SOPS, age) |
| [security-hardening.md](strategy/security-hardening.md) | 2FA, firewall rules, SSH hardening, fail2ban |
| [storage-strategy.md](strategy/storage-strategy.md) | Drive layout, backup topology, data protection, capacity planning |
| [domain-research.md](strategy/domain-research.md) | Domain comparison (archived — see domain-strategy) |

## Reference

Device guides, naming conventions, research, and reference material.

| Document | Description |
|----------|-------------|

| [guarani-naming-convention-2026-02-24.md](reference/guarani-naming-convention-2026-02-24.md) | Guarani naming guide for all services |
| [ha-devices-guide-2026-02-24.md](reference/ha-devices-guide-2026-02-24.md) | Home Assistant device integration guide |
| [home-devices.md](reference/home-devices.md) | Family device inventory |
| [tailscale-primer.md](reference/tailscale-primer.md) | Tailscale/Headscale introduction |
| [branding.md](reference/branding.md) | cronova.dev identity and branding |
| [homelab-evaluation.md](reference/homelab-evaluation.md) | Hardware comparison research |
| [beryl-ax-setup-2026-01-19.md](reference/beryl-ax-setup-2026-01-19.md) | Beryl AX initial setup |
| [beryl-ax-tailscale-persistence.md](reference/beryl-ax-tailscale-persistence.md) | Beryl AX Tailscale reboot fix |
| [keychron-k2c3-quickstart.md](reference/keychron-k2c3-quickstart.md) | Keychron keyboard setup |
| [rpi5-case-research.md](reference/rpi5-case-research.md) | RPi 5 case options |
| [3d-printed-cases-research.md](reference/3d-printed-cases-research.md) | 3D printed enclosure research |
| [family-emergency-internet.md](reference/family-emergency-internet.md) | Emergency internet procedures |

## Plans

Future plans and proposals — what's next.

| Document | Description |
|----------|-------------|

| [frigate-improvement-plan-2026-03-02.md](plans/frigate-improvement-plan-2026-03-02.md) | Frigate NVR improvements (Phase 1 done, Phase 2 blocked on 8TB HDD) |
| [uptime-kuma-monitors-2026-03-02.md](plans/uptime-kuma-monitors-2026-03-02.md) | Uptime Kuma monitor setup (complete — 35 monitors) |
| [igpu-passthrough-plan-2026-02-25.md](plans/igpu-passthrough-plan-2026-02-25.md) | SR-IOV iGPU passthrough for Frigate (done 2026-03-02) |
| [javya-deploy-nas-2026-03-02.md](plans/javya-deploy-nas-2026-03-02.md) | Javya deployment on NAS |
| [forgejo-github-mirror-2026-03-02.md](plans/forgejo-github-mirror-2026-03-02.md) | Forgejo → GitHub mirror setup |
| [ha-dashboard-plan-2026-02-24.md](plans/ha-dashboard-plan-2026-02-24.md) | Home Assistant dashboard design |
| [ha-monitoring-plan-2026-02-24.md](plans/ha-monitoring-plan-2026-02-24.md) | HA monitoring integrations |
| [crowdsec-opnsense-2026-03-11.md](plans/crowdsec-opnsense-2026-03-11.md) | CrowdSec IPS on OPNsense setup plan |
| [vlan-hardening-execution-2026-03-11.md](plans/vlan-hardening-execution-2026-03-11.md) | VLAN firewall rules execution checklist |
| [homelab-expansion-ideas-2026-02-24.md](plans/homelab-expansion-ideas-2026-02-24.md) | Service expansion roadmap |
| [self-hosted-paas-research-2026-02-25.md](plans/self-hosted-paas-research-2026-02-25.md) | PaaS comparison (Coolify chosen) |
| [nas-deployment-plan.md](plans/nas-deployment-plan.md) | NAS initial deployment plan |
| [rpi5-deployment-plan.md](plans/rpi5-deployment-plan.md) | RPi 5 OpenClaw deployment |
| [wan-watchdog-2026-02-23.md](plans/wan-watchdog-2026-02-23.md) | WAN monitoring watchdog |

## Journal

Execution logs, reports, and session notes — what happened.

| Document | Description |
|----------|-------------|

| [opnsense-gateway-cutover-2026-02-08.md](journal/opnsense-gateway-cutover-2026-02-08.md) | OPNsense cutover plan |
| [opnsense-cutover-execution-2026-02-21.md](journal/opnsense-cutover-execution-2026-02-21.md) | OPNsense cutover execution log |
| [post-cutover-verification-2026-02-21.md](journal/post-cutover-verification-2026-02-21.md) | Post-cutover verification |
| [pre-nas-audit-2026-02-21.md](journal/pre-nas-audit-2026-02-21.md) | Pre-NAS deployment audit |
| [red-8tb-recovery-2026-02-22.md](journal/red-8tb-recovery-2026-02-22.md) | WD Red 8TB recovery |
| [improvement-report-2026-02-22.md](journal/improvement-report-2026-02-22.md) | Improvement report |
| [documentation-review-2026-02-26.md](journal/documentation-review-2026-02-26.md) | Documentation review and gap analysis |
| [frigate-ha-optimization-2026-02-24.md](journal/frigate-ha-optimization-2026-02-24.md) | Frigate + HA optimization |

### Sessions

Daily work logs in [journal/sessions/](journal/sessions/).

## HTML

Generated HTML versions of selected documents in [html/](html/).
