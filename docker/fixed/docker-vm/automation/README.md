# Automation Stack

Home Assistant + Mosquitto MQTT for smart home automation.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Home Assistant | 8123 | Home automation |
| Mosquitto | 1883 | MQTT broker |

## Integration Flow

```
Frigate → Mosquitto → Home Assistant → Notifications
           (MQTT)        (automations)    (ntfy)
```

## Quick Start

```bash
# 1. Create Mosquitto config
cat > mosquitto.conf << 'EOF'
listener 1883
allow_anonymous false
password_file /mosquitto/config/password.txt
persistence true
persistence_location /mosquitto/data/
log_dest stdout
EOF

# 2. Start services
docker compose up -d

# 3. Create MQTT users
docker exec -it mosquitto mosquitto_passwd -c /mosquitto/config/password.txt homeassistant
docker exec -it mosquitto mosquitto_passwd -b /mosquitto/config/password.txt frigate <password>
docker compose restart mosquitto
```

## Home Assistant Setup

1. Access http://192.168.0.10:8123
2. Create admin account
3. Add MQTT integration:
   - Settings → Devices & Services → Add → MQTT
   - Broker: `mosquitto` (or host IP)
   - Port: 1883
   - Username/password from step 3 above

## Frigate Integration

Add Frigate integration in Home Assistant:
- Settings → Devices & Services → Add → Frigate
- URL: http://192.168.0.10:5000

## MQTT Topics (Frigate)

| Topic | Purpose |
|-------|---------|
| `frigate/events` | Detection events |
| `frigate/<camera>/person` | Person detection |
| `frigate/stats` | System statistics |

## Dependencies

- Mosquitto starts first (Home Assistant depends on it)
- Frigate (security stack) connects via MQTT
