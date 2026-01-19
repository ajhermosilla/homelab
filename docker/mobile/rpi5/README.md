# Mobile Kit - RPi 5

Docker services for the mobile homelab kit running on Raspberry Pi 5.

**Note:** Headscale has been migrated to VPS for 24/7 availability. See `docker/vps/networking/headscale/`. RPi 5 now runs Pi-hole only and operates on-demand (7AM-7PM or travel).

## Services

| Service | Port(s) | Purpose |
|---------|---------|---------|
| Pi-hole | 53, 8080 | DNS ad-blocking |

## Quick Start

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit environment variables
nano .env

# 3. Start Pi-hole
cd networking/pihole
docker compose up -d

# 4. Set Pi-hole web password
docker exec -it pihole pihole -a -p
```

## Network Configuration

### Beryl AX Router

1. Set static IP for RPi 5: `192.168.8.5`
2. Configure DHCP to use RPi 5 as DNS server (192.168.8.5)
3. Ensure port 53 (DNS) is not blocked

### Joining Tailscale Mesh

Connect RPi 5 to Headscale (running on VPS):

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Join mesh
tailscale up --login-server=https://hs.cronova.dev --hostname=rpi5 --accept-routes --accept-dns=false
```

Then register on VPS:
```bash
ssh vps 'sudo docker exec headscale headscale nodes register --key <KEY> --user augusto'
```

## Directory Structure

```
rpi5/
├── .env.example          # Environment template
├── .env                  # Your environment (gitignored)
├── README.md
└── networking/
    ├── headscale/        # DEPRECATED - now on VPS
    │   └── docker-compose.yml
    └── pihole/
        └── docker-compose.yml
```

## Backup

Critical data to backup:
- Pi-hole: Export via Teleporter (Settings > Teleporter > Export)

Headscale backups are now handled by VPS. See `docker/vps/networking/headscale/backup.sh`.

See [Disaster Recovery](../../../docs/disaster-recovery.md) for full procedures.

## Useful Commands

```bash
# Pi-hole
docker exec -it pihole pihole -t      # Live query log
docker exec -it pihole pihole status  # Status
docker exec -it pihole pihole -g      # Update blocklists
docker logs -f pihole                 # Container logs

# Tailscale (on RPi 5)
tailscale status                      # Mesh status
tailscale ping <hostname>             # Test connectivity
```

## References

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Tailscale Client Setup](https://tailscale.com/kb/1017/install/)
- [Headscale on VPS](../../../docker/vps/networking/headscale/)
