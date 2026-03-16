# DNS Architecture

How DNS resolution works across all homelab environments.

## Overview

```
[Client Device]
       |
       v
   [Pi-hole]          ← Ad-blocking, logging, local DNS
       |
       v
[Upstream Resolver]   ← Recursive DNS (Unbound or public)
       |
       v
   [Internet]
```

**Principle:** DNS ad-blocking is always client-facing. Implementation varies by environment (AdGuard Home or Pi-hole).

## Environment DNS Flows

### Mobile Kit

Mobile kit uses Beryl AX AdGuard Home as the sole DNS ad-blocker:

```
[MacBook/Devices]
       |
       | DNS: 192.168.8.1
       v
[AdGuard Home on Beryl AX]  ← Built-in, lightweight, always on
       |
       | Upstream: 1.1.1.1, 9.9.9.9
       v
[Cloudflare/Quad9]
```

| Component | Role | IP |
|-----------|------|-----|
| Beryl AX | AdGuard Home (DNS), DHCP | 192.168.8.1 |
| Upstream | Public recursive DNS | 1.1.1.1, 9.9.9.9 |

**Mobile kit:** MacBook Air + Beryl AX + Samsung A13. RPi 5 moved to fixed homelab (runs OpenClaw, not Pi-hole).

**Why public upstream:** Mobile kit travels. Running Unbound adds complexity for minimal benefit on the go.

### Fixed Homelab

```
[Home Devices]
       |
       | DNS: 192.168.0.10 (Docker Host)
       v
[Pi-hole in Docker]
       |
       | Upstream: 192.168.0.1 (OPNsense)
       v
[Unbound on OPNsense]
       |
       | Recursive queries
       v
[Root DNS Servers]
```

| Component | Role | IP |
|-----------|------|-----|
| OPNsense | DHCP, points to Pi-hole | 192.168.0.1 |
| Pi-hole (Docker) | Ad-blocking, DNS server | 192.168.0.10 |
| Unbound (OPNsense) | Recursive resolver | 192.168.0.1:5353 |

**Why Unbound behind Pi-hole:**
- Pi-hole handles ad-blocking and logging (what you care about)
- Unbound does recursive resolution (no third-party DNS)
- Maximum privacy: queries go directly to root servers
- Unbound on non-standard port (5353) to avoid conflict

**OPNsense Unbound Config:**
```
Services → Unbound DNS → General
- Listen Port: 5353 (not 53, Pi-hole uses that)
- Enable DNSSEC: Yes
- DNS Query Forwarding: Disabled (recursive mode)
```

**Pi-hole Upstream Config:**
```
Settings → DNS → Upstream DNS Servers
- Custom: 192.168.0.1#5353
- Uncheck all public resolvers
```

### VPS (yvága — AdGuard + Unbound)

```
[VPS Services / Tailscale Nodes]
       |
       | DNS: 127.0.0.1 / 100.77.172.46
       v
[AdGuard Home]              ← Ad-blocking, DNS rewrites for *.cronova.dev
       |
       | Upstream: 172.20.0.10:5335 (static IP, not hostname)
       v
[Unbound]                   ← Recursive resolver (no third-party)
       |
       | Recursive queries
       v
[Root DNS Servers]
```

| Component | Role | IP |
|-----------|------|-----|
| AdGuard Home | Ad-blocking, DNS filtering, internal rewrites | 127.0.0.1:53, 100.77.172.46:53 |
| Unbound | Recursive resolver (no third-party DNS) | 172.20.0.10:5335 (adguard-net) |
| Pi-hole (VPS) | Legacy, secondary — may be removed | 127.0.0.1 (not actively used) |

**Architecture notes:**
- AdGuard upstream uses Unbound's **static IP** (172.20.0.10), not hostname — AdGuard can't resolve Docker hostnames since it IS the DNS resolver (circular dependency)
- AdGuard cache disabled — Unbound handles caching with `serve-expired`
- VPS has `accept-dns=false` on Tailscale to prevent recursive loops
- VPS `/etc/hosts` must have `127.0.0.1 hs.cronova.dev` — without it, DNS outage causes Tailscale logout cascade
- 18 DNS rewrites in AdGuard for internal `*.cronova.dev` hostnames → Tailscale IPs
- Blocklists (3): AdGuard DNS filter, OISD small, Steven Black hosts
- Both containers have Watchtower disabled (critical infrastructure)

**Use cases:**
- VPS containers use AdGuard for DNS (ad-blocking for scraping)
- All Tailscale nodes use VPS as fallback nameserver (headscale global DNS config)
- Full privacy: no third-party DNS provider sees queries

## Tailscale DNS Integration

When on Tailscale mesh, devices can use Pi-hole on Docker VM or VPS:

| DNS Location | Tailscale IP | Use Case |
|--------------|--------------|----------|
| Pi-hole, Docker VM (home) | 100.68.63.168 | Primary — LAN DNS for all home devices |
| AdGuard, VPS (yvága) | 100.77.172.46 | Fallback — recursive DNS via Unbound |

**Headscale DNS Config** (on VPS):
```yaml
# /etc/headscale/config.yaml
dns_config:
  nameservers:
    - 100.68.63.168   # Home Pi-hole (primary)
    - 100.77.172.46   # VPS Pi-hole (fallback)
  magic_dns: true
  base_domain: tail.net
```

## Local DNS Records

Pi-hole can resolve local hostnames:

```
# Pi-hole → Local DNS → DNS Records
192.168.0.237   oga.home
192.168.0.20    rpi5.home
192.168.0.11    rpi4.home
192.168.0.12    nas.home
```

Or use Headscale MagicDNS:
```
oga.tail.net     → 100.78.12.241
docker.tail.net  → 100.68.63.168
```

## DNS Failover

| Scenario | Behavior |
|----------|----------|
| Home Pi-hole down | Home devices fail DNS (fix quickly) |
| OPNsense Unbound down | Pi-hole falls back to public DNS |
| VPS AdGuard down | Tailscale nodes fall back to home Pi-hole; VPS containers fail DNS |
| VPS Unbound down | AdGuard has no upstream — all VPS DNS fails |
| Home internet down | VPS DNS unaffected; mobile kit works standalone |
| VPS down | Home Pi-hole unaffected; Tailscale nodes use home Pi-hole only |

**Home Pi-hole upstream recommendation:** Configure with both Unbound AND one public resolver:
```
Upstream DNS:
- 192.168.0.1#5353 (Unbound, primary)
- 9.9.9.9 (Quad9, fallback)
```

## Port Allocation

| Service | Port | Interface |
|---------|------|-----------|
| Pi-hole DNS | 53 | LAN-facing |
| Pi-hole Web | 8053 | LAN-facing |
| Unbound | 5353 | localhost only |

## Configuration Checklist

### Mobile Kit (Beryl AX)
- [x] Configure AdGuard Home on Beryl AX
- [x] Set upstream: 1.1.1.1, 9.9.9.9
- [x] Beryl AX is DHCP server and DNS (192.168.8.1)

### Fixed Homelab
- [x] Configure Unbound on OPNsense (port 5353)
- [x] Install Pi-hole in Docker Host (v6.3, port 53 DNS, port 8053 web)
- [x] Set Pi-hole upstream: 192.168.0.1#5353
- [x] Configure OPNsense DHCP to give Pi-hole IP as DNS
- [x] Add local DNS records (23 `dns.hosts` entries in pihole.toml)

### VPS (yvága)
- [x] Deploy AdGuard Home + Unbound stack (docker/vps/networking/adguard/)
- [x] Set AdGuard upstream: 172.20.0.10:5335 (Unbound static IP)
- [x] Disable AdGuard cache (Unbound handles it)
- [x] Add 18 DNS rewrites for internal *.cronova.dev hostnames
- [x] Configure blocklists: AdGuard DNS, OISD small, Steven Black
- [x] Set VPS resolv.conf: nameserver 127.0.0.1
- [x] Set accept-dns=false on VPS Tailscale
- [x] Add 127.0.0.1 hs.cronova.dev to /etc/hosts + cloud-init template

### Headscale
- [x] Configure dns_config with Tailscale IPs
- [x] Enable MagicDNS
- [x] Configure extra_records (20 A records for *.cronova.dev → Tailscale IPs)

## Security Considerations

- Pi-hole web interface: strong password, LAN-only access
- Unbound: bind to localhost or LAN only
- No DNS over WAN (firewall blocks port 53 inbound)
- Consider DNS-over-TLS for upstream (Pi-hole supports it)

## Troubleshooting

```bash
# Test Pi-hole
dig @192.168.0.10 example.com

# Test Unbound
dig @192.168.0.1 -p 5353 example.com

# Check Pi-hole logs
pihole -t

# Check what's blocking
pihole -q doubleclick.net
```

## References

- [Pi-hole + Unbound](https://docs.pi-hole.net/guides/dns/unbound/)
- [OPNsense Unbound](https://docs.opnsense.org/manual/unbound.html)
- [Headscale DNS](https://headscale.net/ref/dns/)
