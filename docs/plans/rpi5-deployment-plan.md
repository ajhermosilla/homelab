# RPi 5 Deployment Plan

> **Status**: Ready to deploy. PSU purchased Jan 2026. Case: pending 3D print with friend. Plan updated 2026-03-19 with provider strategy and security notes.

Step-by-step guide to deploy the Raspberry Pi 5 as an OpenClaw AI assistant node.

## Overview

OpenClaw is an open-source personal AI assistant gateway (325K+ GitHub stars, MIT license). It runs locally as a thin client, routing messages from 20+ chat platforms (WhatsApp, Telegram, Signal, Discord, etc.) to cloud LLM APIs. Created by Peter Steinberger, acquired by OpenAI in Feb 2026.

**RPi 5 8GB is an excellent fit** — officially supported, ~500MB RAM in gateway mode, leaving 7.5GB free. The Cortex-A76 quad-core handles the gateway workload easily.

**Complementary to PicoClaw on RPi Zero W** — OpenClaw is the full-featured hub (20+ platforms, MCP, voice, browser automation), PicoClaw is the lightweight edge agent (Telegram/Discord, <10MB RAM).

## Hardware Summary

| Component | Model | Notes |
|-----------|-------|-------|
| Board | Raspberry Pi 5 8GB | OpenClaw AI assistant (~500MB RAM usage) |
| Storage | 32GB SDHC Class 10 | Consider USB SSD later for better I/O |
| Cooling | Official Active Cooler | Required for 24/7 operation |
| PSU | Official 27W USB-C (5V/5A) | **Purchased Jan 2026 (Amazon B0D3MFLNC1, ~$30)** |
| Case | TBD | Pending 3D print with friend |
| Power draw | ~5W typical | Much lower than PSU rating |

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

- Login to OPNsense via Tailscale: <https://100.79.230.235>
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

Register free API keys (no credit card needed):

| Provider | URL | Free Limits | Role |
|----------|-----|-------------|------|
| Groq | <https://console.groq.com> | ~14,400 req/day | Primary |
| Google Gemini | <https://aistudio.google.com/apikey> | 250 req/day | Fallback 1 |
| OpenRouter | <https://openrouter.ai/keys> | 200 req/day | Fallback 2 |
| Mistral | <https://console.mistral.ai> | 1B tokens/month | Fallback 3 |

Store all keys in KeePassXC under "Homelab > OpenClaw".

> **Note**: Anthropic blocked subscription OAuth tokens in third-party agents (Feb 2026).
> API keys from Claude Console still work but cost $1-25/M tokens. The free providers
> above give ~15,000+ requests/day at $0/month.

### 5. Dedicated Phone Number (WhatsApp)

Buy a **Personal prepaid SIM** (~10,000 PYG / $1.35, comes with 40K credit) for WhatsApp registration.

**Why Personal over Tigo:** Balances don't expire — lowest maintenance for a bot SIM that only needs occasional keep-alive. Tigo is better for the LTE failover router (always-on, coverage matters).

**Where to buy:** Shopping del Sol (Av. Eusebio Ayala 4599, open Sun 11-20h), or any kiosco/cell phone shop for just the chip. Cedula + fingerprint required.

Setup:

1. Buy Personal SIM at a store
2. Insert in any old phone, register WhatsApp on the new number
3. Link to OpenClaw via QR code on RPi 5
4. Remove SIM — session persists over home Ethernet
5. Store SIM safely, top up ~2,000-5,000 PYG every 2-3 months

> **Security**: Never use this number for 2FA. If WhatsApp bans it, buy a new SIM and re-link.
> See `docs/plans/phone-number-research-2026-03-20.md` and `docs/reference/prepaid-sim-paraguay-2026-03-20.md` for full analysis.

---

## Pre-Deployment Checklist

### Hardware Ready

- [ ] RPi 5 board with active cooler attached
- [ ] 32GB SD card flashed with Pi OS (hostname: rpi5, user: augusto)
- [x] 27W PSU available
- [ ] Ethernet cable to MokerLink switch
- [ ] Dedicated Personal prepaid SIM for WhatsApp (~$1.35)

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

# Configure providers (edit ~/.openclaw/openclaw.json)
# Primary: Groq (fastest, free)
# Fallback: Gemini, OpenRouter, Mistral
# See provider config below

# Connect messaging channels
openclaw channels login

# Test the gateway
openclaw gateway --port 18789
```

### Provider Configuration

Edit `~/.openclaw/openclaw.json`:

```json
{
  "providers": {
    "groq": {
      "api_key": "<GROQ_API_KEY>"
    },
    "google": {
      "api_key": "<GEMINI_API_KEY>"
    },
    "openrouter": {
      "api_key": "<OPENROUTER_API_KEY>"
    },
    "mistral": {
      "api_key": "<MISTRAL_API_KEY>"
    }
  },
  "agents": {
    "defaults": {
      "model": "groq/llama-3.3-70b-versatile",
      "max_tokens": 4096,
      "temperature": 0.7
    }
  }
}
```

Model routing: Groq for quick responses (300+ tok/s), Gemini for complex tasks (1M context), Mistral for code generation.

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

```bash
# RPi 5 - OpenClaw (Tailscale)
Host rpi5
    HostName <rpi5-tailscale-ip>
    User augusto
    IdentityFile ~/.ssh/id_ed25519
```

### 2. Update Ansible Inventory

Edit `ansible/inventory.yml` — replace LAN IP with Tailscale IP for the `rpi5` host.

### 3. Add Uptime Kuma Monitor

Via web UI at <https://status.cronova.dev:>

- **Name:** OpenClaw Gateway
- **Type:** HTTP(s)
- **URL:** <http://<rpi5-tailscale-ip>:18789
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
node --version  # Should be v24.x (or v22.16+)

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

## Security

> **Critical**: OpenClaw had a severe RCE vulnerability (CVE-2026-25253, CVSS 8.8)
> in Feb 2026. Over 40,000 exposed instances found, 63% vulnerable.

### Mandatory security measures

- Always run the latest OpenClaw version
- **Never expose gateway port (18789) publicly** — access via Tailscale only
- UFW: allow 18789 only from Tailscale interface
- Run as unprivileged user (not root)
- The RPi being a dedicated device provides natural isolation

### UFW rules (locked down)

```bash
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow in on tailscale0 to any port 18789
sudo ufw enable
```

---

## Complementary Setup with PicoClaw

| Device | Role | Tool | Platforms | RAM |
|--------|------|------|-----------|-----|
| RPi 5 (8GB) | Full AI hub | OpenClaw | WhatsApp, Signal, Telegram, Discord, 16+ more | ~500MB |
| RPi Zero W (512MB) | Edge agent | PicoClaw | Telegram, Discord | ~10MB |

Both share the same free LLM providers (Groq, Gemini, OpenRouter, Mistral).

---

## Cost

| Item | Cost |
|------|------|
| RPi 5 + cooler | Already owned |
| 27W PSU | $0 (already purchased) |
| 32GB SD card | Already owned |
| Personal prepaid SIM | ~$1.35 one-time (balances don't expire) |
| LLM APIs | $0/month (free tiers) |
| **Total**|**~$1.35 one-time, ~$0/year** (Personal balances don't expire) |

---

## References

- [hardware.md](../architecture/hardware.md) - Full hardware specs
- [mobile-homelab.md](../architecture/mobile-homelab.md) - Mobile kit (RPi 5 migration history)
- [picoclaw-rpi-zero-2026-03-19.md](picoclaw-rpi-zero-2026-03-19.md) - Complementary PicoClaw plan
- `ansible/playbooks/openclaw.yml` - OpenClaw Ansible playbook
- [Raspberry Pi 5 Specs](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [OpenClaw Docs](https://docs.openclaw.ai/)
- [OpenClaw RPi Guide](https://docs.openclaw.ai/platforms/raspberry-pi)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [CVE-2026-25253](https://www.sonicwall.com/blog/openclaw-auth-token-theft-leading-to-rce-cve-2026-25253/) - RCE vulnerability details
