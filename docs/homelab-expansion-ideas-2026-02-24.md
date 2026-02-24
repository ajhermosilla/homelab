# Homelab Expansion Ideas — Service & Project Recommendations

**Date:** 2026-02-24
**Context:** Proxmox host (N150, 9GB Docker VM), NAS (i3-3220T, 8GB), VPS (Vultr), OPNsense firewall, 18 active services. Research from r/homelab, r/selfhosted, ServeTheHome, TechnoTim, Jeff Geerling.

---

## Current Stack (18 Active Services)

| # | Service | Host | Category |
|---|---------|------|----------|
| 1 | Headscale | VPS | Networking |
| 2 | Caddy (VPS) | VPS | Networking |
| 3 | Uptime Kuma | VPS | Monitoring |
| 4 | ntfy | VPS | Notifications |
| 5 | changedetection.io | VPS | Automation |
| 6 | Restic REST (VPS) | VPS | Backup |
| 7 | Pi-hole | Docker VM | Networking |
| 8 | Caddy (Fixed) | Docker VM | Networking |
| 9 | Vaultwarden | Docker VM | Security |
| 10 | Frigate | Docker VM | Security |
| 11 | Mosquitto | Docker VM | Automation |
| 12 | Home Assistant | Docker VM | Automation |
| 13 | Watchtower | Docker VM | Maintenance |
| 14 | Glances | NAS | Monitoring |
| 15 | Forgejo | NAS | Git |
| 16 | Restic REST (NAS) | NAS | Backup |
| 17 | Samba | NAS | Storage |
| 18 | Syncthing | NAS | Storage |

Plus 4 backup sidecars (headscale-backup, vaultwarden-backup, homeassistant-backup, Restic VPS).

---

## Tier 1 — Quick Wins (High Value, Easy Effort)

### Homepage Dashboard

- **What:** Single pane of glass for all services with live status widgets, Docker auto-discovery, and API integrations
- **Why:** 18+ services across 3 hosts — no single place to see them all. Auto-discovers Docker containers via labels, pulls live stats from Pi-hole, Frigate, HA, Jellyfin
- **Resources:** ~30MB RAM, single container
- **Where:** Docker VM
- **Time:** 30 minutes
- **Links:** [GitHub](https://github.com/gethomepage/homepage), [TechnoTim Guide](https://technotim.com/posts/homepage-dashboard/)

### Dozzle (Docker Log Viewer)

- **What:** Real-time Docker log streaming across all hosts from one web UI. Supports SQL queries via in-browser DuckDB and ntfy alerts
- **Why:** Replaces `ssh + docker logs` for debugging. Connects to Docker VM, NAS, and VPS from a single instance
- **Resources:** ~15MB RAM, stateless (no database, no log storage)
- **Where:** Docker VM (connect NAS and VPS as remote agents)
- **Time:** 15 minutes
- **Links:** [Dozzle](https://dozzle.dev/), [GitHub](https://github.com/amir20/dozzle)

### Stirling-PDF (PDF Toolkit)

- **What:** Self-hosted PDF manipulation (merge, split, convert, compress, OCR, sign, watermark) with web UI and REST API
- **Why:** Replaces sketchy online PDF tools that harvest data. API enables automation workflows
- **Resources:** ~100MB RAM
- **Where:** Docker VM
- **Time:** 15 minutes
- **Links:** [Blog](https://akashrajpurohit.com/blog/selfhost-stirling-pdf-for-pdf-manipulation/)

---

## Tier 2 — Evening Projects (High Value, Medium Effort)

### Authelia (Single Sign-On + 2FA)

- **What:** Authentication server that adds SSO and 2FA in front of all Caddy-proxied services. TOTP, WebAuthn/FIDO2, Duo push
- **Why:** Centralizes authentication through Caddy's `forward_auth`. One login protects Frigate, Jellyfin, Forgejo, Pi-hole. Single container with file/SQLite config (unlike Authentik which needs PostgreSQL + Redis + workers)
- **Resources:** ~30MB RAM
- **Where:** Docker VM alongside Caddy
- **Time:** 2-3 hours
- **Links:** [GitHub](https://github.com/authelia/authelia), [Setup Guide](https://akashrajpurohit.com/blog/setup-authelia-for-sso-authentication/)

### CrowdSec on OPNsense (Collaborative IPS)

- **What:** Crowd-sourced intrusion prevention. Blocks malicious IPs locally and shares intelligence with global network. Native OPNsense plugin
- **Why:** Protects exposed services (Caddy, Headscale). 60x faster than Fail2Ban (Go vs Python). Installs via OPNsense firmware UI, creates floating firewall rules automatically
- **Resources:** ~100MB RAM on OPNsense VM
- **Where:** OPNsense VM
- **Time:** 1 hour
- **Links:** [CrowdSec Docs](https://docs.crowdsec.net/docs/getting_started/install_crowdsec_opnsense/), [HomeNetworkGuy](https://homenetworkguy.com/how-to/install-and-configure-crowdsec-on-opnsense/)

### VictoriaMetrics + Grafana (Metrics & Dashboards)

- **What:** Lightweight Prometheus alternative (3-4x less RAM) + Grafana visualization. Historical metrics dashboards for all hosts
- **Why:** Glances and Uptime Kuma give real-time data but no history. VictoriaMetrics scrapes existing endpoints and provides capacity planning, alerting, and trend analysis
- **Resources:** VictoriaMetrics ~50MB + Grafana ~100MB + node-exporter ~10MB/host
- **Where:** Docker VM
- **Time:** 2-3 hours
- **Links:** [VictoriaMetrics](https://victoriametrics.com/), [MangoHost Guide](https://mangohost.net/blog/self-hosted-monitoring-with-victoriametrics-grafana-a-lightweight-alternative/)

---

## Tier 3 — Weekend Projects (High Value, More Effort)

### Immich (Self-Hosted Google Photos)

- **What:** Full Google Photos replacement with mobile apps, automatic backup, ML face recognition, smart search, albums, sharing, map view. Stable v2.0 since October 2025
- **Why:** Biggest privacy win if using Google/iCloud Photos. Mobile app handles background uploads. ML runs locally (CLIP model). 8TB WD Red on NAS is perfect
- **Resources:** ~500MB-1GB RAM (needs PostgreSQL)
- **Where:** NAS (photos on 8TB WD Red)
- **Time:** 3-4 hours
- **Links:** [Immich](https://immich.app/), [XDA Migration Guide](https://www.xda-developers.com/google-photos-vs-immich-3628122/)

### Paperless-ngx (Document Management)

- **What:** Scans, OCRs, tags, and indexes documents. Consume folder watches for new files, ML auto-tagging, full-text search
- **Why:** Scan with phone → drop in Syncthing folder → auto-processed. Combined with Stirling-PDF for preprocessing, complete document pipeline
- **Resources:** ~300-500MB RAM (needs PostgreSQL + Redis)
- **Where:** Docker VM or NAS
- **Time:** 3-4 hours
- **Links:** [Paperless-ngx Docs](https://docs.paperless-ngx.com/setup/), [TechnoTim + Local AI](https://technotim.com/posts/paperless-ngx-local-ai/)

### n8n (Workflow Automation)

- **What:** Self-hosted Zapier/IFTTT with 200+ integrations, visual workflow builder, SSH/HTTP/cron/MQTT support
- **Why:** Glue that connects everything. Use cases: SMART disk health monitoring, backup verification alerts, Watchtower daily digest, Frigate snapshot enrichment, Docker container health alerts
- **Resources:** ~200MB RAM (needs PostgreSQL for production)
- **Where:** Docker VM
- **Time:** 2-3 hours
- **Links:** [TechnoTim](https://technotim.com/posts/n8n-self-hosted/), [n8n + Ollama](https://ngrok.com/blog/self-hosted-local-ai-workflows-with-docker-n8n-ollama-and-ngrok-2025)

---

## OPNsense Security Projects

### Suricata IDS/IPS

- **What:** Deep packet inspection already built into OPNsense — just enable and configure
- **Why:** Combined with CrowdSec (perimeter blocklist) + Suricata (deep inspection) = proper security stack
- **Resources:** 200-500MB RAM depending on rulesets (may need OPNsense VM RAM bump)
- **Links:** [OPNsense IPS Docs](https://docs.opnsense.org/manual/ips.html)

### GeoIP Blocking

- **What:** Block traffic from countries with no legitimate business using OPNsense's built-in GeoIP alias feature
- **Why:** Eliminates huge percentage of brute-force and scanning traffic on WAN inbound

### VLAN Hardening

- **What:** Strict inter-VLAN rules — IOT only reaches MQTT+NTP, Guest gets internet only, Cameras only reach Frigate
- **Why:** Proper segmentation means compromised IoT device can't reach NAS or Vaultwarden

### DNS-over-TLS

- **What:** Encrypt upstream DNS queries (Cloudflare/Quad9) via OPNsense Unbound
- **Why:** Prevents ISP from snooping on DNS queries

---

## Creative HA Automations

### Zone-Based Security Modes

Everyone leaves → Frigate "away mode" (all cameras aggressive, indoor active). Someone home → perimeter only, indoor off. Uses HA Companion App presence tracking.

### Frigate Vision Blueprint

LLM describes what camera sees: "Delivery driver placing package on porch" instead of generic "person detected." Supports cooldowns and multi-camera logic.

- **Link:** [Community Blueprint](https://community.home-assistant.io/t/blueprint-frigate-vision-ai-powered-notifications-with-llm-recognition-cooldowns-multi-cam-logic-v0-9/907582)

### Daily Time-Lapse

Cron collects Frigate snapshots at regular intervals → stitch into daily time-lapse video → save to Jellyfin library or Syncthing folder.

### Actionable ntfy Notifications

Frigate detects person → ntfy notification with action buttons: "View Camera," "Unlock Door," "Turn On Porch Light." Tapping triggers HA automation.

---

## What NOT to Deploy

| Service | Why Not |
|---------|---------|
| Nextcloud | Resource hog (500MB+ min), Syncthing + Samba already covers file sync/sharing |
| Ollama / Local LLM | N150 has no GPU, CPU inference painfully slow |
| GitLab | 4GB+ RAM, Forgejo covers your needs perfectly |
| Kubernetes / K3s | Overkill for 15-20 containers across 3 hosts |
| Portainer | CLI-first with lazydocker, adds little value at ~200MB RAM |
| Plex | Already have Jellyfin |
| Zenarmor | Free tier limited, Suricata + CrowdSec gives better coverage at zero cost |

---

## RAM Budget

### Docker VM (9GB total, ~5GB used)

| Service | RAM |
|---------|-----|
| Homepage | 30MB |
| Dozzle | 15MB |
| Stirling-PDF | 100MB |
| Authelia | 30MB |
| VictoriaMetrics + Grafana | 150MB |
| Paperless-ngx | 400MB |
| n8n | 200MB |
| **Total** | **~925MB** |

### NAS (8GB total, ~3GB used)

| Service | RAM |
|---------|-----|
| Immich | 750MB |
| **Total** | **~750MB** |

Both well within capacity.

---

## Recommended Deployment Order

| # | Service | Where | RAM | Time | Priority |
|---|---------|-------|-----|------|----------|
| 1 | Homepage | Docker VM | 30MB | 30 min | Do first |
| 2 | Dozzle | Docker VM | 15MB | 15 min | Do first |
| 3 | CrowdSec | OPNsense | 100MB | 1 hour | Security |
| 4 | Stirling-PDF | Docker VM | 100MB | 15 min | Utility |
| 5 | Authelia | Docker VM | 30MB | 2-3 hours | Security |
| 6 | VictoriaMetrics + Grafana | Docker VM | 150MB | 2-3 hours | Observability |
| 7 | Immich | NAS | 750MB | 3-4 hours | Privacy |
| 8 | Paperless-ngx | Docker VM | 400MB | 3-4 hours | Productivity |
| 9 | n8n | Docker VM | 200MB | 2-3 hours | Automation |

---

## Sources

- [Homepage GitHub](https://github.com/gethomepage/homepage)
- [Dozzle](https://dozzle.dev/)
- [Authelia GitHub](https://github.com/authelia/authelia)
- [CrowdSec OPNsense Docs](https://docs.crowdsec.net/docs/getting_started/install_crowdsec_opnsense/)
- [VictoriaMetrics](https://victoriametrics.com/)
- [Immich](https://immich.app/)
- [Paperless-ngx Docs](https://docs.paperless-ngx.com/setup/)
- [Stirling-PDF](https://akashrajpurohit.com/blog/selfhost-stirling-pdf-for-pdf-manipulation/)
- [n8n Self-Hosted (TechnoTim)](https://technotim.com/posts/n8n-self-hosted/)
- [OPNsense IPS Docs](https://docs.opnsense.org/manual/ips.html)
- [Authentik vs Authelia vs Keycloak 2026](https://blog.elest.io/authentik-vs-authelia-vs-keycloak-choosing-the-right-self-hosted-identity-provider-in-2026/)
- [TechnoTim Homelab Tour 2025](https://technotim.com/posts/homelab-services-tour-2025/)
- [2026 Homelab Stack (Elest.io)](https://blog.elest.io/the-2026-homelab-stack-what-self-hosters-are-actually-running-this-year/)
- [Frigate Vision Blueprint](https://community.home-assistant.io/t/blueprint-frigate-vision-ai-powered-notifications-with-llm-recognition-cooldowns-multi-cam-logic-v0-9/907582)
