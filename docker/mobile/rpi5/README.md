# Mobile Kit - RPi 5

Docker services for the mobile homelab kit running on Raspberry Pi 5.

## Services

| Service | Port(s) | Purpose |
|---------|---------|---------|
| Headscale | 443, 3478/udp | Tailscale coordination server |
| Pi-hole | 53, 8080 | DNS ad-blocking |

## Quick Start

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit environment variables
nano .env

# 3. Start Pi-hole first (DNS)
cd networking/pihole
docker compose up -d

# 4. Configure Headscale
cd ../headscale
cp config/config.yaml.example config/config.yaml
nano config/config.yaml

# 5. Start Headscale
docker compose up -d

# 6. Create user and auth key
docker exec headscale headscale users create augusto
docker exec headscale headscale preauthkeys create --user augusto --reusable --expiration 24h
```

## Network Configuration

### Beryl AX Router

1. Set static IP for RPi 5: `192.168.8.10`
2. Configure DHCP to use RPi 5 as DNS server
3. Ensure ports 443 and 3478 are not blocked

### Tailscale Clients

Connect devices to your Headscale server:

```bash
tailscale up --login-server=https://hs.cronova.dev --authkey=<your-key>
```

## Directory Structure

```
rpi5/
├── .env.example          # Environment template
├── .env                  # Your environment (gitignored)
├── README.md
└── networking/
    ├── headscale/
    │   ├── docker-compose.yml
    │   └── config/
    │       ├── config.yaml.example
    │       └── config.yaml  # Your config (gitignored)
    └── pihole/
        └── docker-compose.yml
```

## Backup

Critical data to backup hourly:
- Headscale: `/var/lib/headscale/db.sqlite`, `/etc/headscale/config.yaml`
- Pi-hole: Export via Teleporter or backup volumes

See [Disaster Recovery](../../../docs/disaster-recovery.md) for full procedures.

## Useful Commands

```bash
# Headscale
docker exec headscale headscale nodes list
docker exec headscale headscale users list
docker logs -f headscale

# Pi-hole
docker exec -it pihole pihole -t      # Live query log
docker exec -it pihole pihole status  # Status
docker exec -it pihole pihole -g      # Update blocklists
```

## References

- [Headscale Documentation](https://headscale.net/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Tailscale Client Setup](https://tailscale.com/kb/1017/install/)
