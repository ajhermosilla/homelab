# Storage Stack

Samba + Syncthing for network file shares and P2P sync.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Samba | 139, 445 | SMB/CIFS file shares |
| Syncthing | 8384 | P2P file sync |

## Quick Start

```bash
# 1. Mount drives and create directories
sudo mkdir -p /mnt/{purple,red8}
sudo mount /dev/sdb1 /mnt/purple
sudo mount /dev/sdc1 /mnt/red8

# 2. Create symlinks
sudo ln -s /mnt/red8/media /srv/media
sudo ln -s /mnt/red8/downloads /srv/downloads
sudo ln -s /mnt/red8/data /srv/data
sudo ln -s /mnt/red8/sync /srv/sync

# 3. Set ownership
sudo chown -R 1000:1000 /mnt/red8 /mnt/purple

# 4. Configure environment
cp .env.example .env
# Set SAMBA_PASSWORD

# 5. Start services
docker compose up -d
```

## Samba Shares

| Share | Path | Use Case |
|-------|------|----------|
| media | /srv/media | Movies, TV, Music (Jellyfin) |
| downloads | /srv/downloads | Active downloads (*arr) |
| data | /srv/data | Documents, photos, archives |
| backup | /srv/backup | Backup target |

### Connect from macOS

```
Finder → Go → Connect to Server
smb://192.168.1.12/media

# Or via Tailscale
smb://nas.tail/media
```

## Syncthing

Web UI: http://192.168.1.12:8384

### Suggested Folders

| Folder | Path | Sync With |
|--------|------|-----------|
| documents | /sync/docs | MacBook, Phone |
| photos | /sync/photos | Phone |
| configs | /sync/configs | MacBook |

## NFS Exports

For Docker VM access, add to `/etc/exports`:

```
/srv/frigate 192.168.1.10(rw,sync,no_subtree_check,no_root_squash)
/srv/media 192.168.1.10(ro,sync,no_subtree_check)
/srv/downloads 192.168.1.10(rw,sync,no_subtree_check)
```

Apply: `sudo exportfs -ra`
