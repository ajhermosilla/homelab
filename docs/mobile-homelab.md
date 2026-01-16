# Mobile Homelab Architecture

Portable infrastructure for dev, self-hosting, and travel.

**Key principle:** Mobile kit operates on-demand (7AM-7PM or travel). Headscale runs on VPS for 24/7 mesh availability. Mobile kit can be off without breaking the mesh.

## Operating Model

| Mode | Schedule | Notes |
|------|----------|-------|
| On-demand | 7AM-7PM | Daily use |
| Travel | As needed | Full kit portable |
| Off | Night/hot days | Saves energy, reduces heat |

**Why on-demand?**
- Paraguay heat: reduce active equipment
- Energy savings: RPi 5 + Beryl AX off when not needed
- Fire safety: fewer devices running 24/7
- Mesh still works: Headscale on VPS handles coordination

## Hardware

| Device | Role | Power |
|--------|------|-------|
| Raspberry Pi 5 (8GB) | Pi-hole DNS (mobile) | USB-C PSU |
| MacBook Air M1 | Workstation, Docker dev, soft-serve | Battery |
| Beryl AX (GL-MT3000) | Network gateway, DHCP | USB-C |
| Samsung A13 | Internet via USB tethering | Battery |

## Network Topology

```
            [Internet]
                 |
          [Samsung A13]
           USB Tether
                 |
         [Beryl AX Router]
          192.168.8.1
           /         \
          /           \
   [MacBook Air]    [RPi 5]
   192.168.8.10    192.168.8.5
         \           /
          \         /
        [Tailscale Mesh]
          100.x.x.x
              |
         [VPS - Headscale]
          100.64.0.100
```

## Services

### Raspberry Pi 5 (On-Demand)

| Service | Port | Purpose |
|---------|------|---------|
| Pi-hole | 53, 80 | DNS ad-blocking (mobile) |
| Tailscale | - | Mesh client |

*Headscale moved to VPS for 24/7 availability.*

### MacBook Air M1 (Workstation)

| Service | Port | Purpose |
|---------|------|---------|
| soft-serve | 23231-23233 | Git server |
| Docker workloads | Various | Dev containers |

## IP Addressing

### Local Network (Beryl AX)

| Device | IP | MAC Reservation |
|--------|----|----|
| Beryl AX | 192.168.8.1 | - |
| RPi 5 | 192.168.8.5 | Yes |
| MacBook Air | 192.168.8.10 | Yes |

### Tailscale Network

| Device | Tailscale IP | Hostname |
|--------|--------------|----------|
| VPS | 100.64.0.100 | vps |
| RPi 5 | 100.64.0.1 | rpi5 |
| MacBook Air | 100.64.0.2 | macbook |
| Mini PC (home) | 100.64.0.10 | minipc |
| RPi 4 (home) | 100.64.0.11 | rpi4 |
| NAS (home) | 100.64.0.12 | nas |

*Headscale on VPS assigns and coordinates all IPs.*

## Scenarios

### Traveling (Primary Use Case)

```
[Hotel Wifi/Tethering] → [Beryl AX] → [RPi 5 + MacBook]
                                           ↓
                                    [Tailscale Mesh]
                                           ↓
                                    [VPS - Headscale]
                                           ↓
                                  [Home devices: connected]
```

- Mobile kit provides local DNS (Pi-hole)
- MacBook ↔ RPi 5 works locally
- Tailscale mesh connects to home via VPS

### At Home

```
[Home Router] → [Beryl AX optional] → [RPi 5 + MacBook]
                         ↓
                 [All devices on Tailscale]
                         ↓
                   [VPS coordinates]
```

- RPi 5 optional at home (Fixed homelab Pi-hole available)
- MacBook connects directly to home network or via Tailscale

### Mobile Kit Off

```
[MacBook only on home WiFi]
         ↓
   [Tailscale Mesh]
         ↓
  [VPS - Headscale] ← Still running 24/7
         ↓
  [Home devices: connected]
```

- RPi 5 and Beryl AX powered off
- Mesh still works (VPS handles coordination)
- MacBook connects via home network + Tailscale

## Deployment Order

| Phase | Task | Status |
|-------|------|--------|
| 1 | Wait for RPi 5 PSU | In transit |
| 2 | Flash RPi OS, install Docker | Pending |
| 3 | Deploy Pi-hole on RPi 5 | Pending |
| 4 | Configure Beryl AX DHCP reservations | Pending |
| 5 | Join RPi 5 to Headscale (VPS) | Pending |
| 6 | Test on-demand operation | Pending |

## Docker Structure (RPi 5)

```
docker/mobile/rpi5/
└── networking/
    └── pihole/
        └── docker-compose.yml
```

*Headscale docker-compose is now in `docker/vps/networking/headscale/`*

## Backup Strategy

| Source | Destination | Method | Frequency |
|--------|-------------|--------|-----------|
| Pi-hole config | Git repo | Teleporter export | On change |

*Headscale backup handled by VPS (see `docker/vps/networking/headscale/backup.sh`).*

## Security Considerations

- Pi-hole web password in `.env` (set via `pihole -a -p`)
- Beryl AX admin password: change from default
- Enable Beryl AX firewall, disable WAN access to admin

## Power Management

### Daily Operation (7AM-7PM)

```bash
# Morning: Power on
# - Plug in RPi 5
# - Power on Beryl AX
# - Wait ~2 minutes for boot

# Evening: Power off
# - Safe to unplug (Pi-hole is stateless)
# - Mesh continues via VPS
```

### Hot Days

On extremely hot days, keep mobile kit off entirely:
- MacBook uses home WiFi + Tailscale
- Mesh works via VPS
- No impact on homelab operation

## Future Enhancements

- [ ] Tailscale exit node on RPi 5
- [ ] Syncthing between MacBook and RPi 5
- [ ] Ansible playbooks for declarative deployment

## References

- [Pi-hole](https://pi-hole.net/)
- [GL-MT3000 Docs](https://docs.gl-inet.com/router/en/4/user_guide/gl-mt3000/)
- [Headscale Docs](https://headscale.net/) (now on VPS)
