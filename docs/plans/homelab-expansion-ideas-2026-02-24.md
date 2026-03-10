# Homelab Expansion Ideas — Service & Project Recommendations

**Date:** 2026-02-24
**Updated:** 2026-03-10
**Context:** Proxmox host (N150, 9GB Docker VM), NAS (i3-3220T, 8GB), VPS (Vultr), OPNsense firewall. Originally 18 services, now 41+ active. Research from r/homelab, r/selfhosted, ServeTheHome, TechnoTim, Jeff Geerling.

**Deployment status:** 7 of 9 recommended services deployed. Remaining: CrowdSec (OPNsense), n8n.

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

### Homepage Dashboard — DEPLOYED

- **What:** Single pane of glass for all services with live status widgets, Docker auto-discovery
- **Where:** Docker VM (Mbyja, `mbyja.cronova.dev`, behind Authelia)

### Dozzle (Docker Log Viewer) — DEPLOYED

- **What:** Real-time Docker log streaming across all hosts from one web UI
- **Where:** Docker VM (Ysyry, `ysyry.cronova.dev`, behind Authelia)

### BentoPDF (PDF Toolkit) — DEPLOYED (replaced Stirling-PDF)

- **What:** Client-side WASM PDF manipulation (merge, split, convert). Replaced Stirling-PDF (Java/Spring Boot, 85% idle CPU, ~500MB RAM) with BentoPDF (0% CPU, ~4MB RAM)
- **Where:** Docker VM (Kuatia, `kuatia.cronova.dev`, behind Authelia)

---

## Tier 2 — Evening Projects (High Value, Medium Effort)

### Authelia (Single Sign-On + 2FA) — DEPLOYED

- **What:** Authentication server with TOTP 2FA via Caddy `forward_auth`
- **Where:** Docker VM (Okẽ, `auth.cronova.dev`). Protects: Yrasema, Ysyry, Kuatia, Mbyja, Papa, Aranduka. TOTP via Authy, filesystem notifier.

### CrowdSec on OPNsense (Collaborative IPS)

- **What:** Crowd-sourced intrusion prevention. Blocks malicious IPs locally and shares intelligence with global network. Native OPNsense plugin
- **Why:** Protects exposed services (Caddy, Headscale). 60x faster than Fail2Ban (Go vs Python). Installs via OPNsense firmware UI, creates floating firewall rules automatically
- **Resources:** ~100MB RAM on OPNsense VM
- **Where:** OPNsense VM
- **Time:** 1 hour
- **Links:** [CrowdSec Docs](https://docs.crowdsec.net/docs/getting_started/install_crowdsec_opnsense/), [HomeNetworkGuy](https://homenetworkguy.com/how-to/install-and-configure-crowdsec-on-opnsense/)

### VictoriaMetrics + Grafana (Metrics & Dashboards) — DEPLOYED

- **What:** Lightweight Prometheus alternative + Grafana visualization
- **Where:** Docker VM (Papa, `papa.cronova.dev`, behind Authelia). Scrapes Docker VM + NAS + HA. 90-day retention.

---

## Tier 3 — Weekend Projects (High Value, More Effort)

### Immich (Self-Hosted Google Photos) — DEPLOYED

- **What:** Full Google Photos replacement with mobile apps, ML face recognition, smart search
- **Where:** Docker VM (Vera, `vera.cronova.dev`, own auth). 4 containers: server, ML, Valkey, PostgreSQL.

### Paperless-ngx (Document Management) — DEPLOYED

- **What:** Document scanning, OCR, tagging, full-text search
- **Where:** Docker VM (Aranduka, `aranduka.cronova.dev`, behind Authelia). 3 containers: server, PostgreSQL, Redis.

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

| Service | RAM | Status |
|---------|-----|--------|
| Homepage | 30MB | Deployed |
| Dozzle | 15MB | Deployed |
| BentoPDF | ~4MB | Deployed (replaced Stirling-PDF) |
| Authelia | 30MB | Deployed |
| VictoriaMetrics + Grafana | 150MB | Deployed |
| Paperless-ngx | 400MB | Deployed |
| n8n | 200MB | Pending |
| **Total deployed** | **~629MB** | |

### NAS (8GB total, ~3GB used)

| Service | RAM |
|---------|-----|
| Immich | 750MB |
| **Total** | **~750MB** |

Both well within capacity.

---

## Recommended Deployment Order

| # | Service | Where | Status |
|---|---------|-------|--------|
| 1 | Homepage (Mbyja) | Docker VM | Deployed |
| 2 | Dozzle (Ysyry) | Docker VM | Deployed |
| 3 | CrowdSec | OPNsense | **Pending** |
| 4 | BentoPDF (Kuatia) | Docker VM | Deployed (replaced Stirling-PDF) |
| 5 | Authelia (Okẽ) | Docker VM | Deployed |
| 6 | VictoriaMetrics + Grafana (Papa) | Docker VM | Deployed |
| 7 | Immich (Vera) | Docker VM | Deployed |
| 8 | Paperless-ngx (Aranduka) | Docker VM | Deployed |
| 9 | n8n (Pytyvõ) | Docker VM | **Pending** |

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
