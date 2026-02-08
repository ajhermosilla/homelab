# Setup Runbook

Step-by-step guide for deploying the homelab from scratch.

## Prerequisites

### Hardware Ready

- [ ] Mini PC with dual NIC
- [ ] Raspberry Pi 4 with 1TB SSD
- [ ] NAS with drives installed
- [ ] MokerLink switch
- [ ] TP-Link PoE switch
- [ ] TP-Link AP
- [ ] Cameras (3x)
- [ ] UPS plugged in and charged
- [ ] All Ethernet cables

### Software Ready

- [ ] Proxmox VE ISO on USB
- [ ] Debian 12 ISO on USB
- [ ] Start9 ISO on USB/SD
- [ ] OPNsense ISO downloaded
- [ ] This repo cloned locally

### Accounts Ready

- [ ] Vultr VPS provisioned
- [ ] Domain (cronova.dev) accessible
- [ ] Cloudflare account configured
- [ ] Google account for backup

---

## Phase 1: VPS Setup (Day 1)

Deploy VPS first to enable mesh network for all other devices.

### 1.1 Provision VPS

```bash
# SSH into new VPS
ssh root@<vps-ip>

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install docker-compose
apt install docker-compose-plugin -y

# Install useful tools
apt install vim git htop -y
```

### 1.2 Clone Repo

```bash
cd /opt
git clone https://github.com/ajhermosilla/homelab.git
cd homelab
```

### 1.3 Deploy Headscale

```bash
cd /opt/homelab/docker/vps/networking/headscale

# Create .env from example
cp .env.example .env
vim .env  # Edit values

# Create config from example
cp config/config.yaml.example config/config.yaml
vim config/config.yaml  # Edit domain, etc.

# Start Headscale
docker compose up -d

# Verify
docker compose logs -f
```

### 1.4 Configure DNS

In Cloudflare, add A record:
- `hs.cronova.dev` → `<vps-ip>`

### 1.5 Deploy VPS Caddy

```bash
cd /opt/homelab/docker/vps/networking/caddy
cp .env.example .env
docker compose up -d
```

### 1.6 Create First Auth Key

```bash
# Create user
docker exec headscale headscale users create augusto

# Generate auth key (reusable, no expiry for initial setup)
docker exec headscale headscale preauthkeys create --user augusto --reusable --expiration 24h

# Save this key for connecting devices!
```

### 1.7 Deploy Remaining VPS Services

```bash
# Pi-hole
cd /opt/homelab/docker/vps/networking/pihole
cp .env.example .env
docker compose up -d

# DERP Relay
cd /opt/homelab/docker/vps/networking/derp
cp .env.example .env
docker compose up -d

# Monitoring (Uptime Kuma + ntfy)
cd /opt/homelab/docker/vps/monitoring
cp .env.example .env
docker compose up -d

# Backup
cd /opt/homelab/docker/vps/backup
cp .env.example .env
# Create htpasswd
htpasswd -B -c htpasswd augusto
docker compose up -d
```

### 1.8 Verify VPS

- [ ] Headscale accessible at https://hs.cronova.dev
- [ ] Pi-hole admin at http://<vps-ip>:8053
- [ ] Uptime Kuma at http://<vps-ip>:3001

---

## Phase 2: Network Setup (Day 1-2)

### 2.1 Physical Setup

1. Connect ISP modem to Mini PC NIC1 (WAN)
2. Connect Mini PC NIC2 to MokerLink Port 1
3. Connect PoE switch to MokerLink Port 6
4. Connect AP to MokerLink Port 7
5. Connect NAS to MokerLink Port 4
6. Connect RPi 4 to MokerLink Port 3
7. Power on all devices

### 2.2 Install Proxmox VE

See `docs/proxmox-setup.md` for detailed steps.

1. Boot Mini PC from Proxmox USB
2. Complete installation wizard
3. Access web UI at https://192.168.0.100:8006
4. Enable IOMMU for NIC passthrough
5. Configure network bridge (vmbr0)

### 2.3 Create OPNsense VM

See `docs/opnsense-setup.md` for detailed steps.

1. Upload OPNsense ISO to Proxmox
2. Create VM with WAN NIC passthrough
3. Install OPNsense
4. Configure WAN (DHCP from ISP)
5. Configure LAN (192.168.0.1/24)
6. Enable DHCP server

### 2.4 Configure VLANs

See `docs/vlan-design.md` for detailed steps.

1. Create VLANs in OPNsense (10, 20)
2. Configure VLAN interfaces
3. Set up firewall rules
4. Configure MokerLink switch ports

### 2.5 Join OPNsense to Tailscale

```bash
# In OPNsense shell
pkg install tailscale
tailscale up --login-server=https://hs.cronova.dev --authkey=<key>
```

---

## Phase 3: Docker VM (Day 2)

### 3.1 Create Docker VM

See `docs/proxmox-setup.md` for VM creation.

1. Create VM (8GB RAM, 100GB disk)
2. Install Debian 12
3. Configure static IP or DHCP reservation
4. Install Docker

### 3.2 Join Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --login-server=https://hs.cronova.dev --authkey=<key>
```

### 3.3 Clone Repo

```bash
cd /opt
git clone https://github.com/ajhermosilla/homelab.git
cd homelab
```

### 3.4 Deploy Core Services

```bash
# Pi-hole (deploy first for DNS)
cd /opt/homelab/docker/fixed/docker-vm/networking/pihole
cp .env.example .env
docker compose up -d

# Update DHCP to use Pi-hole as DNS (192.168.0.10)

# Caddy
cd /opt/homelab/docker/fixed/docker-vm/networking/caddy
cp .env.example .env
docker compose up -d
```

### 3.5 Deploy Automation

```bash
# Mosquitto + Home Assistant
cd /opt/homelab/docker/fixed/docker-vm/automation
cp .env.example .env
docker compose up -d
```

### 3.6 Deploy Security

```bash
# Vaultwarden + Frigate
cd /opt/homelab/docker/fixed/docker-vm/security
cp .env.example .env

# Frigate config
cp frigate.yml.example frigate.yml
vim frigate.yml  # Configure cameras

docker compose up -d
```

### 3.7 Deploy Media

```bash
cd /opt/homelab/docker/fixed/docker-vm/media
cp .env.example .env
docker compose up -d
```

---

## Phase 4: NAS Setup (Day 2-3)

### 4.1 Install Debian

1. Boot NAS from Debian USB
2. Minimal install (SSH server only)
3. Configure network (static IP or DHCP reservation)

### 4.2 Mount Drives

```bash
# Identify drives
lsblk
sudo blkid

# Create mount points
sudo mkdir -p /mnt/{purple,data,external}

# Format if needed (CAUTION: destroys data)
# sudo mkfs.ext4 /dev/sdX

# Add to fstab
sudo vim /etc/fstab
# UUID=xxx /mnt/purple ext4 defaults,noatime 0 2
# UUID=xxx /mnt/data   ext4 defaults,noatime 0 2

# Mount
sudo mount -a

# Create directories
sudo mkdir -p /mnt/data/{media,backups,family,photos}
sudo mkdir -p /mnt/purple/frigate
sudo chown -R $USER:$USER /mnt/{purple,data}
```

### 4.3 Join Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --login-server=https://hs.cronova.dev --authkey=<key>
```

### 4.4 Configure NFS

See `docs/nfs-setup.md` for detailed steps.

```bash
# Install NFS server
sudo apt install nfs-kernel-server

# Export Frigate directory
sudo vim /etc/exports
# /mnt/purple/frigate 192.168.0.0/24(rw,sync,no_subtree_check,no_root_squash)

sudo exportfs -ra
```

### 4.5 Deploy NAS Services

```bash
cd /opt
git clone https://github.com/ajhermosilla/homelab.git
cd homelab

# Storage (Samba + Syncthing)
cd docker/fixed/nas/storage
cp .env.example .env
docker compose up -d

# Backup (Restic REST)
cd ../backup
cp .env.example .env
htpasswd -B -c htpasswd augusto
docker compose up -d
```

### 4.6 Mount NFS on Docker VM

```bash
# On Docker VM
sudo apt install nfs-common
sudo mkdir -p /mnt/frigate
sudo mount -t nfs 192.168.0.12:/mnt/purple/frigate /mnt/frigate

# Add to fstab
echo "192.168.0.12:/mnt/purple/frigate /mnt/frigate nfs defaults 0 0" | sudo tee -a /etc/fstab
```

---

## Phase 5: Start9 Setup (Day 3)

### 5.1 Flash Start9

1. Download Start9 image
2. Flash to SD card or SSD
3. Boot RPi 4

### 5.2 Initial Setup

1. Access Start9 web interface
2. Create admin account
3. Configure network

### 5.3 Install Services

1. Bitcoin Core (will take days to sync)
2. LND
3. Electrum Server (after Bitcoin syncs)

### 5.4 Join Tailscale

Install Tailscale via Start9 marketplace or manually.

---

## Phase 6: Camera Setup (Day 3)

### 6.1 Physical Installation

1. Mount cameras
2. Connect PoE cameras to PoE switch
3. Power on

### 6.2 Configure Cameras

1. Access camera web UI (find IP via DHCP leases)
2. Set static IP in IoT range (192.168.10.101-103)
3. Configure RTSP streams
4. Set passwords

### 6.3 Add to Frigate

Edit `frigate.yml` with camera details:
```yaml
cameras:
  front_door:
    ffmpeg:
      inputs:
        - path: rtsp://{CAM_USER}:{CAM_PASS}@192.168.10.101:554/stream
```

Restart Frigate:
```bash
docker compose restart frigate
```

### 6.4 Verify Recordings

1. Access Frigate at http://192.168.0.10:5000
2. Verify cameras show video
3. Check recordings in /mnt/frigate

---

## Phase 7: Finalization (Day 3-4)

### 7.1 Configure Backups

```bash
# On Docker VM - install restic
apt install restic

# Initialize repository
export RESTIC_REPOSITORY="rest:http://$RESTIC_USER:$RESTIC_HTPASSWD@192.168.0.12:8000/homelab"
# Set your restic encryption password
export RESTIC_PASSWORD_FILE=/root/.restic-password
restic init

# Test backup
restic backup /var/lib/headscale --tag headscale
```

### 7.2 Set Up Cron Jobs

```bash
# Edit crontab
crontab -e

# Hourly Headscale backup
0 * * * * /opt/homelab/scripts/backup-headscale.sh

# Daily Vaultwarden backup
0 3 * * * /opt/homelab/scripts/backup-vaultwarden.sh

# Monthly backup verification
0 3 1-7 * 0 /opt/homelab/scripts/backup-verify.sh
```

### 7.3 Configure Monitoring

1. Access Uptime Kuma
2. Add monitors (see `docker/vps/monitoring/monitors.md`)
3. Configure ntfy notifications
4. Test alerts

### 7.4 Configure UPS

See `docs/nut-config.md` for NUT setup.

### 7.5 Final Verification

- [ ] All services accessible via Tailscale
- [ ] DNS resolution working (Pi-hole)
- [ ] Media streaming works (Jellyfin)
- [ ] Password manager accessible (Vaultwarden)
- [ ] Cameras recording (Frigate)
- [ ] Backups running
- [ ] Monitoring active
- [ ] UPS graceful shutdown configured

---

## Post-Setup Tasks

### Week 1

- [ ] Wait for Bitcoin sync to complete
- [ ] Configure Home Assistant automations
- [ ] Set up Syncthing folders
- [ ] Import passwords to Vaultwarden
- [ ] Configure media libraries in Jellyfin

### Week 2

- [ ] Run first backup verification
- [ ] Test restore procedures
- [ ] Configure offsite backup (rclone to Google Drive)
- [ ] Document any customizations

### Month 1

- [ ] Review monitoring alerts
- [ ] Optimize Frigate detection zones
- [ ] Review firewall rules
- [ ] Update all containers
- [ ] First monthly backup drill

---

## Troubleshooting

### Can't reach Tailscale devices

```bash
# Check Tailscale status
tailscale status

# Re-authenticate
tailscale up --login-server=https://hs.cronova.dev --authkey=<key> --force-reauth
```

### Docker containers won't start

```bash
# Check logs
docker compose logs -f <service>

# Check disk space
df -h

# Check Docker status
systemctl status docker
```

### NFS mount fails

```bash
# Check NFS server
showmount -e 192.168.0.12

# Check firewall
sudo ufw status

# Test mount manually
sudo mount -v -t nfs 192.168.0.12:/mnt/purple/frigate /mnt/frigate
```

---

## References

- [proxmox-setup.md](proxmox-setup.md)
- [opnsense-setup.md](opnsense-setup.md)
- [vlan-design.md](vlan-design.md)
- [nfs-setup.md](nfs-setup.md)
- [nut-config.md](nut-config.md)
- [backup-test-procedure.md](backup-test-procedure.md)
- [services.md](services.md)
- [hardware.md](hardware.md)
