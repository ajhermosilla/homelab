# AI Assistant Strategy — 2026-03-19

Community research on OpenClaw and PicoClaw use cases for homelabs. Based on Reddit (r/selfhosted, r/OpenClaw, r/homelab, r/homeassistant), GitHub discussions, Hacker News, and project documentation.

## Two-Device Strategy

| Device | Tool | Primary Focus | Secondary Focus |
|--------|------|--------------|-----------------|
| RPi Zero W (512MB) | PicoClaw | Personal Telegram assistant | Homelab alert summarization |
| RPi 5 (8GB) | OpenClaw | Family WhatsApp hub | Home Assistant MCP integration (future) |

**Why this split:**

- WhatsApp is the dominant messaging platform in Paraguay — family already uses it
- Telegram for personal/technical use — private assistant for research and homelab
- Both share the same free API keys (Groq, Gemini, OpenRouter, Mistral)
- $0/month running cost, ~$20 total hardware spend

---

## PicoClaw on RPi Zero W — Use Cases

### Primary: Personal Telegram Assistant

- Quick queries and research (web search via DuckDuckGo)
- Spanish/English translation (bilingual household)
- Professional research: supplier lookups, market data, document summarization
- Code snippets and technical questions
- Daily briefing via cron (weather, calendar, homelab status)

### Secondary: Homelab Alert Summarization

- Receive Alertmanager webhooks, enrich with context, forward to ntfy
- One-shot agent mode for ad-hoc queries ("how much disk space is left on NAS?")
- Cron-based infrastructure health summaries

### What it can't do

- WhatsApp (not supported — only Telegram, Discord, QQ, DingTalk)
- Voice control
- Browser automation
- Home Assistant integration (ARMv6 too limited for HA add-on)

---

## OpenClaw on RPi 5 — Use Cases

### Primary: Family WhatsApp Hub

- Family WhatsApp group with AI bot responding to @mentions
- Shared grocery/shopping lists via chat commands
- Recipe suggestions and meal planning
- Homework help for kids
- Real-time translation in group chat (Spanish/English)
- Daily weather/calendar briefings via cron
- Pairing mode for DM access control (unknown senders get pairing code)

### Secondary: Multi-Channel Unification

- One assistant across WhatsApp + Telegram + Signal + Discord
- Browser automation for web research
- Document summarization via browser tool
- Email drafting through Gmail Pub/Sub integration
- Webhook receiver for Alertmanager alert enrichment

### Future: Home Assistant MCP Integration

Three integration paths exist (all early-stage):

| Project | Stars | Approach | Status |
|---------|-------|----------|--------|
| techartdev/OpenClawHomeAssistant | 334 | HA add-on running OpenClaw gateway | Most mature |
| ddrayne/openclaw-homeassistant | 35 | OpenClaw as voice provider for HA Assist | Voice-focused |
| traceless929/HaPicoClaw | 7 | PicoClaw + HA MCP Server bridge | Very new (Mar 2026) |

**Recommendation:** Wait for v1.0 of both OpenClaw and the HA integration before investing time. Use HA native Assist for voice control — it's faster (sub-second vs 5-30s AI latency).

---

## Provider Strategy ($0/month)

Shared across both instances:

| Priority | Provider | Model | Free Limits | Best For |
|----------|----------|-------|-------------|----------|
| Primary | Groq | Llama 3.3 70B | ~14,400 req/day | Quick responses (300+ tok/s) |
| Fallback 1 | Google Gemini | 2.5 Flash | 250 req/day, 1M context | Complex reasoning |
| Fallback 2 | OpenRouter | Free router | 200 req/day | Diverse model pool |
| Fallback 3 | Mistral | Small 3.1 | 1B tokens/month, 2 RPM | Code generation |

Combined: ~15,000+ requests/day at zero cost.

---

## What the Community Says NOT to Do

### Overengineering

- **Don't build auto-healing infrastructure** — AI agents restarting services, scaling containers, or modifying configs without human approval. Multiple horror stories of feedback loops making things worse.
- **Don't replace Grafana with conversational queries** — people try it, find it slower and less informative, go back to dashboards within a week.
- **Don't set up too many channels at once** — start with ONE (Telegram or WhatsApp), get it solid, then expand.

### Security

- **Never expose gateway ports publicly** — OpenClaw :18789 and PicoClaw :18790 have minimal built-in auth. Use Tailscale or VPN only.
- **Don't mount Docker socket into AI containers** — gives AI root-equivalent access.
- **Don't run PicoClaw pre-v1.0 on untrusted networks** — explicit security warning from the project.
- OpenClaw had critical RCE (CVE-2026-25253) in Feb 2026 — always run latest version.

### Practical Failures

- **Voice control via AI for simple commands** — too slow (5-30s). Use HA native Assist for "turn on lights", AI for complex queries only.
- **Local LLMs on RPi** — too slow for interactive use. RPi 5 can't run meaningful models. Docker VM's N150 iGPU could handle Qwen3 8B (~5 tok/s CPU) but it's not a good experience.
- **Multi-agent architectures** — tooling not mature. Most homelabbers run single agent. Agent-to-agent handoff doesn't work well yet.
- **Frigate + AI integration** — no mature tooling exists. The community approach (Frigate MQTT → HA automation → AI notification) works but is cobbled together.

---

## Deployment Order

| Phase | What | When | Cost | Time |
|-------|------|------|------|------|
| 1 | PicoClaw on RPi Zero W | After $8 microSD purchase | $8 | 65 min |
| 2 | OpenClaw on RPi 5 | After $12 PSU + $1.35 SIM purchase | $13 | 30 min |
| 3 | HA MCP integration | When projects reach v1.0 | $0 | TBD |

Total: ~$21 hardware, $0/month ongoing.

### SIM Strategy

| SIM | Carrier | Purpose | Why |
|-----|---------|---------|-----|
| Bot SIM | **Personal** | OpenClaw WhatsApp | Balances don't expire |
| LTE SIM | **Tigo** | TL-MR100 failover router | Best coverage |

Both available at Shopping del Sol or kioscos. ~$2 total.
See `phone-number-research-2026-03-20.md` and `../reference/prepaid-sim-paraguay-2026-03-20.md`.

---

## Privacy Architecture

```text
[Family WhatsApp]                    [Personal Telegram]
       │                                     │
       ▼                                     ▼
┌──────────────┐                    ┌─────────────────┐
│   RPi 5      │                    │   RPi Zero W    │
│   OpenClaw   │                    │   PicoClaw      │
│   (gateway)  │                    │   (gateway)     │
└──────┬───────┘                    └────────┬────────┘
       │                                     │
       └──────────────┬──────────────────────┘
                      │
              ┌───────▼────────┐
              │  Tailscale     │
              │  mesh (LAN)    │
              └───────┬────────┘
                      │
         ┌────────────┼────────────┐
         ▼            ▼            ▼
   ┌──────────┐  ┌─────────┐  ┌────────┐
   │ Groq API │  │ Gemini  │  │ Ollama │
   │ (primary)│  │ (fb #1) │  │ (local │
   │  FREE    │  │  FREE   │  │  fb)   │
   └──────────┘  └─────────┘  └────────┘
```

- All gateway processing runs locally on the RPis
- Only LLM API calls leave the network
- Conversation history stored on local SD cards
- Tailscale mesh for inter-device communication
- No ports exposed to public internet

---

## References

- [OpenClaw GitHub](https://github.com/openclaw/openclaw) (325K stars)
- [PicoClaw GitHub](https://github.com/sipeed/picoclaw) (25.5K stars)
- [OpenClaw HA Add-on](https://github.com/techartdev/OpenClawHomeAssistant) (334 stars)
- [PicoClaw HA Add-on](https://github.com/traceless929/HaPicoClaw) (7 stars)
- [OpenClaw RPi Guide](https://docs.openclaw.ai/platforms/raspberry-pi)
- [PicoClaw Deployment Plan](picoclaw-rpi-zero-2026-03-19.md)
- [RPi 5 Deployment Plan](rpi5-deployment-plan.md)
- [CVE-2026-25253 — OpenClaw RCE](https://www.sonicwall.com/blog/openclaw-auth-token-theft-leading-to-rce-cve-2026-25253/)
