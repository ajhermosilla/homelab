# Tailscale Primer

WireGuard-based mesh VPN. Every device gets a stable IP (100.x.x.x) and can reach every other device directly, regardless of NAT/firewall.

## Costs

| Plan | Price | Devices | Users |
|------|-------|---------|-------|
| Personal | Free | 100 | 1 |
| Personal Plus | $48/yr | 100 | 1 |
| Enterprise | $$$ | Unlimited | Teams |

Free tier is generous for personal use.

## Benefits

- **Zero config** - install, login, done
- **Mesh topology** - devices connect directly (not through a server)
- **MagicDNS** - access devices by name (`macbook`, `rpi5`)
- **Works anywhere** - behind NAT, hotel wifi, cellular
- **Subnet routing** - expose entire networks (e.g., your home LAN)
- **Exit nodes** - route all traffic through a specific device
- **ACLs** - fine-grained access control
- **SSO** - use GitHub/Google login

## Limitations

- **Coordination server** - Tailscale runs it (they see metadata, not traffic)
- **Requires internet** - initial connection needs their servers
- **100.x.x.x range** - can conflict if you use CGNAT
- **Client on every device** - no agentless access

## Competitors

| Tool | Model | Self-hosted? | Notes |
|------|-------|--------------|-------|
| **Headscale** | Tailscale-compatible | Yes | Drop-in replacement for Tailscale's coord server |
| **Netbird** | Mesh VPN | Yes | Similar to Tailscale, fully self-hostable |
| **Zerotier** | Mesh VPN | Partial | Older, more complex, free tier exists |
| **Nebula** | Mesh VPN | Yes | From Slack, more DIY |
| **WireGuard raw** | Point-to-point | Yes | Manual config, no mesh magic |

## Recommendation for This Homelab

**Tailscale free tier** would let the mobile kit (Mac + RPi 5) and fixed homelab (Mini PC, RPi 4) all see each other seamlessly. When traveling, Mac still reaches home services.

For full control: **Headscale** on Mini PC as the coordination server, same Tailscale clients everywhere.

## Resources

- [Tailscale Docs](https://tailscale.com/kb/)
- [Headscale GitHub](https://github.com/juanfont/headscale)
- [Netbird](https://netbird.io/)
