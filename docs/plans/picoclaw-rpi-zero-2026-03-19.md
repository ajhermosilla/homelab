# PicoClaw on Raspberry Pi Zero W — Deployment Plan

**Date**: 2026-03-19
**Hardware**: Raspberry Pi Zero W v1.3 (purchased May 2021, unused)
**Goal**: Always-on, near-zero-power AI assistant accessible via Telegram

---

## Overview

PicoClaw is an ultra-lightweight AI assistant by Sipeed (<10MB RAM, single Go binary). It connects to remote LLM APIs (Claude, OpenAI, etc.) and interfaces via chat platforms (Telegram, Discord). The RPi Zero W runs it as a thin client — all AI processing happens remotely.

---

## Prerequisites

### Hardware

- [x] Raspberry Pi Zero W v1.3
- [ ] MicroSD card (32GB recommended, A1/A2 rated — Samsung EVO Select or SanDisk Extreme)
- [ ] Micro-USB power supply (5V/1.2A+ — any phone charger or USB port on NAS)
- [ ] Micro-USB OTG adapter (for initial setup if needed, optional with WiFi)

### Accounts (all free, no credit card)

- [ ] Telegram bot — create via @BotFather, get bot token
- [ ] Groq API key — <https://console.groq.com> (primary)
- [ ] Google Gemini API key — <https://aistudio.google.com/apikey> (fallback 1)
- [ ] OpenRouter API key — <https://openrouter.ai/keys> (fallback 2)
- [ ] Mistral API key — <https://console.mistral.ai> (fallback 3)

### Network

- Home WiFi SSID and password (2.4GHz only)
- Optional: assign static IP in OPNsense DHCP (e.g., 192.168.0.25)
- Optional: join Tailscale mesh for remote SSH

---

## Phase 1 — OS Installation (15 min)

### Option A: DietPi (recommended)

1. Download DietPi ARMv6 image: <https://dietpi.com/#downloadinfo>
2. Flash to microSD with Balena Etcher or `dd`
3. Before first boot, edit on the SD card:
   - `dietpi.txt`: set `AUTO_SETUP_NET_WIFI_ENABLED=1`
   - `dietpi-wifi.txt`: add SSID and password
   - `dietpi.txt`: set `AUTO_SETUP_LOCALE_NAME=en_US.UTF-8`
   - `dietpi.txt`: set `AUTO_SETUP_TIMEZONE=America/Asuncion`
4. Insert SD, power on, wait ~5 min for first boot
5. SSH in: `ssh root@<ip>` (default password: `dietpi`)
6. Complete initial setup (change password, minimal install)

### Option B: Raspberry Pi OS Lite (alternative)

1. Use Raspberry Pi Imager, select "Raspberry Pi OS Lite (32-bit)"
2. Configure WiFi, SSH, username in Imager settings
3. Flash, boot, SSH in

---

## Phase 2 — System Hardening (10 min)

```bash
# Update system
apt update && apt upgrade -y

# Create picoclaw user
useradd -m -s /bin/bash picoclaw

# Enable tmpfs for logs (reduce SD card wear)
echo "tmpfs /var/log tmpfs defaults,noatime,nosuid,size=30m 0 0" >> /etc/fstab
echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=50m 0 0" >> /etc/fstab

# Reduce GPU memory (headless, no display needed)
echo "gpu_mem=16" >> /boot/config.txt

# Disable unnecessary services
systemctl disable bluetooth hciuart triggerhappy

# Reboot
reboot
```

---

## Phase 3 — PicoClaw Installation (5 min)

```bash
# Download ARMv6 binary from latest release
PICOCLAW_VERSION="0.2.3"
wget "https://github.com/sipeed/picoclaw/releases/download/v${PICOCLAW_VERSION}/picoclaw_${PICOCLAW_VERSION}_linux_armv6.tar.gz"
tar xzf picoclaw_*.tar.gz
mv picoclaw /usr/local/bin/
chmod +x /usr/local/bin/picoclaw

# Verify
picoclaw --version

# Initialize config
su - picoclaw -c "picoclaw onboard"
```

---

## Phase 4 — Configuration (10 min)

### Provider Strategy ($0/month)

Anthropic blocked subscription OAuth tokens in third-party agents (Feb 2026). API keys
still work but cost $1-25/M tokens. Instead, use free providers with failover:

| Priority | Provider | Model | Free Limits | Why |
|----------|----------|-------|-------------|-----|
| Primary | Groq | Llama 3.3 70B | ~14,400 req/day | Fastest (300+ tok/s), GPT-4 quality, tool calling |
| Fallback 1 | Google Gemini | 2.5 Flash | 250 req/day | Best quality, 1M context |
| Fallback 2 | OpenRouter | Free router | 200 req/day | Auto-selects best free model |
| Fallback 3 | Mistral | Small 3.1 | 1B tokens/month, 2 RPM | Huge quota, slow RPM |

### Get API keys (free, no credit card)

1. **Groq**: <https://console.groq.com> → API Keys → Create
2. **Google Gemini**: <https://aistudio.google.com/apikey> → Create API key
3. **OpenRouter**: <https://openrouter.ai/keys> → Create Key (select free models only)
4. **Mistral**: <https://console.mistral.ai> → API Keys → Create

### Edit config

Edit `~picoclaw/.picoclaw/config.json`:

```json
{
  "agents": {
    "defaults": {
      "model": "groq/llama-3.3-70b-versatile",
      "max_tokens": 4096,
      "temperature": 0.7,
      "max_tool_iterations": 10,
      "restrict_to_workspace": true
    }
  },
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
  "channels": {
    "telegram": {
      "bot_token": "<TELEGRAM_BOT_TOKEN>",
      "allowed_users": ["<your_telegram_user_id>"]
    }
  },
  "tools": {
    "web": {
      "provider": "duckduckgo"
    }
  }
}
```

### Model routing (cost optimization)

PicoClaw supports rule-based model routing. For heavier tasks, fall back to
higher-quality models:

- Quick questions → `groq/llama-3.3-70b-versatile` (fast, free)
- Complex reasoning → `google/gemini-2.5-flash` (1M context, free)
- Code generation → `mistral/codestral-latest` (free, 2 RPM)

### Optional: local fallback (internet outage)

If you have Ollama on Docker VM:

```json
{
  "providers": {
    "ollama": {
      "base_url": "http://192.168.0.10:11434/v1",
      "api_key": "ollama"
    }
  }
}
```

Model: `ollama/qwen3:8b` (~5GB RAM, CPU-only ~5 tok/s, tool calling works)

---

## Phase 5 — Systemd Service (5 min)

```bash
cat > /etc/systemd/system/picoclaw.service << 'EOF'
[Unit]
Description=PicoClaw AI Assistant
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=picoclaw
ExecStart=/usr/local/bin/picoclaw
Restart=always
RestartSec=10
Environment=HOME=/home/picoclaw

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable picoclaw
systemctl start picoclaw
```

---

## Phase 6 — Verification (5 min)

```bash
# Check service status
systemctl status picoclaw

# Check RAM usage
ps aux | grep picoclaw

# Check logs
journalctl -u picoclaw -f

# Test: send a message to your Telegram bot
# It should respond via the configured LLM
```

---

## Phase 7 — Integration with Homelab (optional)

### Join Tailscale mesh

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --login-server=https://hs.cronova.dev --accept-dns=false
```

### Add to monitoring

- Add node-exporter or Telegraf for metrics to VictoriaMetrics
- Add Uptime Kuma monitor for PicoClaw health

### Guarani name

Following the naming convention: **Ñe'ẽ** (ñe'ẽ = "word/speech" in Guarani) — fitting for an AI assistant that speaks.

---

## Power and Placement

- Power from NAS USB port (always on, no extra power supply)
- Or dedicated 5V/1.2A micro-USB charger
- Place near WiFi AP for best signal
- No case needed if mounted inside rack/shelf (tiny form factor)

---

## Cost

| Item | Cost |
|------|------|
| RPi Zero W | $0 (already owned) |
| 32GB microSD | ~$8 |
| Micro-USB cable | ~$2 (or reuse) |
| LLM API (Groq/Gemini/OpenRouter/Mistral) | $0/month (free tiers) |
| Web search (DuckDuckGo) | $0/month |
| **Total**|**~$10 one-time, $0/month** |

Combined free API budget: ~15,000+ requests/day across all providers.

---

## Risks

- ARMv6 support declining — PicoClaw may drop ARMv6 in future versions
- WiFi 2.4GHz only — susceptible to interference
- SD card wear — mitigated by tmpfs for logs
- Pre-v1.0 software — expect breaking changes between versions
- Single point of failure — no redundancy (acceptable for a personal assistant)

---

## Timeline

| Phase | Time | When |
|-------|------|------|
| 1. OS installation | 15 min | At home |
| 2. System hardening | 10 min | At home |
| 3. PicoClaw install | 5 min | At home |
| 4. Configuration | 10 min | At home |
| 5. Systemd service | 5 min | At home |
| 6. Verification | 5 min | At home |
| 7. Homelab integration | 15 min | At home |
| **Total**|**~65 min** | |

Blocked on: microSD card purchase (~$8).
