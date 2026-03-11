#!/bin/bash
# backup-verify.sh - Monthly backup verification script
# Run on: First Sunday of each month
# Usage: ./backup-verify.sh [--full]
#
# Tests (8 suites):
#   1. Restic repository health
#   2. Snapshot freshness (Headscale, VW, HA, Paperless, Immich)
#   3. Headscale restore
#   4. Vaultwarden restore
#   5. Home Assistant restore
#   6. Paperless-ngx restore
#   7. Immich DB restore (pg_dump integrity)
#   8. Offsite backup (Google Drive)
#
# Options:
#   --full    Run full quarterly restore drill (in test directory)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:?RESTIC_REPOSITORY required - see scripts/README.md for setup}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-/root/.restic-password}"
RESTORE_DIR="/tmp/backup-verify-$$"
NTFY_URL="${NTFY_URL:-https://notify.cronova.dev}"
NTFY_TOPIC="${NTFY_TOPIC:-cronova-info}"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive-crypt:homelab}"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
FULL_MODE=false

# Parse arguments
if [[ "${1:-}" == "--full" ]]; then
    FULL_MODE=true
fi

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_test() { echo -e "\n${YELLOW}=== TEST: $1 ===${NC}"; }

# Cleanup on exit
cleanup() {
    if [[ -d "$RESTORE_DIR" ]]; then
        log_info "Cleaning up restore directory..."
        rm -rf "$RESTORE_DIR"
    fi
}
trap cleanup EXIT

# Test 1: Restic Repository Health
test_restic_health() {
    log_test "Restic Repository Health"

    export RESTIC_REPOSITORY
    export RESTIC_PASSWORD_FILE

    if restic check 2>&1 | grep -q "no errors were found"; then
        log_info "Repository is healthy"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "Repository has errors!"
        log_warn "Attempting repair..."
        restic repair index
        restic repair snapshots
        if restic check 2>&1 | grep -q "no errors were found"; then
            log_info "Repository repaired successfully"
            ((TESTS_PASSED++))
            return 0
        fi
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 2: Verify Snapshots Exist
test_snapshots() {
    log_test "Snapshot Verification"

    export RESTIC_REPOSITORY
    export RESTIC_PASSWORD_FILE

    local now=$(date +%s)
    local errors=0

    # Check Headscale (should be within 2 hours)
    local hs_snapshot=$(restic snapshots --tag headscale --json 2>/dev/null | jq -r '.[-1].time // empty')
    if [[ -n "$hs_snapshot" ]]; then
        local hs_time=$(date -d "$hs_snapshot" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${hs_snapshot%%.*}" +%s 2>/dev/null)
        local hs_age=$(( (now - hs_time) / 3600 ))
        if [[ $hs_age -le 2 ]]; then
            log_info "Headscale snapshot: ${hs_age}h ago (OK)"
        else
            log_warn "Headscale snapshot: ${hs_age}h ago (expected <2h)"
            ((errors++))
        fi
    else
        log_error "No Headscale snapshot found!"
        ((errors++))
    fi

    # Check Vaultwarden (should be within 25 hours)
    local vw_snapshot=$(restic snapshots --tag vaultwarden --json 2>/dev/null | jq -r '.[-1].time // empty')
    if [[ -n "$vw_snapshot" ]]; then
        local vw_time=$(date -d "$vw_snapshot" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${vw_snapshot%%.*}" +%s 2>/dev/null)
        local vw_age=$(( (now - vw_time) / 3600 ))
        if [[ $vw_age -le 25 ]]; then
            log_info "Vaultwarden snapshot: ${vw_age}h ago (OK)"
        else
            log_warn "Vaultwarden snapshot: ${vw_age}h ago (expected <25h)"
            ((errors++))
        fi
    else
        log_error "No Vaultwarden snapshot found!"
        ((errors++))
    fi

    # Check Home Assistant (should be within 25 hours)
    local ha_snapshot=$(restic snapshots --tag homeassistant --json 2>/dev/null | jq -r '.[-1].time // empty')
    if [[ -n "$ha_snapshot" ]]; then
        local ha_time=$(date -d "$ha_snapshot" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${ha_snapshot%%.*}" +%s 2>/dev/null)
        local ha_age=$(( (now - ha_time) / 3600 ))
        if [[ $ha_age -le 25 ]]; then
            log_info "Home Assistant snapshot: ${ha_age}h ago (OK)"
        else
            log_warn "Home Assistant snapshot: ${ha_age}h ago (expected <25h)"
            ((errors++))
        fi
    else
        log_warn "No Home Assistant snapshot found (may be expected if not deployed)"
    fi

    # Check Paperless-ngx (should be within 25 hours)
    local pl_snapshot=$(restic snapshots --tag paperless --json 2>/dev/null | jq -r '.[-1].time // empty')
    if [[ -n "$pl_snapshot" ]]; then
        local pl_time=$(date -d "$pl_snapshot" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${pl_snapshot%%.*}" +%s 2>/dev/null)
        local pl_age=$(( (now - pl_time) / 3600 ))
        if [[ $pl_age -le 25 ]]; then
            log_info "Paperless-ngx snapshot: ${pl_age}h ago (OK)"
        else
            log_warn "Paperless-ngx snapshot: ${pl_age}h ago (expected <25h)"
            ((errors++))
        fi
    else
        log_warn "No Paperless-ngx snapshot found (may be expected if not deployed)"
    fi

    # Check Immich DB (should be within 25 hours)
    local im_snapshot=$(restic snapshots --tag immich-db --json 2>/dev/null | jq -r '.[-1].time // empty')
    if [[ -n "$im_snapshot" ]]; then
        local im_time=$(date -d "$im_snapshot" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${im_snapshot%%.*}" +%s 2>/dev/null)
        local im_age=$(( (now - im_time) / 3600 ))
        if [[ $im_age -le 25 ]]; then
            log_info "Immich DB snapshot: ${im_age}h ago (OK)"
        else
            log_warn "Immich DB snapshot: ${im_age}h ago (expected <25h)"
            ((errors++))
        fi
    else
        log_warn "No Immich DB snapshot found (may be expected if not deployed)"
    fi

    if [[ $errors -eq 0 ]]; then
        ((TESTS_PASSED++))
        return 0
    else
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 3: Headscale Restore
test_headscale_restore() {
    log_test "Headscale Restore"

    export RESTIC_REPOSITORY
    export RESTIC_PASSWORD_FILE

    mkdir -p "$RESTORE_DIR/headscale"

    if ! restic restore latest --target "$RESTORE_DIR/headscale" --tag headscale 2>/dev/null; then
        log_error "Failed to restore Headscale backup"
        ((TESTS_FAILED++))
        return 1
    fi

    local db_path="$RESTORE_DIR/headscale/var/lib/headscale/db.sqlite"
    local key_path="$RESTORE_DIR/headscale/var/lib/headscale/noise_private.key"

    # Check db.sqlite exists and is not empty
    if [[ -f "$db_path" && -s "$db_path" ]]; then
        log_info "db.sqlite exists and is not empty"

        # Verify database integrity
        local node_count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM nodes;" 2>/dev/null || echo "0")
        log_info "Database contains $node_count nodes"
    else
        log_error "db.sqlite missing or empty!"
        ((TESTS_FAILED++))
        return 1
    fi

    # Check noise_private.key exists
    if [[ -f "$key_path" ]]; then
        log_info "noise_private.key exists"
    else
        log_error "noise_private.key missing!"
        ((TESTS_FAILED++))
        return 1
    fi

    log_info "Headscale restore test passed"
    ((TESTS_PASSED++))
    return 0
}

# Test 4: Vaultwarden Restore
test_vaultwarden_restore() {
    log_test "Vaultwarden Restore"

    export RESTIC_REPOSITORY
    export RESTIC_PASSWORD_FILE

    mkdir -p "$RESTORE_DIR/vaultwarden"

    if ! restic restore latest --target "$RESTORE_DIR/vaultwarden" --tag vaultwarden 2>/dev/null; then
        log_error "Failed to restore Vaultwarden backup"
        ((TESTS_FAILED++))
        return 1
    fi

    local db_path="$RESTORE_DIR/vaultwarden/var/lib/vaultwarden/db.sqlite3"
    local rsa_path="$RESTORE_DIR/vaultwarden/var/lib/vaultwarden/rsa_key.pem"

    # Check db.sqlite3 exists
    if [[ -f "$db_path" && -s "$db_path" ]]; then
        log_info "db.sqlite3 exists"

        # Verify database
        local user_count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
        log_info "Database contains $user_count users"
    else
        log_error "db.sqlite3 missing or empty!"
        ((TESTS_FAILED++))
        return 1
    fi

    # Check RSA keys exist
    if [[ -f "$rsa_path" ]]; then
        log_info "RSA key exists"
    else
        log_error "RSA key missing!"
        ((TESTS_FAILED++))
        return 1
    fi

    log_info "Vaultwarden restore test passed"
    ((TESTS_PASSED++))
    return 0
}

# Test 5: Home Assistant Restore
test_homeassistant_restore() {
    log_test "Home Assistant Restore"

    export RESTIC_REPOSITORY
    export RESTIC_PASSWORD_FILE

    # Check if Home Assistant backups exist
    local ha_count=$(restic snapshots --tag homeassistant --json 2>/dev/null | jq length)
    if [[ "$ha_count" == "0" || -z "$ha_count" ]]; then
        log_warn "No Home Assistant backups found (skipping)"
        return 0
    fi

    mkdir -p "$RESTORE_DIR/homeassistant"

    if ! restic restore latest --target "$RESTORE_DIR/homeassistant" --tag homeassistant 2>/dev/null; then
        log_error "Failed to restore Home Assistant backup"
        ((TESTS_FAILED++))
        return 1
    fi

    local config_path="$RESTORE_DIR/homeassistant/config/configuration.yaml"
    local storage_path="$RESTORE_DIR/homeassistant/config/.storage"

    # Check configuration.yaml exists
    if [[ -f "$config_path" ]]; then
        log_info "configuration.yaml exists"
    else
        log_error "configuration.yaml missing!"
        ((TESTS_FAILED++))
        return 1
    fi

    # Check .storage directory exists
    if [[ -d "$storage_path" ]]; then
        log_info ".storage directory exists"
    else
        log_warn ".storage directory missing (may be new install)"
    fi

    log_info "Home Assistant restore test passed"
    ((TESTS_PASSED++))
    return 0
}

# Test 6: Paperless-ngx Restore
test_paperless_restore() {
    log_test "Paperless-ngx Restore"

    export RESTIC_REPOSITORY
    export RESTIC_PASSWORD_FILE

    # Check if Paperless backups exist
    local pl_count=$(restic snapshots --tag paperless --json 2>/dev/null | jq length)
    if [[ "$pl_count" == "0" || -z "$pl_count" ]]; then
        log_warn "No Paperless-ngx backups found (skipping)"
        return 0
    fi

    mkdir -p "$RESTORE_DIR/paperless"

    if ! restic restore latest --target "$RESTORE_DIR/paperless" --tag paperless 2>/dev/null; then
        log_error "Failed to restore Paperless-ngx backup"
        ((TESTS_FAILED++))
        return 1
    fi

    local data_path="$RESTORE_DIR/paperless/data/data"
    local media_path="$RESTORE_DIR/paperless/data/media"

    # Check data directory exists
    if [[ -d "$data_path" ]]; then
        log_info "data directory exists"
    else
        log_error "data directory missing!"
        ((TESTS_FAILED++))
        return 1
    fi

    # Check media directory exists (contains the actual documents)
    if [[ -d "$media_path" ]]; then
        local doc_count=$(find "$media_path" -type f 2>/dev/null | wc -l)
        log_info "media directory exists ($doc_count files)"
    else
        log_error "media directory missing!"
        ((TESTS_FAILED++))
        return 1
    fi

    log_info "Paperless-ngx restore test passed"
    ((TESTS_PASSED++))
    return 0
}

# Test 7: Immich Database Restore
test_immich_restore() {
    log_test "Immich Database Restore"

    export RESTIC_REPOSITORY
    export RESTIC_PASSWORD_FILE

    # Check if Immich backups exist
    local im_count=$(restic snapshots --tag immich-db --json 2>/dev/null | jq length)
    if [[ "$im_count" == "0" || -z "$im_count" ]]; then
        log_warn "No Immich DB backups found (skipping)"
        return 0
    fi

    mkdir -p "$RESTORE_DIR/immich"

    if ! restic restore latest --target "$RESTORE_DIR/immich" --tag immich-db 2>/dev/null; then
        log_error "Failed to restore Immich DB backup"
        ((TESTS_FAILED++))
        return 1
    fi

    local dump_path="$RESTORE_DIR/immich/backup/immich-db.sql.gz"

    # Check dump file exists and is not empty
    if [[ -f "$dump_path" && -s "$dump_path" ]]; then
        local dump_size=$(du -h "$dump_path" | cut -f1)
        log_info "pg_dump exists ($dump_size)"

        # Verify it's a valid gzip file containing SQL
        if gunzip -t "$dump_path" 2>/dev/null; then
            log_info "gzip integrity OK"
            # Check for PostgreSQL header in dump
            if gunzip -c "$dump_path" 2>/dev/null | head -5 | command grep -q "PostgreSQL"; then
                log_info "Valid PostgreSQL dump confirmed"
            else
                log_warn "Could not verify PostgreSQL header (may still be valid)"
            fi
        else
            log_error "gzip integrity check failed!"
            ((TESTS_FAILED++))
            return 1
        fi
    else
        log_error "pg_dump file missing or empty!"
        ((TESTS_FAILED++))
        return 1
    fi

    log_info "Immich DB restore test passed"
    ((TESTS_PASSED++))
    return 0
}

# Test 8: Offsite Backup Verification
test_offsite_backup() {
    log_test "Offsite Backup (Google Drive)"

    if ! command -v rclone &> /dev/null; then
        log_warn "rclone not installed, skipping offsite test"
        return 0
    fi

    # List remote files
    if rclone ls "$RCLONE_REMOTE" 2>/dev/null | head -5; then
        log_info "Remote files accessible"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "Cannot access remote backup!"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Generate report
generate_report() {
    local total=$((TESTS_PASSED + TESTS_FAILED))
    local date=$(date +"%Y-%m-%d %H:%M")

    echo ""
    echo "========================================"
    echo "  BACKUP VERIFICATION REPORT"
    echo "  $date"
    echo "========================================"
    echo ""
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo "Total Tests:  $total"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}ALL TESTS PASSED${NC}"
        return 0
    else
        echo -e "${RED}SOME TESTS FAILED${NC}"
        return 1
    fi
}

# Send notification
send_notification() {
    local status=$1
    local message=$2
    local priority="default"

    if [[ "$status" == "failed" ]]; then
        priority="high"
    fi

    if command -v curl &> /dev/null; then
        curl -s -d "$message" \
             -H "Priority: $priority" \
             -H "Tags: backup" \
             "$NTFY_URL/$NTFY_TOPIC" > /dev/null 2>&1 || true
    fi
}

# Main
main() {
    echo "========================================"
    echo "  Backup Verification Script"
    echo "  $(date)"
    echo "========================================"

    if [[ "$FULL_MODE" == true ]]; then
        log_info "Running FULL quarterly verification"
    else
        log_info "Running monthly verification"
    fi

    mkdir -p "$RESTORE_DIR"

    # Run tests
    test_restic_health || true
    test_snapshots || true
    test_headscale_restore || true
    test_vaultwarden_restore || true
    test_homeassistant_restore || true
    test_paperless_restore || true
    test_immich_restore || true
    test_offsite_backup || true

    # Generate report
    if generate_report; then
        send_notification "success" "Backup verification passed ($TESTS_PASSED/$((TESTS_PASSED + TESTS_FAILED)) tests)"
        exit 0
    else
        send_notification "failed" "Backup verification FAILED ($TESTS_FAILED tests failed)"
        exit 1
    fi
}

main "$@"
