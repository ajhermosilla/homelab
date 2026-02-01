# VLAN Design

OPNsense VLAN configuration for network segmentation and IoT isolation.

## Overview

```
                          [ISP Modem]
                               │
                        [OPNsense VM]
                         (Mini PC)
                               │
                    ┌──────────┼──────────┐
                    │          │          │
              VLAN 1      VLAN 10     VLAN 20
            Management      IoT       Guest
           192.168.1.0  192.168.10.0 192.168.20.0
                │          │          │
           ┌────┴────┐     │     ┌────┴────┐
           │         │     │     │         │
        [Servers] [Admin]  │  [Phones]  [Visitors]
                           │
                    ┌──────┴──────┐
                    │             │
               [Cameras]    [Smart Home]
```

---

## VLAN Assignments

| VLAN ID | Name | Subnet | Purpose |
|---------|------|--------|---------|
| 1 | Management | 192.168.1.0/24 | Servers, admin devices |
| 10 | IoT | 192.168.10.0/24 | Cameras, smart devices |
| 20 | Guest | 192.168.20.0/24 | Untrusted devices, visitors |

---

## Device Placement

### VLAN 1 - Management (192.168.1.0/24)

Trusted devices with full network access.

| Device | IP | Connection | Notes |
|--------|-----|------------|-------|
| OPNsense | .1 | MokerLink P1 | Router/gateway |
| Docker VM | .10 | MokerLink P2 | Pi-hole, Jellyfin, etc |
| RPi 4 (Start9) | .11 | MokerLink P3 | Bitcoin node |
| NAS | .12 | MokerLink P4 | Storage, backups |
| OpenClaw VM | .20 | (virtual) | AI assistant |
| TP-Link AP | - | MokerLink P7 | VLAN trunk |
| Yamaha RX-V671 | .30 | MokerLink P5 | AV Receiver (Ethernet) |
| Apple TV | .31 | WiFi (HomeNet) | Jellyfin client |
| LG Smart TV | .32 | WiFi (HomeNet) | Jellyfin client |
| MacBook | DHCP | MokerLink P8 | Admin workstation |
| Phones | DHCP | WiFi (HomeNet) | Family devices |

### VLAN 10 - IoT (192.168.10.0/24)

Untrusted IoT devices. No internet access by default.

| Device | IP | Notes |
|--------|-----|-------|
| Reolink Cam 1 | .101 | Front door |
| Reolink Cam 2 | .102 | Back yard |
| Tapo C110 | .103 | Indoor (WiFi) |
| Smart bulbs | DHCP | If added |
| Smart plugs | DHCP | If added |

### VLAN 20 - Guest (192.168.20.0/24)

Internet-only access. No LAN access.

| Device | IP | Notes |
|--------|-----|-------|
| Guest phones | DHCP | Visitors |
| Guest laptops | DHCP | Visitors |

---

## OPNsense Configuration

### 1. Create VLANs

**Interfaces → Other Types → VLAN:**

| Parent | VLAN Tag | Description |
|--------|----------|-------------|
| vtnet1 (LAN) | 10 | IoT |
| vtnet1 (LAN) | 20 | Guest |

### 2. Assign Interfaces

**Interfaces → Assignments:**

| Interface | Device | Description |
|-----------|--------|-------------|
| LAN | vtnet1 | Management (untagged) |
| IOT | vtnet1.10 | IoT VLAN |
| GUEST | vtnet1.20 | Guest VLAN |

### 3. Configure Interface IPs

| Interface | IPv4 | DHCP Range |
|-----------|------|------------|
| LAN | 192.168.1.1/24 | .100-.199 |
| IOT | 192.168.10.1/24 | .100-.199 |
| GUEST | 192.168.20.1/24 | .100-.199 |

### 4. Enable DHCP

**Services → DHCPv4:**

For each interface:
- Enable DHCP
- Set range: .100 to .199
- DNS: Point to Pi-hole (192.168.1.10)

---

## Firewall Rules

### Management VLAN (LAN)

| # | Action | Source | Destination | Ports | Description |
|---|--------|--------|-------------|-------|-------------|
| 1 | Pass | LAN net | any | any | Allow all outbound |

### IoT VLAN

| # | Action | Source | Destination | Ports | Description |
|---|--------|--------|-------------|-------|-------------|
| 1 | Pass | IOT net | 192.168.1.10 | 53 | Allow DNS (Pi-hole) |
| 2 | Pass | IOT net | 192.168.1.10 | 123 | Allow NTP |
| 3 | Pass | 192.168.10.101-103 | 192.168.1.10 | 5000 | Cameras → Frigate |
| 4 | Block | IOT net | RFC1918 | any | Block LAN access |
| 5 | Block | IOT net | any | any | Block internet (default deny) |

**Camera-specific rules:** Cameras only need to reach Frigate, no internet.

### Guest VLAN

| # | Action | Source | Destination | Ports | Description |
|---|--------|--------|-------------|-------|-------------|
| 1 | Pass | GUEST net | 192.168.1.10 | 53 | Allow DNS |
| 2 | Block | GUEST net | RFC1918 | any | Block LAN access |
| 3 | Pass | GUEST net | any | 80,443 | Allow HTTP/HTTPS |
| 4 | Block | GUEST net | any | any | Block all else |

---

## Switch Configuration

### MokerLink 8-Port 2.5G Switch

Configure for VLAN trunking:

| Port | Mode | VLAN | Device | Speed |
|------|------|------|--------|-------|
| 1 | Trunk | 1,10,20 | Mini PC (OPNsense) | 2.5G |
| 2 | Access | 1 | Docker VM | 2.5G |
| 3 | Access | 1 | RPi 4 (Start9) | 1G |
| 4 | Access | 1 | NAS | 2.5G |
| 5 | Access | 1 | Yamaha RX-V671 | 1G |
| 6 | Access | 10 | TP-Link PoE Switch | 1G |
| 7 | Trunk | 1,10,20 | TP-Link AP | 1G |
| 8 | Access | 1 | Reserved (MacBook) | 2.5G |

### TP-Link PoE Switch (TL-SG1005P)

**Unmanaged switch** - all ports share same VLAN (10, inherited from MokerLink P6).

| Port | Device | IP |
|------|--------|-----|
| 1 | Uplink to MokerLink P6 | - |
| 2 | Reolink Cam 1 | 192.168.10.101 |
| 3 | Reolink Cam 2 | 192.168.10.102 |
| 4-5 | Reserved | - |

All cameras automatically on VLAN 10 (IoT) without per-port config.

---

## WiFi Configuration

### TP-Link AX3000 AP

| SSID | VLAN | Purpose |
|------|------|---------|
| HomeNet | 1 | Trusted devices |
| IoT-Devices | 10 | Smart home (if supported) |
| Guest | 20 | Visitors |

**Note:** Stock firmware may not support multi-VLAN. Options:
- Single SSID on Management VLAN
- Flash OpenWrt for full VLAN support

---

## Camera Isolation

### Security Model

```
┌─────────────────────────────────────────────────────┐
│                   IoT VLAN (10)                      │
│                                                      │
│   [Cam 1]    [Cam 2]    [Cam 3]                     │
│   .101       .102       .103                         │
│      │          │          │                         │
│      └──────────┼──────────┘                         │
│                 │                                    │
│           Only allowed to:                           │
│           192.168.1.10:5000 (Frigate)               │
│                                                      │
│           ✗ No internet                             │
│           ✗ No LAN access                           │
│           ✗ No camera-to-camera                     │
└─────────────────────────────────────────────────────┘
```

### Why Isolate Cameras?

- Prevent firmware phone-home to China
- Block network scanning/attacks
- Contain compromised devices
- RTSP streams stay local

---

## Tailscale Bypass

Tailscale devices access services via overlay network, bypassing VLANs:

| Tailscale IP | Device | Physical VLAN |
|--------------|--------|---------------|
| 100.64.0.10 | Docker VM | 1 |
| 100.64.0.11 | RPi 4 | 1 |
| 100.64.0.12 | NAS | 1 |

Access from anywhere: `ssh 100.64.0.12` works regardless of VLAN.

---

## Implementation Checklist

### Phase 1: OPNsense
- [x] Create VLAN 10 (IoT)
- [x] Create VLAN 20 (Guest)
- [x] Assign interfaces
- [x] Configure DHCP per VLAN
- [x] Create firewall rules

### Phase 2: Switch
- [x] Configure MokerLink VLAN trunks
- [x] Configure access ports
- [x] Connect PoE switch to IoT VLAN

### Phase 3: Cameras
- [ ] Assign static IPs (.101-.103)
- [ ] Verify Frigate connectivity
- [ ] Confirm no internet access

### Phase 4: WiFi (Optional)
- [ ] Create Guest SSID
- [ ] Map to VLAN 20
- [ ] Test isolation

---

## Troubleshooting

### Device Can't Get IP
```bash
# Check DHCP leases in OPNsense
Services → DHCPv4 → Leases

# Verify VLAN tagging matches switch config
```

### Camera Can't Reach Frigate
```bash
# Check firewall logs
Firewall → Log Files → Live View

# Verify rule allows IoT → 192.168.1.10:5000
```

### Inter-VLAN Traffic Blocked
```bash
# Expected behavior!
# Only explicitly allowed traffic passes between VLANs
```

---

## Reference

- [OPNsense VLAN Guide](https://docs.opnsense.org/manual/how-tos/vlan.html)
- [OPNsense Firewall Rules](https://docs.opnsense.org/manual/firewall.html)
