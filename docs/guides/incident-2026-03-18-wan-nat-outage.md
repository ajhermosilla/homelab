# Incident Report: ISP Outage + Missing NAT Rules

**Date**: 2026-03-18
**Duration**: ~2 hours (ISP recovery + troubleshooting)
**Severity**: High — all homelab services unreachable externally, no LAN internet
**ISP**: Tigo Paraguay (ARRIS modem, bridge mode)

---

## Summary

An ISP outage caused OPNsense to lose WAN connectivity. The WAN watchdog script (deployed earlier the same day) had its cron entry registered but never executed. Manual `configctl interface reconfigure wan` restored WAN, but OPNsense's outbound NAT rules were not regenerated. Without NAT, LAN hosts could reach OPNsense but not the internet. This caused a cascading failure: Docker VM lost internet → Tailscale disconnected → Pi-hole DNS upstream failed → all LAN DNS broke → cameras went offline.

---

## Timeline (PYT, UTC-3)

| Time | Event |
|------|-------|
| ~12:30 | ISP outage begins |
| ~12:30 | OPNsense WAN loses IP, all Tailscale tunnels drop |
| 13:00 | Investigation begins — Mac on phone hotspot, Docker VM reachable via Tailscale relay |
| 13:05 | Docker VM Tailscale shows offline, NAS/Proxmox unreachable |
| 13:10 | Plugged USB-Gigabit to MokerLink switch — Mac gets DHCP (192.168.0.117) |
| 13:12 | SSH to OPNsense — WAN shows blank (no IP) |
| 13:12 | `configctl interface reconfigure wan` — WAN IP restored (181.127.152.105) |
| 13:14 | OPNsense can ping 8.8.8.8, but Docker VM cannot |
| 13:15 | Reconnected Tailscale on Docker VM via LAN SSH |
| ~13:30 | Second outage — ISP drops again, WAN goes blank |
| 13:36 | WAN watchdog log checked — script never ran (cron issue) |
| 13:38 | Manual watchdog execution — WAN recovered via Step 1 |
| 13:40 | Cron restarted (`service cron restart`) |
| 13:48 | Pi-hole DNS found broken — gravity.db corrupted (missing views), FTL PID file permission denied |
| 13:50 | Discovered Docker VM `/etc/resolv.conf` overwritten by Tailscale (`nameserver 100.100.100.100`) |
| 13:52 | Set Docker VM DNS to `nameserver 192.168.0.1` — still no internet |
| 13:56 | Docker VM routing OK (gateway 192.168.0.1, can ping OPNsense) but no internet |
| 13:58 | Discovered `pfctl -s nat` shows NO outbound NAT rules |
| 14:00 | `configctl filter reload` — returned OK but NAT not restored |
| 14:01 | `configctl service reload all` — configd communication error |
| 14:05 | `/usr/local/etc/rc.filter_configure` — firewall reconfigured but still no NAT |
| 14:10 | Manual pfctl NAT injection: `echo 'nat on vtnet0 from 192.168.0.0/24 to any -> (vtnet0) round-robin' > /tmp/nat.conf && pfctl -a '*' -N -f /tmp/nat.conf` — **SUCCESS** |
| 14:10 | LAN internet restored, cameras green |
| 14:15 | Pi-hole restarted — FTL running, DNS resolving (PID file error is cosmetic) |
| 14:17 | Full recovery confirmed — `dig google.com @192.168.0.10` returns results |

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

## Temporary Fix in Place

Manual NAT rule added via pfctl — **will not survive OPNsense reboot**. A scheduled reboot is needed to cleanly restore all rules from OPNsense config.

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
if ! pfctl -s nat | grep -q 'nat on vtnet0'; then
    echo 'nat on vtnet0 from 192.168.0.0/24 to any -> (vtnet0) round-robin' > /tmp/nat_emergency.conf
    pfctl -a '*' -N -f /tmp/nat_emergency.conf
    /usr/local/etc/rc.filter_configure
    log_msg "NAT rules were missing — emergency NAT injected + filter reconfigured"
fi
```

#### 3. Fix Docker VM Tailscale DNS Bootstrap

Add `hs.cronova.dev` to Docker VM's `/etc/hosts` (like VPS already has):
```
104.207.144.195 hs.cronova.dev
```
This prevents Tailscale from failing to reconnect when DNS is down.

Note: Docker VM already has this in `/etc/hosts` but Tailscale overwrites `/etc/resolv.conf` to `100.100.100.100`. When Tailscale is disconnected, this DNS server is unreachable. Consider setting `accept-dns=false` on Docker VM or adding a fallback nameserver.

#### 4. Fix Pi-hole PID File Permissions

The `pihole status` check fails with "Permission denied" on `/run/pihole-FTL.pid`. This is a Pi-hole v6 issue. Options:
- Add `CHOWN` and `DAC_OVERRIDE` to Pi-hole container caps
- Run FTL as root inside the container
- Ignore — FTL is running, the status check is misleading

### P1 — Short Term

#### 5. Schedule OPNsense Reboot

Reboot OPNsense to cleanly restore all pf rules from config. Do this during a maintenance window (late night). The manual NAT rule currently in place will not survive reboot, but the proper rules should load from config.

#### 6. Investigate OPNsense Outbound NAT Config

Via web UI (Firewall > NAT > Outbound), verify:
- Mode is set to "Automatic outbound NAT" or "Hybrid"
- Rules exist for 192.168.0.0/24, 192.168.10.0/24, 192.168.20.0/24
- If mode is "Manual" and rules were somehow deleted, recreate them

#### 7. Dual Network Troubleshooting

The inability to have internet + LAN simultaneously severely hampered troubleshooting. Options:
- Set Mac network service order: phone hotspot as primary, USB-Gigabit as secondary
- Use `route add` to only route 192.168.0.0/24 via USB-Gigabit while keeping internet via hotspot
- Example: `sudo route add 192.168.0.0/24 192.168.0.1`

---

## Architecture Lessons

```text
FAILURE CASCADE:
ISP Down → WAN Lost → Watchdog didn't fire → Manual WAN fix
  → NAT not restored → LAN no internet → Tailscale down
  → Docker VM DNS broken (resolv.conf = Tailscale)
  → Pi-hole upstream fails → ALL LAN DNS dead
  → Cameras offline, all services unreachable

GAPS EXPOSED:
1. Watchdog cron not integrated with OPNsense properly
2. WAN recovery doesn't restore NAT rules
3. Docker VM DNS depends on Tailscale (single point of failure)
4. No way to have LAN + internet simultaneously for troubleshooting
5. Pi-hole status check broken (cosmetic but confusing)
```

---

## References

- Previous incident: `docs/guides/incident-2026-03-05-isp-outage.md`
- WAN watchdog plan: `docs/plans/wan-watchdog-2026-02-23.md`
- WAN watchdog script: `scripts/wan_watchdog.sh`
