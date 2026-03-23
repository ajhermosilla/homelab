# Homelab Evaluation

Comprehensive evaluation of the planned homelab stack. Reviewed 2026-01-15.

## Summary

| Factor | Score | Notes |
|--------|-------|-------|
| Utility | 9/10 | All bases covered, maybe over-engineered initially |
| Learning | 10/10 | Exceptional breadth and depth |
| Privacy | 9.5/10 | Near-perfect sovereignty |
| Costs | 9/10 | ~$15/mo for enterprise-grade setup |
| Geekiness | 11/10 | Off the charts |

---

## Utility: 9/10

### Strengths

| Service | Daily Use Value |
|---------|-----------------|
| Headscale | Remote access anywhere, no vendor lock-in |
| Vaultwarden | Password management across all devices |
| Pi-hole (x3) | Ad-free browsing everywhere |
| Jellyfin + *arr | Media consumption without subscriptions |
| Frigate | Security monitoring with AI detection |
| Home Assistant | Automation potential |
| Syncthing | File sync without cloud |
| Start9 | Bitcoin sovereignty |

### What You'll Actually Use Daily

- Vaultwarden (passwords)
- Pi-hole (transparent)
- Jellyfin (media)
- Headscale (remote access)

### Potentially Underutilized

- Home Assistant (needs smart devices to shine)
- Start9/Bitcoin (unless actively using Lightning)
- Frigate (3 cameras may be overkill initially)

### Suggestion

Consider if all 23 services are needed at launch. Start with core (Headscale, Pi-hole, Vaultwarden, Jellyfin) and add incrementally.

---

## Learning Opportunities: 10/10

### Coverage

| Domain | Technologies |
|--------|--------------|
| Virtualization | Proxmox VE, VM management |
| Networking | OPNsense, VLANs, DNS, mesh networking |
| Containers | Docker, docker-compose, multi-host |
| Security | Firewalls, certificates, encrypted backups |
| Storage | NFS, Samba, backup strategies |
| Linux | Debian, systemd, CLI tools |
| Bitcoin | Full node, Lightning, Electrum |
| ML/AI | Frigate object detection, Coral TPU |
| IaC | SOPS, age encryption, Ansible (planned) |

### Unique Learning Paths

- Running Headscale (not just using Tailscale)
- Proxmox + OPNsense virtualized router
- NFS for distributed storage
- Hardware video decode (QuickSync)

### Growth Areas (Future)

- Kubernetes (if you want to level up from Docker)
- Terraform (for VPS provisioning)
- Monitoring stack (Prometheus/Grafana)

---

## Data Privacy: 9.5/10

### Implementation

| Aspect | Implementation | Rating |
|--------|----------------|--------|
| Mesh control | Headscale (self-hosted) | Excellent |
| DNS | Pi-hole everywhere | Excellent |
| Passwords | Vaultwarden (local) | Excellent |
| Files | Syncthing P2P (no cloud) | Excellent |
| Media | Jellyfin (no tracking) | Excellent |
| Bitcoin | Start9 full node | Excellent |
| Backups | rclone crypt to Google | Good |

### Minor Concerns

- Google Drive for offsite backup (encrypted, but Google sees metadata)
- VPS on Vultr (US jurisdiction)

### Privacy Hardening Options

- Consider Backblaze B2 or Hetzner Storage Box instead of Google
- VPS on privacy-focused provider (Njalla, 1984.is) if paranoid
- Current setup is already excellent for 99% of threat models

#### The "carry your mesh in your backpack" philosophy is peak sovereignty

---

## Costs: 9/10

### Monthly Costs

| Item | Cost | Notes |
|------|------|-------|
| VPS (Vultr) | $6/mo | Helper only, not critical |
| Google One | $0 extra | Already have AI Pro subscription |
| cronova.dev | Owned | No additional cost |
| <BUSINESS_DOMAIN> | ~$5/mo | ~$60/yr to purchase |
| Electricity | ~$5-10/mo | Estimate for ~200W |
| **Total**|**~$12-16/mo** | |

### Hardware (One-Time, Already Owned)

- Most hardware repurposed (NAS from 2013, RPi 4)
- Smart purchases (PoE switch for cameras, UPS)

### Cost Optimizations Already Done

- Skipped nanduti.io + <BUSINESS_DOMAIN> ($42/yr saved)
- No Portainer (free tier limits)
- No Nextcloud (Syncthing is lighter)
- VPS as helper only (could be $0 if removed)

### Potential Savings

Could eliminate VPS entirely (~$72/yr) if you:

- Run DERP on mobile kit when traveling
- Use free uptime monitoring (Uptime Robot)
- Skip changedetection

**Verdict:** Exceptional value. Commercial equivalents would cost $50-100+/mo.

---

## Geekiness: 11/10

### Highlights

| Factor | Geek Points |
|--------|-------------|
| Headscale on RPi 5 | "Carry your mesh in your backpack" - peak mobile sovereignty |
| Start9 Bitcoin node | Full node + Lightning on dedicated hardware |
| Mini-ITX NAS from 2013 | Repurposed hardware, sustainable |
| CLI-first philosophy | lazydocker > Portainer, no GUIs needed |
| Modern shell tools | eza, bat, fd, ripgrep, starship |
| Guarani domain research | Cultural flex (nanduti.io research) |
| 3D printable case | Local maker culture |
| QuickSync video decode | Hardware optimization for Frigate |
| SOPS + age | Encrypted secrets in git |
| Three-tier redundancy | Mobile/Fixed/VPS independent operation |

### Geek Credentials

- Conventional commits
- Bare git repo for dotfiles
- GPG signed commits
- Vim keybindings everywhere
- Neovim + LazyVim

### What Would Increase Geekiness Further

- OpenWrt on Beryl AX (instead of stock)
- Custom Frigate ML model training
- Home Assistant automations with ESPHome
- Lightning payments for services

---

## Recommendations

### Phased Deployment

Prevents overwhelm and lets you learn each layer properly:

| Phase | Services | Focus |
|-------|----------|-------|
| 1 | Headscale, Pi-hole, Vaultwarden | Core infrastructure |
| 2 | Jellyfin, *arr stack | Media consumption |
| 3 | Home Assistant, Frigate, Mosquitto | Automation & security |
| 4 | Start9 (Bitcoin, Lightning) | Financial sovereignty |

### Quick Wins

1. Deploy mobile kit first (RPi 5 + Pi-hole + Headscale)
2. Get Vaultwarden running early (password access)
3. Media stack can wait until core is stable

### Long-Term Considerations

- Monitor actual usage of each service
- Prune services that don't get used
- Consider Kubernetes when Docker feels limiting
- Add Prometheus/Grafana for observability

---

## Conclusion

A thoughtfully designed, privacy-respecting, cost-effective homelab with excellent learning potential and maximum geek factor.

The architecture prioritizes sovereignty (self-hosted everything), resilience (three-tier redundancy), and practicality (CLI-first, minimal dependencies).

#### This is not just a homelab. It's a philosophy
