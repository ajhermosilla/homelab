# Domain Strategy

Two-domain strategy for personal/developer identity and business separation. Updated 2026-01-14.

## Domain Inventory

| Domain | Status | Purpose | Annual Cost |
|--------|--------|---------|-------------|

| **cronova.dev** | Owned | Developer, Homelab, Open Source, Micro SaaS | Already paid |
| **verava.ai** | Available | Supply Chain + AI Consulting | ~$50-80/yr |
| ~~nanduti.io~~ | Skipped | Was planned for homelab | Saved $30/yr |
| ~~verava.net~~ | Skipped | Replaced by verava.ai | Saved $12/yr |

## Why Two Domains?

### cronova.dev (Already Established)

| Asset | Status |
|-------|--------|

| Domain | Owned |
| Email | <augusto@cronova.dev> (configured) |
| GitHub Org | github.com/cronova |
| Personal GitHub | github.com/ajhermosilla |

**Meaning:** Cron (scheduled tasks) + Nova (new star) = "Scheduled Innovation"

### verava.ai (To Purchase)

> **Status (2026-03-18)**: verava.ai purchase deferred — not needed for current homelab scope.

| Factor | Value |
|--------|-------|

| TLD | .ai = AI-first positioning |
| Business | Supply Chain + AI Consulting |
| Domain hack | "vera" (true) + ".ai" = "True AI" |
| Memorability | High |

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                      AUGUSTO HERMOSILLA                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Developer / Personal]            [Business / Customers]        │
│  ─────────────────────             ──────────────────────        │
│                                                                  │
│       cronova.dev                       verava.ai                │
│                                                                  │
│  • Homelab infrastructure          • Supply Chain platform       │
│  • Open Source projects            • Customer portal             │
│  • Micro SaaS tools                • B2B API                     │
│  • Personal services               • Consulting presence         │
│  • Developer APIs                                                │
│  • Private git repos                                             │
│                                                                  │
│  augusto@cronova.dev               augusto@verava.ai             │
│  github.com/cronova                (future email)                │
│  github.com/ajhermosilla                                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Subdomain Architecture

### cronova.dev (Developer + Homelab)

#### Infrastructure Services (Tailscale-only)

| Subdomain | Service | Location | Access |
|-----------|---------|----------|--------|

| `hs.cronova.dev` | Headscale | VPS | Tailscale clients |
| `jara.cronova.dev` | Home Assistant | Docker VM | Tailscale |
| `yrasema.cronova.dev` | Jellyfin | Docker VM | Tailscale |
| `btc.cronova.dev` | Start9 | RPi 4 | Tailscale |
| `nas.cronova.dev` | Syncthing/Samba | NAS | Tailscale |
| `git.cronova.dev` | Forgejo | NAS | Tailscale |

#### Public Services

| Subdomain | Service | Location | Access |
|-----------|---------|----------|--------|

| `vault.cronova.dev` | Vaultwarden | Docker VM | Public |
| `status.cronova.dev` | Uptime Kuma | VPS | Public |
| `notify.cronova.dev` | ntfy | VPS | Public |

#### Developer/SaaS Services

| Subdomain | Service | Location | Access |
|-----------|---------|----------|--------|

| `<www.cronova.dev>` | Landing page | Cloudflare Pages | Public |
| `docs.cronova.dev` | Documentation | Cloudflare Pages | Public |
| `api.cronova.dev` | Public APIs | VPS/Docker | Public |
| `saas.cronova.dev` | Micro SaaS apps | VPS/Docker | Public |

### verava.ai (Business Only)

| Subdomain | Service | Purpose |
|-----------|---------|---------|

| `<www.verava.ai>` | Landing page | Company presence |
| `app.verava.ai` | Customer platform | SaaS for clients |
| `api.verava.ai` | Customer API | B2B integrations |
| `docs.verava.ai` | Customer docs | Product documentation |
| `demo.verava.ai` | Demo environment | Sales demos |

---

## DNS Configuration

### Cloudflare Setup

```text
┌──────────────────────────────────────────────────────────────────┐
│                     Cloudflare DNS                                │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  cronova.dev                         verava.ai                    │
│  ────────────                        ─────────                    │
│                                                                   │
│  # Public services (proxied)         # All proxied                │
│  A     @        → VPS_IP             A     @        → VPS_IP      │
│  A     www      → Cloudflare Pages   A     www      → VPS_IP      │
│  A     docs     → Cloudflare Pages   A     app      → VPS_IP      │
│  A     status   → VPS_IP             A     api      → VPS_IP      │
│  A     notify   → VPS_IP             A     docs     → VPS_IP      │
│  A     vault    → VPS_IP                                          │
│  A     api      → VPS_IP                                          │
│  A     saas     → VPS_IP                                          │
│                                                                   │
│  # Tailscale services (DNS only, grey cloud)                     │
│  A     hs       → RPi5 public IP (or Tailscale Funnel)           │
│  A     home     → 100.68.63.168 (internal only)                    │
│  A     media    → 100.68.63.168 (internal only)                    │
│  A     btc      → 100.64.0.11 (internal only)                    │
│  A     nas      → 100.82.77.97 (internal only)                    │
│  A     git      → 100.64.0.2 (internal only)                     │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Split-Horizon DNS

For Tailscale-only services, use Headscale MagicDNS:

```yaml
# /etc/headscale/config.yaml
dns_config:
  magic_dns: true
  base_domain: cronova.dev
  nameservers:
    - 100.64.0.1      # RPi 5 Pi-hole
    - 100.68.63.168   # Home Pi-hole
```

This means:

- `jara.cronova.dev` resolves to `100.68.63.168` inside Tailscale
- Outside Tailscale, it doesn't resolve (private)

---

## Traffic Flow

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                    │
│                                                                          │
│         cronova.dev                          verava.ai                   │
│    (Developer + Homelab)                (Supply Chain + AI)              │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                          [Cloudflare]
                          DNS + CDN
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
       [Cloudflare Pages]  [VPS - Caddy]    [Tailscale Mesh]
       - www.cronova.dev   - vault.cronova  - jara.cronova.dev
       - docs.cronova.dev  - status.cronova - yrasema.cronova.dev
                           - notify.cronova - btc.cronova.dev
                           - api.cronova    - nas.cronova.dev
                           - www.verava.ai  - git.cronova.dev
                           - app.verava.ai
                           - api.verava.ai
                                 │
                          [Tailscale Mesh]
                           100.64.0.0/10
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
   [Mobile Kit]           [Fixed Homelab]         [VPS Helper]
   RPi 5 + MacBook        Mini PC + RPi 4         Vultr US
   hs.cronova.dev         + NAS
   git.cronova.dev        jara.cronova.dev
                          yrasema.cronova.dev
                          btc.cronova.dev
                          nas.cronova.dev
```

---

## Caddy Configuration

### VPS Caddyfile

```caddyfile
# ============================================
# cronova.dev - Developer/Homelab Services
# ============================================

# Vault - Public password manager
vault.cronova.dev {
    reverse_proxy 100.68.63.168:8843
}

# Status - Public uptime monitoring
status.cronova.dev {
    reverse_proxy localhost:3001
}

# Notifications - Public push service
notify.cronova.dev {
    reverse_proxy localhost:80
}

# API - Public developer APIs
api.cronova.dev {
    reverse_proxy localhost:8080
}

# SaaS - Micro SaaS applications
saas.cronova.dev {
    reverse_proxy localhost:3000
}

# Root redirect
cronova.dev {
    redir https://www.cronova.dev{uri}
}

# ============================================
# verava.ai - Business Services
# ============================================

# Main website
www.verava.ai {
    root * /var/www/verava
    file_server
    # Or reverse_proxy to app server
}

# Customer application
app.verava.ai {
    reverse_proxy localhost:4000
}

# Customer API
api.verava.ai {
    reverse_proxy localhost:4001
}

# Documentation
docs.verava.ai {
    root * /var/www/verava-docs
    file_server
}

# Root redirect
verava.ai {
    redir https://www.verava.ai{uri}
}
```

---

## Email Strategy

| Identity | Email | Purpose |
|----------|-------|---------|

| Developer (primary) | <augusto@cronova.dev> | Open source, GitHub, tech community |
| Business | <augusto@verava.ai> | Customer communication |
| Personal/Homelab | <augusto@hermosilla.me> | Private, family |

### Email Providers

| Domain | Provider | Notes |
|--------|----------|-------|

| cronova.dev | Google Workspace / Cloudflare Email | Already configured |
| verava.ai | Google Workspace / Proton | Future setup |
| hermosilla.me | Existing | Personal |

---

## Brand Positioning

### cronova.dev

**Tagline:** "Tools for developers who build things"

#### Content

- Open source projects
- Micro SaaS tools
- Developer APIs
- Technical blog
- Homelab documentation

**Audience:** Developers, geeks, makers

### verava.ai

**Tagline:** "AI-powered supply chain intelligence"

#### Content

- Consulting services
- Supply chain platform
- Case studies
- Industry insights

**Audience:** Supply chain managers, logistics companies, enterprise

---

## Why This Strategy?

### cronova.dev over nanduti.io

| Factor | cronova.dev | nanduti.io |
|--------|-------------|------------|

| Status | Already owned | Would need to buy |
| Email | Configured | Not configured |
| GitHub | github.com/cronova | None |
| Brand | Established | New |
| Cost | $0 additional | ~$30/yr |
| Geek factor | 9/10 | 9/10 |

**Decision:** Use cronova.dev for homelab. Same geek factor, zero additional cost.

### verava.ai over verava.net

| Factor | verava.ai | verava.net |
|--------|-----------|------------|

| TLD vibe | AI-first, modern | Corporate, dated |
| Business fit | Supply Chain + AI | Generic |
| Price | ~$50-80/yr | ~$12/yr |
| Memorability | High | Medium |
| Domain hack | "vera" + ".ai" | None |

**Decision:** verava.ai is worth the premium for AI positioning.

---

## Cost Summary

| Item | Annual Cost |
|------|-------------|

| cronova.dev | Already owned |
| verava.ai | ~$50-80/yr |
| VPS (Vultr) | ~$72/yr |
| **Total** | ~$122-152/yr |

**Savings:** $42/yr by not buying nanduti.io + verava.net

---

## Implementation Checklist

### Immediate

- [ ] Purchase verava.ai (check registrar pricing)
- [ ] Configure cronova.dev DNS for homelab subdomains
- [ ] Update architecture docs to use cronova.dev

### After PSU Arrives

- [ ] Deploy Headscale at hs.cronova.dev
- [ ] Deploy Pi-hole with cronova.dev local DNS
- [ ] Configure Caddy reverse proxy

### Future

- [ ] Set up verava.ai email (<augusto@verava.ai>)
- [ ] Build <www.cronova.dev> landing page
- [ ] Build <www.verava.ai> landing page
- [ ] Populate github.com/cronova with open source projects

---

## Registrar Comparison (verava.ai)

| Registrar | .ai Price | Notes |
|-----------|-----------|-------|

| Cloudflare | ~$50-60/yr | At-cost, DNS included |
| Namecheap | ~$60-70/yr | Good UI |
| Porkbun | ~$55-65/yr | Budget friendly |
| Google Domains | Discontinued | Moved to Squarespace |
| GoDaddy | ~$80+/yr | Avoid (upsells) |

**Recommendation:** Cloudflare Registrar for at-cost pricing + DNS + CDN integration.

---

## GitHub Strategy

### github.com/cronova (Organization)

| Repository | Purpose |
|------------|---------|

| `homelab` | This repo - infrastructure as code |
| `dotfiles` | Personal config (already at ajhermosilla) |
| `<micro-saas>` | Future SaaS tools |
| `<open-source>` | Future open source projects |

### github.com/ajhermosilla (Personal)

| Repository | Purpose |
|------------|---------|

| `dotfiles` | Personal configuration |
| `javya` | Worship planning tool |
| Private repos | Personal projects |

---

## The Elevator Pitch

> "I'm Augusto. I run **Verava** (verava.ai) - we help supply chain companies leverage AI for better decisions.
>
> I also build open source tools and micro SaaS products at **Cronova** (cronova.dev). My entire infrastructure runs on self-hosted services - homelab style.
>
> Two brands, one stack, maximum sovereignty."

---

## References

- [Cloudflare Registrar](https://www.cloudflare.com/products/registrar/)
- [.ai Domain Registry](https://nic.ai/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Headscale Documentation](https://headscale.net/)
