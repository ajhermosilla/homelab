# WAN Watchdog — ISP Outage Recovery Research

**Date**: 2026-02-23
**Context**: ISP outage (~3:00–4:00 PM PYT) left OPNsense without a WAN IP. Required manual power cycle of ARRIS modem + OPNsense console access to recover.

## Root Cause Analysis

### 1. ARRIS Bridge Mode Stale State (Primary Culprit)

Cable modems in bridge mode maintain a MAC address table that maps to the single downstream device. After an ISP outage:

1. ISP goes down. The CMTS (cable headend) drops the modem's session.
2. ISP comes back. The modem re-registers (lights go green).
3. However, the modem's internal bridge table can become inconsistent — stale ARP entries, corrupted bridge state, or lingering DHCP session data.
4. DHCP packets from OPNsense never reach the ISP's DHCP server.
5. **Only a power cycle clears all internal state**, forces a fresh CMTS registration, and re-establishes the bridge.

This cannot be fixed from the OPNsense side — the modem is physically between OPNsense and the ISP.

### 2. FreeBSD dhclient Regression

OPNsense uses FreeBSD's `dhclient`, which follows a renewal lifecycle:

- At **50%** of lease time: sends DHCPREQUEST (unicast) to renew
- At **75%** of lease time: broadcasts DHCPREQUEST (rebind phase)
- At **100%** (lease expiry): removes IP from the interface entirely

**Known regression (FreeBSD 12.1+)**: After lease expiry with no server, dhclient prints "No working leases in persistent database - sleeping" and effectively stops retrying. The `dhclient-script` TIMEOUT handler rejects valid leases when the gateway is not yet pingable.

**Result**: Even if the ISP/modem recovers, dhclient may have already given up.

## Solution: WAN Watchdog Script

### Design

Deployed at `/root/wan_watchdog.sh` on OPNsense. Runs every 5 minutes via cron. Escalating recovery:

| Step | Method | What It Does |
|------|--------|-------------|

| 1 | `configctl interface reconfigure wan` | OPNsense-native, keeps system state consistent |
| 2 | `dhclient -r` + `dhclient` | Full DHCP release/renew cycle |
| 3 | `ifconfig down/up` + `dhclient` | Nuclear option — full interface reset |

Each step waits 30 seconds and re-tests connectivity before escalating.

### Safety Features

- **Cooldown**: 30-minute lockout between recovery attempts (prevents rapid-fire during extended outages)
- **Multi-probe**: Pings `1.1.1.1`, `8.8.8.8`, `9.9.9.9` — all three must fail before triggering recovery
- **Silent on success**: Exits immediately with no logging when connectivity is fine
- **Log rotation**: 7 days, auto-rotated via newsyslog

### Files Deployed

| File | Purpose |
|------|---------|

| `/root/wan_watchdog.sh` | Watchdog script |
| `/usr/local/opnsense/service/conf/actions.d/actions_wanwatchdog.conf` | configd action (enables cron integration) |
| `/etc/newsyslog.conf.d/wan_watchdog.conf` | Log rotation config |
| `/var/log/wan_watchdog.log` | Runtime log (created on first failure) |

### Cron Job

- **Schedule**: `*/5 *** *` (every 5 minutes)
- **Location**: System > Settings > Cron in OPNsense web UI

## OPNsense Settings to Review

### Reject Leases From (Interfaces > WAN)

Set to `192.168.100.1` (ARRIS management IP). Prevents OPNsense from accepting a private IP from the modem's fallback DHCP server when the WAN side is down.

**Note**: Known bug (OPNsense Issue #7580) where this doesn't always work.

### DHCP Advanced Options (Interfaces > WAN)

Consider adding: `supersede dhcp-lease-time 86400;` — forces a 24-hour lease regardless of ISP offer, giving more time for ISP recovery before lease expiry triggers dhclient's broken behavior.

## What the Watchdog Cannot Fix

The **ARRIS modem stale bridge state** requires a physical power cycle. Options:

1. **Smart plug** (Tapo/Shelly) controlled via Home Assistant — auto-power-cycle the modem after the watchdog exhausts all OPNsense-side fixes
2. **Manual power cycle** — unplug ARRIS, wait 30–60 seconds, plug back in

## Monitoring

- **Uptime Kuma** (VPS): Add a ping monitor for `100.79.230.235` (OPNsense Tailscale IP) for early notification via ntfy
- **Log review**: `cat /var/log/wan_watchdog.log` on OPNsense to see recovery history

## References

- [FreeBSD Forums: dhclient "No working leases" regression](https://forums.freebsd.org/threads/dhclient-gives-up-with-no-working-leases-in-persistent-database-after-power-outage-and-slow-isp-network-restart.93888/)
- [OPNsense Issue #5866: Auto DHCP renewal on gateway recovery](https://github.com/opnsense/core/issues/5866) (closed, "not planned")
- [OPNsense Issue #7514: DHCP lease expiration drops connection](https://github.com/opnsense/core/issues/7514)
- [Rex Bytes: OPNsense WAN Watchdog](https://rexbytes.com/2025/09/03/opnsense-automatic-recovery-when-wan-fails/)
- [Netgate Forum: Auto-renew DHCP after outage](https://forum.netgate.com/topic/127403/auto-renew-dhcp-after-outage)
