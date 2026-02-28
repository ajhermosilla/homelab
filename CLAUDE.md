# Homelab

Infrastructure-as-code for a self-hosted homelab: Proxmox, Docker, OPNsense, Tailscale. Three hosts (VPS, Docker VM, NAS) managed via Ansible and Docker Compose.

## Owner
- **Name**: Augusto Hermosilla
- **Email**: augusto@hermosilla.me
- **Git server**: Forgejo at git.cronova.dev (SSH alias: `git@git.cronova.dev`)
- **GPG key**: 8AFCB80F4AC0B02B

## Hosts & SSH Aliases
Always use these SSH aliases (defined in `~/.ssh/config`):
- `vps` — Vultr VPS (user `linuxuser`, NOT `augusto`)
- `docker-vm` — Proxmox VM 101 (user `augusto`)
- `nas` — ASUS NAS (user `augusto`)
- `proxmox` — Proxmox host (user `root`)

## Repo Structure
```
homelab/
├── ansible/              # Playbooks + inventory for all hosts
│   ├── inventory.yml
│   └── playbooks/        # common, docker, caddy, pihole, tailscale, backup, etc.
├── docker/
│   ├── fixed/
│   │   ├── docker-vm/    # 10 stacks: networking, automation, security, auth, tools, etc.
│   │   └── nas/          # 5 stacks: backup, git, monitoring, paas, storage
│   ├── vps/              # headscale, caddy, monitoring, scraping
│   ├── shared/           # Shared backup scripts and common.env
│   └── mobile/           # Mobile kit configs (Beryl AX)
├── docs/
│   ├── architecture/     # Hardware, network topology, services
│   ├── guides/           # Setup runbooks (NAS, Proxmox, OPNsense, etc.)
│   ├── strategy/         # DNS, certs, monitoring, DR, security
│   ├── plans/            # Future work and research
│   └── reference/        # Device guides, naming conventions, misc
├── scripts/              # Boot orchestrator, backup scripts
└── CLAUDE.md
```

## Commands

### Ansible (run from repo root)
```bash
ansible-playbook -i ansible/inventory.yml ansible/playbooks/<playbook>.yml
ansible-playbook -i ansible/inventory.yml ansible/playbooks/<playbook>.yml --limit <host>
ansible-playbook -i ansible/inventory.yml ansible/playbooks/<playbook>.yml --check  # dry run
```

### Docker Compose (on remote hosts via SSH)
```bash
ssh <host> "cd /opt/homelab/repo/docker/fixed/<host>/<stack>/ && docker compose up -d"
ssh <host> "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

### Forgejo PR Workflow
```bash
# Create PR
curl -s -X POST "https://git.cronova.dev/api/v1/repos/augusto/homelab/pulls" \
  -H "Authorization: token $FORGEJO_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"...","head":"feat/branch","base":"main"}'
# Merge PR
curl -s -X POST "https://git.cronova.dev/api/v1/repos/augusto/homelab/pulls/<id>/merge" \
  -H "Authorization: token $FORGEJO_TOKEN" \
  -d '{"Do":"merge","delete_branch_after_merge":true}'
```

## Conventions
- **Commits**: Conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`)
- **Compose files**: One `docker-compose.yml` per stack, `.env` for secrets (gitignored), `.env.example` committed
- **Service naming**: Guarani language names (see `docs/reference/guarani-naming-convention-2026-02-24.md`)
- **DNS**: All services on `*.cronova.dev`, Pi-hole for internal resolution
- **Secrets**: `.env` files gitignored. SOPS with age encryption for `secrets.yaml` if needed

## Important Gotchas
- `grep` is aliased to `rg` on Mac AND NAS — use `command grep` in pipes/scripts on remote hosts
- Pi-hole container doesn't have `command` binary — use `grep` directly inside it
- NAS `sudo` requires password — use `docker exec` to write root-owned files
- `sed -i` on Linux creates a NEW inode — Docker bind mounts track the old inode (restart container after `sed -i`)
- Docker Compose v5: `.env` vars auto-inject into containers. Escape `$` as `$$` in `.env` for Argon2 hashes
- NAS Docker data-root is `/data/docker` (NOT `/var/lib/docker` — `/var` is only 6G)
- Forgejo merge API returns empty body with 405 but actually succeeds
- Pi-hole v6 config: `/etc/pihole/pihole.toml` (NOT `custom.list`). Multiple `hosts` keys exist — be specific with `dns.hosts`
