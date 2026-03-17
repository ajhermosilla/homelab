# Home Assistant — Infrastructure Monitoring Plan

**Date:** 2026-02-24
**Context:** Proxmox host (oga), Docker VM (jara), NAS — need visibility into CPU, RAM, disk, temperatures from Home Assistant.

---

## Options Compared

| Option | What It Monitors | RAM Cost | New Containers | Setup Effort |
|--------|-----------------|----------|----------------|-------------|

| **HA System Monitor** | Docker VM only (CPU, RAM, disk, network) | 0 | 0 | Low (built-in) |
| **Proxmox VE HACS** | Proxmox host + all VMs (CPU, RAM, disk, uptime, status) | 0 | 0 | Low (API token + HACS) |
| **Glances** | Any host (CPU, RAM, disk, network, temps, per-process) | ~70MB each | 1 per host | Medium |
| **Netdata** | Deep metrics, auto-dashboards | 150-300MB each | 1 per host | Medium |
| **Prometheus + Grafana** | Everything, custom dashboards | 500MB+ | 3+ | High |
| **MQTT scripts** | Custom metrics (temps, SMART) | ~0 | 0 | Medium (scripting) |

---

## Recommended Tiered Approach

### Tier 1 — Immediate (zero new containers)

#### 1a. HA System Monitor (built-in)

- **What**: CPU usage, memory usage, disk usage, network throughput, last boot, process counts
- **Scope**: Docker VM only (where HA runs)
- **Setup**: Settings → Integrations → Add → System Monitor
- **Entities created**: `sensor.processor_use`, `sensor.memory_use_percent`, `sensor.disk_use_percent_*`, etc.
- **No install needed** — built into HA core

#### 1b. Proxmox VE (HACS integration)

- **What**: Proxmox host metrics + per-VM status (CPU, RAM, disk, uptime, running/stopped)
- **Scope**: MiniPC (oga) host, OPNsense VM, Docker VM
- **Setup**:
  1. Create API token in Proxmox web UI (Datacenter → Permissions → API Tokens)
  2. Install via HACS → Integrations → Search "Proxmox VE"
  3. Configure: Proxmox IP (`100.78.12.241`), port `8006`, API token
- **Entities created**: `sensor.oga_cpu_used`, `sensor.oga_memory_used`, `binary_sensor.docker_running`, etc.
- **Zero agents** — polls Proxmox API directly from HA

### Tier 2 — Short-term (lightweight agent on NAS)

#### 2a. Glances on NAS

The NAS isn't a Proxmox VM, so it needs its own monitoring agent. Glances is lightweight (~70MB RAM) and HA has a built-in integration.

```yaml
# Add to NAS compose (docker/fixed/nas/)
glances:
  image: nicolargo/glances:latest-full
  container_name: glances
  restart: unless-stopped
  pid: host
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  environment:
    - GLANCES_OPT=-w
  ports:
    - "61208:61208"
```

- HA integration: Settings → Integrations → Add → Glances → host `100.82.77.97`, port `61208`
- Entities: CPU, RAM, disk (per mount), network I/O, temperatures, container stats

#### 2b. Glances on Docker VM (optional)

System Monitor covers most Docker VM metrics, but Glances adds per-container stats and temperatures. Only add if System Monitor isn't enough.

### Tier 3 — Optional (specific hardware metrics)

#### 3a. MQTT scripts on Proxmox host

Cron job that publishes hardware-specific data to MQTT:

- CPU package temperature (`sensors` command)
- SMART disk health (`smartctl`)
- GPU/iGPU stats (if passthrough configured)

```bash
# Example cron script (runs every 60s)
#!/bin/bash
TEMP=$(sensors -u | grep temp1_input | head -1 | awk '{print $2}')
mosquitto_pub -h 100.68.63.168 -t "homelab/proxmox/cpu_temp" -m "$TEMP" \
  -u mqtt_user -P mqtt_pass
```

HA picks these up via MQTT sensor config. Useful for temperatures that Proxmox API doesn't expose.

---

## Implementation Order

| Phase | Action | Can Do Remotely? | Status |
|-------|--------|-----------------|--------|

| **Now** | System Monitor integration (browser) | Yes | Done |
| **Now** | Proxmox VE HACS integration (browser + Proxmox web UI) | Yes | Done |
| **Later** | Glances on NAS (SSH + compose) | Yes | Done |
| **Optional** | MQTT scripts on Proxmox (SSH) | Yes | Pending |
| **Optional** | Glances on Docker VM | Yes | Pending |

---

## Dashboard Integration

Once sensors are available, add to the Home Overview Dashboard:

| Card | Data Source | Section |
|------|-----------|---------|

| Gauge cards | System Monitor (CPU, RAM, disk %) | Infrastructure Status |
| Entity cards | Proxmox VE (VM status, uptime) | Infrastructure Status |
| Mini-graph-card | Glances (NAS disk, network trends) | Infrastructure Status |
| Conditional card | Any sensor above threshold | Alerts |

---

## Prerequisites

- [x] HACS installed on Home Assistant
- [x] System Monitor integration added
- [x] Proxmox API token created (Proxmox web UI)
- [x] Proxmox VE HACS integration installed and configured
- [x] Glances container deployed on NAS
- [x] Glances HA integration configured

**Status (2026-03-10):** All tiers (1-2) complete. Tier 3 (MQTT scripts) remains optional. VictoriaMetrics + Grafana (Papa) also deployed separately for historical metrics.
