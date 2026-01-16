# NFS Setup Guide

NFS configuration for Frigate recordings (Docker VM → NAS).

## Overview

```
┌─────────────────┐         NFS          ┌─────────────────┐
│   Docker VM     │ ◄──────────────────► │      NAS        │
│  (192.168.1.10) │                      │  (192.168.1.12) │
│                 │                      │                 │
│  /mnt/nas/      │                      │  /srv/frigate   │
│  └── frigate/   │                      │  (Purple 2TB)   │
│                 │                      │                 │
│  [Frigate NVR]  │                      │  [NFS Server]   │
└─────────────────┘                      └─────────────────┘
```

**Purpose:** Frigate runs on Docker VM (Intel N150 QuickSync) but stores recordings on NAS (WD Purple 2TB dedicated to surveillance).

---

## NAS Configuration (Server)

### 1. Install NFS Server

```bash
sudo apt update
sudo apt install nfs-kernel-server
```

### 2. Create Export Directory

```bash
# Create directory on Purple 2TB (already mounted at /mnt/purple)
sudo mkdir -p /srv/frigate

# Create symlink from mount point
sudo ln -s /mnt/purple/frigate /srv/frigate

# Set ownership (match Docker VM user)
sudo chown -R 1000:1000 /srv/frigate
sudo chmod 755 /srv/frigate
```

### 3. Configure Exports

```bash
sudo nano /etc/exports
```

Add the following line:

```
/srv/frigate    192.168.1.10(rw,sync,no_subtree_check,no_root_squash)
```

**Options explained:**
- `rw` - Read/write access
- `sync` - Write changes to disk before replying (safer)
- `no_subtree_check` - Disable subtree checking (better performance)
- `no_root_squash` - Allow root access from client (needed for Docker)

### 4. Apply Configuration

```bash
# Export the shares
sudo exportfs -ra

# Verify exports
sudo exportfs -v

# Expected output:
# /srv/frigate  192.168.1.10(rw,wdelay,no_root_squash,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
```

### 5. Start NFS Service

```bash
sudo systemctl enable nfs-kernel-server
sudo systemctl start nfs-kernel-server
sudo systemctl status nfs-kernel-server
```

### 6. Firewall (if enabled)

```bash
# Allow NFS from Docker VM
sudo ufw allow from 192.168.1.10 to any port nfs
sudo ufw allow from 192.168.1.10 to any port 111  # portmapper
```

---

## Docker VM Configuration (Client)

### 1. Install NFS Client

```bash
sudo apt update
sudo apt install nfs-common
```

### 2. Create Mount Point

```bash
sudo mkdir -p /mnt/nas/frigate
```

### 3. Test Mount

```bash
# Manual mount to test
sudo mount -t nfs 192.168.1.12:/srv/frigate /mnt/nas/frigate

# Verify mount
df -h /mnt/nas/frigate
ls -la /mnt/nas/frigate

# Test write access
touch /mnt/nas/frigate/test.txt
rm /mnt/nas/frigate/test.txt
```

### 4. Configure Persistent Mount

```bash
sudo nano /etc/fstab
```

Add the following line:

```
192.168.1.12:/srv/frigate  /mnt/nas/frigate  nfs  defaults,_netdev,nofail  0  0
```

**Options explained:**
- `defaults` - Standard mount options
- `_netdev` - Wait for network before mounting
- `nofail` - Don't fail boot if mount fails

### 5. Apply and Verify

```bash
# Unmount if already mounted
sudo umount /mnt/nas/frigate

# Mount using fstab
sudo mount -a

# Verify
mount | grep frigate
df -h /mnt/nas/frigate
```

---

## Frigate Configuration

### Docker Compose

In `docker/fixed/docker-vm/security/docker-compose.yml`:

```yaml
services:
  frigate:
    volumes:
      - ${FRIGATE_RECORDINGS:-/mnt/nas/frigate}:/media/frigate
```

### Environment

In `.env`:

```bash
FRIGATE_RECORDINGS=/mnt/nas/frigate
```

### Frigate Config

In `frigate.yml`:

```yaml
record:
  enabled: true
  retain:
    days: 7
    mode: motion
```

Recordings will be stored at `/media/frigate` inside the container, which maps to `/mnt/nas/frigate` on the host, which is the NFS mount to NAS.

---

## Troubleshooting

### Mount Fails on Boot

```bash
# Check if NFS services are running
systemctl status nfs-common

# Check network connectivity
ping 192.168.1.12

# Try manual mount with verbose output
sudo mount -v -t nfs 192.168.1.12:/srv/frigate /mnt/nas/frigate
```

### Permission Denied

```bash
# On NAS: Check ownership
ls -la /srv/frigate

# Should be owned by UID 1000
sudo chown -R 1000:1000 /srv/frigate

# On NAS: Check exports
sudo exportfs -v

# Ensure no_root_squash is set
```

### Stale File Handle

```bash
# Unmount and remount
sudo umount -f /mnt/nas/frigate
sudo mount -a

# Or lazy unmount if busy
sudo umount -l /mnt/nas/frigate
sudo mount -a
```

### NFS Performance

```bash
# Check NFS statistics
nfsstat -c

# Monitor NFS traffic
sudo tcpdump -i eth0 port 2049
```

---

## Verification Checklist

### NAS (Server)
- [ ] NFS server installed and running
- [ ] `/srv/frigate` directory exists
- [ ] Ownership set to 1000:1000
- [ ] Export configured in `/etc/exports`
- [ ] `exportfs -v` shows the share

### Docker VM (Client)
- [ ] NFS client installed
- [ ] `/mnt/nas/frigate` mount point exists
- [ ] Manual mount works
- [ ] fstab entry added
- [ ] `mount -a` succeeds
- [ ] Write test passes

### Frigate
- [ ] `FRIGATE_RECORDINGS` set in `.env`
- [ ] Container starts without errors
- [ ] Recordings appear in `/mnt/nas/frigate`

---

## Alternative: Via Tailscale

If accessing via Tailscale mesh instead of local network:

```bash
# /etc/exports on NAS
/srv/frigate    100.64.0.10(rw,sync,no_subtree_check,no_root_squash)

# /etc/fstab on Docker VM
100.64.0.12:/srv/frigate  /mnt/nas/frigate  nfs  defaults,_netdev,nofail  0  0
```

This allows Frigate to access NAS recordings even when not on local network.

---

## Related Documentation

- `docs/hardware.md` - NAS drive layout (Purple 2TB for Frigate)
- `docs/fixed-homelab.md` - Docker VM and NAS setup
- `docker/fixed/docker-vm/security/docker-compose.yml` - Frigate config
