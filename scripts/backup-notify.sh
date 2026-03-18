#!/bin/bash
# backup-notify.sh - Notification helper for backup jobs
# Usage: backup-notify.sh <service> <status> [message]
#
# Examples:
#   backup-notify.sh headscale success "Backup completed in 5s"
#   backup-notify.sh vaultwarden failed "Connection refused"
#   backup-notify.sh homeassistant success

set -euo pipefail

# Configuration
NTFY_URL="${NTFY_URL:-https://notify.cronova.dev}"
NTFY_TOPIC_INFO="${NTFY_TOPIC_INFO:-cronova-info}"
NTFY_TOPIC_CRITICAL="${NTFY_TOPIC_CRITICAL:-cronova-critical}"

# Arguments
SERVICE="${1:-unknown}"
STATUS="${2:-unknown}"
MESSAGE="${3:-}"

# Determine topic and priority based on status and service
get_notification_settings() {
    local service="$1"
    local status="$2"

    case "$status" in
        success|ok|completed)
            echo "$NTFY_TOPIC_INFO default backup,white_check_mark"
            ;;
        failed|error)
            case "$service" in
                headscale|vaultwarden)
                    echo "$NTFY_TOPIC_CRITICAL urgent backup,x"
                    ;;
                *)
                    echo "$NTFY_TOPIC_CRITICAL high backup,warning"
                    ;;
            esac
            ;;
        warning|warn)
            echo "$NTFY_TOPIC_INFO high backup,warning"
            ;;
        *)
            echo "$NTFY_TOPIC_INFO default backup"
            ;;
    esac
}

# Format message
format_message() {
    local service="$1"
    local status="$2"
    local custom_msg="$3"

    local timestamp=$(date +"%Y-%m-%d %H:%M")

    case "$status" in
        success|ok|completed)
            if [[ -n "$custom_msg" ]]; then
                echo "[$service] Backup completed: $custom_msg"
            else
                echo "[$service] Backup completed successfully"
            fi
            ;;
        failed|error)
            if [[ -n "$custom_msg" ]]; then
                echo "[$service] BACKUP FAILED: $custom_msg"
            else
                echo "[$service] BACKUP FAILED - check logs!"
            fi
            ;;
        warning|warn)
            if [[ -n "$custom_msg" ]]; then
                echo "[$service] Backup warning: $custom_msg"
            else
                echo "[$service] Backup completed with warnings"
            fi
            ;;
        *)
            echo "[$service] $status: $custom_msg"
            ;;
    esac
}

# Send notification
send() {
    local topic priority tags
    read -r topic priority tags <<< "$(get_notification_settings "$SERVICE" "$STATUS")"

    local message=$(format_message "$SERVICE" "$STATUS" "$MESSAGE")

    curl -s \
        -H "Priority: $priority" \
        -H "Tags: $tags" \
        -H "Title: Homelab Backup" \
        -d "$message" \
        "$NTFY_URL/$topic" > /dev/null 2>&1 || true

    echo "Notification sent: $message"
}

# Main
main() {
    if [[ "$SERVICE" == "unknown" ]]; then
        echo "Usage: backup-notify.sh <service> <status> [message]"
        echo ""
        echo "Services: headscale, vaultwarden, homeassistant, pihole, frigate, etc."
        echo "Status: success, failed, warning"
        exit 1
    fi

    send
}

main
