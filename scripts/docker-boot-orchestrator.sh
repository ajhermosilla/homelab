#!/usr/bin/env bash
# docker-boot-orchestrator.sh — Post-boot Docker stack orchestration
# Ensures stacks start in correct dependency order via docker compose up -d
# (not individual container restarts, which miss network creation)
#
# Solves:
#   1. mqtt-net race: Docker daemon restarts containers individually after reboot,
#      so the external mqtt-net network may not exist when Frigate starts → crash loop
#   2. NFS race: fstab nofail means mount fails silently if NAS boots slower
#
# Safe to re-run manually: stops everything, then starts in order.

set -euo pipefail

REPO_ROOT="/opt/homelab/repo"
COMPOSE_BASE="${REPO_ROOT}/docker/fixed/docker-vm"
NFS_MOUNT="/mnt/nas/frigate"
NFS_TIMEOUT=300
DOCKER_TIMEOUT=60

# Stack compose directories (absolute paths)
# Pi-hole runs from /opt/homelab/pihole/ (not the repo) because it needs
# a local .env with PIHOLE_PASSWORD that isn't checked into git.
NETWORKING_STACKS=("/opt/homelab/pihole" "${COMPOSE_BASE}/networking/caddy")
AUTOMATION_STACK="${COMPOSE_BASE}/automation"
SECURITY_STACK="${COMPOSE_BASE}/security"
MEDIA_STACK="${COMPOSE_BASE}/media"
MAINTENANCE_STACK="${COMPOSE_BASE}/maintenance"

# --- Logging ---

log() {
    local msg="[boot-orchestrator] $*"
    echo "$msg"
    logger -t boot-orchestrator "$*" 2>/dev/null || true
}

log_warn() {
    log "WARNING: $*"
}

log_error() {
    log "ERROR: $*"
}

# --- Phase helpers ---

wait_for_docker() {
    log "Phase 1: Waiting for Docker daemon (timeout: ${DOCKER_TIMEOUT}s)"
    local elapsed=0
    while ! docker info >/dev/null 2>&1; do
        if (( elapsed >= DOCKER_TIMEOUT )); then
            log_error "Docker daemon not available after ${DOCKER_TIMEOUT}s — aborting"
            exit 1
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    log "Docker daemon ready (${elapsed}s)"
}

wait_for_nfs() {
    log "Phase 2: Waiting for NFS mount ${NFS_MOUNT} (timeout: ${NFS_TIMEOUT}s)"

    # If already mounted, we're good
    if mountpoint -q "$NFS_MOUNT" 2>/dev/null; then
        log "NFS already mounted at ${NFS_MOUNT}"
        return 0
    fi

    # Try mounting (systemd automount or manual)
    log "Attempting mount of ${NFS_MOUNT}"
    mount "$NFS_MOUNT" 2>/dev/null || true

    local elapsed=0
    while ! mountpoint -q "$NFS_MOUNT" 2>/dev/null; do
        if (( elapsed >= NFS_TIMEOUT )); then
            log_warn "NFS mount not available after ${NFS_TIMEOUT}s — continuing without NFS"
            log_warn "Frigate will record to local disk; media stack may have issues"
            return 1
        fi
        # Retry mount every 30s
        if (( elapsed % 30 == 0 && elapsed > 0 )); then
            log "Retrying NFS mount (${elapsed}s elapsed)"
            mount "$NFS_MOUNT" 2>/dev/null || true
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    log "NFS mounted at ${NFS_MOUNT} (${elapsed}s)"
    return 0
}

stop_all_containers() {
    log "Phase 3: Stopping all containers for clean state"
    local containers
    containers=$(docker ps -q 2>/dev/null)
    if [ -n "$containers" ]; then
        docker stop $containers 2>/dev/null || true
        log "All containers stopped"
    else
        log "No running containers"
    fi
}

compose_up() {
    local stack_path="$1"

    if [ ! -f "${stack_path}/docker-compose.yml" ]; then
        log_warn "Compose file not found: ${stack_path}/docker-compose.yml — skipping"
        return 1
    fi

    log "Starting stack: ${stack_path}"
    if docker compose -f "${stack_path}/docker-compose.yml" --project-directory "${stack_path}" up -d 2>&1; then
        log "Stack started: ${stack_path}"
        return 0
    else
        log_error "Failed to start stack: ${stack_path}"
        return 1
    fi
}

wait_for_healthy() {
    local container="$1"
    local timeout="${2:-120}"
    local elapsed=0

    log "Waiting for ${container} to be healthy (timeout: ${timeout}s)"
    while true; do
        local health
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "missing")

        case "$health" in
            healthy)
                log "${container} is healthy (${elapsed}s)"
                return 0
                ;;
            unhealthy)
                log_error "${container} is unhealthy after ${elapsed}s"
                return 1
                ;;
            missing)
                if (( elapsed >= timeout )); then
                    log_error "${container} not found after ${timeout}s"
                    return 1
                fi
                ;;
            *)
                if (( elapsed >= timeout )); then
                    log_error "${container} not healthy after ${timeout}s (status: ${health})"
                    return 1
                fi
                ;;
        esac
        sleep 5
        elapsed=$((elapsed + 5))
    done
}

# --- Main ---

main() {
    log "=== Docker Boot Orchestrator starting ==="

    # Phase 1: Docker daemon
    wait_for_docker

    # Phase 2: NFS mount (non-fatal if unavailable)
    wait_for_nfs || true

    # Phase 3: Stop all containers
    stop_all_containers

    # Phase 4: Networking (Pi-hole + Caddy)
    log "Phase 4: Starting networking stacks"
    for stack in "${NETWORKING_STACKS[@]}"; do
        compose_up "$stack" || true
    done

    # Phase 5: Automation (creates mqtt-net, wait for Mosquitto healthy)
    log "Phase 5: Starting automation stack"
    compose_up "$AUTOMATION_STACK" || true
    wait_for_healthy "mosquitto" 120 || log_warn "Mosquitto not healthy — security stack may have MQTT issues"

    # Phase 6: Security (Frigate joins mqtt-net)
    log "Phase 6: Starting security stack"
    compose_up "$SECURITY_STACK" || true

    # Phase 7: Media (NFS-dependent — needs /mnt/nas/media and /mnt/nas/downloads)
    log "Phase 7: Starting media stack"
    compose_up "$MEDIA_STACK" || true

    # Phase 8: Maintenance (Watchtower — last)
    log "Phase 8: Starting maintenance stack"
    compose_up "$MAINTENANCE_STACK" || true

    # Phase 9: Final status
    log "Phase 9: Final container status"
    log "=== Container Status ==="
    docker ps --format 'table {{.Names}}\t{{.Status}}' | while IFS= read -r line; do
        log "$line"
    done

    local total
    total=$(docker ps -q | wc -l)
    log "=== Boot orchestration complete: ${total} containers running ==="
}

main "$@"
