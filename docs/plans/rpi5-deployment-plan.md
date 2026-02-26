# RPi 5 Deployment Plan

Step-by-step guide to deploy the Raspberry Pi 5 as an OpenClaw AI assistant node.

## Hardware Summary

| Component | Model | Notes |
|-----------|-------|-------|
| Board | Raspberry Pi 5 8GB | OpenClaw AI assistant |
| Storage | 32GB SDHC Class 10 | Consider NVMe HAT later |
| Cooling | Official Active Cooler | Required for 24/7 operation |
| PSU | Official 27W USB-C | In transit (Miami -> Asuncion) |
| Case | TBD | See `docs/rpi5-case-research.md` |

---

## Remote Preparation (Before Physical Access)

Complete these tasks remotely before the deployment day:

### 1. Generate Tailscale Auth Key

```bash
# SSH to VPS
ssh vps

# Generate pre-auth key (expires in 1 hour, single use)
docker exec headscale headscale preauthkeys create --expiration 1h

# Save the key! You'll need it during RPi 5 setup
```

### 2. Add OPNsense DHCP Reservation

- Login to OPNsense via Tailscale: https://100.79.230.235
- Services > DHCPv4 > LAN
- Add reservation: MAC -> 192.168.0.20 (get MAC from RPi 5 board sticker)

### 3. Flash Raspberry Pi OS to SD Card

```bash
# Use Raspberry Pi Imager on MacBook
# Settings:
#   OS: Raspberry Pi OS Lite (64-bit, Debian Bookworm)
#   Hostname: rpi5
#   Username: augusto
#   Enable SSH (password authentication initially)
#   WiFi: skip (Ethernet only)
#   Locale: America/Asuncion
```

### 4. Pre-generate Credentials

```bash
# OpenClaw API keys (Anthropic, OpenAI, etc.)
# Store in Vaultwarden before going home
```

---

## Pre-Deployment Checklist

### Hardware Ready
- [ ] RPi 5 board with active cooler attached
- [ ] 32GB SD card flashed with Pi OS (hostname: rpi5, user: augusto)
- [ ] 27W PSU available
- [ ] Ethernet cable to MokerLink switch

### Network Ready
- [ ] MokerLink switch port available
- [ ] OPNsense DHCP reservation: 192.168.0.20 -> RPi 5 MAC
- [ ] Pi-hole DNS entry: rpi5.home -> 192.168.0.20

### Software Ready
- [ ] Tailscale auth key from Headscale (generate day-of, 1h expiry)
- [ ] OpenClaw API keys saved in Vaultwarden

---

## On-Site Deployment (~20-30 min)

### Step 1: Physical Setup

1. Insert flashed SD card into RPi 5
2. Connect Ethernet cable to MokerLink switch
3. Connect 27W PSU
4. Wait for boot (~60 seconds)

### Step 2: Initial SSH Access

```bash
# Copy SSH key (from MacBook)
ssh-copy-id augusto@192.168.0.20

# Verify key-based login
ssh rpi5
```

### Step 3: Run Ansible Playbooks (in order)

```bash
cd ~/homelab/ansible

# 1. Tailscale first (mesh connectivity = backup access)
ansible-playbook -i inventory.yml playbooks/tailscale.yml -l rpi5

# 2. Common setup (base packages, UFW, disables password auth)
ansible-playbook -i inventory.yml playbooks/common.yml -l rpi5

# 3. OpenClaw (Node.js + OpenClaw)
ansible-playbook -i inventory.yml playbooks/openclaw.yml -l rpi5
```

### Step 4: OpenClaw Initial Setup

```bash
# SSH into RPi 5
ssh rpi5

# Run onboarding wizard
openclaw onboard --install-daemon

# Configure API keys (Anthropic, OpenAI, etc.)
# Follow the interactive prompts

# Connect messaging channels
openclaw channels login

# Test the gateway
openclaw gateway --port 18789
```

### Step 5: Enable Systemd Service

```bash
# Enable and start OpenClaw as a service
sudo systemctl enable --now openclaw

# Verify it's running
sudo systemctl status openclaw
```

---

## Verification

### SSH via Tailscale

```bash
# After Tailscale enrollment, update SSH config with Tailscale IP
# Then verify:
ssh rpi5
```

### OpenClaw Gateway

```bash
# From RPi 5
curl http://localhost:18789

# From another Tailscale node
curl http://<rpi5-tailscale-ip>:18789
```

### UFW Rules

```bash
# Expected rules:
sudo ufw status

# Should show:
# 22/tcp    ALLOW  Anywhere
# 18789/tcp ALLOW  Anywhere
# Anywhere on tailscale0 ALLOW  Anywhere
```

### Service Survives Reboot

```bash
sudo reboot

# Wait ~60 seconds, then:
ssh rpi5
sudo systemctl status openclaw
curl http://localhost:18789
```

---

## Post-Deployment

### 1. Update SSH Config with Tailscale IP

Edit `~/.ssh/config` on MacBook:

```
# RPi 5 - OpenClaw (Tailscale)
Host rpi5
    HostName <rpi5-tailscale-ip>
    User augusto
    IdentityFile ~/.ssh/id_ed25519
```

### 2. Update Ansible Inventory

Edit `ansible/inventory.yml` — replace LAN IP with Tailscale IP for the `rpi5` host.

### 3. Add Uptime Kuma Monitor

Via web UI at https://status.cronova.dev:
- **Name:** OpenClaw Gateway
- **Type:** HTTP(s)
- **URL:** http://<rpi5-tailscale-ip>:18789
- **Interval:** 60s

### 4. Update Hardware Doc

In `docs/architecture/hardware.md`, change RPi 5 status from "Pending setup" to "Active".

### 5. Add Pi-hole DNS Entry

```bash
# SSH to docker-vm, edit Pi-hole config
ssh docker-vm
docker exec -it pihole bash

# Add DNS entry in /etc/pihole/pihole.toml under dns.hosts:
# { addr = "192.168.0.20", names = ["rpi5.home"] }

pihole reloaddns
```

---

## Troubleshooting

### RPi 5 Not Booting

```bash
# Check LED status:
# - Solid red: power OK
# - Blinking green: SD card activity
# - No green blink: SD card not detected or bad image

# Re-flash SD card if needed
# Try a different SD card
```

### Can't SSH

```bash
# Verify RPi 5 got DHCP lease
# Check OPNsense: Services > DHCPv4 > Leases

# Try direct IP
ssh augusto@192.168.0.20

# If password auth disabled too early, need keyboard+monitor
```

### OpenClaw Won't Start

```bash
# Check Node.js
node --version  # Should be v22.x

# Check OpenClaw
openclaw --version

# Check service logs
journalctl -u openclaw -f

# Try running manually
openclaw gateway --port 18789
```

### Tailscale Won't Connect

```bash
# Check status
tailscale status

# Re-authenticate (get new key from Headscale)
ssh vps
docker exec headscale headscale preauthkeys create --expiration 1h

# On RPi 5
sudo tailscale up --login-server=https://hs.cronova.dev --authkey=<new-key> --reset
```

---

## Rollback Plan

If something goes wrong:

1. **OpenClaw issues:** `sudo systemctl restart openclaw` or reinstall via Ansible
2. **OS issues:** Re-flash SD card (no persistent data on RPi 5)
3. **Network issues:** Connect keyboard+monitor, check `/etc/network/` config
4. **Tailscale issues:** Re-enroll with new auth key

---

## Time Estimate

| Phase | Estimate |
|-------|----------|
| Physical setup | 5 min |
| SSH + key copy | 2 min |
| Ansible playbooks | 10-15 min |
| OpenClaw setup | 5-10 min |
| Verification | 5 min |
| **Total** | ~20-30 min |

---

## References

- [hardware.md](../architecture/hardware.md) - Full hardware specs
- [mobile-homelab.md](../architecture/mobile-homelab.md) - Mobile kit (RPi 5 migration history)
- [ansible/playbooks/openclaw.yml](../../ansible/playbooks/openclaw.yml) - OpenClaw Ansible playbook
- [Raspberry Pi 5 Specs](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [OpenClaw Docs](https://docs.openclaw.ai/)
