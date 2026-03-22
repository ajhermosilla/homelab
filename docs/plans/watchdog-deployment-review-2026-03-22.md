# WAN Watchdog + NAT Emergency Deployment Review — 2026-03-22

> **Status**: Code reviewed, ready to deploy. Deferred to next maintenance window (Mon Mar 24 night).

## What's Changing

| Item | Current (deployed) | New (repo) |
|------|-------------------|------------|
| `wan_watchdog.sh` | 83 lines, WAN-only | 131 lines, WAN + NAT check |
| `nat_emergency.conf` | Doesn't exist | 3 NAT rules (LAN/IOT/GUEST) |

## New Functionality

1. **`check_nat()`** — verifies outbound NAT rules exist via `pfctl -sn | grep "nat on vtnet0"`
2. **NAT check on every cycle** — even when WAN is up (lines 80-85), catches silent NAT failures
3. **`recover_nat()`** — two-step escalation: `rc.filter_configure` → emergency pfctl injection
4. **NAT verification after WAN recovery** — `check_nat || recover_nat` after each successful WAN recovery step

## Benefits

- Prevents the March 18 cascading failure (NAT disappeared silently while WAN was up)
- Defense in depth — permanent Hybrid NAT rules are primary, watchdog is safety net
- Self-healing — if NAT breaks again (OPNsense update, config corruption), fixed within 5 minutes

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| pfctl injects conflicting rules | Low | Medium | `check_nat` verifies first; injection only when zero rules |
| `rc.filter_configure` disrupts connections | Low | Low | Only runs when NAT is missing |
| Script bug causes high CPU | Very low | Low | 30-min cooldown, each cron run independent |
| `nat_emergency.conf` wrong subnets | Very low | High | Verified against OPNsense config.xml (Mar 18) |
| OPNsense update changes pfctl behavior | Low | Medium | Simple `grep`, should survive updates |

## Edge Cases Reviewed

- WAN up + NAT missing (March 18 scenario) — handled correctly
- WAN down + NAT missing — WAN recovery first, then NAT check
- Both recovery methods fail — logged, no harm
- `nat_emergency.conf` missing — file existence check, falls through
- Concurrent cron execution — lockfile prevents

## Known Minor Issue

`pfctl -N -f` could create duplicate NAT rules if OPNsense's Hybrid rules are also loaded. No functional impact (pf matches first rule). Cleans up on next reboot or filter reload.

## Deployment Commands

```bash
# 1. Backup current script
ssh root@192.168.0.1 "cp /root/wan_watchdog.sh /root/wan_watchdog.sh.bak"

# 2. Deploy new files
scp scripts/wan_watchdog.sh root@192.168.0.1:/root/wan_watchdog.sh
scp scripts/nat_emergency.conf root@192.168.0.1:/root/nat_emergency.conf

# 3. Verify
ssh root@192.168.0.1 "head -2 /root/wan_watchdog.sh && wc -l /root/wan_watchdog.sh && cat /root/nat_emergency.conf"

# 4. Test (WAN is up — should exit silently)
ssh root@192.168.0.1 "/root/wan_watchdog.sh && echo 'OK — exited cleanly'"

# 5. Check NAT still working
ssh root@192.168.0.1 "pfctl -sn | grep nat"
```

## Rollback

```bash
ssh root@192.168.0.1 "cp /root/wan_watchdog.sh.bak /root/wan_watchdog.sh"
```

## Verdict

Safe to deploy. New code is additive, doesn't modify existing behavior, has proper guards. Worst case is redundant NAT rule that cleans up on reboot.
