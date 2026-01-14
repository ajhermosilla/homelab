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

**Principle:** Pi-hole is always the client-facing DNS. What happens upstream varies by environment.

## Environment DNS Flows

### Mobile Kit

```
[MacBook/Devices]
       |
       | DNS: 192.168.8.5
       v
[Pi-hole on RPi 5]
       |
       | Upstream: 1.1.1.1, 9.9.9.9
       v
[Cloudflare/Quad9]
```

| Component | Role | IP |
|-----------|------|-----|
| Beryl AX | DHCP, gives Pi-hole as DNS | 192.168.8.1 |
| Pi-hole (RPi 5) | Ad-blocking, DNS server | 192.168.8.5 |
| Upstream | Public recursive DNS | 1.1.1.1, 9.9.9.9 |

**Why public upstream:** Mobile kit travels. Running Unbound adds complexity for minimal benefit on the go.

### Fixed Homelab

```
[Home Devices]
       |
       | DNS: 192.168.1.10 (Docker Host)
       v
[Pi-hole in Docker]
       |
       | Upstream: 192.168.1.1 (OPNsense)
       v
[Unbound on OPNsense]
       |
       | Recursive queries
       v
[Root DNS Servers]
```

| Component | Role | IP |
|-----------|------|-----|
| OPNsense | DHCP, points to Pi-hole | 192.168.1.1 |
| Pi-hole (Docker) | Ad-blocking, DNS server | 192.168.1.10 |
| Unbound (OPNsense) | Recursive resolver | 192.168.1.1:5353 |

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
- Custom: 192.168.1.1#5353
- Uncheck all public resolvers
```

### VPS

```
[VPS Services]
       |
       | DNS: 127.0.0.1
       v
[Pi-hole on VPS]
       |
       | Upstream: 1.1.1.1, 9.9.9.9
       v
[Cloudflare/Quad9]
```

| Component | Role | IP |
|-----------|------|-----|
| Pi-hole | Local DNS for VPS + Tailscale fallback | 127.0.0.1 |
| Upstream | Public recursive DNS | 1.1.1.1, 9.9.9.9 |

**Use cases:**
- VPS containers use Pi-hole for DNS (ad-blocking for scraping)
- Tailscale devices can use VPS Pi-hole as fallback when home is down

## Tailscale DNS Integration

When on Tailscale mesh, devices can use any Pi-hole:

| Pi-hole Location | Tailscale IP | Use Case |
|------------------|--------------|----------|
| RPi 5 (mobile) | 100.64.0.1 | Primary when traveling |
| Docker Host (home) | 100.64.0.10 | Primary when home |
| VPS | 100.64.0.100 | Fallback, US-based |

**Headscale DNS Config** (on RPi 5):
```yaml
# /etc/headscale/config.yaml
dns_config:
  nameservers:
    - 100.64.0.1      # RPi 5 Pi-hole (primary)
    - 100.64.0.10     # Home Pi-hole (secondary)
  magic_dns: true
  base_domain: tail.net
```

## Local DNS Records

Pi-hole can resolve local hostnames:

```
# Pi-hole → Local DNS → DNS Records
192.168.1.10    minipc.home
192.168.1.11    rpi4.home
192.168.1.12    nas.home
192.168.8.5     rpi5.local
```

Or use Headscale MagicDNS:
```
minipc.tail.net  → 100.64.0.10
rpi5.tail.net    → 100.64.0.1
```

## DNS Failover

| Scenario | Behavior |
|----------|----------|
| Pi-hole down | Devices fail DNS (fix quickly) |
| Unbound down | Pi-hole falls back to public DNS |
| Home internet down | Mobile Pi-hole still works |
| VPS down | Home/mobile Pi-hole unaffected |

**Recommendation:** Configure Pi-hole with both Unbound AND one public resolver as backup:
```
Upstream DNS:
- 192.168.1.1#5353 (Unbound, primary)
- 9.9.9.9 (Quad9, fallback)
```

## Port Allocation

| Service | Port | Interface |
|---------|------|-----------|
| Pi-hole DNS | 53 | LAN-facing |
| Pi-hole Web | 80 | LAN-facing |
| Unbound | 5353 | localhost only |

## Configuration Checklist

### Mobile Kit (RPi 5)
- [ ] Install Pi-hole
- [ ] Set upstream: 1.1.1.1, 9.9.9.9
- [ ] Configure Beryl AX DHCP to give 192.168.8.5 as DNS
- [ ] Add local DNS records

### Fixed Homelab
- [ ] Configure Unbound on OPNsense (port 5353)
- [ ] Install Pi-hole in Docker Host
- [ ] Set Pi-hole upstream: 192.168.1.1#5353
- [ ] Configure OPNsense DHCP to give Pi-hole IP as DNS
- [ ] Add local DNS records

### VPS
- [ ] Install Pi-hole
- [ ] Set upstream: 1.1.1.1, 9.9.9.9
- [ ] Configure Docker to use 127.0.0.1 as DNS

### Headscale
- [ ] Configure dns_config with Tailscale IPs
- [ ] Enable MagicDNS

## Security Considerations

- Pi-hole web interface: strong password, LAN-only access
- Unbound: bind to localhost or LAN only
- No DNS over WAN (firewall blocks port 53 inbound)
- Consider DNS-over-TLS for upstream (Pi-hole supports it)

## Troubleshooting

```bash
# Test Pi-hole
dig @192.168.1.10 example.com

# Test Unbound
dig @192.168.1.1 -p 5353 example.com

# Check Pi-hole logs
pihole -t

# Check what's blocking
pihole -q doubleclick.net
```

## References

- [Pi-hole + Unbound](https://docs.pi-hole.net/guides/dns/unbound/)
- [OPNsense Unbound](https://docs.opnsense.org/manual/unbound.html)
- [Headscale DNS](https://headscale.net/ref/dns/)
