# Mobile Homelab Architecture

Self-contained portable infrastructure for dev, self-hosting, and demos.

## Hardware

| Device | Role | Power |
|--------|------|-------|
| Raspberry Pi 5 (8GB) | Core server - Headscale, DNS, containers | USB-C PSU |
| MacBook Air M1 | Workstation, Docker dev, soft-serve | Battery |
| Beryl AX (GL-MT3000) | Network gateway, DHCP, VPN endpoint | USB-C |
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
```

## Services

### Raspberry Pi 5 (Always-On Core)

| Service | Port | Purpose |
|---------|------|---------|
| Headscale | 443, 3478 | Tailscale coordination server |
| AdGuard Home | 53, 80, 3000 | DNS server + ad blocking |
| Future containers | - | TBD |

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
| RPi 5 | 100.64.0.1 | rpi5 |
| MacBook Air | 100.64.0.2 | macbook |
| Mini PC (home) | 100.64.0.10 | minipc |
| RPi 4 (home) | 100.64.0.11 | rpi4 |

*IPs are examples - Headscale assigns them.*

## Scenarios

### Traveling (Primary Use Case)

```
[Hotel Wifi/Tethering] → [Beryl AX] → [RPi 5 + MacBook]
                                           ↓
                                    [Tailscale Mesh]
                                           ↓
                                  [Home devices online?]
                                     If yes: connected
                                     If no: don't care
```

- Mobile kit is self-contained
- MacBook ↔ RPi 5 always works (local + Tailscale)
- Home devices connect when available

### At Home

```
[Home Router] → [Beryl AX in bridge/AP mode] → [RPi 5 + MacBook]
                         ↓
                 [All devices on Tailscale]
```

- Everything on same mesh
- RPi 5 still coordinates
- Can access home services from MacBook

### Offline / Air-Gapped

```
[Beryl AX as AP] → [RPi 5 + MacBook]
      (no internet)
```

- Local network still works
- Pi-hole DNS resolves local names
- Tailscale mesh works for cached keys
- Demos work without internet

## Deployment Order

| Phase | Task | Status |
|-------|------|--------|
| 1 | Wait for RPi 5 PSU | In transit |
| 2 | Flash RPi OS, install Docker | Pending |
| 3 | Deploy Headscale on RPi 5 | Pending |
| 4 | Deploy AdGuard Home on RPi 5 | Pending |
| 5 | Configure Beryl AX DHCP reservations | Pending |
| 6 | Join MacBook to Headscale | Pending |
| 7 | Join home devices to Headscale | Pending |
| 8 | Test all scenarios | Pending |

## Docker Structure (RPi 5)

```
docker/
├── networking/
│   ├── headscale/
│   │   ├── docker-compose.yml
│   │   └── config/
│   └── adguard/
│       └── docker-compose.yml
```

## Security Considerations

- Headscale API key stored in `.env` (gitignored)
- AdGuard admin password in `.env`
- Beryl AX admin password: change from default
- Enable Beryl AX firewall, disable WAN access to admin

## Future Enhancements

- [ ] Tailscale exit node on RPi 5 (route all traffic through it)
- [ ] Automated backups of Headscale DB
- [ ] Monitoring (Prometheus + Grafana on RPi 5?)
- [ ] File sync (Syncthing) between MacBook and RPi 5

## References

- [Headscale Docs](https://headscale.net/)
- [AdGuard Home](https://adguard.com/adguard-home.html)
- [GL-MT3000 Docs](https://docs.gl-inet.com/router/en/4/user_guide/gl-mt3000/)
