# Uptime Kuma Setup - 2026-01-19

External monitoring for all homelab services, running on VPS.

## Access

- **URL:** <https://status.cronova.dev>
- **Container:** `uptime-kuma` on `monitoring-net`
- **Data:** Docker volume `uptime-kuma-data`

## Deployment

```bash
# On VPS (linuxuser@100.77.172.46)
sudo docker run -d \
  --name uptime-kuma \
  --restart unless-stopped \
  --network monitoring-net \
  -v uptime-kuma-data:/app/data \
  -e TZ=America/Asuncion \
  louislam/uptime-kuma:1
```

Caddy reverse proxy at `/opt/homelab/caddy/Caddyfile`:

```text
status.cronova.dev {
    reverse_proxy uptime-kuma:3001
}
```

## Working Monitors

| Name | Type | Target | Interval |
|------|------|--------|----------|

| Headscale | HTTP(s) | `https://hs.cronova.dev/health` | 60s |
| Uptime Kuma | HTTP(s) | `https://status.cronova.dev` | 60s |
| Caddy | TCP | `caddy:443` | 60s |
| ntfy | HTTP(s) | `https://notify.cronova.dev` | 60s |

## Recommended Monitors

### Tailscale Mesh (5m interval)

| Name | Type | Target |
|------|------|--------|

| MacBook | Ping | `100.86.220.9` |
| Phone (mombeu) | Ping | `100.110.253.126` |

### Domains (15m interval)

| Name | Type | Target |
|------|------|--------|

| cronova.dev | HTTP(s) | `https://cronova.dev` |
| hermosilla.me | HTTP(s) | `https://hermosilla.me` |

### DNS Resolution

| Name | Type | Query | Server |
|------|------|-------|--------|

| DNS Check | DNS | `hs.cronova.dev` | `1.1.1.1` |

### External Dependencies (15m interval)

| Name | Type | Target |
|------|------|--------|

| GitHub | HTTP(s) | `https://github.com` |
| Cloudflare | HTTP(s) | `https://1.1.1.1` |
| Fastmail | HTTP(s) | `https://www.fastmail.com` |

## Future Monitors (when deployed)

| Service | Type | Target |
|---------|------|--------|

| Pi-hole (RPi 5) | TCP | `100.64.0.1:53` |
| Vaultwarden | HTTP(s) | `https://vault.cronova.dev/alive` |
| Home Assistant | HTTP(s) | `http://100.68.63.168:8123` |
| Jellyfin | HTTP(s) | `http://100.68.63.168:8096` |

## Monitor Types Reference

| Type | Use Case |
|------|----------|

| HTTP(s) | Web services, APIs, health endpoints |
| TCP | Port availability (databases, services without HTTP) |
| Ping | Host reachability (Tailscale nodes, servers) |
| DNS | DNS resolution checks |
| Docker Host | Monitor all containers via Docker socket |
| Push | Cron jobs, backups (service pushes heartbeat to Kuma) |

## Tips

### Container Networking

When monitoring Docker containers from Uptime Kuma:

- Use container name, not `localhost` (e.g., `caddy:443` not `localhost:443`)
- Containers must be on same Docker network (`monitoring-net`)

### SSL Certificate Monitoring

HTTPS monitors automatically track certificate expiry. Configure alerts for 14/7/3 days before expiration.

### Status Page

Create a public status page at Settings > Status Pages:

- Add monitors to display
- Get public URL to share

## ntfy - Push Notifications

### Access

- **URL:** <https://notify.cronova.dev>
- **Container:** `ntfy` on `monitoring-net`
- **Data:** Docker volumes `ntfy-cache`, `ntfy-data`

### Deployment

```bash
# On VPS (linuxuser@100.77.172.46)
sudo docker run -d \
  --name ntfy \
  --restart unless-stopped \
  --network monitoring-net \
  -v ntfy-cache:/var/cache/ntfy \
  -v ntfy-data:/var/lib/ntfy \
  -e TZ=America/Asuncion \
  binwiederhier/ntfy serve \
  --base-url=https://notify.cronova.dev \
  --cache-file=/var/cache/ntfy/cache.db \
  --auth-file=/var/lib/ntfy/user.db \
  --auth-default-access=deny-all \
  --behind-proxy
```

Caddy reverse proxy:

```text
notify.cronova.dev {
    reverse_proxy ntfy:80
}
```

### User Management

```bash
# Add admin user
sudo docker exec -e NTFY_PASSWORD='yourpassword' ntfy \
  ntfy user --auth-file=/var/lib/ntfy/user.db add --role=admin augusto

# List users
sudo docker exec ntfy ntfy user --auth-file=/var/lib/ntfy/user.db list

# Change password
sudo docker exec -e NTFY_PASSWORD='newpassword' ntfy \
  ntfy user --auth-file=/var/lib/ntfy/user.db change-pass augusto
```

### Uptime Kuma Integration

1. Settings > Notifications > Setup Notification
2. Type: **ntfy**
3. Server URL: `https://notify.cronova.dev`
4. Topic: `alerts`
5. Username: `augusto`
6. Password: (your password)
7. Click **Test**then**Save**

### Phone App Setup

1. Install ntfy app ([Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy) / [iOS](https://apps.apple.com/app/ntfy/id1625396347))
2. Add subscription: `https://notify.cronova.dev/alerts`
3. Login with credentials when prompted

### Test Notification

```bash
# From VPS
curl -u augusto:PASSWORD -d "Test message" https://notify.cronova.dev/alerts

# With priority and title
curl -u augusto:PASSWORD \
  -H "Title: Alert Test" \
  -H "Priority: high" \
  -d "Service is down!" \
  https://notify.cronova.dev/alerts
```

### Recommended Topics

| Topic | Use Case | Priority |
|-------|----------|----------|

| `alerts` | Uptime Kuma alerts | high |
| `backups` | Backup job notifications | default |
| `info` | General homelab info | low |

## Maintenance

### Uptime Kuma

```bash
# View logs
ssh linuxuser@100.77.172.46 'sudo docker logs -f uptime-kuma'

# Restart
ssh linuxuser@100.77.172.46 'sudo docker restart uptime-kuma'

# Backup data
ssh linuxuser@100.77.172.46 'sudo docker run --rm -v uptime-kuma-data:/data -v /tmp:/backup alpine tar czf /backup/uptime-kuma-backup.tar.gz /data'
```

### ntfy

```bash
# View logs
ssh linuxuser@100.77.172.46 'sudo docker logs -f ntfy'

# Restart
ssh linuxuser@100.77.172.46 'sudo docker restart ntfy'

# Backup data
ssh linuxuser@100.77.172.46 'sudo docker run --rm -v ntfy-data:/data -v /tmp:/backup alpine tar czf /backup/ntfy-backup.tar.gz /data'
```

## Related Files

- Docker compose: `docker/vps/monitoring/docker-compose.yml`
- Caddy config: `docker/vps/networking/caddy/Caddyfile`
- Monitoring strategy: `docs/strategy/monitoring-strategy.md`
