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
- [~] **WireGuard VPN client** - Optional, use Tailscale exit node instead
- [x] **Tailscale** - Joined Headscale mesh as `beryl-ax`
- [x] **AdGuard Home** - Primary DNS ad-blocking for mobile kit
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

GL.iNet UI doesn't expose custom server option. Use SSH instead.

**Important:** Use a pre-auth key to avoid ephemeral node timeout (30min idle = disconnect).

```bash
# 1. Create pre-auth key on VPS (1 year expiration)
ssh vps 'sudo docker exec headscale headscale preauthkeys create --user 1 --reusable --expiration 8760h'

# 2. SSH to Beryl
ssh root@192.168.8.1

# 3. Connect with authkey (persistent registration)
tailscale up --login-server=https://hs.cronova.dev --hostname=beryl-ax --authkey=<KEY> --accept-routes --accept-dns=false
```

**If disconnected/logged out**, reset and re-register:
```bash
tailscale down
tailscale logout
tailscale up --login-server=https://hs.cronova.dev --hostname=beryl-ax --authkey=<KEY> --accept-routes --accept-dns=false
```

Verify:
```bash
tailscale status
```

### Exit Node (On-Demand VPN)

Use Tailscale exit node instead of WireGuard - easier to toggle, same benefit.

```bash
# Enable exit node (route all traffic through VPS)
tailscale set --exit-node=vps-vultr

# Disable exit node (direct connection)
tailscale set --exit-node=
```

**When to use:**
- Untrusted WiFi (hotels, cafes)
- Need US IP for geo-restricted content

**When NOT to use:**
- Local banking (homebanking rejects VPS IPs)
- Local streaming services
- Normal browsing (adds latency)

### DNS Strategy (Dual-DNS)

Mobile kit uses two DNS ad-blockers for redundancy:

| Device | Role | Why |
|--------|------|-----|
| Beryl AX | AdGuard Home (primary) | Built-in, lightweight, always on with router |
| RPi 5 | Pi-hole (secondary) | Full-featured, but RPi 5 may be used for tinkering |

**Setup:**
1. Enable AdGuard Home: Applications > AdGuard Home
2. Configure upstream DNS (Cloudflare/Quad9)
3. Optional: Add RPi 5 Pi-hole as fallback DNS in DHCP settings

### Travel Kit Configuration

```
[Hotel WiFi] --> [Beryl AX (Repeater)] --> [Your Devices]
                      |
                      +--> AdGuard Home (primary DNS, ad blocking)
                      +--> Tailscale mesh (homelab access)
                      +--> WireGuard to VPS (optional, encrypted exit)
                      +--> RPi 5 Pi-hole (fallback DNS, when available)
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
| Beryl AX | Travel router, AdGuard Home (primary DNS) | 192.168.8.1 |
| MacBook | Primary workstation | DHCP |
| Phone (mombeu) | Mobile client | DHCP |
| RPi 5 | Pi-hole (secondary DNS), tinkering | 192.168.8.5 |

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
- [x] Configure AdGuard Home
