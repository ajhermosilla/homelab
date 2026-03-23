# ARR Stack Hardening Plan — 2026-03-24

> **Status**: Research complete, ready to implement. Requires ProtonVPN Plus subscription (~$4.50/mo) before deployment.

## Goal

Harden the *arr media stack with VPN-based torrent privacy, proper folder structure for hardlinks, and companion tools for quality management and monitoring.

## Current State

| Component | Status | Issue |
|-----------|--------|-------|
| Sonarr | Running | Separate /media and /downloads mounts (breaks hardlinks) |
| Radarr | Running | Same hardlink issue |
| Prowlarr | Running | OK |
| qBittorrent | Running | **No VPN — real IP exposed in torrent swarms** |
| Jellyfin | Running | OK, iGPU transcoding working |
| VPN sidecar | Missing | **Critical gap** |
| Subtitles | Missing | No Bazarr |
| Quality profiles | Manual | No Recyclarr |
| Monitoring | Missing | No Scraparr |

## Architecture — Before vs After

### Before (current)

```text
Internet (real IP exposed)
    │
    ▼
qBittorrent (:6881) ← torrents download with REAL IP
    │ media-net
Sonarr ─ Radarr ─ Prowlarr ─ Jellyfin
```

### After (with Gluetun)

```text
Internet
    │
    ▼
┌─────────┐     ┌────────────────┐
│ Gluetun │────▶│ ProtonVPN (WG) │ encrypted tunnel
│  (VPN)  │     └────────────────┘
└────┬────┘
     │ network_mode: service:gluetun
     │ (kill switch: if VPN drops, zero connectivity)
┌────┴──────────┐
│  qBittorrent  │ ← torrents download with VPN IP only
└───────────────┘
     │ media-net
Sonarr ─ Radarr ─ Prowlarr ─ Jellyfin ─ Bazarr ─ Recyclarr ─ Scraparr
```

## VPN Provider: ProtonVPN Plus

| Factor | Detail |
|--------|--------|
| Plan | VPN Plus, 2-year (~$4.49/mo) or promo (~$2.99/mo) |
| Protocol | WireGuard |
| Port forwarding | Yes, NAT-PMP (automatic via Gluetun) |
| Server | Argentina or Brazil (nearest to Paraguay) |
| Kill switch | Network-level via Gluetun iptables |
| Privacy | 4x audited no-logs, Swiss jurisdiction |
| Payment | Bitcoin/cash accepted (no personal info needed) |
| Signup | ProtonMail address only, no real name/ID |

### Getting WireGuard credentials

1. Sign up at <https://account.protonvpn.com/signup>
2. Go to account.proton.me → VPN → WireGuard
3. Platform: Linux / Router
4. VPN options: enable **NAT-PMP (Port Forwarding)**
5. Select P2P server (AR#1 or BR#1)
6. Copy **PrivateKey** (shown only once)
7. Save to KeePassXC under "Homelab > ProtonVPN"

---

## Phase 1 — Gluetun VPN Sidecar (critical)

Add Gluetun to the media stack and route qBittorrent through it.

**Changes to `docker/fixed/docker-vm/media/docker-compose.yml`:**

- Add `gluetun` service with ProtonVPN WireGuard config
- Change qBittorrent to `network_mode: "service:gluetun"`
- Move qBittorrent ports to Gluetun
- Add port forwarding auto-update

**New `.env` variables:**

```bash
WIREGUARD_PRIVATE_KEY=<from ProtonVPN>
VPN_SERVER_COUNTRIES=Argentina
```

---

## Phase 2 — Folder Structure (enables hardlinks)

Restructure to TRaSH Guides standard with single `/data` root.

### NAS path changes

```text
/mnt/red8/data/              # single root (after 8TB recovery)
├── torrents/
│   ├── movies/
│   ├── tv/
│   └── music/
└── media/
    ├── movies/
    ├── tv/
    └── music/
```

### Volume mount changes

All *arr apps mount the same root:

```yaml
sonarr:
  volumes:
    - /mnt/nas/data:/data

radarr:
  volumes:
    - /mnt/nas/data:/data

qbittorrent:
  volumes:
    - /mnt/nas/data/torrents:/data/torrents

jellyfin:
  volumes:
    - /mnt/nas/data/media:/data/media:ro
```

### NFS export changes

Single export instead of separate media/downloads:

```text
/mnt/red8/data  192.168.0.10(rw,sync,no_subtree_check,no_root_squash)
```

**Note:** Phase 2 depends on 8TB recovery (data currently on Purple). Can be done after Phase 1.

---

## Phase 3 — Harden qBittorrent

Settings to change in qBittorrent WebUI after Gluetun is running:

| Setting | Location | Value |
|---------|----------|-------|
| DHT | BitTorrent | **Disable** |
| PEX | BitTorrent | **Disable** |
| Local Peer Discovery | BitTorrent | **Disable** |
| Encryption | BitTorrent | **Require encryption** |
| Anonymous mode | BitTorrent | **Enable** |
| Bypass auth for localhost | Web UI > Auth | Enable (for port forwarding script) |

### Verify no IP leaks

```bash
# Check VPN IP
docker exec gluetun wget -qO- https://ipinfo.io

# Should show ProtonVPN server IP, NOT your real IP
```

---

## Phase 4 — Companion Apps

### Bazarr (subtitles)

```yaml
bazarr:
  image: lscr.io/linuxserver/bazarr:latest
  container_name: bazarr
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/Asuncion
  volumes:
    - bazarr-config:/config
    - /mnt/nas/data/media:/data/media
  ports:
    - "127.0.0.1:6767:6767"
  networks:
    - media-net
```

### Recyclarr (quality profiles)

```yaml
recyclarr:
  image: ghcr.io/recyclarr/recyclarr:latest
  container_name: recyclarr
  environment:
    - TZ=America/Asuncion
  volumes:
    - ./recyclarr.yml:/config/recyclarr.yml:ro
  networks:
    - media-net
```

With config:

```yaml
# recyclarr.yml
sonarr:
  series:
    base_url: http://sonarr:8989
    api_key: !env_var SONARR_API_KEY
    include:
      - template: web-1080p-v4

radarr:
  movies:
    base_url: http://radarr:7878
    api_key: !env_var RADARR_API_KEY
    include:
      - template: remux-web-1080p
```

### Scraparr (monitoring → VictoriaMetrics)

```yaml
scraparr:
  image: ghcr.io/thecfu/scraparr:latest
  container_name: scraparr
  environment:
    - SONARR__URL=http://sonarr:8989
    - SONARR__APIKEY=${SONARR_API_KEY}
    - RADARR__URL=http://radarr:7878
    - RADARR__APIKEY=${RADARR_API_KEY}
    - PROWLARR__URL=http://prowlarr:9696
    - PROWLARR__APIKEY=${PROWLARR_API_KEY}
  ports:
    - "127.0.0.1:7100:7100"
  networks:
    - media-net
```

### Byparr (Cloudflare bypass, if needed)

```yaml
byparr:
  image: ghcr.io/elfhosted/byparr:latest
  container_name: byparr
  ports:
    - "127.0.0.1:8191:8191"
  networks:
    - media-net
```

---

## Deployment Order

| Phase | What | When | Blocker |
|-------|------|------|---------|
| 1 | Gluetun VPN sidecar | After ProtonVPN signup | VPN subscription |
| 2 | Folder restructure | After 8TB recovery | NAS storage |
| 3 | Harden qBittorrent | Same session as Phase 1 | None (WebUI settings) |
| 4 | Companion apps | After Phase 1 works | None |

**Phase 1 + 3 can be done in one session (~30 min).**
**Phase 2 requires 8TB recovery first.**
**Phase 4 is independent, deploy anytime.**

---

## Cost

| Item | Cost |
|------|------|
| ProtonVPN Plus (2-year) | ~$4.49/mo |
| Gluetun, Bazarr, Recyclarr, Scraparr, Byparr | $0 (open source) |
| **Monthly total** | **~$4.50** |

---

## Risks

| Risk | Mitigation |
|------|------------|
| VPN drops, torrents leak IP | Gluetun kill switch (iptables, network-level) |
| Port changes after restart | Auto-update via Gluetun VPN_PORT_FORWARDING_UP_COMMAND |
| Folder restructure breaks libraries | Do after 8TB recovery, re-scan Sonarr/Radarr |
| ProtonVPN account suspension | Pay with Bitcoin, no personal info |
| Gluetun container dies | Docker restart policy + healthcheck |

---

## References

- [TRaSH Guides - Docker Folder Structure](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/Docker/)
- [TRaSH Guides - Home](https://trash-guides.info/)
- [Gluetun Wiki - ProtonVPN](https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/protonvpn.md)
- [Gluetun GitHub](https://github.com/qdm12/gluetun)
- [ProtonVPN Port Forwarding](https://protonvpn.com/support/port-forwarding)
- [Recyclarr - TRaSH Guides](https://trash-guides.info/Recyclarr/)
- [Scraparr GitHub](https://github.com/thecfu/scraparr)
- [Byparr - FlareSolverr Replacement](https://store.elfhosted.com/blog/2025/04/16/byparr-bypasses-flaresolverr/)
