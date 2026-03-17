# OPNsense Setup Guide

OPNsense VM configuration on Proxmox for the fixed homelab.

## Overview

```text
                    [ISP Modem]
                         │
                    ┌────┴────┐
                    │  WAN    │ ← vmbr0 (bridged)
                    │         │
                    │ OPNsense│
                    │   VM    │
                    │         │
                    │  LAN    │ ← vmbr1 (bridged)
                    └────┬────┘
                         │
                [MokerLink Switch]
                         │
            ┌────────────┼────────────┐
            │            │            │
       [Docker VM]    [NAS]       [Devices]
```

---

## Proxmox VM Setup

### 1. Create VM

#### VM Settings

| Setting | Value |
|---------|-------|

| VM ID | 100 |
| Name | opnsense |
| OS Type | Other |
| ISO | OPNsense-24.x-amd64.iso |
| Disk | 20GB (local-lvm) |
| CPU | 2 cores |
| RAM | 2048 MB |
| Network | See below |

### 2. Network Configuration

#### Two network interfaces required (both bridged)

| Interface | Type | Purpose |
|-----------|------|---------|

| net0 | Bridge (vmbr0) | WAN - ISP/switch side |
| net1 | Bridge (vmbr1) | LAN - internal network |

#### Bridged Networking

Both NICs use Proxmox bridges (no PCI passthrough needed):

```bash
# /etc/network/interfaces on Proxmox

# WAN bridge (OPNsense WAN - public IP via DHCP)
auto vmbr0
iface vmbr0 inet manual
    bridge-ports enp1s0
    bridge-stp off
    bridge-fd 0

# LAN bridge (OPNsense LAN + Docker VM + Proxmox mgmt)
auto vmbr1
iface vmbr1 inet static
    address 192.168.0.237/24
    gateway 192.168.0.1
    bridge-ports enp2s0
    bridge-stp off
    bridge-fd 0
```

### 3. VM Hardware Summary

```text
Hardware:
  - Memory: 2048 MB
  - Processors: 2 (host)
  - BIOS: OVMF (UEFI)
  - Disk: 20GB virtio
  - net0: vmbr0 (WAN bridge)
  - net1: vmbr1 (LAN bridge)
```

---

## OPNsense Installation

### 1. Boot from ISO

- Start VM
- Select "Install (UFS)" from boot menu
- Choose keyboard layout
- Select target disk (ada0)
- Confirm installation

### 2. Initial Console Setup

After reboot, at console:

```text
*** Welcome to OPNsense ***

WAN (vtnet0/igc0) -> dhcp (from ISP)
LAN (vtnet1)      -> 192.168.0.1/24

Login: root
Password: opnsense
```

Assign interfaces:

- WAN: `vtnet0` (bridged, vmbr0)
- LAN: `vtnet1` (bridged, vmbr1)

### 3. Web GUI Access

From a device on LAN:

```yaml
https://192.168.0.1
Username: root
Password: opnsense
```

---

## Basic Configuration

### 1. Change Password

#### System > Access > Users > root

- Set strong password

### 2. General Settings

#### System > Settings > General

| Setting | Value |
|---------|-------|

| Hostname | opnsense |
| Domain | cronova.local |
| Timezone | America/Asuncion |
| DNS Servers | 1.1.1.1, 9.9.9.9 |

### 3. WAN Interface

#### Interfaces > WAN

| Setting | Value |
|---------|-------|

| IPv4 Type | DHCP |
| Block Private | Enabled |
| Block Bogon | Enabled |

### 4. LAN Interface

#### Interfaces > LAN

| Setting | Value |
|---------|-------|

| IPv4 Address | 192.168.0.1/24 |
| Description | LAN |

---

## DHCP Server

#### Services > DHCPv4 > LAN

| Setting | Value |
|---------|-------|

| Enable | Yes |
| Range | 192.168.0.100 - 192.168.0.199 |
| DNS Servers | 192.168.0.10 (Pi-hole) |
| Gateway | 192.168.0.1 |
| Domain | cronova.local |

### Static Mappings

#### Services > DHCPv4 > LAN > DHCP Static Mappings

| Device | MAC | IP |
|--------|-----|-----|

| Docker VM | xx:xx:xx:xx:xx:xx | 192.168.0.10 |
| RPi 4 | xx:xx:xx:xx:xx:xx | 192.168.0.11 |
| NAS | xx:xx:xx:xx:xx:xx | 192.168.0.12 |
| Yamaha RX-V671 | xx:xx:xx:xx:xx:xx | 192.168.0.30 |
| Apple TV | xx:xx:xx:xx:xx:xx | 192.168.0.31 |
| LG TV | xx:xx:xx:xx:xx:xx | 192.168.0.32 |

---

## VLAN Configuration

See `docs/guides/vlan-design.md` for detailed VLAN setup.

### Create VLANs

#### Interfaces > Other Types > VLAN

| Parent | Tag | Description |
|--------|-----|-------------|

| vtnet0 | 10 | IoT |
| vtnet0 | 20 | Guest |

### Assign Interfaces

#### Interfaces > Assignments

| Interface | Device | Description |
|-----------|--------|-------------|

| LAN | vtnet0 | Management (untagged) |
| OPT1 | vtnet0.10 | IoT |
| OPT2 | vtnet0.20 | Guest |

### Configure VLAN Interfaces

#### Interfaces > IOT (OPT1)

| Setting | Value |
|---------|-------|

| Enable | Yes |
| IPv4 | 192.168.10.1/24 |
| Description | IoT |

#### Interfaces > GUEST (OPT2)

| Setting | Value |
|---------|-------|

| Enable | Yes |
| IPv4 | 192.168.20.1/24 |
| Description | Guest |

---

## Firewall Rules

### LAN (Management)

#### Firewall > Rules > LAN

| # | Action | Source | Dest | Port | Description |
|---|--------|--------|------|------|-------------|

| 1 | Pass | LAN net | any | any | Allow all outbound |

### IoT VLAN

#### Firewall > Rules > IOT

| # | Action | Source | Dest | Port | Description |
|---|--------|--------|------|------|-------------|

| 1 | Pass | IOT net | 192.168.0.10 | 53 | DNS (Pi-hole) |
| 2 | Pass | IOT net | 192.168.0.10 | 123 | NTP |
| 3 | Pass | 192.168.10.101-103 | 192.168.0.10 | 5000 | Cameras → Frigate |
| 4 | Block | IOT net | RFC1918 | any | Block LAN access |
| 5 | Block | IOT net | any | any | Block internet |

### Guest VLAN

#### Firewall > Rules > GUEST

| # | Action | Source | Dest | Port | Description |
|---|--------|--------|------|------|-------------|

| 1 | Pass | GUEST net | 192.168.0.10 | 53 | DNS |
| 2 | Block | GUEST net | RFC1918 | any | Block LAN |
| 3 | Pass | GUEST net | any | 80,443 | HTTP/HTTPS |
| 4 | Block | GUEST net | any | any | Block all else |

---

## DNS Resolver (Unbound)

#### Services > Unbound DNS > General

| Setting | Value |
|---------|-------|

| Enable | Yes |
| Listen Port | 53 |
| Network Interfaces | LAN, IOT, GUEST |
| DNSSEC | Enabled |

**Note:** Pi-hole on Docker VM (192.168.0.10) provides ad-blocking. Configure DHCP to use Pi-hole as DNS, with OPNsense Unbound as fallback.

---

## Tailscale Integration

Install Tailscale plugin for mesh access:

#### System > Firmware > Plugins

- Install `os-tailscale`

#### VPN > Tailscale

- Enable Tailscale
- Authenticate with Headscale:

  ```text
  tailscale up --login-server=https://hs.cronova.dev --authkey=<key>
  ```

---

## NUT Integration (UPS)

For graceful shutdown on power loss:

#### Services > UPS > Configuration

| Setting | Value |
|---------|-------|

| UPS Type | nut (networked) |
| Remote Host | 192.168.0.12 (NAS) |
| Remote User | upsmon |
| Remote Password | (from NAS NUT config) |

See `docs/guides/nut-config.md` for NUT server setup on NAS.

---

## Dual-WAN / LTE Failover

Automatic WAN failover using a TP-Link TL-MR100 LTE router on the LAN as a secondary gateway. When the ISP goes down, OPNsense routes critical traffic (Tailscale, DNS) over LTE within ~60 seconds. The family doesn't notice — Augusto retains remote access.

### Design: LAN-Side Gateway

The Aoostar N1 Pro has only 2 NICs (both occupied: WAN + LAN). Instead of adding a third NIC via USB adapter, the TL-MR100 connects to the MokerLink switch alongside all other LAN devices. OPNsense uses it as a failover gateway on the LAN interface — no extra interfaces, no Proxmox USB passthrough, no cable mess.

The MR100 is a standalone LTE router with a built-in SIM slot. It handles the cellular connection internally and presents a clean Ethernet interface. Double NAT is irrelevant since Tailscale handles NAT traversal via DERP relays.

### Hardware

| Item | Details |
|------|---------|

| **LTE Router** | TP-Link TL-MR100 (~$32, Flytec CDE) |
| **SIM** | Tigo or Personal prepaid, 5GB/month (~$3/mo) |
| **Connection** | Ethernet from MR100 LAN port → MokerLink switch |

### Prerequisites: MR100 Setup

Before connecting to the homelab, configure the MR100 standalone (connect via WiFi or direct Ethernet to a laptop):

1. **Insert SIM** into the MR100's micro-SIM slot (bottom of device)
2. **Access admin UI** at `http://192.168.1.1` (MR100 default)
   - Default password: `admin`
3. **Set APN** if not auto-detected:
   - Tigo: `internet.tigo.py`
   - Personal: `internet`
4. **Change MR100 LAN IP** to `192.168.0.3/24`:
   - **Network > LAN Settings** → IP Address: `192.168.0.3`, Subnet: `255.255.255.0`
   - This puts the MR100 on the same subnet as OPNsense LAN
5. **Disable DHCP server** on the MR100:
   - **Network > LAN Settings > DHCP** → Disable
   - OPNsense remains the only DHCP server on the network
6. **Disable MR100 WiFi** (both bands):
   - **Wireless > Wireless Settings** → Disable
   - No rogue SSID on the network
7. **Set admin password** to something strong (store in Vaultwarden)
8. **Verify LTE connection**: check signal bars and test browsing via the MR100's admin UI

### Physical Connection

Plug the MR100's LAN/WAN Ethernet port into any free port on the MokerLink switch. Connect power. Done.

```text
Rack / Shelf:
  [ARRIS modem] ──eth──► [MokerLink switch] ◄──eth── [Aoostar nic1 (LAN)]
  [TL-MR100]    ──eth──┘        │            ◄──eth── [Aoostar nic0 (WAN) ← ARRIS]
   (power + SIM)                ├── NAS
                                ├── WiFi AP
                                └── other devices
```

### OPNsense Configuration

#### 1. Add LTE Gateway

The MR100 is at `192.168.0.3` on the LAN. Add it as a gateway manually.

#### System > Gateways > Configuration > Add

| Setting | Value |
|---------|-------|

| Name | LTE_GW |
| Description | TP-Link MR100 LTE failover |
| Interface | LAN |
| Address Family | IPv4 |
| IP Address | 192.168.0.3 |
| Upstream Gateway | Yes |
| Far Gateway | Yes |
| Monitor IP | 9.9.9.9 |
| Priority | 255 (default) |

**Important:**Enable**Far Gateway** — this tells OPNsense the gateway is not directly connected (it's a router on the LAN, not a point-to-point link). Without this, gateway monitoring may not work correctly.

Verify the existing ISP gateway:

| Setting | Value |
|---------|-------|

| Name | ISP_WAN_DHCP |
| Interface | WAN |
| Monitor IP | 1.1.1.1 |

Use different monitor IPs (1.1.1.1 vs 9.9.9.9) so both gateways are health-checked independently.

#### 2. Create Gateway Group

#### System > Gateways > Group > Add

| Setting | Value |
|---------|-------|

| Group Name | WAN_FAILOVER |
| ISP_WAN_DHCP | Tier 1 (primary) |
| LTE_GW | Tier 2 (failover) |
| Trigger Level | Member Down |

#### 3. Enable Gateway Switching

#### System > Settings > General

- Enable: **Allow default gateway switching**

#### 4. Update Firewall Rules

#### Firewall > Rules > LAN

- Edit the default "Allow all outbound" rule
- Set **Gateway** to `WAN_FAILOVER` (instead of default)

#### 5. Prevent LAN Devices from Using MR100 Directly

LAN devices should never use `192.168.0.3` as a gateway — only OPNsense should route through it. The MR100's DHCP is disabled (step 5 in prerequisites), so devices won't discover it. As an extra safeguard, add a firewall rule:

**Firewall > Rules > LAN** (add at top):

| # | Action | Source | Dest | Port | Description |
|---|--------|--------|------|------|-------------|

| 1 | Block | !OPNsense | 192.168.0.3 | any | Only OPNsense can reach MR100 |

This ensures only OPNsense itself routes traffic through the MR100.

#### 6. DHCP Static Mapping (Optional but Recommended)

Reserve `192.168.0.3` for the MR100 in OPNsense DHCP so nothing else gets that IP:

#### Services > DHCPv4 > LAN > DHCP Static Mappings > Add

| Setting | Value |
|---------|-------|

| MAC Address | (MR100's MAC — check sticker on bottom) |
| IP Address | 192.168.0.3 |
| Description | TP-Link MR100 LTE failover |

### Testing Failover

1. **Verify both gateways are online**:
   - **System > Gateways > Configuration** — both should show "Online"
   - ISP_WAN_DHCP monitors 1.1.1.1 via ISP, LTE_GW monitors 9.9.9.9 via MR100

1. **Simulate ISP failure**:

   ```bash
   # Unplug ARRIS modem (or disable WAN interface in OPNsense)
   # Interfaces > WAN > Disable → Save → Apply
   ```

1. **Verify failover** (~30-60 seconds):
   - **System > Gateways > Configuration** — ISP_WAN should show "Offline", LTE_GW "Online"
   - From a LAN device: `ping 8.8.8.8` should work (routed via MR100 LTE)
   - Tailscale should reconnect within 1-2 minutes
   - ntfy alert should fire (Uptime Kuma detects WAN change)

1. **Verify failback**:
   - Re-enable WAN / plug ARRIS back in
   - ISP_WAN goes back to "Online"
   - Traffic automatically returns to ISP (Tier 1)

1. **Check LTE data usage**:
   - Access MR100 admin UI at `http://192.168.0.3`
   - **Advanced > System Tools > Statistics** → check monthly data

### WAN Watchdog Integration

The existing `/root/wan_watchdog.sh` on OPNsense handles DHCP recovery for the primary WAN. With multi-WAN, the gateway group handles failover automatically — the watchdog is complementary (it tries to recover ISP before failover kicks in).

### Architecture

```text
                    ┌──────────┐
   ISP ────────────►│  ARRIS   │
   (Tier 1)         │ (bridge) │
                    └────┬─────┘
                         │ nic0/vmbr0
                    ┌────▼─────────────────────┐
                    │   Aoostar N1 Pro          │
                    │   (Proxmox)               │
                    │                           │
                    │   ┌───────────────────┐   │
                    │   │    OPNsense VM    │   │
                    │   │  WAN_FAILOVER:    │   │
                    │   │  vtnet0 = Tier 1  │   │
                    │   │  LAN GW = Tier 2  │   │
                    │   └───────────────────┘   │
                    │                           │
                    └────┬─────────────────────┘
                         │ nic1/vmbr1
                    ┌────▼─────────────────────┐
                    │    MokerLink Switch       │
                    │                           │
                    │  ┌─────────┐              │
                    │  │ TL-MR100│◄── LTE SIM   │
                    │  │ .0.2    │   (Tier 2)   │
                    │  └─────────┘              │
                    └────┬────────┬────────┬───┘
                         │        │        │
                    [Docker VM] [NAS]  [Devices]
                      .0.10     .0.12
```

---

## Backup Configuration

#### System > Configuration > Backups

- Enable automatic backups
- Download backup after major changes
- Store in homelab git repo (encrypted)

```bash
# Encrypt backup with age
age -r age1... opnsense-config.xml > opnsense-config.xml.age
```

---

## Monitoring

### Uptime Kuma

Add OPNsense health check:

- Type: HTTP
- URL: <https://192.168.0.1>
- Expected: 200

### Prometheus (Optional)

Install telegraf plugin for metrics export.

---

## Verification Checklist

### Initial Setup

- [ ] VM created with correct resources
- [ ] WAN bridge (vmbr0) configured
- [ ] LAN bridge configured
- [ ] OPNsense installed
- [ ] Web GUI accessible

### Network

- [ ] WAN gets IP from ISP
- [ ] LAN devices get DHCP
- [ ] Internet access works
- [ ] DNS resolution works

### VLANs

- [ ] IoT VLAN created
- [ ] Guest VLAN created
- [ ] Switch configured for VLANs
- [ ] Firewall rules applied
- [ ] Camera isolation verified

### Security

- [ ] Strong admin password set
- [ ] Firmware updated
- [ ] Backup created
- [ ] Tailscale connected

---

## Related Documentation

- `docs/guides/vlan-design.md` - VLAN configuration details
- `docs/architecture/fixed-homelab.md` - Overall architecture
- `docs/guides/nut-config.md` - UPS graceful shutdown
- `docs/architecture/hardware.md` - Mini PC specs
- `docs/reference/family-emergency-internet.md` - Family emergency internet runbook
- `docs/guides/incident-2026-03-05-isp-outage.md` - ISP outage incident that motivated dual-WAN
