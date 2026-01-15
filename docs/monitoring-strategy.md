# Monitoring Strategy

Uptime Kuma + ntfy for homelab monitoring and alerting.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     VPS (Vultr)                              │
│  ┌─────────────┐    ┌─────────┐                             │
│  │ Uptime Kuma │───▶│  ntfy   │───▶ Phone/Desktop           │
│  │ :3001       │    │ :80     │     Notifications           │
│  └──────┬──────┘    └─────────┘                             │
│         │                                                    │
│         │ Monitor                                            │
└─────────┼───────────────────────────────────────────────────┘
          │
          │ Tailscale Mesh
          │
    ┌─────┴─────────────────────────────────────────┐
    │                                               │
    ▼                                               ▼
┌───────────────┐                          ┌───────────────┐
│  Mobile Kit   │                          │ Fixed Homelab │
│  RPi 5        │                          │ Mini PC, NAS  │
│  Headscale    │                          │ RPi 4         │
└───────────────┘                          └───────────────┘
```

---

## Uptime Kuma Monitors

### Critical Services (60s interval)

Must be online 24/7. Alert immediately on failure.

| Service | Type | Target | Expected |
|---------|------|--------|----------|
| Headscale | HTTPS | `https://hs.cronova.dev/health` | 200 OK |
| Vaultwarden | HTTPS | `https://vault.cronova.dev/alive` | 200 OK |
| Pi-hole (RPi 5) | TCP | `100.64.0.1:53` | Open |
| Pi-hole (Fixed) | TCP | `100.64.0.10:53` | Open |
| NUT Server | TCP | `100.64.0.12:3493` | Open |

### High Priority Services (5m interval)

Core homelab services. Alert after 2 failures.

| Service | Type | Target | Expected |
|---------|------|--------|----------|
| Home Assistant | HTTP | `http://100.64.0.10:8123` | 200 OK |
| Jellyfin | HTTP | `http://100.64.0.10:8096` | 200 OK |
| Frigate | HTTP | `http://100.64.0.10:5000` | 200 OK |
| Start9 | HTTP | `http://100.64.0.11` | 200 OK |
| NAS Samba | TCP | `100.64.0.12:445` | Open |
| NAS Syncthing | HTTP | `http://100.64.0.12:8384` | 200 OK |
| Restic REST (NAS) | TCP | `100.64.0.12:8000` | Open |

### VPS Services (5m interval)

Running on VPS. Alert after 2 failures.

| Service | Type | Target | Expected |
|---------|------|--------|----------|
| DERP Relay | TCP | `localhost:443` | Open |
| Pi-hole (VPS) | TCP | `localhost:53` | Open |
| changedetection | HTTP | `http://localhost:5000` | 200 OK |
| Restic REST (VPS) | TCP | `localhost:8000` | Open |

### External Checks (15m interval)

Public-facing. Alert after 3 failures.

| Service | Type | Target | Expected |
|---------|------|--------|----------|
| cronova.dev | HTTPS | `https://cronova.dev` | 200/301/302 |
| verava.ai | HTTPS | `https://verava.ai` | 200/301/302 |
| status.cronova.dev | HTTPS | `https://status.cronova.dev` | 200 OK |
| notify.cronova.dev | HTTPS | `https://notify.cronova.dev` | 200 OK |

---

## ntfy Topic Structure

### Topics

| Topic | Purpose | Priority |
|-------|---------|----------|
| `cronova-critical` | Service down, data loss risk | Urgent |
| `cronova-warning` | Degraded performance, attention needed | High |
| `cronova-info` | Backups completed, maintenance | Default |
| `cronova-test` | Testing notifications | Low |

### Subscribe on Phone

```bash
# Android/iOS ntfy app
# Subscribe to: https://notify.cronova.dev/cronova-critical
```

### Topic Access Control

Configure in ntfy (VPS):

```bash
# Create admin user
docker exec -it ntfy ntfy user add --role=admin augusto

# Set topic permissions
docker exec -it ntfy ntfy access augusto '*' rw
docker exec -it ntfy ntfy access '*' 'cronova-test' rw  # Public test topic
```

---

## Alert Configuration

### Uptime Kuma → ntfy Integration

In Uptime Kuma (Settings → Notifications):

| Field | Value |
|-------|-------|
| Type | ntfy |
| Server URL | `https://notify.cronova.dev` |
| Topic | `cronova-critical` |
| Priority | urgent |
| Username | augusto |
| Password | (your password) |

### Alert Rules

| Event | Topic | Priority | Action |
|-------|-------|----------|--------|
| Critical service down | cronova-critical | urgent | Wake phone |
| High priority service down | cronova-warning | high | Notification |
| Service recovered | cronova-info | default | Silent |
| Backup completed | cronova-info | low | Silent |
| SSL expiry < 14 days | cronova-warning | high | Notification |

---

## Notification Scripts

### Backup Completion Notification

```bash
#!/bin/bash
# /usr/local/bin/notify-backup.sh

NTFY_URL="https://notify.cronova.dev/cronova-info"

curl -H "Title: Backup Completed" \
     -H "Priority: low" \
     -H "Tags: white_check_mark" \
     -d "Homelab backup completed successfully at $(date)" \
     "$NTFY_URL"
```

### Service Recovery Notification

```bash
#!/bin/bash
# Called by Uptime Kuma on recovery

NTFY_URL="https://notify.cronova.dev/cronova-info"
SERVICE="$1"

curl -H "Title: Service Recovered" \
     -H "Priority: default" \
     -H "Tags: green_circle" \
     -d "$SERVICE is back online" \
     "$NTFY_URL"
```

### Test Notification

```bash
# Quick test
curl -d "Test notification from homelab" \
     https://notify.cronova.dev/cronova-test
```

---

## Status Page Configuration

### Public Status Page

Uptime Kuma supports public status pages:

1. Settings → Status Pages → Create
2. Name: `Homelab Status`
3. Slug: `status`
4. Add monitors for public services:
   - Vaultwarden
   - status.cronova.dev
   - notify.cronova.dev

Access at: `https://status.cronova.dev/status/status`

### Incident Management

When services go down:
1. Uptime Kuma creates incident automatically
2. Update status page with details
3. Resolve when service recovers

---

## Maintenance Windows

### Configure Scheduled Maintenance

In Uptime Kuma:
1. Select monitor
2. Maintenance → Add
3. Set schedule (e.g., Sunday 3-5 AM)
4. Alerts suppressed during window

### Common Maintenance Tasks

| Task | Frequency | Duration |
|------|-----------|----------|
| Proxmox updates | Monthly | 30 min |
| Docker image updates | Weekly | 15 min |
| NAS backup verification | Monthly | 1 hour |
| Certificate renewal | Auto | - |

---

## Monitoring Checklist

### Initial Setup

- [ ] Deploy Uptime Kuma on VPS
- [ ] Configure ntfy authentication
- [ ] Create notification integration
- [ ] Add all critical monitors
- [ ] Subscribe to topics on phone
- [ ] Test alert delivery
- [ ] Create public status page

### Weekly Verification

- [ ] Check all monitors are green
- [ ] Review alert history
- [ ] Verify notification delivery
- [ ] Check certificate expiry warnings

### Monthly Review

- [ ] Analyze uptime reports
- [ ] Adjust alert thresholds if needed
- [ ] Test disaster recovery procedures
- [ ] Update monitors for new services

---

## Prometheus Integration (Future)

For advanced metrics, consider adding:

```yaml
# docker-compose.yml addition
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml

grafana:
  image: grafana/grafana:latest
  ports:
    - "3000:3000"
```

Exporters to consider:
- node_exporter (system metrics)
- cadvisor (container metrics)
- nut_exporter (UPS metrics)
- blackbox_exporter (probe endpoints)

---

## Reference

- [Uptime Kuma Docs](https://github.com/louislam/uptime-kuma/wiki)
- [ntfy Documentation](https://docs.ntfy.sh/)
- [ntfy Android App](https://play.google.com/store/apps/details?id=io.heckel.ntfy)
- [ntfy iOS App](https://apps.apple.com/app/ntfy/id1625396347)
