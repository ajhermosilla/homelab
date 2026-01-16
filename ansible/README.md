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
# docker exec headscale headscale preauthkeys create --user augusto --reusable --expiration 1h

# Run playbook with auth key
ansible-playbook -i inventory.yml playbooks/tailscale.yml -e "authkey=tskey-xxx"

# Single host
ansible-playbook -i inventory.yml playbooks/tailscale.yml -e "authkey=tskey-xxx" --limit docker
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
| `fixed` | minipc, docker, nas, rpi4 | Fixed homelab |
| `mobile` | rpi5 | Mobile kit |
| `docker_hosts` | vultr, docker, nas | Hosts running Docker |
| `pihole_hosts` | vultr, docker, rpi5 | Hosts running Pi-hole |
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
│   ├── common.yml      # Common setup
│   ├── docker.yml      # Docker installation
│   └── tailscale.yml   # Tailscale setup
└── README.md           # This file
```

## Future Playbooks

Planned additions:
- `backup.yml` - Configure restic backups
- `monitoring.yml` - Deploy monitoring stack
- `update.yml` - System and container updates
- `pihole.yml` - Pi-hole deployment
- `caddy.yml` - Caddy reverse proxy setup

## Tips

### SSH Config

Add to `~/.ssh/config` for easier access:

```
Host vultr
    HostName 100.64.0.100
    User root

Host docker
    HostName 100.64.0.13
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
