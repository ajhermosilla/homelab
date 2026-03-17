# Home Devices

Devices served by homelab services.

## Family Members

| Name | Role |
|------|------|

| Augusto | Owner |
| Andre | Wife |
| Anna Pau | Family |
| Mauri | Family |

---

## Mobile Devices (4)

| Device | Owner | OS | Homelab Services |
|--------|-------|-----|------------------|

| Samsung A16 | Augusto | Android | Tailscale, Vaultwarden, Jellyfin, ntfy, HA Companion |
| Google Pixel 6 | Andre | Android | Vaultwarden, Jellyfin |
| iPhone 14 Pro Max | Anna Pau | iOS | Vaultwarden, Jellyfin |
| Samsung A16 | Mauri | Android | Vaultwarden, Jellyfin |

#### Apps to install

- Tailscale (Augusto only - admin)
- Bitwarden (all - password manager)
- Jellyfin (all - media streaming)
- ntfy (Augusto - notifications)
- Home Assistant (Augusto - home automation)

---

## Computers (4)

| Device | Owner/Use | Specs | Homelab Services |
|--------|-----------|-------|------------------|

| MacBook Air M1 | Augusto (main) | 16GB RAM, 1TB SSD | Tailscale, dev work |
| MacBook Pro Mid 2012 | Andre | Pre-retina | Pi-hole DNS, Jellyfin |
| Lenovo ThinkPad X240 | Tinkering | i7, 8GB RAM, 240GB SSD | Lab experiments |
| Acer C720 | Tinkering | 2GB RAM, 128GB SSD | Lab experiments |

#### Tinkering ideas

- ThinkPad X240: Linux desktop, Docker experiments, portable dev box
- Acer C720: Install Linux (GalliumOS/ChromeOS Flex), lightweight tasks

---

## Entertainment (2)

| Device | Year | Platform | IP | MAC | Homelab Services |
|--------|------|----------|----|-----|------------------|

| LG Smart TV UM7100PSA | 2021 | WebOS | 192.168.0.51 | 74:40:be:da:6f:10 | Jellyfin, Pi-hole DNS, HA |
| Apple TV 4th Gen 32GB | 2016 | tvOS 26.3 | 192.168.0.50 | d0:03:4b:4b:24:91 | Jellyfin (via Infuse), Pi-hole DNS, HA |

**DHCP:** Static reservations in OPNsense (outside pool range .100-.250)

#### Jellyfin clients

- LG TV: Native Jellyfin app (WebOS)
- Apple TV: Infuse or Swiftfin app

---

## Audio (2)

| Device | Year | Notes |
|--------|------|-------|

| Yamaha RX-V671 | 2012 | AV Receiver, 7.1 channel |
| Infinity Speakers + Subwoofer | 2012 | Home theater speakers |

**Setup:** TV → Yamaha RX-V671 → Infinity Speakers

---

## Office (2)

| Device | Year | Connection | Notes |
|--------|------|------------|-------|

| HP Deskjet Ink Advantage 3545 | ~2016 | WiFi (5c:b9:01:56:34:58) | Printer |
| Brother ADS-1700W | 2021 | WiFi | Document scanner |

---

## Service Access Matrix

| Service | Augusto | Andre | Anna Pau | Mauri | TV/AppleTV |
|---------|---------|-------|----------|-------|------------|

| Tailscale | ✅ | ❌ | ❌ | ❌ | ❌ |
| Vaultwarden | ✅ | ✅ | ✅ | ✅ | ❌ |
| Jellyfin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Home Assistant | ✅ | ✅ | ❌ | ❌ | ✅ |
| HA Companion | ✅ | ❌ | ❌ | ❌ | ❌ |
| Pi-hole DNS | ✅ | ✅ | ✅ | ✅ | ✅ |
| ntfy | ✅ | ❌ | ❌ | ❌ | ❌ |
| Frigate | ✅ | ✅ | ❌ | ❌ | ❌ |

---

## Network Assignment

| Network | Devices |
|---------|---------|

| Management (VLAN 1) | MacBook Air, ThinkPad, C720 |
| IoT (VLAN 10) | Cameras (see hardware.md) |
| Guest (VLAN 20) | Visitor devices |
| Default | Phones, TV, Apple TV, Printer, Scanner, Andre's MacBook |

**Note:** Family devices stay on default network with Pi-hole DNS. Only admin/tinkering devices need Management VLAN access.

---

## DNS (Pi-hole)

All home devices use Pi-hole for:

- Ad blocking
- Tracking protection
- Local DNS resolution (*.cronova.dev)

Configure via OPNsense DHCP → DNS Server: `192.168.0.10`

---

## Device Summary

| Category | Count |
|----------|-------|

| Mobile | 4 |
| Computers | 4 |
| Entertainment | 2 |
| Audio | 2 |
| Office | 2 |
| **Total**|**14** |

*Excludes homelab infrastructure (documented in hardware.md)*
