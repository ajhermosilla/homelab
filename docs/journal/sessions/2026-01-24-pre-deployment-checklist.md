# Pre-Deployment Checklist

#### Print this and check off items as you complete them

---

## Downloads (MacBook → USB)

| Done | Task | Link |
|:----:|------|------|
| [x] | Proxmox VE 9.1 ISO (1.8G) | proxmox.com/en/downloads |
| [x] | OPNsense 25.7 ISO (amd64, dvd) | opnsense.org/download |
| [x] | Debian 13 netinst ISO (791M) | debian.org/download |
| [ ] | Ventoy installed on USB (8GB+ USB 3.0) | ventoy.net |
| [ ] | All ISOs copied to Ventoy USB | |
| [ ] | Test USB boots on Mini PC | |

---

## Hardware - Mini PC

| Done | Task |
|:----:|------|
| [x] | USB keyboard works |
| [x] | HDMI cable works |
| [ ] | Ethernet cables labeled |
| [x] | Mini PC boots to BIOS |
| [x] | Dual NIC visible in BIOS |
| [x] | VT-x/VT-d enabled in BIOS |
| [x] | **Proxmox installed** (192.168.0.237) |

---

## Hardware - NAS

| Done | Task |
|:----:|------|
| [ ] | Open NAS case |
| [ ] | Install SSD 240GB (boot drive) |
| [ ] | Install WD Purple 2TB (Frigate) |
| [ ] | Install WD Red Plus 8TB (data) |
| [ ] | All 3 drives detected in BIOS |
| [ ] | Case closed / ready |

---

## Hardware - Cameras

| Done | Task |
|:----:|------|
| [ ] | Unbox Reolink x2, verify mounts included |
| [ ] | Unbox Tapo C110, verify contents |
| [ ] | Plan mounting locations |
| [ ] | Measure cable runs (<15m each) |
| [ ] | PoE cables ready (2x) |
| [ ] | Tools ready: drill, bits, screwdriver |
| [ ] | Ladder available |
| [ ] | Tapo app installed, RTSP account created |
| [ ] | Camera default credentials noted |

---

## Hardware - Backup

| Done | Task |
|:----:|------|
| [ ] | Beryl AX tested (emergency router) |
| [ ] | Phone charged (backup tether) |

---

## Network Planning

### IP Scheme (confirm or adjust)

| Device | IP Address | Confirmed |
|--------|------------|:---------:|
| OPNsense LAN | 192.168.1.1 | [ ] |
| AX3000 (AP mode) | 192.168.1.2 | [ ] |
| Proxmox | 192.168.1.5 | [ ] |
| Docker VM | 192.168.1.10 | [ ] |
| NAS | 192.168.1.12 | [ ] |
| Camera front | 192.168.1.101 | [ ] |
| Camera back | 192.168.1.102 | [ ] |
| Camera indoor | 192.168.1.103 | [ ] |

### Current Settings (note for reference)

| Item | Value |
|------|-------|
| AX3000 current IP | _______________ |
| AX3000 DHCP range | _______________ |
| ISP modem mode | Bridge / Router |

---

## Credentials (WRITE THESE DOWN)

| Service | Username | Password |
|---------|----------|----------|
| Proxmox | root | _________________ |
| OPNsense | root | _________________ |
| NAS (root) | root | _________________ |
| NAS (user) | augusto | _________________ |
| Reolink cameras | admin | _________________ |
| Tapo RTSP | _________ | _________________ |
| MQTT (Frigate) | frigate | _________________ |

### Tailscale

| Done | Task |
|:----:|------|
| [ ] | Generate auth key from Headscale |

Auth key: `tskey-auth-________________________`

---

## Final Check (Night Before Jan 23)

| Done | Item |
|:----:|------|
| [ ] | Ventoy USB ready with all ISOs |
| [ ] | Keyboard + HDMI cable ready |
| [ ] | All passwords written down |
| [ ] | Tailscale auth key generated |
| [ ] | NAS drives installed |
| [ ] | Mini PC accessible (near monitor) |

---

## Bring to Jan 23 Session

- [ ] Ventoy USB
- [ ] USB keyboard
- [ ] HDMI cable
- [ ] This checklist
- [ ] Passwords

---

## Bring to Jan 24 Session (with friend)

- [ ] Drill + bits
- [ ] Screwdriver
- [ ] Ladder
- [ ] PoE cables (2x)
- [ ] Reolink cameras (2x)
- [ ] Tapo C110 camera
- [ ] Zip ties / cable clips
- [ ] This checklist
- [ ] Passwords
- [ ] Beryl AX (emergency backup)

---

## Quick Reference

| Service | URL | Notes |
|---------|-----|-------|
| Proxmox | <https://192.168.0.237:8006> | Current (pre-OPNsense) |
| Proxmox | <https://192.168.1.5:8006> | After OPNsense cutover |
| OPNsense | <https://192.168.1.1> | After cutover |
| Frigate | <http://192.168.1.10:5000> | After cutover |

---

*Checklist created: 2026-01-21*
