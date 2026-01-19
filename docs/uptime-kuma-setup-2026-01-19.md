# Uptime Kuma Setup - 2026-01-19

External monitoring for all homelab services, running on VPS.

## Access

- **URL:** https://status.cronova.dev
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
```
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
| ntfy | HTTP(s) | `https://notify.cronova.dev` |
| Home Assistant | HTTP(s) | `http://100.64.0.10:8123` |
| Jellyfin | HTTP(s) | `http://100.64.0.10:8096` |

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

## Notifications (TODO)

Set up ntfy integration:
1. Deploy ntfy container (already in docker-compose)
2. Create user: `docker exec -it ntfy ntfy user add --role=admin augusto`
3. In Uptime Kuma: Settings > Notifications > Add > ntfy
4. Server: `https://notify.cronova.dev`
5. Topic: `cronova-critical`

## Maintenance

```bash
# View logs
ssh linuxuser@100.77.172.46 'sudo docker logs -f uptime-kuma'

# Restart
ssh linuxuser@100.77.172.46 'sudo docker restart uptime-kuma'

# Backup data
ssh linuxuser@100.77.172.46 'sudo docker run --rm -v uptime-kuma-data:/data -v /tmp:/backup alpine tar czf /backup/uptime-kuma-backup.tar.gz /data'
```

## Related Files

- Docker compose: `docker/vps/monitoring/docker-compose.yml`
- Caddy config: `docker/vps/networking/caddy/Caddyfile`
- Monitoring strategy: `docs/monitoring-strategy.md`
