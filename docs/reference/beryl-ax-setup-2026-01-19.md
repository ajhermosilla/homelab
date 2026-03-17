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
3. Access admin panel: <https://192.168.8.1> (accept self-signed cert warning)
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

- Admin panel: <https://192.168.8.1> (HTTP also works)
- LAN subnet: `192.168.8.0/24`
- DHCP range: `192.168.8.100-200`

**Note:** HTTPS uses self-signed certificate - browser warning is normal and safe to accept on LAN

## Phase 2: Firmware Options

| Option | Base | Pros | Cons |
|--------|------|------|------|

| **Stock GL.iNet** | OpenWrt 21.02 | Easy UI, VPN presets, toggle switch | Older kernel |
| **GL.iNet Open Source** | OpenWrt 23.05 | Latest kernel, open WiFi drivers | May lose some GL features |
| **Vanilla OpenWrt** | OpenWrt 23.05.x | Full control, latest packages | Flashing issues, no GL.iNet UI |

### Firmware URLs

- Stock: <https://www.gl-inet.com/support/firmware-versions/>
- Open Source: <https://forum.gl-inet.com/t/mt3000-beryl-ax-open-source-wifi-driver-firmware/36607>
- Vanilla OpenWrt: <https://firmware-selector.openwrt.org> (mediatek/filogic, glinet_gl-mt3000)

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

# 4. Enable auto-start (survives reboots)
/etc/init.d/tailscale enable
```

**If disconnected/logged out**, reset and re-register:

```bash
tailscale down
tailscale logout
tailscale up --login-server=https://hs.cronova.dev --hostname=beryl-ax --authkey=<KEY> --accept-routes --accept-dns=false
/etc/init.d/tailscale enable
```

Verify:

```bash
tailscale status
/etc/init.d/tailscale enabled && echo "Auto-start enabled" || echo "Not enabled"
```

### Exit Node (On-Demand VPN)

Use Tailscale exit node instead of WireGuard - easier to toggle, same benefit.

```bash
# Enable exit node (route all traffic through VPS)
tailscale set --exit-node=vps-vultr

# Disable exit node (direct connection)
tailscale set --exit-node=
```

#### When to use

- Untrusted WiFi (hotels, cafes)
- Need US IP for geo-restricted content

#### When NOT to use

- Local banking (homebanking rejects VPS IPs)
- Local streaming services
- Normal browsing (adds latency)

### DNS Strategy (Dual-DNS)

Mobile kit uses two DNS ad-blockers for redundancy:

| Device | Role | Why |
|--------|------|-----|

| Beryl AX | AdGuard Home (primary) | Built-in, lightweight, always on with router |
| RPi 5 | Pi-hole (secondary) | Full-featured, but RPi 5 may be used for tinkering |

#### Setup

1. Enable AdGuard Home: Applications > AdGuard Home
2. Configure upstream DNS (Cloudflare/Quad9)
3. Optional: Add RPi 5 Pi-hole as fallback DNS in DHCP settings

### Travel Kit Configuration

```json
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

## Security Baseline

**Hardened:** 2026-01-19

### Access Control

| Service | Port | Bind Address | WAN Access | Status |
|---------|------|--------------|------------|--------|

| SSH | 22 | 192.168.8.1 | Blocked | ✓ LAN-only |
| Admin UI | 80, 443 | 0.0.0.0 | Blocked (firewall) | ✓ Secured |
| Admin UI | 8080, 8443 | 127.0.0.1 | N/A | ✓ Localhost |
| AdGuard Home | 3000 | 192.168.8.1 | Blocked | ✓ LAN-only |
| AdGuard DNS | 3053 | 0.0.0.0 | Blocked (firewall) | ✓ Secured |

### Firewall Rules

```text
WAN → Default DROP policy
LAN → ACCEPT (trusted)
Tailscale → ACCEPT (trusted)
```

**Critical:** All WAN traffic hits `zone_wan_src_DROP` - default deny.

### Authentication

| Component | Method | Status |
|-----------|--------|--------|

| Admin UI | Password | Set (KeepassXC) |
| SSH | Password | Active (LAN-only, Tailscale OK) |
| AdGuard Home | None | No login configured |

**TODO:** Add SSH key authentication, disable password.

### Firmware

| Component | Version | Date Checked |
|-----------|---------|--------------|

| GL.iNet Firmware | 4.8.1 | 2026-01-19 |
| OpenWrt | 21.02-SNAPSHOT | 2026-01-19 |

**Status:** Up to date (no updates available)

#### Check for updates

- Web UI: System > Upgrade > Online Upgrade
- Or: <https://dl.gl-inet.com/firmware/mt3000/release/>

### Security Commands Reference

```bash
# Verify SSH is LAN-only
netstat -tuln | grep :22
# Should show: 192.168.8.1:22

# Verify AdGuard is LAN-only
netstat -tuln | grep :3000
# Should show: 192.168.8.1:3000

# Check WAN firewall (should DROP all)
iptables -L zone_wan_input -n -v

# Check Tailscale auto-start
/etc/init.d/tailscale enabled && echo "OK" || echo "FAILED"
```

### Threat Model

#### Trusted networks

- LAN (192.168.8.0/24) - your devices
- Tailscale mesh (100.x.x.x) - your homelab

#### Untrusted networks

- WAN (hotel WiFi, cafe, tethering) - hostile

#### Defense in depth

1. Firewall blocks all WAN ports by default
2. Services bind to LAN IP only (SSH, AdGuard)
3. Localhost-only for sensitive services (uhttpd)
4. Tailscale provides secure remote access

## Backup & Recovery

### Create Backup

#### Via SSH (recommended)

```bash
# 1. SSH to Beryl AX
ssh root@192.168.8.1

# 2. Create backup with timestamp
sysupgrade -b /tmp/beryl-ax-backup-$(date +%Y%m%d-%H%M).tar.gz

# 3. Exit SSH
exit

# 4. Copy to MacBook (from MacBook terminal)
mkdir -p ~/homelab/backups/beryl-ax
scp -O root@192.168.8.1:/tmp/beryl-ax-backup-*.tar.gz ~/homelab/backups/beryl-ax/

# 5. Verify backup
ls -lh ~/homelab/backups/beryl-ax/
tar -tzf ~/homelab/backups/beryl-ax/beryl-ax-backup-*.tar.gz | head -10
```

#### What's backed up

- Network settings (WiFi, DHCP, DNS)
- Firewall rules
- Tailscale configuration
- AdGuard Home settings
- Admin passwords
- SSH configuration

#### NOT backed up

- Firmware itself
- AdGuard Home logs/statistics
- DHCP leases

### Restore from Backup

#### If router is reset or bricked

```bash
# 1. Copy backup to router
scp -O ~/homelab/backups/beryl-ax/beryl-ax-backup-*.tar.gz root@192.168.8.1:/tmp/

# 2. SSH and restore
ssh root@192.168.8.1
sysupgrade -r /tmp/beryl-ax-backup-*.tar.gz

# Router will reboot with restored settings
```

#### After restore

- Verify Tailscale: `tailscale status`
- Verify AdGuard: `netstat -tuln | grep 3000`
- Verify SSH: `netstat -tuln | grep :22`

### Backup Schedule

| When | Why |
|------|-----|

| Before travel | Pre-trip safety net |
| After config changes | Capture new settings |
| Weekly during heavy use | Prevent data loss |

#### Storage

- Local: `~/homelab/backups/beryl-ax/`
- Optional: Commit to git (contains passwords - use SOPS if sharing)
- Optional: Upload to Vaultwarden as attachment

**Latest backup:** `beryl-ax-backup-20260119-1538.tar.gz` (40KB)

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
