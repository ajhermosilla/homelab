# OPNsense Setup Guide

OPNsense VM configuration on Proxmox for the fixed homelab.

## Overview

```
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

**VM Settings:**

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

**Two network interfaces required (both bridged):**

| Interface | Type | Purpose |
|-----------|------|---------|
| net0 | Bridge (vmbr0) | WAN - ISP/switch side |
| net1 | Bridge (vmbr1) | LAN - internal network |

**Bridged Networking:**

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

```
Hardware:
  - Memory: 2048 MB
  - Processors: 2 (host)
  - BIOS: OVMF (UEFI)
  - Disk: 20GB virtio
  - PCI Device: 02:00.0 (WAN NIC passthrough)
  - Network: vmbr0 (LAN bridge)
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

```
*** Welcome to OPNsense ***

WAN (vtnet0/igc0) -> dhcp (from ISP)
LAN (vtnet1)      -> 192.168.0.1/24

Login: root
Password: opnsense
```

Assign interfaces:
- WAN: `igc0` (passthrough NIC)
- LAN: `vtnet0` (bridge)

### 3. Web GUI Access

From a device on LAN:

```
https://192.168.0.1
Username: root
Password: opnsense
```

---

## Basic Configuration

### 1. Change Password

**System > Access > Users > root**
- Set strong password

### 2. General Settings

**System > Settings > General**

| Setting | Value |
|---------|-------|
| Hostname | opnsense |
| Domain | cronova.local |
| Timezone | America/Asuncion |
| DNS Servers | 1.1.1.1, 9.9.9.9 |

### 3. WAN Interface

**Interfaces > WAN**

| Setting | Value |
|---------|-------|
| IPv4 Type | DHCP |
| Block Private | Enabled |
| Block Bogon | Enabled |

### 4. LAN Interface

**Interfaces > LAN**

| Setting | Value |
|---------|-------|
| IPv4 Address | 192.168.0.1/24 |
| Description | LAN |

---

## DHCP Server

**Services > DHCPv4 > LAN**

| Setting | Value |
|---------|-------|
| Enable | Yes |
| Range | 192.168.0.100 - 192.168.0.199 |
| DNS Servers | 192.168.0.10 (Pi-hole) |
| Gateway | 192.168.0.1 |
| Domain | cronova.local |

### Static Mappings

**Services > DHCPv4 > LAN > DHCP Static Mappings**

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

See `docs/vlan-design.md` for detailed VLAN setup.

### Create VLANs

**Interfaces > Other Types > VLAN**

| Parent | Tag | Description |
|--------|-----|-------------|
| vtnet0 | 10 | IoT |
| vtnet0 | 20 | Guest |

### Assign Interfaces

**Interfaces > Assignments**

| Interface | Device | Description |
|-----------|--------|-------------|
| LAN | vtnet0 | Management (untagged) |
| OPT1 | vtnet0.10 | IoT |
| OPT2 | vtnet0.20 | Guest |

### Configure VLAN Interfaces

**Interfaces > IOT (OPT1)**

| Setting | Value |
|---------|-------|
| Enable | Yes |
| IPv4 | 192.168.10.1/24 |
| Description | IoT |

**Interfaces > GUEST (OPT2)**

| Setting | Value |
|---------|-------|
| Enable | Yes |
| IPv4 | 192.168.20.1/24 |
| Description | Guest |

---

## Firewall Rules

### LAN (Management)

**Firewall > Rules > LAN**

| # | Action | Source | Dest | Port | Description |
|---|--------|--------|------|------|-------------|
| 1 | Pass | LAN net | any | any | Allow all outbound |

### IoT VLAN

**Firewall > Rules > IOT**

| # | Action | Source | Dest | Port | Description |
|---|--------|--------|------|------|-------------|
| 1 | Pass | IOT net | 192.168.0.10 | 53 | DNS (Pi-hole) |
| 2 | Pass | IOT net | 192.168.0.10 | 123 | NTP |
| 3 | Pass | 192.168.10.101-103 | 192.168.0.10 | 5000 | Cameras → Frigate |
| 4 | Block | IOT net | RFC1918 | any | Block LAN access |
| 5 | Block | IOT net | any | any | Block internet |

### Guest VLAN

**Firewall > Rules > GUEST**

| # | Action | Source | Dest | Port | Description |
|---|--------|--------|------|------|-------------|
| 1 | Pass | GUEST net | 192.168.0.10 | 53 | DNS |
| 2 | Block | GUEST net | RFC1918 | any | Block LAN |
| 3 | Pass | GUEST net | any | 80,443 | HTTP/HTTPS |
| 4 | Block | GUEST net | any | any | Block all else |

---

## DNS Resolver (Unbound)

**Services > Unbound DNS > General**

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

**System > Firmware > Plugins**
- Install `os-tailscale`

**VPN > Tailscale**
- Enable Tailscale
- Authenticate with Headscale:
  ```
  tailscale up --login-server=https://hs.cronova.dev --authkey=<key>
  ```

---

## NUT Integration (UPS)

For graceful shutdown on power loss:

**Services > UPS > Configuration**

| Setting | Value |
|---------|-------|
| UPS Type | nut (networked) |
| Remote Host | 192.168.0.12 (NAS) |
| Remote User | upsmon |
| Remote Password | (from NAS NUT config) |

See `docs/nut-config.md` for NUT server setup on NAS.

---

## Backup Configuration

**System > Configuration > Backups**

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
- URL: https://192.168.0.1
- Expected: 200

### Prometheus (Optional)

Install telegraf plugin for metrics export.

---

## Verification Checklist

### Initial Setup
- [ ] VM created with correct resources
- [ ] WAN NIC passthrough configured
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

- `docs/vlan-design.md` - VLAN configuration details
- `docs/fixed-homelab.md` - Overall architecture
- `docs/nut-config.md` - UPS graceful shutdown
- `docs/hardware.md` - Mini PC specs
