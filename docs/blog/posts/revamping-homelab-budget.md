---
date: 2026-04-01
draft: true
authors:
  - augusto
categories:
  - Homelab
  - Hardware
tags:
  - proxmox
  - opnsense
  - docker
  - budget
  - nas
---

# I Revamped My Homelab With a 13-Year-Old NAS and a $150 Mini PC

My NAS is older than some of the interns at work. It's an ASUS P8H77-I with an i3-3220T from 2013 — dusty, loud-ish, and still running every single day. When I decided to build a proper homelab, I didn't replace it. I paired it with a $150 mini PC and ended up running 68 services across three hosts.

Here's what I spent and what I got.

<!-- more -->

## The Hardware

### The Old: NAS (2013, $0)

I already had this sitting in a closet. An ASUS P8H77-I Mini-ITX board with an Intel i3-3220T, 8GB DDR3, and a mix of drives I've collected over the years. It boots from a USB stick because the BIOS can't detect the SSD's UEFI partition — a quirk I've learned to live with.

It runs 19 Docker containers: Forgejo (my own git server), Samba, Syncthing, a Restic backup server, Coolify PaaS, and a few apps I've built. It's not fast, but it's reliable. Thirteen years of reliability is hard to argue with.

| Component | Model | Age |
|-----------|-------|-----|
| Board | ASUS P8H77-I Mini-ITX | 2013 |
| CPU | Intel i3-3220T (2C/4T, 35W) | 2013 |
| RAM | 8GB DDR3 | 2013 |
| OS Drive | 240GB Lexar SSD | 2023 |
| Storage | 8TB WD Red + 2TB WD Purple | Mixed |
| Boot | 4GB USB stick | Yes, really |

**Cost: $0** — already owned.

### The New: Mini PC (2025, ~$150)

This is where the magic happens. An Intel N150 mini PC with dual 2.5G Ethernet — I got a really good deal on it and had always wanted to try Proxmox and OPNsense. The dual NICs made it perfect: one for WAN, one for LAN.

It runs Proxmox with two VMs:

- **OPNsense** — replaced my ISP's terrible router as the network gateway
- **Docker VM** (9GB RAM) — runs 36 containers: Pi-hole, Caddy, Home Assistant, Frigate NVR, Jellyfin, Immich, Vaultwarden, the entire monitoring stack, and more

The N150's integrated GPU handles hardware transcoding for Jellyfin and AI object detection for Frigate. It's a $150 box doing the work of three separate appliances.

| Component | Model | Notes |
|-----------|-------|-------|
| Board | Intel N150 Mini PC | Dual 2.5G LAN |
| CPU | Intel N150 (4C, 6W TDP) | Alder Lake-N |
| RAM | 12GB | 9GB allocated to Docker VM |
| Storage | 512GB NVMe | Proxmox + VMs |
| GPU | Intel UHD (integrated) | Jellyfin transcoding + Frigate AI |

**Cost: ~$150** — the best money I've spent on this project.

### The Cloud: VPS ($6/month)

A Vultr VPS with 1GB RAM running Headscale (self-hosted Tailscale), Caddy, Uptime Kuma, ntfy, and AdGuard + Unbound for recursive DNS. This is the glue — it coordinates the Tailscale mesh so I can access everything from anywhere.

**Cost: $6/month** ($72/year).

### The Network Gear (~$80)

| Item | Cost |
|------|------|
| MokerLink 8-port 2.5G switch | ~$45 |
| TP-Link PoE switch (cameras) | ~$25 |
| Archer AX50 (AP mode) | Already owned |
| Reolink cameras ×3 | Already owned |

## The Total

| Category | Cost |
|----------|------|
| NAS | $0 (owned) |
| Mini PC | ~$150 |
| Network gear | ~$80 |
| RPi 5 (AI assistant, pending) | $30 (PSU) |
| VPS (annual) | $72 |
| **Hardware total** | **~$330** |
| **Monthly recurring** | **$6** |

For $330 upfront and $6/month, I run 68 services. No subscriptions to Google, Dropbox, Plex, or any cloud provider for storage, photos, documents, or media. Everything is mine.

## What Runs on What

```text
Mini PC (Proxmox)                 NAS (Docker)              VPS (Vultr)
├── OPNsense (gateway)            ├── Forgejo (git)         ├── Headscale
└── Docker VM (36 containers)     ├── Samba (files)         ├── Caddy
    ├── Pi-hole (DNS)             ├── Syncthing             ├── Uptime Kuma
    ├── Caddy (reverse proxy)     ├── Restic REST           ├── ntfy
    ├── Home Assistant            ├── Coolify PaaS          └── AdGuard + Unbound
    ├── Frigate NVR (3 cameras)   ├── Javya (my app)
    ├── Jellyfin (media)          └── Katupyry (my app)
    ├── Immich (photos)
    ├── Vaultwarden (passwords)
    ├── Paperless-ngx (documents)
    ├── VictoriaMetrics + Grafana
    ├── Authelia (SSO)
    └── ... 24 more containers
```

The NAS handles storage and backups. The mini PC handles compute and networking. The VPS handles external access. Each host does what it's good at.

## The Naming Convention

Every service has a name in Guarani — the indigenous language of Paraguay, where I live. Frigate is *Taguato* (hawk), Home Assistant is *Jara* (owner/lord), the monitoring stack is *Papa* (a word for awareness). It started as a joke and became something I'm genuinely proud of.

## What I Learned

**Old hardware is fine for storage.** The NAS doesn't need a fast CPU. It serves files, runs backups, and hosts a git server. The i3-3220T handles all of that without breaking a sweat. If you have an old PC, it's a NAS.

**Dual NICs are a game-changer.** The dual 2.5G on the mini PC meant I could run OPNsense as a proper gateway — WAN on one port, LAN on the other. No VLANs-as-a-workaround, no USB Ethernet dongles. Worth every penny of the $150.

**Start small, grow naturally.** I didn't plan 68 services on day one. I started with Pi-hole and Caddy, then added Home Assistant, then Frigate, then "well, I need a password manager," then "might as well add photo backup," and here we are. The infrastructure grew to meet real needs, not a checklist.

**The $6/month VPS is the most important piece.** Without Headscale on the VPS, I'd have no remote access. It's the anchor that makes everything else accessible from anywhere in the world.

## What's Next

I'm 3D printing a 10-inch rack with a friend to clean up the cable mess. Right now everything sits on a shelf held together by hope and zip ties. The "after" photos are coming.

I'm also setting up an AI assistant on a Raspberry Pi Zero W ($10) and another on a Raspberry Pi 5 — one for personal use via Telegram, one as a family WhatsApp bot. Because apparently 68 services isn't enough.

---

*I document everything at [docs.cronova.dev](https://docs.cronova.dev) and the code is public at [github.com/ajhermosilla/homelab](https://github.com/ajhermosilla/homelab). Built from Asunción, Paraguay, powered by Docker, Ansible, and a lot of late nights.*

💬 [Discuss this post on GitHub](https://github.com/ajhermosilla/homelab/discussions)
