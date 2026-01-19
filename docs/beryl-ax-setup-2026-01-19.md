# Beryl AX (GL-MT3000) Setup - 2026-01-19

Pocket-sized AX3000 Wi-Fi 6 travel router for mobile homelab.

## Specs

| Component | Details |
|-----------|---------|
| Model | GL.iNet Beryl AX (GT-MT3000) |
| CPU | MediaTek MT7981B 1.3GHz dual-core (Arm Cortex-A53) |
| RAM / Flash | 512MB / 256MB |
| WiFi | AX3000 (574Mbps 2.4GHz + 2402Mbps 5GHz) |
| Ports | 2.5G WAN, 1G LAN, USB 3.0, USB-C power |
| VPN | WireGuard (300Mbps), OpenVPN (150Mbps) |
| Size | 120 x 83 x 34mm, ~200g |
| Firmware | OpenWrt 21.02 (Kernel 5.4) with GL.iNet UI |

## Phase 1: Stock Firmware Exploration

### Initial Setup

1. Unbox, connect USB-C power
2. Connect to `GL-MT3000-xxx` WiFi (password on device label)
3. Access admin panel: http://192.168.8.1
4. Set admin password
5. Configure WiFi SSID and password

### Configured Settings

| Setting | Value |
|---------|-------|
| SSID 2.4GHz | `mbohapy` |
| SSID 5GHz | `mbohapy-5G` |
| WiFi Password | (stored in KeepassXC) |
| Admin Password | (stored in KeepassXC) |
| SSH | Enabled |

### Features Tested

- [x] **Repeater mode** - Extend hotel/cafe WiFi securely
- [ ] **WireGuard VPN client** - Connect to VPS exit node
- [x] **Tailscale** - Joined Headscale mesh as `beryl-ax`
- [ ] **AdGuard Home** - Built-in ad blocking
- [ ] **USB storage** - File sharing via USB 3.0
- [ ] **LuCI interface** - Advanced OpenWrt settings
- [ ] **Toggle switch** - Hardware VPN on/off
- [x] **USB tethering** - Tested with Redmi A5, works (slow but functional)

### Network Modes

| Mode | Use Case |
|------|----------|
| Router | Connect to ethernet WAN |
| Repeater | Extend existing WiFi |
| Access Point | Create WiFi from ethernet |
| Extender | Bridge two networks |
| Tethering | Share phone's mobile data |

### Default Settings

- Admin panel: `192.168.8.1`
- LAN subnet: `192.168.8.0/24`
- DHCP range: `192.168.8.100-200`

## Phase 2: Firmware Options

| Option | Base | Pros | Cons |
|--------|------|------|------|
| **Stock GL.iNet** | OpenWrt 21.02 | Easy UI, VPN presets, toggle switch | Older kernel |
| **GL.iNet Open Source** | OpenWrt 23.05 | Latest kernel, open WiFi drivers | May lose some GL features |
| **Vanilla OpenWrt** | OpenWrt 23.05.x | Full control, latest packages | Flashing issues, no GL.iNet UI |

### Firmware URLs

- Stock: https://www.gl-inet.com/support/firmware-versions/
- Open Source: https://forum.gl-inet.com/t/mt3000-beryl-ax-open-source-wifi-driver-firmware/36607
- Vanilla OpenWrt: https://firmware-selector.openwrt.org (mediatek/filogic, glinet_gl-mt3000)

### Flashing Notes

- Stock firmware can be upgraded via web UI
- Vanilla OpenWrt flashing has reported issues
- Always backup before flashing: System > Backup
- Recovery: Hold reset 10s during boot for uboot

## Phase 3: Homelab Integration

### Tailscale on Beryl (Completed)

GL.iNet UI doesn't expose custom server option. Use SSH instead:

```bash
# SSH to Beryl
ssh root@192.168.8.1

# Connect to Headscale
tailscale up --login-server=https://hs.cronova.dev --hostname=beryl-ax --accept-routes --accept-dns=false
```

Then register on VPS:
```bash
ssh vps 'sudo docker exec headscale headscale nodes register --key <KEY> --user augusto'
```

Verify:
```bash
tailscale status
```

### WireGuard to VPS

Route all traffic through VPS exit node:

1. Applications > VPN > WireGuard Client
2. Import VPS WireGuard config
3. Enable "Use VPN for all traffic"

### Pi-hole Integration

When on Tailscale, use homelab Pi-hole:

1. Network > DNS
2. Manual DNS: `100.64.0.1` (RPi 5 Pi-hole)

### Travel Kit Configuration

```
[Hotel WiFi] --> [Beryl AX (Repeater)] --> [Your Devices]
                      |
                      +--> WireGuard to VPS (encrypted)
                      +--> Tailscale mesh (homelab access)
                      +--> AdGuard (ad blocking)
```

## Useful Commands

```bash
# SSH to Beryl (after enabling SSH in UI)
ssh root@192.168.8.1

# Check system info
cat /etc/glversion
uname -a

# View connected clients
cat /tmp/dhcp.leases

# Check VPN status
wg show
```

## Mobile Homelab Vision

| Device | Role | IP |
|--------|------|-----|
| Beryl AX | Travel router, VPN gateway | 192.168.8.1 |
| MacBook | Primary workstation | DHCP |
| Phone (mombeu) | Mobile client | DHCP |
| RPi 5 | Pi-hole, Headscale (when traveling) | 192.168.8.5 |

## Resources

- [GL.iNet Product Page](https://www.gl-inet.com/products/gl-mt3000/)
- [Official Docs](https://docs.gl-inet.com/router/en/4/user_guide/gl-mt3000/)
- [GL.iNet Forum](https://forum.gl-inet.com/)
- [OpenWrt Forum Thread](https://forum.openwrt.org/t/i-purchased-a-gl-inet-gl-mt3000-beryl-ax/200757)
- [ServeTheHome Review](https://www.servethehome.com/gl-inet-beryl-ax-gl-mt3000-travel-router-review/)

## Progress Log

### 2026-01-19

- [x] Unbox and initial setup
- [x] Configure WiFi SSID (`mbohapy` / `mbohapy-5G`)
- [x] Set admin password (passphrase style)
- [x] Enable SSH access
- [x] Test USB tethering (Redmi A5 - works)
- [x] Install and configure Tailscale via SSH
- [x] Join Headscale mesh as `beryl-ax`
- [x] Test repeater mode
- [ ] Test WireGuard to VPS
- [ ] Configure AdGuard Home
