# Incident Report: ISP Outage + Missing Outbound NAT Rules

**Date**: 2026-03-18
**Duration**: ~3.5 hours (two outages + troubleshooting)
**Severity**: High — all homelab services unreachable externally, no LAN internet
**ISP**: Tigo Paraguay (ARRIS modem, bridge mode)

---

## Summary

Two related but distinct failures on the same day:

**Outage #1 (morning)**: ISP outage caused OPNsense WAN to lose routing. The WAN watchdog script (deployed hours earlier) had its cron entry registered but never executed. Manual `configctl interface reconfigure wan` restored connectivity. Internet worked for ~1 hour.

**Outage #2 (afternoon)**: ISP dropped again, WAN lost its IP entirely. After manual WAN recovery, discovered OPNsense had **zero outbound NAT rules** — a persistent configuration issue, not a transient outage side-effect. Without NAT, LAN hosts could reach OPNsense but not the internet, causing a cascading failure: Docker VM lost internet → Tailscale disconnected → Pi-hole DNS upstream failed → all LAN DNS broke → cameras went offline.

Root cause: OPNsense's "Automatic outbound NAT" mode was generating no rules. This may have been broken since installation or a recent OPNsense update — the March 5 outage auto-recovered (suggesting NAT was working then), so this likely regressed between March 5 and March 18.

---

## Timeline (PYT, UTC-3)

### Outage #1 — WAN Routing (morning)

| Time | Event |
|------|-------|
| ~10:30 | ISP outage begins |
| 10:38 | NAS reachable (Tailscale), Docker VM/Proxmox unreachable |
| 10:45 | Plugged USB-Gigabit — Mac gets DHCP, can ping LAN hosts |
| 10:50 | SSH to OPNsense — WAN has IP but `ping 8.8.8.8` fails (stale routing) |
| 10:50 | `configctl interface reconfigure wan` — **internet restored** |
| 10:55 | Reconnected Tailscale on Docker VM via LAN SSH |
| 11:00 | Full recovery — all services operational |

### Outage #2 — WAN + NAT Failure (afternoon)

| Time | Event |
|------|-------|
| ~12:30 | ISP drops again — WAN loses IP entirely (vtnet0 blank) |
| 13:00 | Investigation begins — Mac on phone hotspot |
| 13:05 | Docker VM Tailscale offline, NAS/Proxmox unreachable |
| 13:12 | SSH to OPNsense via LAN — `configctl interface reconfigure wan` restores WAN IP |
| 13:14 | OPNsense can ping 8.8.8.8, but Docker VM **cannot** |
| 13:36 | WAN watchdog log checked — script never ran (cron issue) |
| 13:38 | Manual watchdog execution — confirms script works, cron doesn't |
| 13:40 | `service cron restart` on OPNsense |
| 13:48 | Pi-hole DNS broken — gravity.db corrupted, FTL PID permissions |
| 13:50 | Docker VM `/etc/resolv.conf` = `nameserver 100.100.100.100` (Tailscale, unreachable) |
| 13:56 | Docker VM gateway correct, can ping OPNsense but NOT internet |
| 13:58 | **`pfctl -sn` shows zero outbound NAT rules** — root cause found |
| 14:00 | `configctl filter reload` → OK but no NAT |
| 14:01 | `configctl service reload all` → configd error |
| 14:05 | `/usr/local/etc/rc.filter_configure` → reconfigured but still no NAT |
| 14:10 | `scp` NAT config + `pfctl -N -f /tmp/nat.conf` — **LAN internet restored** |
| 14:15 | Pi-hole restarted — FTL running, DNS resolving |
| 14:17 | Full recovery confirmed |
| 14:50 | Investigated OPNsense web UI — Automatic rules table empty (persistent, survives reboot) |
| 15:00 | Changed to Hybrid mode, created 3 manual NAT rules (LAN, IOT, GUEST) |
| 15:05 | Permanent fix applied — rules in OPNsense config, pending reboot verification |

---

## Root Causes

### 1. ISP Outage (external)

Tigo Paraguay service interruption. OPNsense WAN lost its DHCP lease entirely (vtnet0 blank).

### 2. WAN Watchdog Cron Not Executing

The watchdog script was deployed to `/root/wan_watchdog.sh` and registered in `crontab -l` (`*/5 * * * *`), but never fired during the outage. After `service cron restart`, the cron daemon was replaced with a new PID. The original cron process may not have picked up the new crontab entry — OPNsense may require a cron restart or use a different cron mechanism (configd-managed cron vs system crontab).

### 3. NAT Rules Not Restored After WAN Reconfigure

`configctl interface reconfigure wan` restored the WAN IP and routing, but did NOT regenerate the outbound NAT rules in pf. This is the critical gap — OPNsense could reach the internet, but LAN traffic was not being NATed.

Attempts to restore NAT:
- `configctl filter reload` → OK but no NAT rules appeared
- `configctl service reload all` → configd communication error
- `/usr/local/etc/rc.filter_configure` → firewall reconfigured but no NAT
- **Manual pfctl injection** → only method that worked

### 4. Cascading DNS Failure

Without NAT, Docker VM lost internet → Tailscale disconnected (can't reach Headscale) → Docker VM's `/etc/resolv.conf` was already overwritten by Tailscale (`nameserver 100.100.100.100`) → Pi-hole's upstream DNS queries failed → all LAN DNS broke → cameras and all devices lost connectivity.

### 5. Pi-hole Gravity DB Corruption

Pi-hole's gravity.db had missing views (`vw_whitelist`, `vw_blacklist`, `vw_regex_*`). The FTL process was actually running (confirmed via `pgrep`) but `pihole status` reported it as down due to PID file permission issues (`/run/pihole-FTL.pid` owned by wrong user).

### 6. Troubleshooting Difficulty

Operator could not have internet and LAN access simultaneously — USB-Gigabit adapter connected to homelab LAN displaced the phone hotspot as the default route. Each diagnostic step required plugging in, running a command, unplugging, and returning to phone hotspot.

---

## Actions Taken

| # | Action | Result |
|---|--------|--------|
| 1 | `configctl interface reconfigure wan` (×2) | WAN IP restored both times |
| 2 | `service cron restart` | Cron daemon restarted with new PID |
| 3 | Manual watchdog execution | WAN recovered via Step 1 |
| 4 | Set Docker VM `/etc/resolv.conf` to `nameserver 192.168.0.1` | DNS fixed but still no internet (NAT missing) |
| 5 | `configctl filter reload` | OK but no NAT rules |
| 6 | `configctl service reload all` | configd error |
| 7 | `/usr/local/etc/rc.filter_configure` | Firewall reconfigured, still no NAT |
| 8 | `pfctl -a '*' -N -f /tmp/nat.conf` (manual NAT) | **NAT restored, LAN internet working** |
| 9 | `docker restart pihole` | FTL running, DNS resolving |

---

## Root Cause: Missing Outbound NAT Configuration

Investigation revealed OPNsense's "Automatic outbound NAT" mode was generating **zero rules**. The Automatic rules table was empty in the web UI, and `pfctl -sn` confirmed no NAT rules at pf level. This persisted across reboots and `configctl filter reload` / `rc.filter_configure` attempts.

### Resolution

1. Changed NAT mode from **Automatic** to **Hybrid** (Firewall > NAT > Outbound)
2. Created 3 manual outbound NAT rules via web UI:

| Interface | Source | Destination | NAT Address | Description |
|-----------|--------|-------------|-------------|-------------|
| WAN | 192.168.0.0/24 | * | Interface address | LAN outbound NAT |
| IOT | 192.168.10.0/24 | * | Interface address | IOT outbound NAT |
| GUEST | 192.168.20.0/24 | * | Interface address | GUEST outbound NAT |

3. Applied changes — rules now persist in OPNsense config (surviving reboots)

### Interim Fix (before permanent rules)

Manual pfctl injection was used to restore internet while troubleshooting:
```sh
# Write NAT config locally, scp to OPNsense, then load
scp /tmp/nat.conf root@192.168.0.1:/tmp/nat.conf
ssh root@192.168.0.1 "pfctl -N -f /tmp/nat.conf"
```

Note: `pfctl -a '*' -N -f` and `pfctl -a 'OPNsense' -N -f` did NOT work. Only `pfctl -N -f` (loading into the main ruleset) was effective.

---

## Prevention Plan

### P0 — Immediate

#### 1. Fix WAN Watchdog Cron

Investigate why cron didn't execute. Options:
- Use OPNsense's built-in cron (System > Settings > Cron in web UI) instead of system crontab
- Create a configd action for the watchdog so it integrates with OPNsense's cron system
- Add a configd action file: `/usr/local/opnsense/service/conf/actions.d/actions_wanwatchdog.conf`

#### 2. Update Watchdog to Restore NAT

Add NAT rule check and restoration to `wan_watchdog.sh`:
```sh
# After WAN recovery, check if NAT rules exist
if ! pfctl -sn | grep -q 'nat on vtnet0'; then
    log_msg "NAT rules missing — triggering filter reconfigure"
    /usr/local/etc/rc.filter_configure
    sleep 10
    if ! pfctl -sn | grep -q 'nat on vtnet0'; then
        # Emergency: inject NAT directly
        pfctl -N -f /tmp/nat_emergency.conf
        log_msg "Emergency NAT injected via pfctl"
    fi
fi
```

#### 3. Fix Docker VM Tailscale DNS Bootstrap

Docker VM's `/etc/resolv.conf` is overwritten by Tailscale to `nameserver 100.100.100.100`. When Tailscale disconnects, the entire host loses DNS resolution. Options:
- Set `accept-dns=false` on Docker VM Tailscale
- Add a fallback nameserver to `/etc/resolv.conf` (e.g., `nameserver 192.168.0.1`)
- Configure systemd-resolved with a fallback

#### 4. Fix Pi-hole PID File Permissions

`pihole status` reports "DNS service is NOT running" due to PID file permission denied, but FTL IS running (confirmed via `pgrep -a pihole-FTL`). Cosmetic but confusing during incidents.

### P1 — Short Term

#### 5. Dual Network Troubleshooting

The inability to have internet + LAN simultaneously severely hampered troubleshooting. Fix:
```bash
# Route only homelab LAN via USB-Gigabit, keep internet via hotspot
sudo route add 192.168.0.0/24 192.168.0.1
```

---

## Architecture Lessons

```text
FAILURE CASCADE (Outage #2):
ISP Down → WAN Lost → Watchdog didn't fire → Manual WAN fix
  → NAT rules missing (persistent config issue) → LAN no internet
  → Docker VM DNS broken (resolv.conf = Tailscale 100.100.100.100)
  → Tailscale disconnects (can't reach Headscale)
  → Pi-hole upstream fails → ALL LAN DNS dead
  → Cameras offline, all services unreachable

GAPS EXPOSED:
1. Outbound NAT was silently broken (Automatic mode generating zero rules)
2. Watchdog cron not integrated with OPNsense properly
3. WAN recovery (configctl reconfigure) doesn't restore NAT rules
4. Docker VM DNS depends entirely on Tailscale (single point of failure)
5. No way to have LAN + internet simultaneously for troubleshooting
6. Pi-hole status check broken (cosmetic but confusing during incidents)

WHAT WORKED:
1. SSH key auth on OPNsense — enabled scripted recovery
2. WAN watchdog script — works when manually executed (Step 1 = instant fix)
3. pfctl NAT injection — creative workaround while investigating
4. Incident documented in real-time — precise timeline for post-mortem
```

## Open Questions

1. **When did Automatic NAT break?** The March 5 outage auto-recovered (NAT was working). Something regressed between March 5-18. Candidates: OPNsense update, VLAN configuration changes, or a config corruption during an outage.
2. **Why does `rc.filter_configure` not generate NAT rules?** This script should regenerate all pf rules from config, including NAT. The fact that it doesn't suggests the NAT config in `/conf/config.xml` may have been incomplete even before this incident.
3. **Will the manual Hybrid rules survive an OPNsense upgrade?** Manual rules in Hybrid mode should persist, but worth verifying after the next OPNsense update.

---

## References

- Previous incident: `docs/guides/incident-2026-03-05-isp-outage.md`
- WAN watchdog plan: `docs/plans/wan-watchdog-2026-02-23.md`
- WAN watchdog script: `scripts/wan_watchdog.sh`
- OPNsense outbound NAT docs: `https://docs.opnsense.org/manual/nat.html`
