# Maintenance Stack

Automated container updates with Watchtower.

## Services

| Service | Purpose |
|---------|---------|
| Watchtower | Automatic container updates |

## Quick Start

```bash
docker compose up -d
```

## Update Schedule

Default: **4 AM every Sunday** (low-traffic time)

## Opt-in Updates

Watchtower only updates containers with the enable label:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

### Auto-update Enabled

- Media stack (Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent)
- Pi-hole (all instances)
- Caddy (all instances)
- Mosquitto
- Syncthing, Samba
- Restic REST servers
- DERP

### Manual Update Required

- **Vaultwarden** - Password manager, test updates first
- **Headscale** - Mesh coordinator, coordinate with all nodes
- **Frigate** - NVR, may have breaking changes
- **Home Assistant** - Automations, should be manually tested

## Notifications (Optional)

Add to `.env`:

```bash
# ntfy
WATCHTOWER_NOTIFICATIONS=shoutrrr
WATCHTOWER_NOTIFICATION_URL=ntfy://notify.cronova.dev/cronova-updates
```

## Monitor-Only Mode

Check for updates without applying:

```bash
# .env
WATCHTOWER_MONITOR_ONLY=true
```

## Manual Commands

```bash
# Force immediate check
docker exec watchtower /watchtower --run-once

# Update specific container
docker exec watchtower /watchtower --run-once jellyfin

# View logs
docker logs watchtower
```
