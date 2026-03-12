# CrowdSec on OPNsense Setup Plan

**Date**: 2026-03-11
**Status**: Pending (requires home access to OPNsense web UI)
**Host**: OPNsense VM 100 (2 vCPU, 2GB RAM, FreeBSD)
**Guarani name**: Itá (stone, rock)
**Estimated time**: 1 hour

## What is CrowdSec?

Crowd-sourced intrusion prevention system. Analyzes logs for suspicious behavior (brute force, scans, exploits), blocks offending IPs via firewall bouncer, and shares threat intelligence with global community. You contribute detections, you receive blocklists.

**Three components:**
1. **Log Processor** (formerly "agent") — reads logs, detects attacks using scenarios
2. **LAPI** (Local API) — central decision store, manages blocklists
3. **Firewall Bouncer** (remediation) — applies bans via OPNsense PF tables

## Why CrowdSec on OPNsense?

- OPNsense is the gateway — all traffic flows through it
- Native OPNsense plugin (FreeBSD package, not a hack)
- Blocks at the firewall level before traffic reaches any service
- Community blocklists provide proactive protection (not just reactive)
- ~100MB RAM footprint — fits within OPNsense's 2GB
- Complements Authelia (app-level) with network-level protection

## Prerequisites

- [x] OPNsense running as gateway (since 2026-02-21)
- [x] SSH root access to OPNsense (ed25519 key, 2026-03-05)
- [x] Web UI access via SSH tunnel (`ssh -L 8443:192.168.0.1:443 proxmox`)
- [ ] CrowdSec account at https://app.crowdsec.net (free, create before starting)

## Step 1: Create CrowdSec Account

1. Go to https://app.crowdsec.net/signup
2. Sign up (email + password)
3. This gives access to the CrowdSec Console — alerts dashboard, blocklist subscriptions, instance management
4. Save credentials in Vaultwarden

## Step 2: Install Plugin

**OPNsense Web UI:**
1. `System → Firmware → Plugins`
2. Search for `os-crowdsec`
3. Click `+` to install

This installs three packages automatically:
- `os-crowdsec` (plugin UI)
- `crowdsec` (log processor + LAPI)
- `crowdsec-firewall-bouncer` (PF integration)

4. **Refresh the page** after installation
5. Verify: `Services → CrowdSec → Overview` should appear in menu

**IMPORTANT:** Do NOT start/enable services from the terminal (`service oscrowdsec onestart`, etc.). The plugin manages the service lifecycle — terminal commands can cause state desync.

**Known issue:** If services fail with "authenticate watcher" errors after install, do a clean reinstall:
```bash
# On OPNsense (SSH as root)
pkg remove os-crowdsec crowdsec crowdsec-firewall-bouncer
rm -rf /usr/local/etc/crowdsec/
# Then reinstall via web UI
```

## Step 3: Verify Default Configuration

Navigate to `Services → CrowdSec → Settings`. Three components should be enabled by default:
- Log Processor — enabled
- LAPI — enabled
- Remediation Component — enabled

**Auto-installed collections:**
- `crowdsecurity/freebsd` — FreeBSD-specific log parsers
- `crowdsecurity/opnsense` — OPNsense log parsers (SSH, web UI, etc.)

**Default whitelist:** Private IP ranges (192.168.x.x, 10.x.x.x, 172.16-31.x.x) are whitelisted by default since CrowdSec 1.6.3. No risk of locking out LAN devices.

**Tailscale IPs (100.x.x.x):** These are NOT in the default private whitelist. Add a manual whitelist to avoid blocking Tailscale nodes:
```bash
# On OPNsense (SSH as root)
cscli parsers install crowdsecurity/whitelists
# Then edit /usr/local/etc/crowdsec/parsers/s02-enrich/whitelists.yaml
# Add: 100.64.0.0/10 to the CIDR list
```

## Step 4: Verify Services Running

**Via Web UI:** `Services → CrowdSec → Overview` — all three services should show green/running.

**Via SSH (optional):**
```bash
# SSH to OPNsense (csh shell — no bash features like 2>&1)
ssh proxmox "ssh root@192.168.0.1"

# Check service status
service oscrowdsec status

# List installed collections
cscli collections list

# List active decisions (should be empty initially)
cscli decisions list

# Check metrics
cscli metrics
```

## Step 5: Enroll in CrowdSec Console

This connects OPNsense to the cloud console for visibility and community blocklists.

```bash
# On OPNsense (SSH as root)
cscli console enroll <ENROLLMENT_KEY>
```

Get the enrollment key from https://app.crowdsec.net → Security Engines → Enroll.

After enrollment:
- Accept the instance in the Console web UI
- Instance appears in the dashboard with alerts and decisions

## Step 6: Subscribe to Community Blocklists

In CrowdSec Console (https://app.crowdsec.net):
1. Go to `Blocklists` section
2. Subscribe to recommended free blocklists:
   - **CrowdSec Community Blocklist** — aggregated from all CrowdSec users
   - Any additional relevant lists (scanners, brute-force, etc.)
3. These blocklists are automatically pulled by the LAPI and enforced by the firewall bouncer

## Step 7: Test the Bouncer

**Controlled ban test** (from OPNsense SSH):
```bash
# Get your current IP (the one you're SSH-ing from)
echo $SSH_CLIENT | awk '{print $1}'

# Add a 2-minute test ban on a FAKE IP (not your own!)
cscli decisions add -t ban -d 2m -i 203.0.113.1

# Verify it appears in decisions
cscli decisions list

# Check PF table (OPNsense uses PF, not iptables)
pfctl -t crowdsec_blacklists -T show

# Wait 2 minutes, verify it auto-expires
cscli decisions list
```

**WARNING:** Do NOT ban your own IP unless you have console/IPMI access to OPNsense. You WILL lose SSH connectivity for the ban duration.

## Step 8: Review Logs & Parsers

```bash
# Check what log sources are being monitored
cscli parsers list

# Check active scenarios (attack detection rules)
cscli scenarios list

# View recent alerts
cscli alerts list

# Check acquisition config (which logs are read)
cat /usr/local/etc/crowdsec/acquis.yaml
```

The OPNsense collection auto-configures acquisition for:
- `/var/log/auth.log` — SSH brute force
- `/var/log/opnsense_latest/latest.log` — firewall logs
- OPNsense web UI auth logs

## Step 9: Install Additional Collections (Optional)

If you later expose services or want broader detection:

```bash
# List available collections
cscli collections list -a

# Example: add HTTP scanning detection
cscli collections install crowdsecurity/http-cve

# Example: add Nginx/Caddy log parsing (if Caddy logs forwarded)
cscli collections install crowdsecurity/caddy
```

For now, the default `freebsd` + `opnsense` collections are sufficient since WAN has no port forwards.

## Post-Install Verification Checklist

- [ ] Plugin installed (`Services → CrowdSec` menu exists)
- [ ] All 3 services running (Overview page shows green)
- [ ] Collections installed (`cscli collections list` shows freebsd + opnsense)
- [ ] Console enrolled (instance visible at app.crowdsec.net)
- [ ] Community blocklist subscribed
- [ ] Test ban works (`cscli decisions add` → appears in `pfctl -t crowdsec_blacklists -T show`)
- [ ] No LAN IPs in blocklist (private ranges whitelisted)
- [ ] Tailscale CGNAT range (100.64.0.0/10) added to whitelist
- [ ] `cscli metrics` shows log lines being parsed

## What Gets Protected

**In scope (initial setup):** CrowdSec on OPNsense only monitors logs generated by OPNsense itself:
- SSH brute force against OPNsense
- Web UI brute force
- Port scans seen by PF firewall
- Community blocklist IPs (proactive blocking)

**Out of scope:** Application-level attacks against Docker VM services (Caddy, Vaultwarden, etc.) are NOT monitored. Those logs live on Docker VM, not OPNsense. To add application-level detection, you'd need a CrowdSec agent on Docker VM parsing Caddy/service logs — that's a separate future project.

**Current protection layers:**
1. **OPNsense UFW/PF** — port-level firewall (existing)
2. **CrowdSec** — network-level IDS/IPS (this plan)
3. **Authelia** — app-level SSO + 2FA (existing)
4. **Docker VM UFW** — INPUT=DROP on Docker VM (existing)

## Monitoring in Grafana (Future)

CrowdSec exposes Prometheus metrics on port 6060. A future scrape target + dashboard could show:
- Active decisions count
- Alerts per scenario
- Log lines parsed per source
- Bouncer API calls

This would require:
1. Exposing CrowdSec metrics from OPNsense to vmagent (port 6060, Tailscale IP)
2. Adding scrape target: `100.79.230.235:6060` (OPNsense Tailscale IP)
3. Grafana dashboard (CrowdSec has an official one: ID 11585)

Not in scope for initial setup — add after CrowdSec is stable.

## Resource Impact

| Resource | Impact |
|----------|--------|
| RAM | ~100MB (within OPNsense's 2GB) |
| CPU | Minimal (log parsing is lightweight) |
| Disk | ~50MB for collections + DB |
| Network | Small — LAPI sync with CrowdSec cloud |

If RAM becomes tight, consider bumping OPNsense VM from 2GB → 3GB in Proxmox (`qm set 100 --memory 3072`).

## Rollback

If CrowdSec causes issues:

1. **Quick disable:** `Services → CrowdSec → Settings` → uncheck all three components → Save
2. **Full removal:** `System → Firmware → Plugins` → remove `os-crowdsec`
3. **Emergency (SSH):** `service oscrowdsec stop` or `pfctl -t crowdsec_blacklists -T flush`

## References

- [CrowdSec OPNsense Docs](https://docs.crowdsec.net/docs/getting_started/install_crowdsec_opnsense/)
- [HomeNetworkGuy Guide](https://homenetworkguy.com/how-to/install-and-configure-crowdsec-on-opnsense/)
- [CrowdSec Hub (collections)](https://hub.crowdsec.net/)
- [CrowdSec Console](https://app.crowdsec.net/)
