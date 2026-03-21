# Hetzner Cloud Migration Plan — 2026-03-13

## Status: DECIDED — Stay on Vultr 1GB ($6/mo)

> **Decision (2026-03-21)**: Stay on current Vultr 1GB plan. Workload runs fine on 1GB RAM. Defer upgrade to 2GB or migration to Sao Paulo when memory pressure requires it. Hetzner EU saves ~$5.65/mo but adds 240ms latency and account suspension risk — not worth it for $68/year.
>
> **Trigger to revisit**: consistent >80% memory usage on VPS, or adding new VPS services.
>
> See community research below (updated 2026-03-21 with Hetzner April price increase data).

## Context

Current VPS is Vultr ($6/mo, 1 vCPU, 1 GB RAM, 25 GB disk, 2 TB traffic). Running 11 containers with 737M/954M RAM used. Planning to upgrade to 2 GB for changedetection + playwright, which would cost ~$12/mo on Vultr. Hetzner offers significantly better specs per dollar.

---

## Pricing Comparison

### Current Workload Requirements

- 11 containers (headscale, caddy, DERP, pihole, adguard, unbound, uptime-kuma, ntfy, changedetection, playwright, headscale-backup)
- ~750M RAM baseline + playwright spikes
- 2 GB minimum, 4 GB comfortable
- Low disk usage (~9 GB of 30 GB)
- Low traffic (<1 TB/mo)

### Plan Comparison

| | Vultr (current) | Vultr 2GB | Hetzner CX22 (EU) | Hetzner CAX11 ARM (EU) | Hetzner CX32 (EU) |
|---|---|---|---|---|---|
| **Price** | $6/mo | ~$12/mo | ~$4.10/mo | ~$4.10/mo | ~$6.80/mo |
| **vCPUs** | 1 | 1 | 2 | 2 (ARM) | 4 |
| **RAM** | 1 GB | 2 GB | 4 GB | 4 GB | 8 GB |
| **Disk** | 25 GB | 50 GB | 40 GB | 40 GB | 80 GB |
| **Traffic** | 2 TB | 3 TB | 20 TB | 20 TB | 20 TB |

**Best value**: CX22 at ~$4/mo gives 4 GB RAM (4x current) for less than current Vultr bill. CX32 at ~$6.80/mo gives 8 GB for half the Vultr 2 GB upgrade price.

### Additional Costs

- Backups: 20% of server price (~$0.82/mo for CX22)
- Snapshots: per GB/mo (minimal)
- Floating IPs: ~$1/mo for IPv4
- Firewalls: free

---

## Features

### Datacenter Locations

| Location | Region | Traffic | Pricing |
|----------|--------|---------|---------|
| Nuremberg (NBG1) | Germany | 20 TB | Base price |
| Falkenstein (FSN1) | Germany | 20 TB | Base price |
| Helsinki (HEL1) | Finland | 20 TB | Base price |
| Ashburn (ASH) | Virginia, US | 1 TB | +20% |
| Hillsboro (HIL) | Oregon, US | 1 TB | +20% |
| Singapore (SIN) | Asia | 0.5 TB | +20% |

**Note**: No South America datacenter. Vultr has Sao Paulo/Buenos Aires. EU→Paraguay latency ~200-250ms, but Tailscale peer-to-peer connections bypass the VPS for most traffic. Only DERP relay and headscale control plane are affected.

### Infrastructure

- NVMe SSDs in RAID10
- Block storage volumes up to 10 TB (attachable/detachable)
- IPv4 + /64 IPv6 included
- Floating IPs (reassignable within datacenter)
- Private networks (free)
- Stateful firewalls (free)
- Managed load balancers

### ARM Option (CAX series)

Ampere Altra processors, same price as x86. Good for Docker workloads but requires arm64 container images. Most of our images support arm64:

- headscale, caddy, pihole, adguard, unbound, uptime-kuma, ntfy, changedetection — all have arm64
- **playwright (sockpuppetbrowser)** — needs verification, likely x86 only

**Recommendation**: Stick with x86 (CX series) to avoid compatibility issues unless playwright arm64 support is confirmed.

### Developer Tools

- REST API, `hcloud` CLI
- Official Terraform provider (`hetznercloud/hcloud`)
- Official Ansible collection
- Packer builder for custom images
- Go and Python SDKs

---

## Benefits Over Vultr

1. **2-4x better specs/dollar** in EU locations
2. **20 TB included traffic** vs 2-3 TB at Vultr
3. **Free firewalls** (managed, stateful)
4. **Mature IaC ecosystem** (Terraform, Ansible, Packer)
5. **ARM option** at same price (CAX series)
6. **Stronger privacy** — German company, GDPR-native (see below)

## Limitations

1. **No South America datacenter** — ~200-250ms from Paraguay (acceptable for Tailscale control plane)
2. **US locations cost 20% more** with only 1 TB traffic
3. **No managed object storage** (Vultr has S3-compatible)
4. **Strict abuse policy** — automated reports can cause fast suspensions
5. **Support** reportedly slower for complex issues

---

## Privacy Comparison

| | Hetzner (Germany) | Vultr (US) |
|---|---|---|
| **Jurisdiction** | GDPR-native | GDPR as overlay |
| **Data Protection Officer** | Published, dedicated | Generic email |
| **Sub-processors** | Mostly EU-based, transparent list | US-based, opaque |
| **Ad data sharing** | None | Shares with advertising partners |
| **Analytics** | Self-hosted Matomo | Third-party tracking |
| **Data residency** | EU emphasis, documented exceptions | No guarantees |
| **Payment processing** | German processor (Computop), no CC stored | Standard |

Hetzner is meaningfully stronger on privacy: GDPR-native jurisdiction, no ad data sharing, EU sub-processors, transparent practices.

---

## Payment Methods

| Method | Details |
|--------|---------|
| Credit Card | Visa, Mastercard, Amex, UnionPay (auto-charged, except UnionPay) |
| SEPA Direct Debit | EUR accounts only, auto-charged |
| PayPal | Available for active accounts |
| Bank/Wire Transfer | Manual payment |

For Paraguay: Visa/Mastercard credit card is the straightforward option.

---

## Migration Plan

### Pre-migration (remote)

1. Verify all container images have x86_64 builds (or arm64 if choosing CAX)
2. Create Hetzner account, provision CX22 in Falkenstein (FSN1)
3. Set low TTL on public DNS records pointing to current Vultr IP
4. Prepare new server: install Docker, clone homelab repo, set up SSH keys

### Migration (15-30 min downtime)

1. Stop VPS containers on Vultr
2. Export headscale SQLite DB + noise keys + config
3. Export uptime-kuma data, changedetection data, ntfy config
4. Transfer to Hetzner server (rsync or scp)
5. Recreate `.env` files from KeePassXC
6. Create Docker networks (`headscale-net`, `monitoring-net`, `adguard-net`, `scraping-net`)
7. Deploy stacks in order: networking → monitoring → scraping
8. Update public DNS A records to new Hetzner IP
9. Update `hs.cronova.dev` `/etc/hosts` entries on Docker VM and NAS
10. Verify headscale, all Tailscale nodes reconnect
11. Verify Caddy certs (Let's Encrypt will auto-provision)
12. Update Ansible inventory with new IP

### Post-migration

1. Verify all services accessible via `*.cronova.dev`
2. Test DERP relay connectivity
3. Monitor for 48h
4. Destroy Vultr instance
5. Update memory and documentation

### Rollback

Keep Vultr instance running for 48h after migration. If issues arise, revert DNS records and restart Vultr containers.

---

## Recommendation

**Hetzner CX22 (Falkenstein)** at ~$4.10/mo:

- 2 vCPU, 4 GB RAM, 40 GB disk, 20 TB traffic
- Saves ~$8/mo vs Vultr 2 GB upgrade ($12/mo)
- 4x the RAM, 2x the CPU, 10x the bandwidth
- Stronger privacy posture (German GDPR-native)
- Only trade-off: ~80ms more latency for DERP relay (acceptable)

---

## References

- [Hetzner Cloud Pricing](https://www.hetzner.com/cloud)
- [Hetzner Docs — Payment Overview](https://docs.hetzner.com/general/billing-and-account-management/billing-at-hetzner/payment-overview/)
- [Hetzner Docs — Cloud Billing](https://docs.hetzner.com/cloud/billing/)
