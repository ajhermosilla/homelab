# Self-Hosted PaaS Research: Definitive Guide (February 2026)

> **Context**: Research for choosing a self-hosted PaaS to deploy personal and professional web apps on a homelab Docker VM (9GB RAM, 2 cores, Proxmox).

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Tier Classification](#tier-classification)
3. [Master Comparison Table](#master-comparison-table)
4. [Tier 1: Full PaaS Platforms](#tier-1-full-paas-platforms)
   - [Coolify](#1-coolify)
   - [Dokploy](#2-dokploy)
   - [CapRover](#3-caprover)
   - [Dokku](#4-dokku)
   - [Easypanel](#5-easypanel)
   - [Cloudron](#6-cloudron)
5. [Tier 2: Deploy Tools](#tier-2-deploy-tools)
   - [Kamal](#7-kamal)
   - [Komodo](#8-komodo)
   - [Haloy](#9-haloy)
6. [Tier 3: Docker Management](#tier-3-docker-management)
   - [Portainer](#10-portainer)
   - [Dockge](#11-dockge)
7. [Out of Scope](#out-of-scope)
   - [Sealos](#12-sealos)
   - [PocketHost](#13-pockethost)
8. [Resource Footprint Analysis](#resource-footprint-analysis)
9. [Decision Framework for Your Homelab](#decision-framework-for-your-homelab)
10. [Final Recommendation](#final-recommendation)
11. [Sources](#sources)

---

## Executive Summary

The self-hosted PaaS landscape in 2026 is mature and competitive. **Coolify**has emerged as the community favorite with 51k+ GitHub stars and the most feature-rich offering, though it carries notable security baggage (11 CVEs disclosed in January 2026).**Dokploy**is the fast-rising challenger with a cleaner UI and Docker Swarm native support.**Dokku**remains the lightweight veteran for CLI-first developers.**Kamal** (from 37signals) is the minimalist's dream but requires more manual infrastructure management.

For a homelab with 9GB RAM already running multiple services (Frigate, Home Assistant, Pi-hole, Caddy, Vaultwarden, Mosquitto), the key constraint is **available RAM after existing services**. A full PaaS like Coolify or Dokploy will consume 250-400MB at idle before deploying any apps. Dokku uses only ~95MB. The choice depends on whether you value a web UI or prefer CLI workflows.

---

## Tier Classification

### Tier 1: Full PaaS (Heroku-like)

Git-push deploy, managed databases, web UI, SSL automation, monitoring, one-click app templates.

| Platform | Maturity | Stars |
|----------|----------|-------|

| Coolify | High | 51k |
| Dokploy | Medium | 28k |
| CapRover | High | 14k |
| Dokku | Very High | 32k |
| Easypanel | Medium | N/A (proprietary core) |
| Cloudron | High | N/A (proprietary, paid) |

### Tier 2: Deploy Tools

Focused on getting containers to servers. No built-in DB management, minimal UI.

| Platform | Maturity | Stars |
|----------|----------|-------|

| Kamal | High | 11k+ |
| Komodo | Medium | 10k |
| Haloy | Low | New |

### Tier 3: Docker Management

GUI for managing existing Docker containers. Not a deploy pipeline.

| Platform | Maturity | Stars |
|----------|----------|-------|

| Portainer | Very High | 32k+ |
| Dockge | Medium | 22k |

---

## Master Comparison Table

| Platform | Type | Min RAM | Idle RAM | Git Deploy | Auto SSL | DB Mgmt | Web UI | GitHub Stars | Best For |
|----------|------|---------|----------|------------|----------|---------|--------|--------------|----------|

| **Coolify** | Full PaaS | 2 GB | ~380 MB | Yes | Yes | Yes | Yes | 51k | Feature-hungry teams |
| **Dokploy** | Full PaaS | 2 GB (4 rec.) | ~300 MB | Yes | Yes | Yes | Yes | 28k | Clean UI + Docker Swarm |
| **CapRover** | Full PaaS | 1 GB | ~210 MB | Yes | Yes | Basic | Yes | 14k | Simple + lightweight PaaS |
| **Dokku** | Full PaaS | 1 GB | ~95 MB | Yes | Yes | Via plugins | CLI only | 32k | CLI-first minimalists |
| **Easypanel** | Full PaaS | 1 GB est. | Unknown | Yes | Yes | Yes | Yes | Proprietary | Non-technical users |
| **Cloudron** | Full PaaS | 2 GB | ~500 MB | No (app store) | Yes | Yes | Yes | Proprietary | Managed app hosting |
| **Kamal** | Deploy tool | 2 GB | ~0 MB* | Via CI/CD | Yes | No | No | 11k+ | Rails/Docker minimalists |
| **Komodo** | Deploy tool | 1 GB est. | Low (Rust) | Webhook | No** | No | Yes | 10k | Multi-server orchestration |
| **Haloy** | Deploy tool | 512 MB est. | Low (Go) | No (CLI push) | Yes | No | No | New | Indie devs, CLI-first |
| **Portainer** | Docker mgmt | 512 MB | ~100 MB | Webhooks | No | No | Yes | 32k+ | Docker beginners |
| **Dockge** | Docker mgmt | 256 MB | ~50 MB | No | No | No | Yes | 22k | Compose file management |

\* Kamal runs nothing on server except your app + kamal-proxy (~10MB)
\** Komodo requires external reverse proxy for HTTPS

---

## Tier 1: Full PaaS Platforms

---

### 1. Coolify

**One-liner**: The most feature-rich self-hosted PaaS alternative to Vercel/Heroku/Netlify, with 280+ one-click services.

**Website**: [coolify.io](https://coolify.io)
**GitHub**: [coollabsio/coolify](https://github.com/coollabsio/coolify) -- 51k stars
**License**: Apache 2.0 (fully open source)
**Latest**: v4.0.0-beta.463 (Feb 2026)

#### Architecture

- **Backend**: PHP (Laravel), Traefik reverse proxy
- **Database**: PostgreSQL (internal)
- **Multi-server**: Docker Swarm-based, SSH connections to remote servers
- **Build**: Nixpacks, Dockerfiles, Docker Compose, Buildpacks

#### Key Features

- Git push deploy from GitHub, GitLab, Bitbucket, Gitea
- 280+ one-click service templates (Supabase, Plausible, n8n, etc.)
- Full Docker Compose stack support (unique among PaaS tools)
- Managed databases with automated S3 backups
- Preview deployments for pull requests (GitHub App integration)
- Integrated Grafana monitoring
- Multi-server management from single panel
- Let's Encrypt automatic SSL
- Webhook and API support

#### Resource Requirements

- **Minimum**: 2 vCPU, 2 GB RAM, 30 GB disk
- **Recommended**: 4 vCPU, 4 GB RAM, 40 GB+ disk
- **Idle RAM**: ~380 MB
- **Disk footprint**: ~1.2 GB

#### Supported App Types

Static sites, Node.js, Python, Go, Rust, PHP, Ruby, Java -- anything with a Dockerfile or buildpack. Full Docker Compose stacks.

#### Community

- 51,000+ GitHub stars (largest in category)
- Very active development (multiple releases per week)
- Large Discord community
- Extensive video guides and LLM-optimized documentation

#### Pros

- Most feature-rich option by far
- Docker Compose support is a killer feature (deploy multi-container stacks)
- Beautiful, modern web UI
- Massive one-click app library
- Active development with rapid iteration
- Apache 2.0 license -- truly open source
- Preview deployments for PRs (Vercel-like workflow)

#### Cons

- **SECURITY**: 11 critical CVEs (CVSS up to 10.0) disclosed January 2026, exposing 52,000+ instances to RCE and auth bypass. Patched quickly but reveals code quality concerns.
- Highest resource consumption among PaaS options (~380 MB idle)
- Web UI can feel clunky for complex setups
- Docker Swarm scaling limitations (no Kubernetes migration path)
- Database restores require manual SSH commands
- Multi-server load balancing needs manual configuration
- Frequent beta releases can introduce regressions (Docker layer caching bug in v432)
- Still technically in "beta" (v4.0.0-beta.xxx)

#### Best For

Teams or solo developers who want a Vercel/Heroku-like experience with maximum features and don't mind the resource overhead. Ideal if you want to deploy full-stack apps, manage databases, and run one-click services all from one panel.

#### Community Quotes

- *"Coolify is basically a self-hosted Vercel/Netlify/Heroku that actually works"* -- r/selfhosted
- *"Docker Compose support is a game-changer -- unlike CapRover and Dokku, Coolify can deploy entire Docker Compose stacks"* -- selfhostable.dev
- *"For most people in 2026, Coolify is the best choice. It's the most feature-rich, actively developed, and beginner-friendly"* -- community consensus
- *"Coolify can be a good thing if you really want too much functionality -- it has some bugs still"* -- Reddit user

---

### 2. Dokploy

**One-liner**: A cleaner, Docker-native PaaS alternative to Coolify with built-in Docker Swarm support and Traefik integration.

**Website**: [dokploy.com](https://dokploy.com)
**GitHub**: [Dokploy/dokploy](https://github.com/Dokploy/dokploy) -- 28k stars
**License**: Apache 2.0 (with commercial restrictions on some features -- effectively source-available)
**Latest**: v0.25.0 (2026)

#### Architecture

- **Backend**: TypeScript (Next.js)
- **Database**: PostgreSQL (internal) + Redis (deployment queue)
- **Reverse proxy**: Traefik (auto-configured with dynamic routing)
- **Multi-server**: Native Docker Swarm mesh networking
- **Build**: Nixpacks, Heroku Buildpacks, Paketo Buildpacks, Dockerfiles

#### Key Features

- Clean, modern UI (widely praised as superior to Coolify's)
- 350+ one-click templates
- Native Docker Swarm multi-server clustering (no manual load balancer config)
- Real-time monitoring (CPU, memory, storage, network per resource)
- Well-documented Swagger/OpenAPI specs
- Multiple git provider support (GitHub, GitLab, Bitbucket)
- Docker Compose deployment support
- Traefik file editor for advanced routing

#### Resource Requirements

- **Minimum**: 2 vCPU, 2 GB RAM (4 GB recommended), 30 GB disk
- **Recommended**: 4 vCPU, 8 GB RAM, 40 GB+ disk
- **Idle RAM (UI only)**: ~250 MB
- **Idle RAM (with apps)**: ~300 MB+

#### Supported App Types

Same breadth as Coolify -- any Docker-compatible app, static sites, databases. Multiple build method support.

#### Community

- 28,000+ GitHub stars (growing fast)
- 200+ contributors
- 6M+ Docker Hub downloads
- Active Discord community

#### Pros

- Cleaner, more intuitive UI than Coolify
- Docker Swarm clustering works out of the box (Traefik auto-discovers services)
- Strong monitoring built in
- Well-documented API
- Faster-growing community momentum
- Official MCP server for AI integration (67 tools)

#### Cons

- Licensing is murky -- "Apache 2.0" but with restrictions on commercial use (effectively source-available)
- Younger project with less battle-testing than Coolify
- No preview deployments for pull requests
- Fewer community resources, tutorials, and video guides
- Similar resource overhead to Coolify
- Smaller one-click template library (though 350+ is still substantial)

#### Best For

Developers who want a PaaS experience with a cleaner interface and value Docker Swarm native support. Good for teams wanting multi-server clustering without manual configuration.

#### Community Quotes

- *"I chose Dokploy for its modern UI, simplicity without sacrificing power, and active development"* -- Medium blog post
- *"Dokploy shines with its modern, Docker-centric approach, superior monitoring capabilities, and better built-in scaling features"* -- Cherry Servers
- *"Many users use Dokploy for critical production applications and Coolify for auxiliary services"* -- INTROSERV blog
- *"Dokploy is a lighter and younger alternative with a fast UI and an active development team"* -- comparison review

---

### 3. CapRover

**One-liner**: A lightweight, battle-tested PaaS that sits between Coolify's feature-richness and Dokku's minimalism.

**Website**: [caprover.com](https://caprover.com)
**GitHub**: [caprover/caprover](https://github.com/caprover/caprover) -- 14k stars
**License**: Apache 2.0
**Originally**: CaptainDuckDuck (since 2017)

#### Architecture

- **Backend**: Node.js
- **Reverse proxy**: Nginx (auto-configured)
- **Monitoring**: NetData (built-in)
- **Multi-server**: Docker Swarm clustering
- **Build**: Captain file templates, Dockerfiles (limited Docker Compose support)

#### Key Features

- Web dashboard + CLI tools
- 50+ one-click app templates
- Docker Swarm cluster support
- Automatic Let's Encrypt SSL
- Custom Nginx configuration per app
- In-place upgrades from web UI
- NetData monitoring integration

#### Resource Requirements

- **Minimum**: 1 GB RAM
- **Idle RAM**: ~210 MB
- **Disk footprint**: ~800 MB

#### Supported App Types

Node.js, Python, PHP, Ruby, Go, Java, .NET, static sites, Docker images.

#### Community

- 14,000 GitHub stars
- Stable, mature community since 2017
- Good documentation
- Active but slower development pace than Coolify/Dokploy

#### Pros

- Lighter resource footprint than Coolify (~210 MB vs ~380 MB)
- Stable and mature (8 years of development)
- Good web UI without being heavyweight
- Docker Swarm clustering works well
- Free and truly open source
- In-place upgrades are trivial

#### Cons

- **No Docker Compose support** (only subselection of Docker Compose parameters)
- UI feels dated compared to Coolify and Dokploy
- Less actively developed (slower release cadence)
- Smaller and shrinking community (relative to Coolify/Dokploy)
- Custom "Captain file" format adds learning overhead
- Single-container limitation per app (no multi-container stacks)

#### Best For

Users who want a visual PaaS that's lighter than Coolify but more than Dokku. Good for teams managing simple containerized apps where Docker Compose support isn't needed.

#### Community Quotes

- *"I prefer CapRover because it does everything I need and is lighter weight than Coolify and has a GUI (unlike Dokku)"* -- Reddit user
- *"CapRover works well if you like control and don't mind a bit of server work"* -- r/selfhosted
- *"CapRover sits nicely between Coolify's feature-richness and Dokku's minimalism"* -- selfhostable.dev

---

### 4. Dokku

**One-liner**: The original "mini Heroku" -- a CLI-only, ultra-lightweight PaaS with 13 years of rock-solid stability.

**Website**: [dokku.com](https://dokku.com)
**GitHub**: [dokku/dokku](https://github.com/dokku/dokku) -- 32k stars
**License**: MIT
**Latest**: v0.36.11 (2026)
**Since**: 2013

#### Architecture

- **Backend**: Go (rewritten from original Bash)
- **Reverse proxy**: Nginx (default), Caddy, or Traefik options
- **Build**: Heroku Buildpacks, Dockerfiles, Docker images
- **Multi-server**: Single server only (by design)
- **Plugins**: Extensive plugin ecosystem

#### Key Features

- `git push dokku main` deployment workflow (identical to Heroku)
- Heroku-compatible buildpacks (no Dockerfile needed for most languages)
- Plugin ecosystem: PostgreSQL, Redis, MongoDB, MariaDB, Elasticsearch, etc.
- Automatic Let's Encrypt SSL (via plugin)
- Multiple reverse proxy options
- Process scaling per app
- Zero-downtime deploys
- Cron job scheduling

#### Resource Requirements

- **Minimum**: 1 GB RAM
- **Idle RAM**: ~95 MB (lowest of all PaaS options)
- **Disk footprint**: ~300 MB

#### Supported App Types

Any language supported by Heroku buildpacks (Node.js, Python, Ruby, Go, Java, PHP, Scala, Clojure) plus anything with a Dockerfile.

#### Community

- 32,000 GitHub stars
- 13 years of development (most mature option)
- Excellent, comprehensive documentation (among best in the space)
- Rich plugin ecosystem

#### Pros

- **Lowest resource usage** -- only ~95MB idle, ~300MB disk
- Rock-solid stability from 13 years of development
- `git push` workflow is simple and elegant
- Heroku buildpacks mean no Dockerfile knowledge needed
- Excellent documentation
- MIT license (most permissive)
- Flexible reverse proxy choice (Nginx/Caddy/Traefik)

#### Cons

- **CLI only** -- no web UI whatsoever
- **Single-server only** -- no multi-server, no clustering
- No multi-user support or RBAC
- Database management requires separate plugins
- Plugin quality varies
- No built-in monitoring
- No Docker Compose support for deployments

#### Best For

Solo developers, side projects, and small production workloads where resource efficiency matters. Perfect for someone running multiple apps on a RAM-constrained VM who prefers CLI workflows.

#### Community Quotes

- *"Dokku is the lightest and cheapest in terms of resource usage"* -- selfhostable.dev
- *"Dokku is the veteran of this list, first released in 2013. It's a mini Heroku that gives you git-push deployments on a single server"* -- Haloy blog
- *"Rock solid stability from long development history"* -- comparison review
- *"If you're an advanced developer who values full control and lightweight deployment, choose Dokku"* -- EgyVps

---

### 5. Easypanel

**One-liner**: A modern, beginner-friendly server control panel with Docker under the hood, positioned as a simpler alternative to Coolify.

**Website**: [easypanel.io](https://easypanel.io)
**GitHub**: [easypanel-io](https://github.com/easypanel-io) (templates are open source; core is proprietary)
**License**: Proprietary (free "Developer Edition" available)

#### Architecture

- **Backend**: Proprietary
- **Build**: Cloud Native Buildpacks
- **Reverse proxy**: Traefik
- **Database**: Built-in support for MySQL, PostgreSQL, MongoDB, Redis

#### Key Features

- One-click app templates
- Automatic Let's Encrypt SSL
- GitHub/GitLab/Bitbucket CI/CD integration
- Built-in database management
- Clean, modern UI designed for simplicity

#### Resource Requirements

- **Minimum**: ~1 GB RAM (estimated)
- **Recommended**: 2 GB+ RAM

#### Supported App Types

Node.js, Ruby, Python, PHP, Go, Java, Docker images, static sites.

#### Community

- Proprietary core -- limited community contributions
- Growing user base among VPS operators

#### Pros

- Very clean, intuitive UI
- Good one-click templates
- Free developer edition
- Low learning curve

#### Cons

- **Proprietary core** -- not truly open source
- Limited community contributions and transparency
- Paid tiers for advanced features
- Smaller ecosystem than Coolify/Dokploy
- Less flexibility for power users

#### Best For

Non-technical users or beginners who want the simplest possible PaaS experience and don't mind proprietary software.

---

### 6. Cloudron

**One-liner**: A polished, all-in-one server app store with automatic updates, backups, user management, and email -- but it costs money.

**Website**: [cloudron.io](https://<www.cloudron.io>)
**License**: Proprietary (paid)
**Pricing**: Free (2 apps, 2 users), Hobbyist ($15/mo), Standard ($30/mo), Premium ($90/mo)

#### Architecture

- **Backend**: Proprietary
- **App model**: Curated app packages (not raw Docker)
- **Updates**: Fully automated
- **Backups**: Automated to S3, Google Cloud, etc.

#### Key Features

- App store model -- install apps like WordPress, Nextcloud, GitLab with one click
- Fully automated updates and security patches
- Built-in email server
- User management with SSO
- Automated backup and restore
- DNS management

#### Resource Requirements

- **Minimum**: 2 GB RAM
- **Idle RAM**: ~500 MB (heaviest of all options)

#### Supported App Types

Only apps that have been packaged for Cloudron. Limited to the curated catalog.

#### Pros

- Most "hands-off" option -- updates, backups, and security are automatic
- Excellent for non-developers who want to run standard apps
- Built-in email server is unique
- User management and SSO built in

#### Cons

- **Not free** -- $15-90/month
- **Not open source**
- Only curated apps (can't deploy arbitrary code)
- No git push deploy workflow
- Not a developer PaaS -- more of a server app store
- Highest idle RAM (~500 MB)

#### Best For

Non-technical users who want to run standard self-hosted apps (Nextcloud, WordPress, email) with zero maintenance. Not suitable as a developer PaaS.

---

## Tier 2: Deploy Tools

---

### 7. Kamal

**One-liner**: 37signals' zero-overhead deployment tool that uses Docker and SSH to deploy containers with zero-downtime swaps.

**Website**: [kamal-deploy.org](https://kamal-deploy.org)
**GitHub**: [basecamp/kamal](https://github.com/basecamp/kamal) -- 11k+ stars
**License**: MIT
**From**: 37signals (makers of Basecamp, HEY)
**Latest**: Kamal 2.x (2025)

#### Architecture

- **Backend**: Ruby gem (CLI tool)
- **On-server**: Only your app container + kamal-proxy (~10MB binary)
- **Reverse proxy**: kamal-proxy (custom, built-in, handles SSL via Let's Encrypt)
- **Deploys via**: SSH (pulls Docker images from a registry)
- **Requires**: Docker registry (Docker Hub, GHCR, etc.)
- **No daemon**: Nothing runs on server except your app

#### Key Features

- Zero-downtime rolling deploys
- Automatic SSL via Let's Encrypt (kamal-proxy)
- Multi-server deployments
- Canary deployments
- Rolling restarts
- Maintenance mode
- Accessory services (Redis, databases alongside app)
- Secrets management (from 1Password, Bitwarden, LastPass, etc.)
- Environment variable management
- Bundled with Rails 8 as default deploy method

#### Resource Requirements

- **Minimum**: 2 GB RAM recommended
- **Server overhead**: ~0 MB (only kamal-proxy, ~10MB binary)
- **Build**: Local machine or CI server (not on deploy target)

#### Supported App Types

Any Docker container. Originally designed for Rails but works with any language that produces a Docker image (Python, Go, Node.js, etc.). Kamal is framework-agnostic.

#### Community

- 11,000+ GitHub stars
- Strong Rails/Ruby community adoption
- Backed by 37signals (runs HEY email, Basecamp production)
- Growing adoption outside Rails ecosystem

#### Pros

- **Zero server overhead** -- nothing runs except your app + tiny proxy
- Battle-tested at 37signals scale
- Clean, simple deployment model
- Built-in SSL without extra configuration
- Multi-server and rolling deploys
- Minimal attack surface on servers
- MIT license

#### Cons

- **Requires Docker registry** (no registry-free option)
- **Requires Ruby** installed on local machine (friction for non-Ruby devs)
- **No web UI** -- entirely CLI-driven via `deploy.yml` config
- No built-in monitoring, logging, or database management
- Docker iptables bypass UFW (security gotcha for non-experts)
- Health check complications with rate limiters
- Best documentation/guides are paid products
- Gap between marketing promise and production reality widens with infrastructure complexity

#### Best For

Developers who want absolute minimal server overhead and are comfortable managing infrastructure manually. Excellent for Rails apps, good for any Docker app if you're comfortable with the CLI workflow.

#### Community Quotes

- *"If you are deploying a new application to a fresh server with no existing infrastructure to work around, Kamal is genuinely excellent"* -- Ivan Turkovic (Feb 2026 review)
- *"The gap between Kamal's marketing promise and production reality widens substantially once infrastructure complexity increases"* -- honest review
- *"Trying to layer nginx alongside kamal-proxy is not worth the complexity"* -- production experience report
- *"Kamal is a strong choice, especially for Rails teams, with zero server overhead and is battle-tested at 37signals scale"* -- Evil Martians

---

### 8. Komodo

**One-liner**: A Rust-based server management platform that treats servers, deployments, builds, and automation as interconnected resources -- like Portainer on steroids.

**Website**: [komo.do](https://komo.do)
**GitHub**: [moghtech/komodo](https://github.com/moghtech/komodo) -- 10k stars
**License**: GPL-3.0 (no feature gating)

#### Architecture

- **Backend**: Rust (Komodo Core -- web server + API + UI)
- **Agents**: Komodo Periphery (lightweight Rust agent on each server)
- **Build**: Docker image builds from git repos, auto-versioned
- **Requires**: Docker registry for builds
- **No built-in reverse proxy** -- must configure externally

#### Key Features

- Unified resource abstraction (servers, deployments, stacks, builds, procedures)
- Docker container management across multiple servers
- Docker Compose stack deployments (file in UI or git repo)
- Auto-versioned Docker image builds with webhook triggers
- Server monitoring (CPU, memory, disk)
- Container log viewing and shell access
- Declarative infrastructure via TOML sync files
- TypeScript-based custom automation scripts
- Alert system for resource usage

#### Resource Requirements

- **Minimum**: ~1 GB RAM (estimated, Rust is efficient)
- **Idle RAM**: Low (Rust binary, no interpreted runtime)
- **Per-server agent**: Lightweight, stateless

#### Supported App Types

Any Docker container or Docker Compose stack.

#### Community

- 10,000 GitHub stars (growing rapidly)
- 45+ contributors
- Active development (Feb 2026 releases)
- Growing homelab adoption

#### Pros

- Rust backend means excellent performance and low resource usage
- Multi-server management without PaaS overhead
- GPL-3.0 with no paid tier or feature gating
- Declarative infrastructure (TOML sync files)
- Flexible automation (TypeScript procedures)
- Scales to many servers without artificial limits
- Strong momentum in homelab community

#### Cons

- Steeper learning curve (broad scope)
- Requires agent on every managed server
- No built-in HTTPS or reverse proxy (must configure Caddy/Traefik/etc.)
- Requires Docker registry for builds
- Smaller community, sparser documentation
- No git push deploy (webhook-triggered builds)

#### Best For

Homelabbers managing multiple servers who want a centralized platform for orchestration without the overhead of a full PaaS. Good Portainer replacement with build/deploy capabilities.

#### Community Quotes

- *"Komodo is the newest option for home labbers and arguably might be what they will lean toward in late 2025 going into 2026"* -- Virtualization Howto
- *"Free, fast, and modern with great management features built in"* -- homelab review
- *"Komodo takes a broader scope than most tools, treating servers, deployments, stacks, builds, and automation procedures as interconnected resources"* -- Haloy blog

---

### 9. Haloy

**One-liner**: A minimalist CLI tool that builds Docker images locally and uploads only changed layers to your server -- no registry needed.

**Website**: [haloy.dev](https://haloy.dev)
**GitHub**: [haloydev/haloy](https://github.com/haloydev/haloy)
**License**: Open source (Go)
**Status**: Very new (2025-2026)

#### Architecture

- **CLI**: Go binary on local machine
- **Server**: Lightweight daemon (haloyd) running over HTTPS
- **Build**: Local Docker build, direct layer upload (no registry)
- **Reverse proxy**: Built-in with Let's Encrypt
- **Deploy**: Zero-downtime container swap

#### Key Features

- Direct Docker layer upload (no registry required)
- Smart layer caching (only upload changed layers)
- Single YAML configuration
- Automatic HTTPS via Let's Encrypt
- Built-in health checks
- Zero-downtime deployments
- Multi-server deployment with staging/production targets
- Container monitoring and auto-recovery
- Designed for AI coding assistant integration

#### Resource Requirements

- **Minimum**: ~512 MB RAM (estimated)
- **Server overhead**: Lightweight Go daemon

#### Supported App Types

Anything that can be containerized with Docker.

#### Pros

- No Docker registry needed (unique selling point)
- Minimal configuration (single YAML file)
- Built-in SSL
- Smart caching reduces deploy bandwidth
- Lightweight
- AI/LLM-friendly design

#### Cons

- **Newest tool in the space** -- least battle-tested
- **CLI only** -- no web dashboard
- Smallest community
- Very few tutorials or guides
- Unproven in production at scale

#### Best For

Indie developers and small teams who want the simplest possible Docker deployment without a registry or PaaS overhead.

---

## Tier 3: Docker Management

---

### 10. Portainer

**One-liner**: The most widely-used Docker management GUI, now supporting Docker, Kubernetes, Podman, and Swarm.

**Website**: [portainer.io](https://<www.portainer.io>)
**GitHub**: [portainer/portainer](https://github.com/portainer/portainer) -- 32k+ stars
**License**: Zlib (CE free), Business Edition paid
**Latest**: Actively maintained (2026)

#### Architecture

- **Backend**: Go
- **Frontend**: Angular
- **Agent-based**: Portainer Agent for remote Docker hosts
- **Supports**: Docker, Kubernetes, Podman, Docker Swarm, ACI

#### Key Features

- Visual Docker container management
- Stack deployment from Docker Compose files
- Container logs, stats, shell access
- Image management
- Network and volume management
- Git-based stack deployments (webhooks)
- User management (basic in CE)
- Multi-environment management

#### Resource Requirements

- **Minimum**: ~512 MB RAM
- **Idle RAM**: ~100 MB

#### What It Is NOT

- Not a PaaS -- no git push deploy, no buildpacks, no SSL management
- Not a CI/CD tool -- no builds from source
- A Docker management GUI, not a deployment platform

#### Pros

- Excellent for visualizing and managing existing Docker containers
- Multi-platform support (Docker, K8s, Podman)
- Mature and widely adopted
- Good for teams transitioning from CLI to GUI
- Stack deployment from compose files

#### Cons

- Not a PaaS -- can't replace Heroku/Vercel workflows
- CE (free) edition becoming more limited over time (RBAC, SSO moved to paid tier)
- No build pipeline
- No git push deployment
- No automatic SSL certificate management

#### Best For

Docker management visualization alongside a CLI-based PaaS like Dokku or Kamal. Complementary tool, not a replacement for PaaS.

---

### 11. Dockge

**One-liner**: A beautiful, reactive Docker Compose stack manager from the creator of Uptime Kuma -- your compose files stay on disk, not locked in a database.

**Website**: [dockge.kuma.pet](https://dockge.kuma.pet)
**GitHub**: [louislam/dockge](https://github.com/louislam/dockge) -- 22k stars
**License**: MIT
**Creator**: Louis Lam (Uptime Kuma)

#### Key Features

- Docker Compose stack management via web UI
- YAML editor with live preview
- Container logs and terminal access
- Files stay on disk (no database lock-in)
- Multi-agent support (v1.5+) for multiple Docker hosts
- Works alongside `docker compose` CLI

#### Resource Requirements

- **Minimum**: ~256 MB RAM
- **Idle RAM**: ~50 MB

#### What It Is NOT

- Not a PaaS -- no git deploy, no builds, no SSL, no databases
- A compose file manager, not a deployment platform

#### Pros

- Beautiful UI (from Uptime Kuma creator)
- Compose files stay on disk -- no lock-in
- Extremely lightweight
- MIT license
- Multi-host support

#### Cons

- No build pipeline, no CI/CD, no SSL, no RBAC
- Only manages existing compose stacks
- Not a PaaS replacement

#### Best For

Managing existing Docker Compose stacks with a nice UI. Complementary to manual compose-based homelab workflows (like your current setup).

---

## Out of Scope

### 12. Sealos

**One-liner**: An AI-native Cloud Operating System built on 100% upstream Kubernetes.

**Website**: [sealos.io](https://sealos.io)
**GitHub**: [labring/sealos](https://github.com/labring/sealos) -- 14k+ stars

**Why Out of Scope**: Sealos requires a full Kubernetes cluster. With 9GB RAM on a Docker VM with 2 cores, running Kubernetes is impractical -- K8s control plane alone consumes 2-4GB RAM. Sealos is designed for organizations with dedicated Kubernetes infrastructure, not single-node homelabs.

**Minimum Requirements**: 4+ GB RAM for K8s control plane, 8+ GB for practical use with apps. A single-node K8s cluster on 9GB RAM leaves very little for actual workloads.

### 13. PocketHost

**One-liner**: Multi-tenant PocketBase hosting platform (not a general-purpose PaaS).

**Website**: [pockethost.io](https://pockethost.io)
**GitHub**: [pockethost/pockethost](https://github.com/pockethost/pockethost)

**Why Out of Scope**: PocketHost is specifically for running PocketBase instances. It's not a general-purpose PaaS. If you need PocketBase, just run it directly -- it's a single 14MB Go binary. Self-hosting PocketHost requires significant setup and is "not recommended for the faint of heart" per the project docs.

---

## Resource Footprint Analysis

Given your Docker VM runs these services already:

- Caddy (reverse proxy)
- Vaultwarden + backup
- Pi-hole
- Watchtower
- Frigate (resource-hungry: GPU detection)
- Mosquitto
- Home Assistant + backup

Estimated current RAM usage: **4-6 GB** (Frigate is the elephant).

**Available for PaaS**: ~3-5 GB

| PaaS | Idle Overhead | Remaining for Apps | Verdict |
|------|--------------|-------------------|---------|

| Coolify | ~380 MB | ~2.6-4.6 GB | Feasible but tight with Frigate |
| Dokploy | ~300 MB | ~2.7-4.7 GB | Feasible |
| CapRover | ~210 MB | ~2.8-4.8 GB | Comfortable |
| Dokku | ~95 MB | ~2.9-4.9 GB | Best fit for constrained RAM |
| Kamal | ~0 MB (local) | ~3-5 GB | Zero server impact |
| Komodo | ~50-100 MB | ~2.9-4.9 GB | Low impact |
| Dockge | ~50 MB | ~2.9-4.9 GB | Negligible |

**Note**: Consider running the PaaS on a separate server (e.g., NAS or RPi5) to avoid competing with Frigate for RAM on the Docker VM.

---

## Decision Framework for Your Homelab

### If you want a "set it and forget it" PaaS with UI

**Coolify**or**Dokploy** -- Pick Coolify for max features, Dokploy for a cleaner UI and native Swarm support.

### If you want maximum resource efficiency on the same Docker VM

**Dokku** -- At ~95MB idle, it leaves the most RAM for your existing services. CLI-only but pairs beautifully with your Vim/tmux/CLI-first workflow.

### If you want zero server overhead (deploy from laptop)

**Kamal** -- Nothing runs on the server except your apps. Build locally, push via SSH.

### If you want to manage existing Docker services better

**Komodo**or**Dockge** -- Not a PaaS, but Komodo could centralize management of your Docker VM + NAS + VPS from one panel.

### If you want PaaS on a separate device

Run Coolify or Dokploy on the NAS or RPi5, deploying apps to the Docker VM as a "remote server." This avoids RAM competition with Frigate.

---

## Final Recommendation

For your specific setup (9GB Docker VM, 2 cores, already running Frigate/HA/Pi-hole/Caddy, CLI-first workflow, Guarani naming convention lover):

### Primary Recommendation: **Coolify**

**Why**: Despite its warts (the January 2026 CVEs were concerning but quickly patched), Coolify is the most complete solution. With 280+ one-click services, Docker Compose support, and the ability to manage remote servers, it gives you a Vercel-like experience for deploying your Javya app and any future projects. The Docker Compose support is particularly valuable since your entire homelab already runs on Compose stacks.

**Deployment strategy**: Install Coolify on a separate server (NAS or a cheap VPS) and add the Docker VM as a "remote server." This keeps the PaaS overhead off your resource-constrained Docker VM.

**Guarani name suggestion**: `ypoti` (meaning "flower" -- where your apps bloom).

### Runner-Up: **Dokku**

**Why**: If you decide to run the PaaS directly on the Docker VM alongside existing services, Dokku's 95MB footprint is unbeatable. Your CLI-first workflow matches perfectly -- `git push dokku main` is as elegant as it gets. The 13-year stability track record means it won't break your existing services.

### Honorable Mention: **Kamal**

**Why**: For deploying Javya (FastAPI + Python) specifically, Kamal's zero-overhead approach is compelling. Build locally on your MacBook Air, deploy via SSH. No PaaS daemon consuming RAM on your server. But you'll miss the database management and one-click services of a full PaaS.

### Worth Watching: **Dokploy**and**Komodo**

Dokploy is growing fast and may surpass Coolify in UI quality. Komodo could be your "homelab control plane" for managing Docker across all three servers (Docker VM, NAS, VPS) from one panel.

---

## Sources

### Comparison Articles

- [Self-Hosted Deployment Tools Compared (Haloy Blog)](https://haloy.dev/blog/self-hosted-deployment-tools-compared)
- [Coolify vs CapRover vs Dokku (selfhostable.dev)](https://selfhostable.dev/blog/coolify-vs-caprover-vs-dokku/)
- [Dokploy vs Coolify 2026 (INTROSERV)](https://introserv.com/blog/dokploy-vs-coolify-complete-comparison-of-the-best-self-hosted-paas-platforms-for-vps-and-dedicated-servers-2026/)
- [Coolify vs Dokploy (Cherry Servers)](https://www.cherryservers.com/blog/coolify-vs-dokploy)
- [CapRover, Coolify & Dokploy Reviewed (KloudShift)](https://kloudshift.net/blog/comparing-self-hostable-paas-solutions-caprover-coolify-dokploy-reviewed/)
- [Coolify Alternatives 2026 (Northflank)](https://northflank.com/blog/coolify-alternatives-in-2026)
- [Dokku Alternatives 2026 (Northflank)](https://northflank.com/blog/6-best-dokku-alternatives)
- [Coolify vs Dokploy (Medium/Girff)](https://girff.medium.com/coolify-vs-dokploy-the-ultimate-comparison-for-self-hosted-in-2025-8c63f1bda088)
- [Coolify vs Dokploy (Contabo)](https://contabo.com/blog/blog-coolify-vs-dokploy-comparison/)
- [Best Self-Hosted PaaS 2026 (OpenAlternative)](https://openalternative.co/categories/paas-deployment-tools/self-hosted)

### Official Project Sites

- [Coolify](https://coolify.io) | [GitHub](https://github.com/coollabsio/coolify)
- [Dokploy](https://dokploy.com) | [GitHub](https://github.com/Dokploy/dokploy)
- [CapRover](https://caprover.com) | [GitHub](https://github.com/caprover/caprover)
- [Dokku](https://dokku.com) | [GitHub](https://github.com/dokku/dokku)
- [Kamal](https://kamal-deploy.org) | [GitHub](https://github.com/basecamp/kamal)
- [Komodo](https://komo.do) | [GitHub](https://github.com/moghtech/komodo)
- [Haloy](https://haloy.dev) | [GitHub](https://github.com/haloydev/haloy)
- [Portainer](https://www.portainer.io) | [GitHub](https://github.com/portainer/portainer)
- [Dockge](https://dockge.kuma.pet) | [GitHub](https://github.com/louislam/dockge)
- [Easypanel](https://easypanel.io)
- [Cloudron](https://www.cloudron.io)
- [Sealos](https://sealos.io) | [GitHub](https://github.com/labring/sealos)

### Reviews and Real-World Reports

- [Honest Take on Kamal (Ivan Turkovic, Feb 2026)](https://www.ivanturkovic.com/2026/02/06/honest-take-kamal-rails-deployment/)
- [Kamal: Hot Deployment Tool (Evil Martians)](https://evilmartians.com/chronicles/mrsk-hot-deployment-tool-or-total-game-changer)
- [Vercel vs Coolify Cost Analysis (Leon Consulting)](https://leonstaff.com/blogs/vercel-vs-coolify-cost-analysis/)
- [Coolify 11 Critical CVEs (The Hacker News)](https://thehackernews.com/2026/01/coolify-discloses-11-critical-flaws.html)
- [Coolify Docker Layer Caching Bug (Loopwerk)](https://www.loopwerk.io/articles/2025/coolify-docker-layer-caching/)
- [Deploying Django with Kamal (Anthony Simon)](https://anthonynsimon.com/blog/kamal-deploy/)
- [How I Run Docker with Komodo (Chollinger)](https://chollinger.com/blog/2025/12/how-i-run-docker-services-and-deployments-with-komodo/)
- [Homelab Starter Stack 2026 (Virtualization Howto)](https://www.virtualizationhowto.com/2025/12/ultimate-home-lab-starter-stack-for-2026-key-recommendations/)
- [2026 Homelab Stack (Elest.io)](https://blog.elest.io/the-2026-homelab-stack-what-self-hosters-are-actually-running-this-year/)

### Community Discussions

- [Why Coolify over CapRover or Dokku (GitHub Discussion)](https://github.com/coollabsio/coolify/discussions/688)
- [Dokploy Comparison Table (Official Docs)](https://docs.dokploy.com/docs/core/comparison)
- [Kamal 2.0 Released (37signals)](https://dev.37signals.com/kamal-2/)
- [Cloudron Competitors List (Forum)](https://forum.cloudron.io/topic/10000/a-list-of-cloudron-like-services-competitors)
