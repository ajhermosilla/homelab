#!/bin/bash
# Homelab Recovery Script
# Run from any device on LAN 192.168.0.0/24 (or via ProxyJump)
#
# Diagnoses and recovers from common outage scenarios:
#   - ISP outage (OPNsense WAN DHCP)
#   - Docker container crash loops
#   - Tailscale tunnel failures
#
# Usage:
#   ./scripts/homelab-recovery.sh              # full check
#   ./scripts/homelab-recovery.sh --wan-only    # just check/fix WAN
#   ./scripts/homelab-recovery.sh --docker-only # just check Docker

set -uo pipefail

# --- Configuration ---
OPNSENSE_IP="192.168.0.1"
PROXMOX_IP="192.168.0.237"
DOCKERVM_IP="192.168.0.10"
NAS_IP="192.168.0.12"
SSH_OPTS="-o ConnectTimeout=5 -o BatchMode=yes"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; }

check_host() {
    local name=$1 ip=$2
    if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
        ok "$name ($ip) reachable"
        return 0
    else
        fail "$name ($ip) unreachable"
        return 1
    fi
}

# --- LAN Reachability ---
check_lan() {
    echo ""
    echo "=== LAN Reachability ==="
    check_host "OPNsense" "$OPNSENSE_IP" || true
    check_host "Proxmox" "$PROXMOX_IP" || true
    check_host "Docker VM" "$DOCKERVM_IP" || true
    check_host "NAS" "$NAS_IP" || true
}

# --- OPNsense WAN ---
check_wan() {
    echo ""
    echo "=== OPNsense WAN ==="

    if ! ping -c 1 -W 2 "$OPNSENSE_IP" >/dev/null 2>&1; then
        fail "OPNsense not reachable — check Proxmox VM 100"
        return 1
    fi

    # Check if we can SSH (requires key auth setup)
    if ! ssh $SSH_OPTS "root@$OPNSENSE_IP" "echo ok" >/dev/null 2>&1; then
        warn "Cannot SSH to OPNsense (key auth not configured?)"
        echo "  Manual check: ssh -o PubkeyAuthentication=no root@$OPNSENSE_IP"
        echo "  Then run: ping -c 2 8.8.8.8"
        return 1
    fi

    # Check WAN internet (OPNsense uses csh — wrap in /bin/sh)
    if ssh $SSH_OPTS "root@$OPNSENSE_IP" /bin/sh -c "'ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1'"; then
        ok "WAN has internet"
    else
        fail "WAN has no internet — attempting DHCP renewal..."
        ssh $SSH_OPTS "root@$OPNSENSE_IP" "configctl interface reconfigure wan"
        sleep 5
        if ssh $SSH_OPTS "root@$OPNSENSE_IP" /bin/sh -c "'ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1'"; then
            ok "WAN recovered after DHCP renewal"
        else
            fail "WAN still down — check ARRIS modem and ISP"
            return 1
        fi
    fi

    # Check MTU (parse locally to avoid csh issues)
    local mtu
    mtu=$(ssh $SSH_OPTS "root@$OPNSENSE_IP" "ifconfig vtnet0" 2>/dev/null | command grep -o 'mtu [0-9]*' | awk '{print $2}')
    if [ -n "$mtu" ] && [ "$mtu" -lt 1400 ]; then
        warn "WAN MTU is $mtu (expected >=1400) — may cause fragmentation"
    elif [ -n "$mtu" ]; then
        ok "WAN MTU: $mtu"
    fi
}

# --- Docker VM ---
check_docker() {
    echo ""
    echo "=== Docker VM Containers ==="

    if ! ping -c 1 -W 2 "$DOCKERVM_IP" >/dev/null 2>&1; then
        fail "Docker VM not reachable"
        return 1
    fi

    if ! ssh $SSH_OPTS "augusto@$DOCKERVM_IP" "echo ok" >/dev/null 2>&1; then
        # Try via Proxmox jump
        if ! ssh $SSH_OPTS -o ProxyJump="augusto@$PROXMOX_IP" "augusto@$DOCKERVM_IP" "echo ok" >/dev/null 2>&1; then
            fail "Cannot SSH to Docker VM (direct or via Proxmox)"
            return 1
        fi
        SSH_CMD="ssh $SSH_OPTS -o ProxyJump=augusto@$PROXMOX_IP augusto@$DOCKERVM_IP"
    else
        SSH_CMD="ssh $SSH_OPTS augusto@$DOCKERVM_IP"
    fi

    # Check for crash-looping containers
    local restarting
    restarting=$($SSH_CMD "docker ps --format '{{.Names}}\t{{.Status}}' | command grep Restarting" 2>/dev/null || true)

    if [ -n "$restarting" ]; then
        fail "Crash-looping containers found:"
        echo "$restarting" | while IFS= read -r line; do
            echo "    $line"
        done

        # Check for missing .env files
        echo ""
        local missing
        missing=$($SSH_CMD "for d in /opt/homelab/repo/docker/fixed/docker-vm/*/; do name=\$(basename \$d); if [ -f \$d/.env.example ] && [ ! -f \$d/.env ]; then echo \$name; fi; done" 2>/dev/null || true)
        if [ -n "$missing" ]; then
            fail "Missing .env files for: $missing"
            echo "  Fix: restore from /opt/homelab/repo/env-backup/ or regenerate"
        fi
    else
        ok "No crash-looping containers"
    fi

    # Count healthy vs total
    local total healthy
    total=$($SSH_CMD "docker ps -q | wc -l" 2>/dev/null)
    healthy=$($SSH_CMD "docker ps --format '{{.Status}}' | command grep -c healthy" 2>/dev/null || echo "0")
    ok "$healthy/$total containers healthy"
}

# --- NAS ---
check_nas() {
    echo ""
    echo "=== NAS ==="

    if ! ping -c 1 -W 2 "$NAS_IP" >/dev/null 2>&1; then
        fail "NAS not reachable"
        return 1
    fi

    ok "NAS reachable"

    if ssh $SSH_OPTS "augusto@$NAS_IP" "echo ok" >/dev/null 2>&1; then
        local restarting
        restarting=$(ssh $SSH_OPTS "augusto@$NAS_IP" "docker ps --format '{{.Names}}\t{{.Status}}' | command grep Restarting" 2>/dev/null || true)
        if [ -n "$restarting" ]; then
            fail "NAS crash-looping containers:"
            echo "$restarting"
        else
            local total
            total=$(ssh $SSH_OPTS "augusto@$NAS_IP" "docker ps -q | wc -l" 2>/dev/null)
            ok "$total containers running"
        fi
    else
        warn "Cannot SSH to NAS"
    fi
}

# --- Tailscale ---
check_tailscale() {
    echo ""
    echo "=== Tailscale ==="

    if ! command -v tailscale >/dev/null 2>&1; then
        warn "tailscale CLI not found on this machine"
        return 0
    fi

    local status
    status=$(tailscale status 2>/dev/null | head -1)
    if echo "$status" | command grep -q "Tailscale is stopped"; then
        fail "Tailscale is stopped on this machine"
    else
        ok "Tailscale running"
        # Check key nodes
        for node in docker nas oga vps-vultr; do
            if tailscale status 2>/dev/null | command grep -q "$node"; then
                local state
                state=$(tailscale status 2>/dev/null | command grep "$node" | awk '{print $NF}')
                if echo "$state" | command grep -q "offline"; then
                    warn "$node: offline"
                else
                    ok "$node: online"
                fi
            fi
        done
    fi
}

# --- Main ---
main() {
    echo "Homelab Recovery Check — $(date '+%Y-%m-%d %H:%M:%S')"

    case "${1:-all}" in
        --wan-only)   check_wan ;;
        --docker-only) check_docker ;;
        --nas-only)   check_nas ;;
        all)
            check_lan
            check_wan
            check_docker
            check_nas
            check_tailscale
            ;;
        *)
            echo "Usage: $0 [--wan-only|--docker-only|--nas-only]"
            exit 1
            ;;
    esac

    echo ""
    echo "=== Done ==="
}

main "$@"
