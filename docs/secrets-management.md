# Secrets Management

How to handle sensitive data across the homelab without compromising security.

## Principles

1. **Never commit plaintext secrets to git**
2. **Encrypt secrets at rest** (age + SOPS)
3. **Minimal secret exposure** (only where needed)
4. **Reproducible deployments** (secrets in git, encrypted)

## Tools

| Tool | Purpose |
|------|---------|
| **age** | Modern encryption (replaces GPG) |
| **SOPS** | Encrypt YAML/JSON files, works with age |
| **.env files** | Runtime secrets (gitignored) |
| **Restic** | Encrypted backups |

## Workflow

### 1. Generate age Key

```bash
# Generate key
age-keygen -o ~/.config/sops/age/keys.txt

# View public key
age-keygen -y ~/.config/sops/age/keys.txt
```

### 2. Configure SOPS

Create `.sops.yaml` in repo root:

```yaml
creation_rules:
  - path_regex: \.enc\.yaml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Encrypt Secrets

```bash
# Create secrets file
cat > docker/git/.env.enc.yaml << EOF
soft_serve_admin_key: "ssh-ed25519 AAAA..."
EOF

# Encrypt it
sops -e -i docker/git/.env.enc.yaml

# Decrypt to .env at deploy time
sops -d docker/git/.env.enc.yaml > docker/git/.env
```

### 4. Gitignore Pattern

```gitignore
# Plaintext secrets (never commit)
.env
*.secret

# Encrypted secrets (safe to commit)
!*.enc.yaml
!*.enc.json
```

## Secret Types by Location

### Mobile (RPi 5)

| Secret | Storage | Method |
|--------|---------|--------|
| Headscale API key | `.env` | SOPS encrypted in git |
| AdGuard admin password | `.env` | SOPS encrypted in git |
| age private key | `~/.config/sops/age/` | Manual backup only |

### Fixed Homelab

| Secret | Storage | Method |
|--------|---------|--------|
| Vaultwarden admin token | `.env` | SOPS encrypted in git |
| Jellyfin API key | `.env` | SOPS encrypted in git |
| OPNsense root password | OPNsense config | Export encrypted backup |
| Start9 master password | Start9 | Manual, not in git |
| Proxmox root password | Proxmox | Manual, not in git |

### VPS

| Secret | Storage | Method |
|--------|---------|--------|
| Uptime Kuma password | `.env` | SOPS encrypted in git |
| ntfy admin password | `.env` | SOPS encrypted in git |
| Restic repository password | `.env` | SOPS encrypted in git |

## Backup of Encryption Keys

| Key | Backup Location | Method |
|-----|-----------------|--------|
| age private key | Paper + secure storage | Print QR code |
| Restic repo passwords | Vaultwarden | Encrypted password manager |
| Start9 seed phrase | Paper | Offline only |

## Recovery Procedure

1. **Restore age key** from paper backup
2. **Clone repo** from git (soft-serve or backup)
3. **Decrypt secrets** with `sops -d`
4. **Deploy services** with decrypted `.env` files

## Commands Cheatsheet

```bash
# Encrypt file in place
sops -e -i secrets.yaml

# Decrypt file in place
sops -d -i secrets.yaml

# Decrypt to stdout
sops -d secrets.yaml

# Edit encrypted file (decrypts, opens editor, re-encrypts)
sops secrets.yaml

# Encrypt specific keys only
sops --encrypt --encrypted-regex '^(password|api_key)$' config.yaml
```

## References

- [age encryption](https://age-encryption.org/)
- [SOPS GitHub](https://github.com/getsops/sops)
- [SOPS + age guide](https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html)
