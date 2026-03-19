# Domain Research

> **ARCHIVED**: This document is superseded by [`domain-strategy.md`](domain-strategy.md).
>
> **Final decision:** Use `cronova.dev` (already owned) + `verava.ai` (to purchase).
> The domains below (nanduti.io, verava.net) were not purchased.

---

*Original research from 2026-01-14 preserved below for reference.*

---

Domain name options for homelab infrastructure and business. Researched 2026-01-14.

## Candidates

| Domain | Status | Price | Purpose |
|--------|--------|-------|---------|
| **nanduti.io** | Available | ~$30/yr | Homelab / Infra |
| **verava.net** | Available | ~$12/yr | Business / Consulting |
| mbyja.io | Available | ~$30/yr | Alternative |
| kuarahy.io | Available | ~$30/yr | Alternative |

## The Showdown

| Aspect | verava.net | nanduti.io | mbyja.io | kuarahy.io |
|--------|------------|------------|----------|------------|
| **Meaning** | Brand name | "Web/Lace" (Guarani) | "Star" (Guarani) | "Sun" (Guarani) |
| **Pronounceable** | Easy | Medium | Hard | Hard |
| **Spellable** | Easy | Medium | Hard | Hard |
| **Memorable** | Medium | High | Medium | Low |
| **TLD Vibe** | Corporate/Classic | Tech/Startup | Tech/Startup | Tech/Startup |
| **Price** | ~$12/yr | ~$30/yr | ~$30/yr | ~$30/yr |
| **Geek Factor** | 5/10 | 9/10 | 7/10 | 6/10 |
| **Paraguay Pride** | 0/10 | 10/10 | 10/10 | 10/10 |

## Analysis

### verava.net

**Vibe:** Professional, corporate, safe

```text
+ Professional, safe, corporate-friendly
+ Easy for customers to type/remember
+ Cheap (.net ~$12/yr)
+ Good for "Supply Chain Consulting + AI" branding
- Generic tech-company feel
- No story behind it
- .net feels 2005
```

**Best for:** Business cards, customer-facing, consulting work.

---

### nanduti.io

**Vibe:** Cultural hacker, poetic geek

```text
+ PERFECT metaphor (ñanduti lace = intricate web = network mesh)
+ Cultural flex (Paraguay heritage)
+ Conversation starter ("What does it mean?")
+ .io = modern tech credibility
+ Homelab/mesh networking poetic justice
- Loses the ñ (but still recognizable)
- Harder to spell over the phone
- More expensive
```

**Best for:** Homelab, personal infrastructure, technical projects.

---

### mbyja.io

**Vibe:** Mysterious, short

```text
+ Short, mysterious
+ "Star" = aspiration, navigation
- Nobody can pronounce it
- Nobody can spell it
- You'll spend your life saying "M-B-Y-J-A"
```

**Best for:** If you want maximum obscurity.

---

### kuarahy.io

**Vibe:** Always-on, but forgettable

```text
+ "Sun" = always-on, reliability
- Too long
- Unspellable
- Forgettable
```

**Best for:** Not recommended.

---

## Why nanduti.io Wins (Geek Factor)

### 1. The Metaphor

Ñanduti is traditional Paraguayan lace with intricate web patterns. The word literally means "white web" in Guarani. You're building a digital web/mesh network. Poetry.

```text
Traditional ñanduti lace = intricate interconnected web
Your homelab            = intricate interconnected mesh
```

### 2. The Story

Every time someone asks "what's nanduti?", you get to explain:

- Guarani indigenous culture
- Paraguayan heritage
- Your sovereign infrastructure philosophy
- Why self-hosting matters

That's a flex no generic domain gives you.

### 3. The Aesthetic

```bash
# This hits different
ssh admin@nanduti.io
curl https://api.nanduti.io/status

# vs this
ssh admin@verava.net
curl https://api.verava.net/status
```

### 4. The TLD

**.io** = The hacker's TLD

- Says "I build things" without saying it
- Tech credibility
- Startup/maker culture

**.net** = The 2005 TLD

- "We couldn't get .com"
- Corporate fallback
- Safe but boring

---

## Recommendation

### Strategy: Get Both

| Domain | Use Case | Subdomains |
|--------|----------|------------|
| **nanduti.io** | Homelab / Personal | headscale.nanduti.io, pihole.nanduti.io, git.nanduti.io |
| **verava.net** | Business / Customers | <www.verava.net>, api.verava.net, app.verava.net |

### Why Both?

1. **Separation of concerns** - Personal infra vs business
2. **Professional flexibility** - Customers see verava.net, you see nanduti.io
3. **Total cost** - ~$42/year for complete coverage
4. **Future-proof** - If one brand grows, the other stays personal

---

## Subdomain Planning (nanduti.io)

| Subdomain | Service | Environment |
|-----------|---------|-------------|
| `hs.nanduti.io` | Headscale | Mobile (RPi 5) |
| `dns.nanduti.io` | Pi-hole | All |
| `git.nanduti.io` | Forgejo | Fixed (NAS) |
| `home.nanduti.io` | Home Assistant | Fixed |
| `media.nanduti.io` | Jellyfin | Fixed |
| `vault.nanduti.io` | Vaultwarden | Fixed |
| `status.nanduti.io` | Uptime Kuma | VPS |
| `notify.nanduti.io` | ntfy | VPS |
| `watch.nanduti.io` | changedetection | VPS |

---

## Technical Notes

### IDN Limitation

.io domains don't support Internationalized Domain Names (IDN).

| Domain | Registrable? |
|--------|--------------|
| ~~ñanduti.io~~ | No (special character ñ) |
| **nanduti.io** | Yes (ASCII only) |

The ñ must be dropped, but "nanduti" is still recognizable and searchable.

### Paraguay TLD Alternative

If you want the ñ, use Paraguay's TLD:

| Domain | Notes |
|--------|-------|
| ñanduti.com.py | Supports IDN |
| nanduti.com.py | Also available |

But .com.py lacks the tech credibility of .io.

---

## WHOIS Results (2026-01-14)

```text
nanduti.io  - Domain not found (AVAILABLE)
verava.net  - No match for domain (AVAILABLE)
mbyja.io    - Domain not found (AVAILABLE)
kuarahy.io  - Domain not found (AVAILABLE)
```

---

## Decision

| Domain | Decision | Action |
|--------|----------|--------|
| **nanduti.io** | BUY | Primary homelab domain |
| **verava.net** | BUY | Business domain |
| mbyja.io | Skip | Too hard to spell |
| kuarahy.io | Skip | Too long |

**Total annual cost:** ~$42/year

---

## Cultural Reference

### What is Ñanduti?

Ñanduti (Guarani: "white web") is a traditional Paraguayan lace-making technique. The intricate radial patterns resemble spider webs, created by weaving threads around a central point.

#### Connection to homelab

- Radial pattern = mesh network topology
- Interconnected threads = Tailscale connections
- Central point = Headscale coordination server
- Handcrafted = self-hosted, DIY infrastructure

The metaphor is perfect.

---

## Registrars

| Registrar | .io Price | .net Price | Notes |
|-----------|-----------|------------|-------|
| Namecheap | ~$30/yr | ~$12/yr | Good UI, privacy included |
| Cloudflare | ~$28/yr | ~$10/yr | At-cost pricing, no markup |
| Porkbun | ~$28/yr | ~$10/yr | Cheap, good reputation |
| Google Domains | Discontinued | - | Moved to Squarespace |

**Recommendation:** Cloudflare Registrar (at-cost, includes DNS/CDN)

---

## References

- [Ñanduti Wikipedia](https://en.wikipedia.org/wiki/%C3%91anduti)
- [.io Registry](https://nic.io/)
- [Cloudflare Registrar](https://www.cloudflare.com/products/registrar/)
- [Namecheap](https://www.namecheap.com/)
