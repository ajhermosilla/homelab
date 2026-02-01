# Ansible Playbooks

Infrastructure automation for the homelab.

## Prerequisites

Install Ansible on your control machine (MacBook):

```bash
# macOS
brew install ansible

# Debian/Ubuntu
apt install ansible
```

## Inventory

The inventory file (`inventory.yml`) defines all hosts organized by:
- Environment (vps, fixed, mobile)
- Function (docker_hosts, pihole_hosts, etc.)

Hosts use Tailscale IPs by default for remote access.

## Available Playbooks

### common.yml

Basic setup for all hosts: packages, timezone, SSH hardening, firewall.

```bash
# All hosts
ansible-playbook -i inventory.yml playbooks/common.yml

# Specific host
ansible-playbook -i inventory.yml playbooks/common.yml --limit docker

# Only upgrade packages
ansible-playbook -i inventory.yml playbooks/common.yml --tags upgrade
```

### docker.yml

Install Docker and docker-compose on Docker hosts.

```bash
ansible-playbook -i inventory.yml playbooks/docker.yml
```

### tailscale.yml

Install Tailscale and connect to Headscale.

```bash
# Generate auth key in Headscale first:
# docker exec headscale headscale preauthkeys create --user 1 --reusable --expiration 90d

# Run playbook with auth key
ansible-playbook -i inventory.yml playbooks/tailscale.yml -e "authkey=tskey-xxx"

# Single host
ansible-playbook -i inventory.yml playbooks/tailscale.yml -e "authkey=tskey-xxx" --limit docker
```

### backup.yml

Configure Restic backups to NAS or VPS.

```bash
# Deploy with credentials
ansible-playbook -i inventory.yml playbooks/backup.yml \
  -e "restic_user=augusto" \
  -e "restic_pass=xxx" \
  -e "restic_password=xxx"

# Initialize repository only
ansible-playbook -i inventory.yml playbooks/backup.yml --tags init
```

### monitoring.yml

Deploy Uptime Kuma + ntfy monitoring stack.

```bash
ansible-playbook -i inventory.yml playbooks/monitoring.yml -l vps
```

### update.yml

System and container updates.

```bash
# Update all systems
ansible-playbook -i inventory.yml playbooks/update.yml

# Update with reboot if required
ansible-playbook -i inventory.yml playbooks/update.yml -e "reboot=true"

# Update Docker containers too
ansible-playbook -i inventory.yml playbooks/update.yml -e "containers=true"

# Docker hosts only
ansible-playbook -i inventory.yml playbooks/update.yml -l docker_hosts -e "containers=true"
```

### pihole.yml

Deploy Pi-hole DNS ad-blocker.

```bash
# Deploy with web password
ansible-playbook -i inventory.yml playbooks/pihole.yml -l pihole_hosts -e "webpassword=xxx"
```

### caddy.yml

Deploy Caddy reverse proxy with automatic HTTPS.

```bash
ansible-playbook -i inventory.yml playbooks/caddy.yml -l vps
```

### nfs-server.yml

Configure NFS exports on NAS.

```bash
ansible-playbook -i inventory.yml playbooks/nfs-server.yml -l nas
```

### openclaw.yml

Install OpenClaw AI assistant on dedicated VM.

```bash
ansible-playbook -i inventory.yml playbooks/openclaw.yml -l openclaw
```

### docker-compose-deploy.yml

Deploy Docker Compose stacks from homelab repo.

```bash
# Deploy all stacks for a host
ansible-playbook -i inventory.yml playbooks/docker-compose-deploy.yml -l docker

# Deploy specific stack
ansible-playbook -i inventory.yml playbooks/docker-compose-deploy.yml -l docker -e "stack=media"

# Stop a stack
ansible-playbook -i inventory.yml playbooks/docker-compose-deploy.yml -l docker -e "stack=media" -e "compose_action=down"

# Pull latest images
ansible-playbook -i inventory.yml playbooks/docker-compose-deploy.yml -l docker -e "compose_action=pull"
```

## Usage Examples

### Check connectivity

```bash
# Ping all hosts
ansible -i inventory.yml all -m ping

# Ping specific group
ansible -i inventory.yml docker_hosts -m ping
```

### Run ad-hoc commands

```bash
# Check disk space
ansible -i inventory.yml all -m command -a "df -h"

# Check Docker version
ansible -i inventory.yml docker_hosts -m command -a "docker --version"

# Restart a service
ansible -i inventory.yml docker -m service -a "name=docker state=restarted" --become
```

### Dry run

```bash
# Check what would change without making changes
ansible-playbook -i inventory.yml playbooks/common.yml --check --diff
```

## Host Groups

| Group | Hosts | Description |
|-------|-------|-------------|
| `all` | All hosts | Every managed host |
| `vps` | vultr | Cloud VPS |
| `fixed` | minipc, docker, openclaw, nas, rpi4 | Fixed homelab |
| `mobile` | rpi5 | Mobile kit |
| `docker_hosts` | vultr, docker, nas | Hosts running Docker |
| `pihole_hosts` | vultr, docker, rpi5 | Hosts running Pi-hole |
| `openclaw_vm` | openclaw | OpenClaw AI assistant |
| `tailscale_clients` | All except control | Tailscale mesh members |

## Variables

### Global (inventory.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `ansible_user` | augusto | SSH user |
| `timezone` | America/Asuncion | Host timezone |
| `use_tailscale` | true | Use Tailscale IPs |

### Playbook-specific

| Playbook | Variable | Description |
|----------|----------|-------------|
| tailscale.yml | `authkey` | Headscale pre-auth key |
| tailscale.yml | `headscale_url` | Headscale server URL |
| docker.yml | `docker_users` | Users to add to docker group |

## Directory Structure

```
ansible/
├── inventory.yml        # Host inventory
├── playbooks/
│   ├── common.yml               # Common setup
│   ├── docker.yml               # Docker installation
│   ├── tailscale.yml            # Tailscale setup
│   ├── backup.yml               # Restic backup configuration
│   ├── monitoring.yml           # Uptime Kuma + ntfy
│   ├── update.yml               # System/container updates
│   ├── pihole.yml               # Pi-hole deployment
│   ├── caddy.yml                # Caddy reverse proxy
│   ├── nfs-server.yml           # NFS exports
│   ├── openclaw.yml             # OpenClaw AI assistant
│   └── docker-compose-deploy.yml # Stack deployment
└── README.md           # This file
```

## Bootstrapping New VMs

New VMs don't have Tailscale yet. Use local IPs for initial setup:

### 1. Create VM in Proxmox

Manual step - create VM, install Debian, note the IP.

### 2. Copy SSH key

```bash
ssh-copy-id augusto@192.168.1.10  # Docker VM
ssh-copy-id augusto@192.168.1.20  # OpenClaw VM
```

### 3. Run playbooks with local IP override

```bash
# Docker VM bootstrap
ansible-playbook -i inventory.yml playbooks/common.yml -l docker \
  -e "ansible_host=192.168.1.10"

ansible-playbook -i inventory.yml playbooks/docker.yml -l docker \
  -e "ansible_host=192.168.1.10"

ansible-playbook -i inventory.yml playbooks/tailscale.yml -l docker \
  -e "ansible_host=192.168.1.10" -e "authkey=tskey-xxx"

# OpenClaw VM bootstrap
ansible-playbook -i inventory.yml playbooks/common.yml -l openclaw \
  -e "ansible_host=192.168.1.20"

ansible-playbook -i inventory.yml playbooks/openclaw.yml -l openclaw \
  -e "ansible_host=192.168.1.20"

ansible-playbook -i inventory.yml playbooks/tailscale.yml -l openclaw \
  -e "ansible_host=192.168.1.20" -e "authkey=tskey-xxx"
```

### 4. After Tailscale is running

Use Tailscale IPs (default in inventory) for all future runs.

## Tips

### SSH Config

Add to `~/.ssh/config` for easier access:

```
Host vultr
    HostName 100.77.172.46
    User linuxuser

Host docker
    HostName 100.64.0.13
    User augusto

Host openclaw
    HostName 100.64.0.14
    User augusto

Host nas
    HostName 100.64.0.12
    User augusto
```

### Vault for Secrets

For sensitive variables, use Ansible Vault:

```bash
# Create encrypted vars file
ansible-vault create vars/secrets.yml

# Edit encrypted file
ansible-vault edit vars/secrets.yml

# Run playbook with vault
ansible-playbook -i inventory.yml playbooks/common.yml --ask-vault-pass
```

### Testing

Test changes on a single host first:

```bash
ansible-playbook -i inventory.yml playbooks/common.yml --limit docker --check
```
