# NUT Configuration (UPS Graceful Shutdown)

Network UPS Tools configuration for graceful shutdown on power loss.

## Overview

```text
[Forza NT-1012U UPS]
        │
        │ USB
        ▼
      [NAS]
   NUT Server
        │
        │ Network
        ▼
┌───────┴───────┐
│               │
▼               ▼
[Mini PC]    [RPi 4]
NUT Client   NUT Client
```

#### Topology

- NAS connects to UPS via USB (master)
- Mini PC and RPi 4 are network clients
- All devices gracefully shutdown when battery is low

---

## NAS Configuration (NUT Server)

### Install NUT

```bash
sudo apt install nut nut-server nut-client
```

### Identify UPS

```bash
# List connected UPS devices
sudo nut-scanner -U

# Expected output (Forza usually appears as blazer_usb or nutdrv_qx)
[nutdev1]
    driver = "blazer_usb"
    port = "auto"
```

### Configure UPS Driver (`/etc/nut/ups.conf`)

```ini
[forza]
    driver = blazer_usb
    port = auto
    desc = "Forza NT-1012U 1000VA"
    vendorid = 0001
    productid = 0000
    default.battery.voltage.high = 26.0
    default.battery.voltage.low = 20.8
```

**Note:** If `blazer_usb` doesn't work, try `nutdrv_qx` driver.

### Configure NUT Mode (`/etc/nut/nut.conf`)

```ini
MODE=netserver
```

### Configure Network Access (`/etc/nut/upsd.conf`)

```ini
LISTEN 0.0.0.0 3493
LISTEN :: 3493
```

### Configure Users (`/etc/nut/upsd.users`)

```ini
[admin]
    password = your-secure-password
    actions = SET
    instcmds = ALL

[upsmon]
    password = monitor-password
    upsmon master

[upsmon_slave]
    password = slave-password
    upsmon slave
```

### Configure UPS Monitor (`/etc/nut/upsmon.conf`)

```ini
MONITOR forza@localhost 1 upsmon monitor-password master
MINSUPPLIES 1
SHUTDOWNCMD "/sbin/shutdown -h +0"
POLLFREQ 5
POLLFREQALERT 5
HOSTSYNC 15
DEADTIME 15
POWERDOWNFLAG /etc/killpower

# Notifications
NOTIFYCMD /usr/sbin/upssched
NOTIFYFLAG ONLINE     SYSLOG+WALL+EXEC
NOTIFYFLAG ONBATT     SYSLOG+WALL+EXEC
NOTIFYFLAG LOWBATT    SYSLOG+WALL+EXEC
NOTIFYFLAG FSD        SYSLOG+WALL+EXEC
NOTIFYFLAG SHUTDOWN   SYSLOG+WALL+EXEC
```

### Start Services

```bash
sudo systemctl enable nut-server nut-client
sudo systemctl start nut-server nut-client

# Verify
upsc forza@localhost
```

---

## Mini PC Configuration (NUT Client)

### Install NUT Client

```bash
# On Proxmox host
apt install nut-client
```

### Configure NUT Mode (`/etc/nut/nut.conf`)

```ini
MODE=netclient
```

### Configure UPS Monitor (`/etc/nut/upsmon.conf`)

```ini
MONITOR forza@192.168.0.12 1 upsmon_slave slave-password slave
MINSUPPLIES 1
SHUTDOWNCMD "/sbin/shutdown -h +0"
POLLFREQ 5
POLLFREQALERT 5
DEADTIME 25

NOTIFYFLAG ONLINE     SYSLOG+WALL
NOTIFYFLAG ONBATT     SYSLOG+WALL
NOTIFYFLAG LOWBATT    SYSLOG+WALL
NOTIFYFLAG FSD        SYSLOG+WALL
NOTIFYFLAG SHUTDOWN   SYSLOG+WALL
```

### Start Service

```bash
systemctl enable nut-client
systemctl start nut-client

# Verify connection
upsc forza@192.168.0.12
```

---

## RPi 4 Configuration (NUT Client)

Start9 uses a custom OS, so NUT configuration may differ.

### Option 1: SSH-based Shutdown

If Start9 doesn't support NUT natively, configure NAS to SSH shutdown:

Add to NAS `/etc/nut/upssched.conf`:

```ini
CMDSCRIPT /usr/local/bin/nut-notify.sh
AT LOWBATT * START-TIMER shutdown-rpi4 30
```

Create `/usr/local/bin/nut-notify.sh`:

```bash
#!/bin/bash
case $NOTIFYTYPE in
    LOWBATT)
        # Shutdown Start9 via SSH
        ssh root@192.168.0.11 "shutdown -h now"
        ;;
esac
```

### Option 2: Standard NUT (if Start9 supports)

Same as Mini PC configuration, pointing to NAS.

---

## Shutdown Sequence

When power fails:

1. **ONBATT** - UPS switches to battery
   - Log event, send notification

1. **LOWBATT** - Battery reaches threshold (~20%)
   - Start shutdown timer (60 seconds)
   - Notify all clients

1. **FSD** (Forced Shutdown) - Master initiates shutdown
   - Clients receive FSD and begin shutdown
   - Order: RPi 4 → Mini PC → NAS (master last)

1. **POWEROFF** - NAS sends UPS kill command
   - UPS powers off after delay

---

## Notification Script

Create `/usr/local/bin/nut-notify.sh` on NAS:

```bash
#!/bin/bash
# NUT notification script

NTFY_URL="https://notify.cronova.dev/cronova-critical"

case $NOTIFYTYPE in
    ONLINE)
        MSG="UPS is back on line power"
        ;;
    ONBATT)
        MSG="UPS is on battery - check power"
        ;;
    LOWBATT)
        MSG="UPS battery is LOW - shutdown imminent"
        ;;
    FSD)
        MSG="UPS forced shutdown in progress"
        ;;
    SHUTDOWN)
        MSG="System is shutting down"
        ;;
    *)
        MSG="UPS event: $NOTIFYTYPE"
        ;;
esac

# Send to ntfy
curl -d "$MSG" "$NTFY_URL" 2>/dev/null

# Log
logger -t nut-notify "$MSG"
```

Make executable:

```bash
chmod +x /usr/local/bin/nut-notify.sh
```

---

## Testing

### Test UPS Communication

```bash
# On NAS
upsc forza@localhost

# Expected output:
# battery.charge: 100
# battery.voltage: 26.00
# device.type: ups
# input.voltage: 220.0
# output.voltage: 220.0
# ups.load: 15
# ups.status: OL
```

### Test Client Connection

```bash
# On Mini PC
upsc forza@192.168.0.12
```

### Simulate Power Failure (CAREFUL!)

```bash
# On NAS - Force shutdown test
sudo upsmon -c fsd

# This will initiate shutdown sequence!
# Only test when prepared for actual shutdown
```

### Test Notifications

```bash
# Manually trigger notification
NOTIFYTYPE=ONBATT /usr/local/bin/nut-notify.sh
```

---

## Monitoring

### Add to Uptime Kuma

- **TCP Check:** `192.168.0.12:3493` (NUT server)
- **Alert:** If NUT server is down, UPS monitoring is offline

### Prometheus Metrics (Optional)

Use [nut_exporter](https://github.com/DRuggeri/nut_exporter):

```bash
docker run -d --name nut-exporter \
  -e NUT_EXPORTER_SERVER=192.168.0.12 \
  -p 9199:9199 \
  druggeri/nut_exporter
```

---

## Troubleshooting

### UPS Not Detected

```bash
# Check USB
lsusb | grep -i ups

# Check driver
sudo upsdrvctl start

# Try different drivers
# Edit /etc/nut/ups.conf and try: nutdrv_qx, blazer_usb, usbhid-ups
```

### Permission Issues

```bash
# Add nut user to dialout group
sudo usermod -aG dialout nut

# Check USB permissions
ls -la /dev/bus/usb/*/*
```

### Client Can't Connect

```bash
# Check firewall
sudo ufw allow 3493/tcp

# Check NUT is listening
ss -tlnp | grep 3493

# Check upsd.conf LISTEN directive
```

---

## Reference

- [NUT Documentation](https://networkupstools.org/docs/user-manual.chunked/index.html)
- [Hardware Compatibility List](https://networkupstools.org/stable-hcl.html)
- [Forza UPS](https://www.forzaups.com/) (may require blazer_usb driver)

---

## Forza NT-1012U Specs

| Spec | Value |
|------|-------|

| Capacity | 1000VA / 500W |
| Input Voltage | 220V |
| Battery | 12V 7Ah x2 |
| Runtime (180W load) | ~15-20 min |
| Interface | USB |
| Driver | blazer_usb or nutdrv_qx |
