# Home Assistant — Home Overview Dashboard Plan

**Date:** 2026-02-24
**Context:** Home Assistant on Docker VM (`jara.cronova.dev`), Frigate NVR with 3 cameras, MQTT via Mosquitto. Dashboard grows as devices are added.

---

## Dashboard Sections

### 1. Infrastructure Status

- Docker VM, NAS, Proxmox — online/offline indicators (ping or HA `binary_sensor`)
- Frigate — detector speed, CPU usage, camera statuses (from Frigate integration entities)
- MQTT — connected/disconnected state
- Uptime Kuma — link to `status.cronova.dev/dashboard` or embed status via API

### 2. Camera Summary

- Last person detection per camera (timestamp + snapshot thumbnail)
- Detection counts today (person, car, dog, cat)
- Quick links to live feeds (Frigate camera entities)
- Zone activity: driveway, terraza, street event counts

### 3. Power & Environment

- Server room temperature and humidity (ESP32 + BME280, pending Phase 1 kit)
- Real-time power consumption per device (SONOFF S31 plugs, pending Phase 3 kit)
- HA Energy Dashboard integration for daily/monthly tracking
- Water leak sensor status (ESP32 + water sensor, pending Phase 1 kit)

### 4. Family & Presence

- Who's home / away (HA Companion App — configured 2026-03-08)
- Welcome home / away mode indicators
- Indoor camera recording status (on when away, off when home)

### 5. Media & Entertainment

- LG TV power/volume/source controls (paired 2026-03-09 via webOS integration)
- Apple TV controls (paired 2026-03-08 via apple_tv integration)

---

## Implementation Notes

### Card Types (built-in)

| Card | Use Case |
|------|----------|
| `entities` | Infrastructure status rows |
| `picture-entity` | Camera live feeds |
| `glance` | Detection counts, sensor readings |
| `conditional` | Show alerts only when relevant |
| `history-graph` | Temperature trends, power usage |
| `button` | Quick actions (arm/disarm, TV controls) |

### HACS Cards (recommended)

| Card | Use Case |
|------|----------|
| **mushroom** | Modern, clean entity cards |
| **mini-graph-card** | Sparkline graphs for temp/power trends |
| **auto-entities** | Dynamic card lists (e.g., all sensors above threshold) |
| **frigate-card** | Enhanced camera cards with event timeline |

### System Monitor Integration

Built-in HA integration (no install needed). Add via Settings → Integrations → System Monitor. Provides:

- CPU usage, memory usage, disk usage
- Network throughput (bytes/sec)
- Last boot time
- Process counts

Useful for monitoring the Docker VM itself.

---

## Phased Build

| Phase | Requires | Sections Available | Status |
|-------|----------|--------------------|--------|
| **Now** | Nothing extra | Infrastructure status, camera summary, Frigate stats | Ready |
| **After Companion App** | Phone setup | Family presence, away mode | Ready (Companion App configured) |
| **After Phase 1 kit** | ESP32 + BME280 | Server room temperature, water leak | Pending hardware |
| **After Phase 3 kit** | SONOFF S31 | Power monitoring, energy dashboard | Pending hardware |
| **After TV pairing** | Physical access | Media controls | Ready (LG TV + Apple TV paired) |

---

## Prerequisites

- [ ] Install HACS frontend cards (mushroom, mini-graph-card, auto-entities)
- [x] Add System Monitor integration via browser
- [x] Set up Companion App on phones (presence tracking)
- [ ] Deploy ESP32 sensors (Phase 1 kit from AliExpress)
- [ ] Flash and deploy SONOFF S31 plugs (Phase 3 kit)
- [x] Pair LG TV and Apple TV integrations (at home)
