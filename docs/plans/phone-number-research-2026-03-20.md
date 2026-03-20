# Phone Number Research for PicoClaw & OpenClaw

**Date**: 2026-03-20
**Context**: Privacy, security, and practical considerations for AI assistant phone numbers in Paraguay.

---

## 1. Do PicoClaw and OpenClaw Require Phone Numbers?

### PicoClaw (Telegram)

**No dedicated phone number needed.**

Telegram bots are special accounts that do not require a phone number. You create a bot via @BotFather, receive a bot token, and that token is all PicoClaw needs. The bot operates independently of any phone number.

However, **you need a personal Telegram account** (which requires a phone number) to:
- Message @BotFather and create the bot
- Interact with the bot as a user

Your personal number is never exposed to the bot or its users. The bot communicates via its token, not a phone number. PicoClaw connects as a bot, not as a user account.

**Verdict**: Use your existing Telegram account. No second number needed.

### OpenClaw (WhatsApp, Signal, Telegram, Discord)

| Platform | Phone Number Required? | Notes |
|----------|----------------------|-------|
| WhatsApp | **Yes** — must link a WhatsApp account | Uses Baileys (reverse-engineered WhatsApp Web protocol) |
| Signal | **Yes** — needs SMS verification | Requires signal-cli + captcha verification |
| Telegram | **No** — uses Bot API (same as PicoClaw) | Official bot accounts, no ToS risk |
| Discord | **No** — uses bot token | Username-based auth, no phone needed |

**WhatsApp is the critical one.** OpenClaw connects via QR code linking (like WhatsApp Web), which requires an active WhatsApp account tied to a phone number. The OpenClaw docs explicitly recommend using a separate number.

---

## 2. WhatsApp Business API vs Personal WhatsApp

### OpenClaw's Default Method: Baileys Library

OpenClaw uses Baileys, an open-source reverse-engineered implementation of the WhatsApp Web multi-device protocol. This means:

- It emulates a linked device (like WhatsApp Web)
- **No Meta approval needed** — just scan a QR code
- **Free** — no per-conversation charges
- **Violates Meta's Terms of Service** — running automation on WhatsApp is explicitly prohibited

### WhatsApp Business API (Official)

The official alternative requires:
- Meta Business Manager account with verification (3 days to 2 weeks)
- A dedicated phone number (cannot be shared with regular WhatsApp)
- Per-conversation charges
- Number is permanently locked to the Business API — cannot switch back to regular WhatsApp

There is an OpenClaw plugin (`openclaw-kapso-whatsapp`) that uses the official Meta Cloud API via Kapso, with no ban risk. However, it adds complexity and cost.

### Can You Use Your Personal WhatsApp Number?

**Technically yes, but strongly discouraged.** Risks:

1. **Account suspension** — Meta actively detects automation patterns
2. **Data exposure** — OpenClaw stores messages and logs on disk, including your personal chats
3. **Self-chat confusion** — bot responses mix with personal conversations
4. **If banned, you lose everything** — your personal WhatsApp history, groups, contacts

### What Happens If You Use Your Personal Number

OpenClaw connects as a linked device. It can see and respond to all your chats (filtered by allowlists). If Meta detects automated behavior, your entire WhatsApp account gets suspended — not just the linked device.

---

## 3. Privacy Risks of Using Personal Numbers

### Telegram

- Telegram uses server-side encryption by default (not E2E except in Secret Chats)
- Your phone number is visible to contacts (configurable in privacy settings)
- **For PicoClaw**: Your personal number is NOT exposed because you use a bot token, not a user account. The bot never knows your phone number unless you explicitly share it.

### WhatsApp

WhatsApp collects extensive metadata even though messages are E2E encrypted:
- Your phone number and recipients' numbers
- Timestamps, frequency, and duration of communications
- IP address (reveals location)
- Device information (model, OS, app version)
- Contact list (uploaded in hashed form)
- Online/last-seen status, group memberships
- Call and media metadata

This metadata is shared with Meta. A dedicated number limits the metadata footprint — Meta only sees the bot's communication patterns, not your personal ones.

### Signal

- Minimal metadata collection (nonprofit, no advertising model)
- E2E encryption by default
- Phone number required for registration but not shared with contacts by default
- Best privacy profile of all platforms

### Can the AI Assistant Leak Your Personal Number?

- **Telegram bot**: No. Bots cannot access your phone number unless you explicitly share it via a contact button.
- **WhatsApp via OpenClaw**: Yes, indirectly. If someone messages the WhatsApp number, they see the number. If it is your personal number, it is exposed.
- **Signal**: The number is visible to contacts who have it in their address book.

---

## 4. Account Suspension Risk (WhatsApp)

### Meta's 2026 Policy on AI Chatbots

As of January 15, 2026, Meta explicitly bans "general-purpose AI chatbots" on WhatsApp — meaning chatbots offering open-ended or assistant-style interactions (exactly what OpenClaw does). Structured bots for support, bookings, and notifications are allowed.

### Ban Triggers

- High message volume during unusual hours
- Rapid automated responses in succession
- Connections from new IP addresses
- Messaging many new contacts rapidly
- User reports

### Risk Level for Personal Assistant Use

Personal assistant usage (low volume, small allowlist, responding only when mentioned) creates a "calmer zone" with lower risk than outbound marketing bots. But there is **no guarantee** — enforcement is opaque and unpredictable. Accounts may run for months or get suspended within a week.

### Mitigation

1. Use a **dedicated number** (if banned, personal account is safe)
2. Keep message volume low
3. Use allowlists to restrict who can interact
4. Run on Node.js (not Bun — causes reconnect loops that trigger detection)
5. Accept the risk and document your setup for quick rebuilds

---

## 5. Dedicated Number Options

### Option A: Paraguay Prepaid SIM (Recommended)

| Provider | SIM Cost | Registration | Data Plans |
|----------|----------|-------------|------------|
| Tigo | 5,000-10,000 PYG ($0.70-$1.40) | Passport/cedula + fingerprint | 10GB ~$5-8/month |
| Personal | 10,000 PYG ($1.35) | Passport/cedula + fingerprint | Similar |
| Claro | 5,000 PYG ($0.65) + 10,000 PYG registration | Passport/cedula + fingerprint | Similar |

**Pros:**
- Cheapest option (~$2-3 one-time, ~$3-5/month for minimal data)
- Real carrier number — works with WhatsApp, Telegram, Signal, everything
- No VoIP detection risk
- Available at any Tigo/Personal/Claro store with cedula
- Can use the cheapest possible plan (bot only needs internet for API calls)

**Cons:**
- Requires keeping the SIM active (top up periodically to prevent number recycling)
- Physical SIM needs a phone for initial WhatsApp setup (can use an old phone)
- SIM swap risk (low in Paraguay but nonzero)

**Recommendation**: Buy a Tigo prepaid SIM for ~$2. Use the cheapest data plan or even just keep it active with minimal top-ups. The RPi 5 uses WiFi/Ethernet for internet — the SIM is only needed for initial WhatsApp verification and occasional re-verification.

### Option B: Silent.link (Privacy-Focused eSIM)

| Plan | Price | Phone Number | SMS | Data |
|------|-------|-------------|-----|------|
| DATA (no number) | $9 one-time + pay-per-GB | No | No | 150+ countries |
| IDENTITY (US +1) | ~$59/year | Yes (US) | Inbound only | 150+ countries |
| IDENTITY (UK +44) | ~$59/year | Yes (UK) | Inbound only | 150+ countries |

**Pros:**
- No KYC — completely anonymous purchase
- Pays with Bitcoin/Lightning/Monero
- Works with WhatsApp, Telegram, Signal registration
- eSIM — no physical SIM to steal or swap
- No carrier customer service to social-engineer

**Cons:**
- **$59/year** — expensive compared to $2 Paraguay SIM
- US/UK numbers only — your contacts see a foreign number
- Inbound SMS only (can't send texts)
- One-time use eSIM — cannot transfer to another device
- Requires eSIM-compatible phone for initial setup
- Crypto-only payments
- Overkill for this use case (you are not hiding from a state actor)

### Option C: Crypton.sh (Cloud Phone Number)

| Feature | Details |
|---------|---------|
| Price | ~$5-14/month depending on country |
| Countries | Multiple (UK, Czechia, others — availability fluctuates) |
| Encryption | 256-bit asymmetric (messages encrypted with your key) |
| KYC | None |
| Payments | Crypto + credit card |

**Pros:**
- No KYC, encrypted SMS
- Cheaper than Silent.link

**Cons:**
- Mixed reviews (unresponsive support, fund issues, no refunds)
- Number availability fluctuates (UK numbers sometimes out of stock)
- Monthly recurring cost
- No guarantee numbers work with WhatsApp (WhatsApp blocks many virtual numbers)
- Reliability concerns for a 24/7 bot setup

### Option D: Google Voice / TextNow / VoIP Numbers

**Do not use.** WhatsApp has gotten much stricter about virtual numbers in 2025-2026:
- Google Voice, TextNow, and most VoIP numbers are now blocked during verification
- WhatsApp maintains databases of VoIP number ranges and blocks them
- Even if registration succeeds initially, re-verification will likely fail
- TextNow numbers get recycled if inactive, creating security risks

Google Voice is also US-only and requires an existing US number to set up.

---

## 6. One Number vs Two Numbers

### Can PicoClaw and OpenClaw Share One Number?

**Yes, with caveats:**

- PicoClaw uses **Telegram Bot API** — no phone number involved at all
- OpenClaw WhatsApp needs a phone number
- If you also want OpenClaw on Signal, that needs a **separate** number (Signal requires exclusive registration — you cannot use the same number on personal Signal and bot Signal simultaneously)

### Recommended Setup

| Service | Number Needed | Source |
|---------|--------------|--------|
| PicoClaw (Telegram bot) | None (bot token only) | Your existing Telegram account creates the bot |
| OpenClaw (WhatsApp) | 1 dedicated number | Paraguay prepaid SIM |
| OpenClaw (Signal) | Same dedicated number OR separate | Same SIM works if not using Signal personally on it |
| OpenClaw (Telegram) | None (bot token) | Same bot or separate bot via @BotFather |
| OpenClaw (Discord) | None (bot token) | Discord Developer Portal |

**Minimum numbers needed: 1 dedicated prepaid SIM** (for WhatsApp + optionally Signal).

If you want Signal on OpenClaw AND use Signal personally, you need 2 numbers (one personal, one for the bot). But since your family uses WhatsApp (not Signal), this is likely unnecessary.

---

## 7. Security Best Practices

### SIM Swap Protection

- Paraguay carriers have basic verification (cedula + fingerprint for SIM purchase)
- SIM swap risk is low for a bot number (no financial accounts tied to it)
- eSIMs are slightly more secure against physical theft but equally vulnerable to carrier social engineering
- **Mitigation**: Do not use the dedicated number for 2FA on any important account

### Number Recycling

- If you stop topping up a prepaid SIM, the carrier eventually recycles the number
- Someone else could get your old number and potentially access linked accounts
- **Mitigation**: Set a calendar reminder to top up every 2-3 months (minimum ~5,000 PYG / $0.70)

### 2FA Implications

- **Never use the dedicated bot number for SMS-based 2FA** on personal accounts
- The number exists solely for WhatsApp/Signal registration
- Use TOTP (authenticator app) or passkeys for all important accounts

### eSIM vs Physical SIM

| Factor | Physical SIM | eSIM |
|--------|-------------|------|
| Theft/cloning | Can be physically stolen | Embedded in device, harder to extract |
| SIM swap | Vulnerable (carrier social engineering) | Equally vulnerable |
| Device lock | Works in any unlocked phone | Tied to one device (Silent.link IDENTITY) |
| Availability in Paraguay | Everywhere | Limited (need eSIM-compatible phone) |
| Cost | $2-3 one-time | $59/year (Silent.link) |

For this use case, a physical SIM is the practical choice.

---

## 8. Paraguay-Specific Considerations

### SIM Purchase Requirements

- **Residents**: Cedula (national ID) + fingerprint + CONATEL form
- **Foreigners**: Passport + fingerprint + CONATEL form
- Available at carrier stores, kiosks, and some supermarkets
- No residency requirement for prepaid

### Carrier Comparison for Bot Use

| Factor | Tigo | Personal | Claro |
|--------|------|----------|-------|
| Coverage | Best nationwide | Good urban | Good urban |
| Cheapest SIM | 5,000 PYG ($0.70) | 10,000 PYG ($1.35) | 5,000 PYG + 10,000 PYG reg |
| Keep-alive cost | ~5,000 PYG/3 months | Similar | Similar |
| eSIM support | No | No | No |

**Recommendation**: Tigo — cheapest, best coverage, most stores.

### Data Plan Needs

The bot number does NOT need a data plan on the SIM. The RPi 5 connects to the internet via Ethernet/WiFi on your home network. The SIM is only needed for:
1. Initial WhatsApp verification (one-time SMS)
2. Periodic re-verification (rare, maybe every few months)
3. Potentially Signal verification (one-time SMS)

You can use the absolute minimum top-up to keep the number active. Even 5,000 PYG ($0.70) every few months should suffice.

### Number Portability

Paraguay supports number portability between carriers (CONATEL regulation). If you are unhappy with one carrier, you can port the number. However, for a bot number this is unlikely to matter.

---

## 9. Recommendation

### For PicoClaw (Telegram)

**No action needed.** Use your existing Telegram account to create a bot via @BotFather. No dedicated number required. Zero cost, zero privacy risk.

### For OpenClaw (WhatsApp)

**Buy one Tigo prepaid SIM (~$2).**

Rationale:
- Cheapest and simplest option
- Real carrier number — zero risk of WhatsApp blocking it
- Isolates your personal WhatsApp from ban risk
- No ongoing cost beyond minimal top-ups (~$3/year)
- Available at any Tigo store with your cedula
- Privacy-focused alternatives (Silent.link at $59/year) are overkill for a personal/family assistant

Setup flow:
1. Buy Tigo SIM at a store ($0.70)
2. Insert in any old phone
3. Register WhatsApp on that phone
4. Scan OpenClaw QR code to link as a device
5. Remove SIM, store it safely
6. The RPi 5 maintains the WhatsApp session via internet (no SIM needed after linking)

### Total Cost

| Item | Cost |
|------|------|
| PicoClaw phone number | $0 (bot token) |
| OpenClaw dedicated SIM (Tigo) | ~$0.70 one-time |
| Keep SIM active | ~$0.70 every 2-3 months |
| **Year 1 total** | **~$3.50** |
| Silent.link alternative | $59/year |

### What NOT to Do

- Do NOT use your personal WhatsApp number for OpenClaw
- Do NOT use Google Voice, TextNow, or VoIP numbers for WhatsApp
- Do NOT use the dedicated number for 2FA on any account
- Do NOT pay $59/year for Silent.link when a $0.70 SIM does the same job
- Do NOT set up WhatsApp Business API (overkill, adds cost and complexity)

---

## 10. Risk Acceptance

Even with a dedicated number, running OpenClaw on WhatsApp carries inherent risk:

- **Baileys is unofficial** — Meta could break it with any update
- **Automation violates WhatsApp ToS** — account suspension is always possible
- **Meta's 2026 AI chatbot ban** explicitly targets general-purpose AI assistants

If the dedicated WhatsApp number gets banned:
1. Buy another Tigo SIM ($0.70)
2. Re-register WhatsApp
3. Re-link to OpenClaw
4. Total downtime: ~30 minutes, cost: $0.70

This is an acceptable risk for a family assistant. Your personal WhatsApp account remains untouched.

---

## References

- [Telegram Bot API — Introduction](https://core.telegram.org/bots)
- [OpenClaw WhatsApp Docs](https://docs.openclaw.ai/channels/whatsapp)
- [OpenClaw WhatsApp Production Setup — LumaDock](https://lumadock.com/tutorials/openclaw-whatsapp-production-setup)
- [OpenClaw WhatsApp Risks — ZenVanRiel](https://zenvanriel.com/ai-engineer-blog/openclaw-whatsapp-risks-engineers-guide/)
- [OpenClaw Channel Comparison — ZenVanRiel](https://zenvanriel.com/ai-engineer-blog/openclaw-channel-comparison-telegram-whatsapp-signal/)
- [OpenClaw Signal Docs](https://docs.openclaw.ai/channels/signal)
- [Silent.link FAQ](https://silent.link/faq)
- [Silent.link Review — KYCnot.me](https://blog.kycnot.me/p/silentlink-review)
- [Crypton.sh — KYCnot.me](https://kycnot.me/service/crypton)
- [Paraguay SIM Cards — Phone Travel Wiz](https://www.phonetravelwiz.com/buying-a-sim-card-in-paraguay-guide/)
- [Paraguay SIM Cards — Expat Guide](https://expatsettle.com/paraguay-sim-cards)
- [WhatsApp 2026 AI Chatbot Ban — TechCrunch](https://techcrunch.com/2025/10/18/whatssapp-changes-its-terms-to-bar-general-purpose-chatbots-from-its-platform/)
- [WhatsApp Privacy 2025 — heydata](https://heydata.eu/en/magazine/whatsapp-privacy-2025/)
- [eSIM vs SIM Security — NordVPN](https://nordvpn.com/blog/is-esim-safe/)
- [OpenClaw Kapso WhatsApp (official API)](https://github.com/Enriquefft/openclaw-kapso-whatsapp)
