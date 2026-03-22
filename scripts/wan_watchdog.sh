#!/bin/sh
# WAN Watchdog — auto-recover OPNsense WAN and NAT after ISP outage
# Deployed to /root/wan_watchdog.sh on OPNsense
# Cron: */5 * * * * /root/wan_watchdog.sh
#
# Checks:
#   - WAN connectivity (ping probes)
#   - Outbound NAT rules exist (pfctl -sn)
#
# Escalating WAN recovery:
#   1. configctl interface reconfigure wan
#   2. dhclient release + renew
#   3. interface down/up + dhclient
#
# NAT recovery:
#   1. /usr/local/etc/rc.filter_configure
#   2. Emergency pfctl injection from /root/nat_emergency.conf
#
# Safety: 30-minute cooldown between recovery attempts
# Probes: 1.1.1.1, 8.8.8.8, 9.9.9.9 — all must fail to trigger

LOG="/var/log/wan_watchdog.log"
LOCKFILE="/tmp/wan_watchdog.lock"
COOLDOWN=1800  # 30 minutes in seconds
WAN_IF="vtnet0"
NAT_EMERGENCY="/root/nat_emergency.conf"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"
}

# Test connectivity — returns 0 if ANY probe responds
check_wan() {
    ping -c 1 -W 3 1.1.1.1 > /dev/null 2>&1 && return 0
    ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1 && return 0
    ping -c 1 -W 3 9.9.9.9 > /dev/null 2>&1 && return 0
    return 1
}

# Test NAT rules — returns 0 if outbound NAT exists
check_nat() {
    pfctl -sn 2>/dev/null | grep -q "nat on $WAN_IF"
}

# Recover NAT rules if missing
recover_nat() {
    log_msg "NAT rules missing — attempting recovery"

    # Step 1: reload filter config from OPNsense config.xml
    /usr/local/etc/rc.filter_configure > /dev/null 2>&1
    sleep 10
    if check_nat; then
        log_msg "NAT recovered via rc.filter_configure"
        return 0
    fi

    # Step 2: emergency pfctl injection
    if [ -f "$NAT_EMERGENCY" ]; then
        pfctl -N -f "$NAT_EMERGENCY" 2>/dev/null
        if check_nat; then
            log_msg "NAT recovered via emergency pfctl injection"
            return 0
        fi
    fi

    log_msg "NAT recovery FAILED — manual intervention required"
    return 1
}

# Check cooldown
if [ -f "$LOCKFILE" ]; then
    lock_age=$(( $(date +%s) - $(stat -f %m "$LOCKFILE" 2>/dev/null || echo 0) ))
    if [ "$lock_age" -lt "$COOLDOWN" ]; then
        exit 0
    fi
    rm -f "$LOCKFILE"
fi

# Quick check — exit silently if WAN and NAT are both fine
if check_wan; then
    # WAN is up — still verify NAT rules exist (silent failure from Mar 18 incident)
    if ! check_nat; then
        recover_nat
    fi
    exit 0
fi

# All probes failed — start recovery
log_msg "WAN DOWN — all probes failed, starting recovery"
touch "$LOCKFILE"

# Step 1: OPNsense native reconfigure
log_msg "Step 1: configctl interface reconfigure wan"
configctl interface reconfigure wan
sleep 30
if check_wan; then
    log_msg "Step 1 SUCCESS — WAN recovered via reconfigure"
    check_nat || recover_nat
    rm -f "$LOCKFILE"
    exit 0
fi

# Step 2: DHCP release + renew
log_msg "Step 2: dhclient release + renew"
dhclient -r "$WAN_IF" 2>/dev/null
sleep 5
dhclient "$WAN_IF" 2>/dev/null
sleep 30
if check_wan; then
    log_msg "Step 2 SUCCESS — WAN recovered via DHCP renew"
    check_nat || recover_nat
    rm -f "$LOCKFILE"
    exit 0
fi

# Step 3: Full interface reset
log_msg "Step 3: interface down/up + dhclient"
ifconfig "$WAN_IF" down
sleep 5
ifconfig "$WAN_IF" up
sleep 5
dhclient "$WAN_IF" 2>/dev/null
sleep 30
if check_wan; then
    log_msg "Step 3 SUCCESS — WAN recovered via interface reset"
    check_nat || recover_nat
    rm -f "$LOCKFILE"
    exit 0
fi

log_msg "FAILED — all recovery steps exhausted. Modem power cycle may be required."
