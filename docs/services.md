# Services

## Active Services

### soft-serve

Self-hosted Git server with SSH-based TUI.

| Property | Value |
|----------|-------|
| Location | `docker/git/` |
| Image | `charmcli/soft-serve:latest` |
| Host | Mobile (MacBook Air M1) |
| Ports | 23231 (SSH), 23232 (HTTP), 23233 (Stats) |
| Data | Docker volume `git_soft-serve-data` |

**Access:**
```bash
# TUI
ssh -p 23231 localhost

# Clone
git clone ssh://localhost:23231/<repo>.git

# Create repo
ssh -p 23231 localhost repo create <name>
```

---

## Planned Services

| Service | Category | Priority | Target Host |
|---------|----------|----------|-------------|
| TBD | - | - | - |

---

## Service Categories

Future services will be organized in `docker/` by category:

- `docker/git/` - Git hosting (soft-serve)
- `docker/networking/` - Reverse proxy, VPN, DNS
- `docker/monitoring/` - Metrics, logging, dashboards
- `docker/media/` - Media servers, downloaders
