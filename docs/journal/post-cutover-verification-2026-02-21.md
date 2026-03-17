# Post-Cutover Verification — 2026-02-21

**Date:** 2026-02-21
**Event:** OPNsense gateway cutover Phase 2 completed

---

## Network Topology (Post-Cutover)

```text
ISP Modem (ARRIS TG2482, bridge mode)
  │
  └── nic0 / vmbr0 ── OPNsense WAN (vtnet0) ── Public IP via DHCP
                         │
                       OPNsense LAN (vtnet1) ── 192.168.0.1/24
                         │
              nic1 / vmbr1 ── MokerLink Switch
                    │         │         │
                Docker VM   TP-Link   RPi 5
              192.168.0.10  AP mode  (pending)
                            192.168.0.2

Proxmox mgmt: 192.168.0.237 (on vmbr1)
```

## DHCP Configuration

| Setting | Value |
|---------|-------|

| Server | OPNsense ISC DHCPv4 |
| Range | 192.168.0.100 – 192.168.0.250 |
| Gateway | 192.168.0.1 |
| DNS | 192.168.0.10 (Pi-hole) |
| Domain | cronova.local |

## Mac Sanity Check

| Check | Result |
|-------|--------|

| IP | 192.168.0.105 (DHCP) |
| Gateway | 192.168.0.1 (OPNsense) |
| DNS | 192.168.0.10 (Pi-hole, from DHCP) |
| Manual DNS overrides | None |
| Internet | Working (47ms to 8.8.8.8) |
| DNS resolution | google.com via Pi-hole |
| Tailscale | All nodes visible, Proxmox direct |

## Running Services

### Docker VM (192.168.0.10)

| Container | Status |
|-----------|--------|

| caddy | Up (healthy) |
| vaultwarden | Up (healthy) |
| pihole | Up (healthy) |
| watchtower | Up (healthy) |

### VPS (100.77.172.46)

| Container | Status |
|-----------|--------|

| headscale | Running |
| uptime-kuma | Running |
| caddy | Running |
| ntfy | Running |
| headscale-backup | Running |

## Tailscale Mesh

| Node | Tailscale IP | Status |
|------|-------------|--------|

| augustos-macbook-air | 100.86.220.9 | Active |
| oga (Proxmox) | 100.78.12.241 | Active, direct |
| docker | 100.68.63.168 | Active |
| opnsense | 100.79.230.235 | Active |
| beryl-ax | 100.102.244.131 | Active |
| mombeu | 100.110.253.126 | Active |

## Key Files

| File | Location |
|------|----------|

| Proxmox network config | `/etc/network/interfaces` + `/etc/network/interfaces.d/vmbr1` |
| Proxmox config backup | `/etc/network/interfaces.original`, `vmbr1.original` |
| OPNsense config | `/conf/config.xml` |
| OPNsense config backup | `/conf/config.xml.bak` |
| DHCP generated config | `/var/dhcpd/etc/dhcpd.conf` |
| Docker VM network | `/etc/network/interfaces` (192.168.0.10, gw 192.168.0.1) |
| Cutover execution plan | `docs/opnsense-cutover-execution-2026-02-21.md` |

## Useful Commands

```bash
# OPNsense access via SSH tunnel
ssh -J augusto@100.78.12.241 root@192.168.0.1

# OPNsense web UI via SSH tunnel
ssh -L 8443:192.168.0.1:443 augusto@100.78.12.241
# Then open https://localhost:8443

# TP-Link admin via SSH tunnel
ssh -L 8080:192.168.0.2:80 augusto@100.78.12.241
# Then open http://localhost:8080

# Restart OPNsense DHCP
ssh -J augusto@100.78.12.241 root@192.168.0.1 'configctl dhcpd restart'

# Reconfigure OPNsense WAN (force DHCP re-request)
configctl interface reconfigure wan

# Check DHCP leases on Mac
ipconfig getpacket en0

# Check firewall rules on OPNsense
pfctl -sr | grep vtnet1
pfctl -sn
```
