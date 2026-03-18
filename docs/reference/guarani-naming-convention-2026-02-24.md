# Guarani Naming Convention — Homelab Services

**Date:** 2026-02-24
**Context:** All homelab services use Guarani names for subdomains and hostnames, reflecting Paraguayan heritage.

---

## Active Names

| Service | Guarani Name | Meaning | Subdomain |
|---------|-------------|---------|-----------|

| Proxmox host | **oga** | house | — (SSH alias) |
| Home Assistant / Docker VM | **jara** | owner, lord | `jara.cronova.dev` |
| Frigate NVR | **taguato** | hawk | `taguato.cronova.dev` |
| Jellyfin | **yrasema** | sound of waterfalls | `yrasema.cronova.dev` |
| Coolify PaaS | **tajy** | lapacho tree | `tajy.cronova.dev` |
| Homepage | **mbyja** | star | `mbyja.cronova.dev` |
| Dozzle | **ysyry** | river, stream | `ysyry.cronova.dev` |
| BentoPDF | **kuatia** | paper, document | `kuatia.cronova.dev` |
| Authelia | **okẽ** | door | `auth.cronova.dev` |
| VictoriaMetrics + Grafana | **papa** | to count, measure | `papa.cronova.dev` |
| Immich | **vera** | shine, flash | `vera.cronova.dev` |
| Paperless-ngx | **aranduka** | book, library | `aranduka.cronova.dev` |
| AdGuard Home + Unbound | **yvága** | sky | `yvaga.cronova.dev` |
| Sonarr | **japysaka** | to catch, capture | `japysaka.cronova.dev` |
| Radarr | **taanga** | bone, structure | `taanga.cronova.dev` |
| Prowlarr | **aoao** | to search, investigate | `aoao.cronova.dev` |

---

## Proposed Names for New Services

### Top Picks

| Service | Guarani Name | Pronunciation | Meaning | Why |
|---------|-------------|---------------|---------|-----|

| Homepage | **mbyja** | mm-BUH-zhah | star | Guiding light, sees everything from above |
| Dozzle | **ysyry** | uh-suh-RUH | river, stream | Logs flowing like water |
| BentoPDF | **kuatia** | kwa-TEE-ah | paper, document | Literally what it handles |
| Authelia | **okẽ** | oh-KÉ | door | Guards the entrance to all services |
| CrowdSec | **itá** | ee-TÁ | stone, rock | Solid, unbreakable defense |
| VictoriaMetrics + Grafana | **papa** | pa-PÁ | to count, measure | Counting and measuring metrics |
| Immich | **vera** | VEH-rah | shine, flash, lightning | Flash of the camera |
| Paperless-ngx | **aranduka** | ah-ran-DOO-kah | book, library | Archive of all documents |
| n8n | **pytyvõ** | puh-tuh-VÕ | helper | Helps automate everything |

### Alternatives Considered

| Service | Alternative | Meaning | Notes |
|---------|-----------|---------|-------|

| Homepage | arakuaa | wisdom | Knows the state of everything |
| Dozzle | ñe'ẽ | word, voice | Reading the words of containers |
| Authelia | ñangareko | guardian, caretaker | Longer but more descriptive |
| CrowdSec | ñembyaty | assembly, gathering | Reflects crowd-sourced nature |
| VictoriaMetrics | aravo | time, hour | Time-series data |
| Grafana | ta'ãnga | image, picture | Visualizes data as graphs |
| Immich | marangatú | beautiful, blessed | Beautiful memories preserved |
| n8n | mba'apo | work, labor | The worker that runs workflows |

---

## Planned Subdomain Map

| Subdomain | Service | Host |
|-----------|---------|------|

| `jara.cronova.dev` | Home Assistant | Docker VM |
| `taguato.cronova.dev` | Frigate NVR | Docker VM |
| `yrasema.cronova.dev` | Jellyfin | Docker VM |
| `vault.cronova.dev` | Vaultwarden | Docker VM |
| `git.cronova.dev` | Forgejo | NAS |
| `status.cronova.dev` | Uptime Kuma | VPS |
| `notify.cronova.dev` | ntfy | VPS |
| `yvaga.cronova.dev` | AdGuard Home + Unbound | VPS |
| `mbyja.cronova.dev` | Homepage | Docker VM |
| `ysyry.cronova.dev` | Dozzle | Docker VM |
| `kuatia.cronova.dev` | BentoPDF | Docker VM |
| `auth.cronova.dev` | Authelia | Docker VM |
| `papa.cronova.dev` | VictoriaMetrics + Grafana | Docker VM |
| `vera.cronova.dev` | Immich | Docker VM |
| `tajy.cronova.dev` | Coolify PaaS | NAS |
| `aranduka.cronova.dev` | Paperless-ngx | Docker VM |
| `pytyvõ.cronova.dev` | n8n | Docker VM |

---

## Naming Guidelines

- Prefer short, pronounceable Guarani words (2-3 syllables)
- Match the meaning to the service's core purpose
- Animal names for active/intelligent services (taguato = hawk for NVR)
- Nature words for infrastructure (ysyry = river for log streams)
- Action/object words for utilities (kuatia = paper for PDF tools)
- Abstract concepts for security (okẽ = door, itá = stone)
