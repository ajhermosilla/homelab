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

| Device | Role | Power | Status |
|--------|------|-------|--------|
| Beryl AX (GL-MT3000) | Network gateway, DHCP, Tailscale | USB-C | Configured |
| Samsung A13 | Dedicated tethering (Claro prepaid) | USB-C (always plugged) | Ready |
| MacBook Air M1 | Workstation, Docker dev | Battery | Active |
| Raspberry Pi 5 (8GB) | Pi-hole DNS (mobile) | USB-C PSU | Pending PSU |
| Samsung A16 (mombeu) | Personal phone, Tailscale client | Battery | Active |

### Phone Roles

| Phone | Role | Carrier | Connection |
|-------|------|---------|------------|
| Samsung A13 | Homelab internet | Claro prepaid (data only) | USB tethered to Beryl AX |
| Samsung A16 (mombeu) | Personal | Tigo | WiFi to mbohapy, Tailscale mesh |

*A13 stays plugged in and tethered when mobile kit is running. A16 is personal phone, not part of homelab infrastructure.*

### Claro Prepaid Data (Samsung A13)

**SIM:** PYG 10,000 prepaid from local store

| Pack | Duration | Notes |
|------|----------|-------|
| 2 GB | 7 days | Good for testing |
| 6 GB | 30 days | Monthly usage |

**Features:**
- WhatsApp free (1GB daily limit, no calls/video)
- Data doesn't roll over
- Prices include IVA
- Dial `*123#` to see available packs

**To verify:**
- Tethering allowed (test before buying big pack)
- Check [simple.claro.com.py](https://simple.claro.com.py/inicio) for current prices

**References:**
- [Claro Paraguay Prepago](https://www.claro.com.py/personas/planes-prepago)
- [Términos Prepago](https://www.claro.com.py/personas/planes-prepago-pospago/terminos-condiciones-prepago)

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
          100.77.172.46
```

## Services

### Beryl AX (Always-On When Kit Running)

| Service | Port | Purpose |
|---------|------|---------|
| AdGuard Home | 53, 3000 | DNS ad-blocking (primary) |
| Tailscale | - | Mesh client |
| DHCP | 67 | LAN IP assignment |

*AdGuard Home is built into GL.iNet firmware - lightweight (~30MB), perfect for router.*

### Raspberry Pi 5 (On-Demand / Tinkering)

| Service | Port | Purpose |
|---------|------|---------|
| Pi-hole | 53, 80 | DNS ad-blocking (secondary) |
| Tailscale | - | Mesh client |

*RPi 5 is a tinkering device - can be reassigned to other projects. Beryl AX AdGuard provides DNS when RPi 5 is busy/off.*

### MacBook Air M1 (Workstation)

| Service | Port | Purpose |
|---------|------|---------|
| Docker workloads | Various | Dev containers |

### DNS Strategy (Dual-DNS)

```
[Devices] → [Beryl AX AdGuard Home] → [Upstream DNS]
                    ↓ (fallback)
            [RPi 5 Pi-hole] → [Upstream DNS]
```

| Scenario | Primary DNS | Fallback |
|----------|-------------|----------|
| Normal operation | Beryl AX (AdGuard) | RPi 5 (Pi-hole) |
| RPi 5 tinkering/off | Beryl AX (AdGuard) | Public DNS |
| Beryl AX issues | RPi 5 (Pi-hole) | Public DNS |

*Both provide ad-blocking. Redundancy without complexity.*

## IP Addressing

### Local Network (Beryl AX)

| Device | IP | MAC Reservation |
|--------|----|----|
| Beryl AX | 192.168.8.1 | - |
| RPi 5 | 192.168.8.5 | Yes |
| MacBook Air | 192.168.8.10 | Yes |

### Tailscale Network (Headscale Mesh)

| Device | Tailscale IP | Hostname | Role |
|--------|--------------|----------|------|
| VPS | 100.77.172.46 | vps-vultr | Exit node, Headscale |
| MacBook Air | 100.86.220.9 | augustos-macbook-air | Workstation |
| Samsung A16 | 100.110.253.126 | mombeu | Personal phone |
| Beryl AX | (assigned) | beryl-ax | Travel router |
| RPi 5 | (pending) | rpi5 | Pi-hole (when deployed) |

*Headscale on VPS assigns and coordinates all IPs. Run `tailscale status` to see current mesh.*

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
| 1 | Configure Beryl AX (WiFi, admin) | Done |
| 2 | Join Beryl AX to Tailscale mesh | Done |
| 3 | Test USB tethering | Done |
| 4 | Test repeater mode | Done |
| 5 | Wait for RPi 5 PSU | In transit |
| 6 | Flash RPi OS, install Docker | Pending |
| 7 | Deploy Pi-hole on RPi 5 | Pending |
| 8 | Configure Beryl AX DHCP (use RPi 5 DNS) | Pending |
| 9 | Join RPi 5 to Headscale (VPS) | Pending |
| 10 | Test on-demand operation | Pending |

## RPi 5 (Moved to Fixed Homelab)

RPi 5 has been migrated from the mobile kit to the fixed homelab, running OpenClaw directly (not Docker). See `docs/rpi5-deployment-plan.md`.

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
