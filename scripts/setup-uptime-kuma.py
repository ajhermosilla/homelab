#!/usr/bin/env python3
"""
Bulk-create Uptime Kuma monitors and ntfy notifications.

Requires: pip install uptime-kuma-api

Usage:
    python3 scripts/setup-uptime-kuma.py [--dry-run] [--list]

Environment variables (or prompted interactively):
    KUMA_URL       - Uptime Kuma URL (default: https://status.cronova.dev)
    KUMA_USERNAME  - Username
    KUMA_PASSWORD  - Password
    NTFY_USERNAME  - ntfy username (for notification setup)
    NTFY_PASSWORD  - ntfy password
"""

import argparse
import os
import sys
from getpass import getpass

try:
    from uptime_kuma_api import UptimeKumaApi, MonitorType, NotificationType
except ImportError:
    print("Error: uptime-kuma-api not installed.")
    print("Install it: pip install uptime-kuma-api")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Notification definitions (ntfy topics)
# ---------------------------------------------------------------------------
NOTIFICATIONS = [
    {
        "name": "Critical (ntfy)",
        "type": NotificationType.NTFY,
        "ntfyserverurl": "https://notify.cronova.dev",
        "ntfytopic": "cronova-critical",
        "ntfyPriority": 5,
        "ntfyIcon": "https://cronova.dev/favicon.ico",
        "ntfyAuthenticationMethod": "usernamePassword",
        "isDefault": False,
        "applyExisting": False,
    },
    {
        "name": "Warning (ntfy)",
        "type": NotificationType.NTFY,
        "ntfyserverurl": "https://notify.cronova.dev",
        "ntfytopic": "cronova-warning",
        "ntfyPriority": 4,
        "ntfyIcon": "https://cronova.dev/favicon.ico",
        "ntfyAuthenticationMethod": "usernamePassword",
        "isDefault": False,
        "applyExisting": False,
    },
    {
        "name": "Info (ntfy)",
        "type": NotificationType.NTFY,
        "ntfyserverurl": "https://notify.cronova.dev",
        "ntfytopic": "cronova-info",
        "ntfyPriority": 3,
        "ntfyIcon": "https://cronova.dev/favicon.ico",
        "ntfyAuthenticationMethod": "usernamePassword",
        "isDefault": False,
        "applyExisting": False,
    },
]

# ---------------------------------------------------------------------------
# Monitor definitions — grouped by tier
# ---------------------------------------------------------------------------
# notification_tier: "critical" | "warning" | "info"
MONITORS = [
    # =========================================================================
    # CRITICAL — 60s interval, ntfy critical priority
    # Core infrastructure: if these go down, everything is affected.
    # =========================================================================
    {
        "type": MonitorType.HTTP,
        "name": "Headscale",
        "url": "https://hs.cronova.dev/health",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Vaultwarden",
        "url": "https://vault.cronova.dev/alive",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.PORT,
        "name": "Pi-hole DNS",
        "hostname": "100.68.63.168",
        "port": 53,
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Caddy (Docker VM)",
        "url": "https://cronova.dev",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.PING,
        "name": "OPNsense Gateway",
        "hostname": "192.168.0.1",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Uptime Kuma",
        "url": "https://status.cronova.dev",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.HTTP,
        "name": "ntfy",
        "url": "https://notify.cronova.dev",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.PORT,
        "name": "Caddy (VPS)",
        "hostname": "100.77.172.46",
        "port": 443,
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.PORT,
        "name": "VPS Pi-hole",
        "hostname": "127.0.0.1",
        "port": 53,
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "critical",
    },
    # =========================================================================
    # WARNING — 60-300s interval, ntfy high priority
    # Important services: security, automation, backups.
    # =========================================================================
    {
        "type": MonitorType.HTTP,
        "name": "Home Assistant (Jara)",
        "url": "https://jara.cronova.dev",
        "interval": 300,
        "maxretries": 2,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Frigate (Taguato)",
        "url": "https://taguato.cronova.dev/api/version",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Forgejo",
        "url": "http://100.82.77.97:3000",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.PORT,
        "name": "NAS Samba",
        "hostname": "100.82.77.97",
        "port": 445,
        "interval": 300,
        "maxretries": 2,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.KEYWORD,
        "name": "Restic REST",
        "url": "http://100.82.77.97:8000",
        "keyword": "Unauthorized",
        "accepted_statuscodes": ["401"],
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Coolify (Tajy)",
        "url": "https://tajy.cronova.dev",
        "interval": 300,
        "maxretries": 2,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Authelia (Oke)",
        "url": "https://auth.cronova.dev",
        "interval": 300,
        "maxretries": 2,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Javya",
        "url": "https://javya.cronova.dev",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Javya API",
        "url": "https://javya-api.cronova.dev/health",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.PING,
        "name": "NAS",
        "hostname": "100.82.77.97",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.PING,
        "name": "Docker VM",
        "hostname": "100.68.63.168",
        "interval": 300,
        "maxretries": 3,
        "notification_tier": "warning",
    },
    {
        "type": MonitorType.PING,
        "name": "Watchtower",
        "hostname": "100.68.63.168",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "warning",
    },
    # =========================================================================
    # INFO — 300-900s interval, ntfy normal priority
    # Standard services and external sites.
    # =========================================================================
    {
        "type": MonitorType.HTTP,
        "name": "Jellyfin (Yrasema)",
        "url": "https://yrasema.cronova.dev/health",
        "interval": 300,
        "maxretries": 2,
        "notification_tier": "info",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Grafana (Papa)",
        "url": "https://papa.cronova.dev",
        "interval": 300,
        "maxretries": 2,
        "notification_tier": "info",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Immich (Vera)",
        "url": "https://vera.cronova.dev",
        "interval": 300,
        "maxretries": 2,
        "notification_tier": "info",
    },
    {
        "type": MonitorType.HTTP,
        "name": "Syncthing",
        "url": "http://100.82.77.97:8384/rest/noauth/health",
        "interval": 300,
        "maxretries": 2,
        "notification_tier": "info",
    },
    {
        "type": MonitorType.KEYWORD,
        "name": "Glances",
        "url": "http://100.82.77.97:61208/api/4/cpu",
        "keyword": "total",
        "interval": 60,
        "maxretries": 3,
        "notification_tier": "info",
    },
    {
        "type": MonitorType.PORT,
        "name": "Pi-hole Fixed",
        "hostname": "100.68.63.168",
        "port": 53,
        "interval": 300,
        "maxretries": 3,
        "notification_tier": "info",
    },
    {
        "type": MonitorType.DNS,
        "name": "DNS - cronova.dev",
        "hostname": "cronova.dev",
        "port": 53,
        "dns_resolve_server": "1.1.1.1",
        "interval": 300,
        "maxretries": 3,
        "notification_tier": "info",
    },
    # === Mobile Kit (may be offline when not traveling) ===
    {
        "type": MonitorType.PING,
        "name": "Beryl AX",
        "hostname": "100.102.244.131",
        "interval": 120,
        "maxretries": 3,
        "notification_tier": "info",
    },
    {
        "type": MonitorType.PORT,
        "name": "Beryl AX - Admin",
        "hostname": "100.102.244.131",
        "port": 80,
        "interval": 120,
        "maxretries": 3,
        "notification_tier": "info",
    },
    # === External (15m interval) ===
    {
        "type": MonitorType.HTTP,
        "name": "cronova.dev",
        "url": "https://cronova.dev",
        "interval": 900,
        "maxretries": 2,
        "notification_tier": "critical",
    },
    {
        "type": MonitorType.HTTP,
        "name": "hermosilla.me",
        "url": "https://hermosilla.me/",
        "interval": 900,
        "maxretries": 3,
        "notification_tier": "info",
    },
    {
        "type": MonitorType.HTTP,
        "name": "verava.ai",
        "url": "https://verava.ai",
        "interval": 900,
        "maxretries": 2,
        "notification_tier": "info",
    },
]


def get_env_or_prompt(var, prompt_text, secret=False):
    val = os.environ.get(var)
    if val:
        return val
    if secret:
        return getpass(prompt_text)
    return input(prompt_text)


def list_monitors(api):
    monitors = api.get_monitors()
    if not monitors:
        print("No monitors configured.")
        return
    print(f"{'ID':>4}  {'Name':<30}  {'Type':<6}  {'Interval':>8}  {'URL/Host'}")
    print("-" * 90)
    for m in sorted(monitors, key=lambda x: x["id"]):
        target = m.get("url") or m.get("hostname", "")
        if m.get("port"):
            target += f":{m['port']}"
        mtype = m.get("type", "")
        print(f"{m['id']:>4}  {m['name']:<30}  {mtype:<6}  {m['interval']:>6}s  {target}")


def setup_notifications(api, ntfy_user, ntfy_pass, dry_run=False):
    existing = api.get_notifications()
    existing_names = {n["name"] for n in existing}

    notification_ids = {}
    for notif in NOTIFICATIONS:
        if notif["name"] in existing_names:
            nid = next(n["id"] for n in existing if n["name"] == notif["name"])
            print(f"  [skip] Notification '{notif['name']}' already exists (id={nid})")
            notification_ids[notif["name"]] = nid
            continue

        if dry_run:
            print(f"  [dry-run] Would create notification: {notif['name']}")
            notification_ids[notif["name"]] = -1
            continue

        params = {**notif, "ntfyusername": ntfy_user, "ntfypassword": ntfy_pass}
        result = api.add_notification(**params)
        nid = result.get("id")
        print(f"  [created] {notif['name']} (id={nid})")
        notification_ids[notif["name"]] = nid

    return notification_ids


def tier_to_notification_name(tier):
    return {"critical": "Critical (ntfy)", "warning": "Warning (ntfy)", "info": "Info (ntfy)"}[tier]


def setup_monitors(api, notification_ids, dry_run=False):
    existing = api.get_monitors()
    existing_names = {m["name"] for m in existing}

    created = 0
    skipped = 0
    for mon in MONITORS:
        if mon["name"] in existing_names:
            print(f"  [skip] {mon['name']} already exists")
            skipped += 1
            continue

        params = {k: v for k, v in mon.items() if k != "notification_tier"}
        tier = mon["notification_tier"]
        notif_name = tier_to_notification_name(tier)
        nid = notification_ids.get(notif_name)
        if nid and nid > 0:
            params["notificationIDList"] = [nid]

        if dry_run:
            target = params.get("url") or params.get("hostname", "")
            print(f"  [dry-run] Would create: {mon['name']} → {target} ({params['interval']}s)")
            continue

        result = api.add_monitor(**params)
        mid = result.get("monitorID")
        print(f"  [created] {mon['name']} (id={mid})")
        created += 1

    return created, skipped


def main():
    parser = argparse.ArgumentParser(description="Setup Uptime Kuma monitors")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be created")
    parser.add_argument("--list", action="store_true", help="List existing monitors and exit")
    args = parser.parse_args()

    kuma_url = get_env_or_prompt("KUMA_URL", "Uptime Kuma URL [https://status.cronova.dev]: ") or "https://status.cronova.dev"
    kuma_user = get_env_or_prompt("KUMA_USERNAME", "Uptime Kuma username: ")
    kuma_pass = get_env_or_prompt("KUMA_PASSWORD", "Uptime Kuma password: ", secret=True)

    print(f"\nConnecting to {kuma_url}...")
    api = UptimeKumaApi(kuma_url)
    api.login(kuma_user, kuma_pass)
    print("Logged in.\n")

    if args.list:
        list_monitors(api)
        api.disconnect()
        return

    # Step 1: Notifications
    print("=== Setting up ntfy notifications ===")
    ntfy_user = get_env_or_prompt("NTFY_USERNAME", "ntfy username: ")
    ntfy_pass = get_env_or_prompt("NTFY_PASSWORD", "ntfy password: ", secret=True)
    notification_ids = setup_notifications(api, ntfy_user, ntfy_pass, dry_run=args.dry_run)

    # Step 2: Monitors
    print(f"\n=== Setting up {len(MONITORS)} monitors ===")
    created, skipped = setup_monitors(api, notification_ids, dry_run=args.dry_run)

    print(f"\nDone! Created {created}, skipped {skipped} (already existed).")

    if args.dry_run:
        print("\n(Dry run — no changes were made. Run without --dry-run to apply.)")

    api.disconnect()


if __name__ == "__main__":
    main()
