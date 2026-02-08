# Media Stack

Jellyfin + *arr suite + qBittorrent for self-hosted media streaming.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Jellyfin | 8096 | Media streaming |
| Sonarr | 8989 | TV show management |
| Radarr | 7878 | Movie management |
| Prowlarr | 9696 | Indexer management |
| qBittorrent | 8080 | Torrent client |

## Integration Flow

```
Prowlarr → Sonarr/Radarr → qBittorrent → Jellyfin
   │              │              │            │
   └─ indexers    └─ requests    └─ downloads └─ streams
```

## Quick Start

```bash
# 1. Mount NFS shares from NAS
sudo mkdir -p /mnt/nas/{media,downloads}
sudo mount -t nfs 192.168.0.12:/srv/media /mnt/nas/media
sudo mount -t nfs 192.168.0.12:/srv/downloads /mnt/nas/downloads

# 2. Configure environment
cp .env.example .env
# Edit .env with paths

# 3. Start services
docker compose up -d
```

## Configuration Order

1. **Prowlarr** (9696) - Add indexers first
2. **Sonarr/Radarr** - Connect to Prowlarr (Settings → Apps)
3. **qBittorrent** (8080) - Change default password
4. **Sonarr/Radarr** - Add qBittorrent as download client
5. **Jellyfin** (8096) - Add media libraries

## Hardware Transcoding

Intel N150 QuickSync enabled via `/dev/dri` passthrough.

```bash
# Verify in container
docker exec jellyfin ls -la /dev/dri
```

Enable in Jellyfin: Dashboard → Playback → Transcoding → Intel QuickSync (QSV)

## Paths

| Path | Purpose |
|------|---------|
| `/mnt/nas/media` | Movies, TV shows, music |
| `/mnt/nas/downloads` | Active downloads |

## Dependencies

- NFS mount to NAS must be ready before starting
- Prowlarr starts first (Sonarr/Radarr depend on it)
