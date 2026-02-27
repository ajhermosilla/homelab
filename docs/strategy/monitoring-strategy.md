# Monitoring Strategy

How the homelab is monitored, alerted, and observed.

## Monitoring Stack Overview

| Component | Location | Purpose |
|-----------|----------|---------|
| **Uptime Kuma** | VPS | External health checks (HTTP, TCP, ping) |
| **ntfy** | VPS | Push notifications (alerts, backup status) |
| **VictoriaMetrics** (Papa) | Docker VM | Time-series metrics database |
| **vmagent** | Docker VM | Prometheus-compatible metrics scraper |
| **Grafana** (Papa) | Docker VM | Dashboards and visualization |
| **Dozzle** (Ysyry) | Docker VM | Real-time container log viewer |
| **Glances** | NAS | System resource monitor (HA integration) |
| **Watchtower** | Docker VM | Auto-update monitoring (Sunday 4 AM) |

---

## Metrics Pipeline

```
node_exporter (Docker VM :9100) ──┐
node_exporter (NAS :9100) ────────┼──► vmagent ──► VictoriaMetrics ──► Grafana
Home Assistant (/api/prometheus) ──┘    (30s scrape)    (90d retention)    (papa.cronova.dev)
```

**Config:** `docker/fixed/docker-vm/monitoring/prometheus.yml`

### Scrape Targets

| Job | Target | Labels |
|-----|--------|--------|
| node-docker-vm | `host.docker.internal:9100` | instance: docker-vm |
| node-nas | `100.82.77.97:9100` | instance: nas |
| home-assistant | `host.docker.internal:8123/api/prometheus` | instance: home-assistant |

### VictoriaMetrics

- Image: `victoriametrics/victoria-metrics:latest`
- Port: 8428 (localhost only)
- Retention: 90 days
- Memory limit: 1GB
- Data volume: `vm-data`

### Grafana

- Image: `grafana/grafana:latest`
- Port: 3000 (localhost only, behind Caddy + Authelia)
- URL: `https://papa.cronova.dev`
- Plugin: `victoriametrics-metrics-datasource`

---

## Uptime Kuma Monitors

Uptime Kuma runs on the VPS and monitors all services via Tailscale mesh. Alerts route to ntfy topics by priority.

### Critical (60s interval, ntfy urgent)

| Monitor | Type | Target |
|---------|------|--------|
| Headscale | HTTP | `https://hs.cronova.dev/health` |
| Vaultwarden | HTTP | `https://vault.cronova.dev/alive` |
| Pi-hole (Docker VM) | TCP | `100.68.63.168:53` |
| Caddy (Docker VM) | HTTP | `https://cronova.dev` |
| OPNsense | Ping | `192.168.0.1` |

### High Priority (5m interval, ntfy high)

| Monitor | Type | Target |
|---------|------|--------|
| Home Assistant (Jara) | HTTP | `https://jara.cronova.dev` |
| Frigate (Taguato) | HTTP | `https://taguato.cronova.dev/api/version` |
| Forgejo | HTTP | `https://git.cronova.dev/api/healthz` |
| NAS (Samba) | TCP | `100.82.77.97:445` |
| Restic REST | HTTP | `http://100.82.77.97:8000/` (expect 401) |
| Coolify (Tajy) | HTTP | `https://tajy.cronova.dev` |
| Authelia (Oke) | HTTP | `https://auth.cronova.dev` |

### Standard (5m interval, ntfy default)

| Monitor | Type | Target |
|---------|------|--------|
| Jellyfin (Yrasema) | HTTP | `https://yrasema.cronova.dev/health` |
| Grafana (Papa) | HTTP | `https://papa.cronova.dev` |
| Immich (Vera) | HTTP | `https://vera.cronova.dev` |
| Syncthing | HTTP | `http://100.82.77.97:8384/rest/noauth/health` |
| Glances | HTTP | `http://100.82.77.97:61208/api/4/cpu` |

### External (15m interval)

| Monitor | Type | Target |
|---------|------|--------|
| cronova.dev | HTTPS | `https://cronova.dev` |
| verava.ai | HTTPS | `https://verava.ai` |

### Planned Monitors (not yet configured)

| Monitor | Type | Target | Notes |
|---------|------|--------|-------|
| Paperless-ngx (Aranduka) | HTTP | `https://aranduka.cronova.dev` | After deployment |
| Stirling-PDF (Kuatia) | HTTP | `https://kuatia.cronova.dev` | After deployment |
| Homepage (Mbyja) | HTTP | `https://mbyja.cronova.dev` | After deployment |
| Dozzle (Ysyry) | HTTP | `https://ysyry.cronova.dev` | After deployment |

---

## ntfy Notification Architecture

**URL:** `https://notify.cronova.dev` (VPS, Caddy reverse proxy)

### Topics

| Topic | Purpose | Priority |
|-------|---------|----------|
| `cronova-critical` | Service down, data loss risk | Urgent (wakes phone) |
| `cronova-warning` | Degraded performance | High |
| `cronova-info` | Backups completed, maintenance | Default (silent) |
| `cronova-test` | Testing notifications | Low |

### Auth

- Anonymous access: deny-all
- Service tokens for automation (backup sidecars, scripts)
- User `augusto` has full read/write on all topics

### Integration Points

| Source | Topic | Trigger |
|--------|-------|---------|
| Uptime Kuma | `cronova-critical` / `cronova-warning` | Service down/degraded |
| Backup sidecars | `cronova-critical` / `cronova-info` | Backup failure / success |
| `scripts/backup-notify.sh` | Per-service routing | Backup event notifications |
| `scripts/backup-verify.sh` | `cronova-info` | Monthly verification results |

### Subscribe on Phone

```
Android/iOS ntfy app → Subscribe to:
  https://notify.cronova.dev/cronova-critical
  https://notify.cronova.dev/cronova-warning
```

---

## Container Log Monitoring — Dozzle (Ysyry)

- URL: `https://ysyry.cronova.dev` (Caddy + Authelia)
- Real-time Docker log viewer for all containers on Docker VM
- No persistent storage — live view only
- Useful for debugging container startup issues, watching Frigate detections, checking backup logs

---

## Auto-Update Monitoring — Watchtower

- Schedule: **Sunday 4:00 AM** (label-enabled, opt-in via `com.centurylinklabs.watchtower.enable=true`)
- Image: `nicholas-fedor/watchtower:1.14.2` (maintained fork — official containrrr is abandoned/Docker 29+ incompatible)
- Behavior: Rolling restarts, old image cleanup
- **Excluded from auto-update** (manual only): vaultwarden, frigate, headscale

---

## Home Assistant Integrations (Monitoring-Related)

| Integration | Source | What It Monitors |
|-------------|--------|------------------|
| System Monitor | Docker VM | CPU, RAM, disk usage |
| Glances | NAS (100.82.77.97:61208) | NAS system metrics |
| Proxmox VE (HACS) | Oga (100.78.12.241) | Host and VM status |
| Frigate | MQTT (mqtt-net) | Camera events, detection counts |

---

## Monitoring Checklist

### Weekly

- [ ] Check Uptime Kuma dashboard — all monitors green
- [ ] Review ntfy alert history — any unexpected alerts
- [ ] Spot-check Dozzle for container error logs

### Monthly (1st Sunday)

- [ ] Run `backup-verify.sh` on Docker VM
- [ ] Check Grafana dashboards — disk usage trends, RAM pressure
- [ ] Verify vmagent scrape targets are all up (`/targets` endpoint)
- [ ] Review Watchtower update logs
- [ ] Check NAS Purple 2TB usage (97% — monitor closely)

### Quarterly

- [ ] Full backup restore drill (`backup-verify.sh --full`)
- [ ] Review and update Uptime Kuma monitors for new/removed services
- [ ] Test ntfy notification delivery (all priority levels)
- [ ] Review VictoriaMetrics retention and disk usage

---

## References

- [VictoriaMetrics Docs](https://docs.victoriametrics.com/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Uptime Kuma Wiki](https://github.com/louislam/uptime-kuma/wiki)
- [ntfy Documentation](https://docs.ntfy.sh/)
- [Dozzle](https://dozzle.dev/)
- [Watchtower](https://github.com/nicholas-fedor/watchtower)
- [Glances](https://nicolargo.github.io/glances/)
