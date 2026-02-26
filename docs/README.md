# Documentation Index

All homelab documentation, organized by category.

## Architecture

Core infrastructure documentation — what runs where, hardware specs, network topology.

| Document | Description |
|----------|-------------|
| [services.md](architecture/services.md) | Definitive service inventory (40+ services, ports, dependencies, Guarani names) |
| [hardware.md](architecture/hardware.md) | Device specs, Tailscale IPs, power budget, storage strategy |
| [fixed-homelab.md](architecture/fixed-homelab.md) | Fixed site architecture (Proxmox, Docker VM, NAS) |
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

## Strategy

Design decisions and policies — why things are done a certain way.

| Document | Description |
|----------|-------------|
| [domain-strategy.md](strategy/domain-strategy.md) | cronova.dev DNS and domain plan |
| [certificate-strategy.md](strategy/certificate-strategy.md) | TLS certificates (DNS-01 Cloudflare) |
| [dns-architecture.md](strategy/dns-architecture.md) | DNS resolution flow (Pi-hole, AdGuard, Cloudflare) |
| [monitoring-strategy.md](strategy/monitoring-strategy.md) | Alerting, metrics, and notification tiers |
| [disaster-recovery.md](strategy/disaster-recovery.md) | Backup and restore for all critical services |
| [secrets-management.md](strategy/secrets-management.md) | Credential handling (.env, SOPS, age) |
| [security-hardening.md](strategy/security-hardening.md) | 2FA, firewall rules, SSH hardening, fail2ban |
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
| [igpu-passthrough-plan-2026-02-25.md](plans/igpu-passthrough-plan-2026-02-25.md) | SR-IOV iGPU passthrough for Frigate |
| [ha-dashboard-plan-2026-02-24.md](plans/ha-dashboard-plan-2026-02-24.md) | Home Assistant dashboard design |
| [ha-monitoring-plan-2026-02-24.md](plans/ha-monitoring-plan-2026-02-24.md) | HA monitoring integrations |
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
| [frigate-ha-optimization-2026-02-24.md](journal/frigate-ha-optimization-2026-02-24.md) | Frigate + HA optimization |

### Sessions

Daily work logs in [journal/sessions/](journal/sessions/).

## HTML

Generated HTML versions of selected documents in [html/](html/).
