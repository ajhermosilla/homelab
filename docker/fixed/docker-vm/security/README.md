# Security Stack

Vaultwarden password manager + Frigate NVR with AI detection.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Vaultwarden | 8843 | Password manager |
| Frigate | 5000 | NVR with AI detection |
| Frigate RTSP | 8554 | Camera restreaming |
| Frigate WebRTC | 8555 | Live view |

## Quick Start

```bash
# 1. Mount NFS for Frigate recordings
sudo mkdir -p /mnt/nas/frigate
sudo mount -t nfs 192.168.1.12:/srv/frigate /mnt/nas/frigate

# 2. Generate Vaultwarden admin token
openssl rand -base64 32

# 3. Configure environment
cp .env.example .env
# Set VAULTWARDEN_ADMIN_TOKEN and camera credentials

# 4. Create frigate.yml (see template in docker-compose.yml)

# 5. Start services
docker compose up -d
```

## Vaultwarden

- Web UI: https://vault.cronova.dev (or http://192.168.1.10:8843)
- Admin panel: https://vault.cronova.dev/admin
- Disable signups after creating your account

## Frigate

### Camera Configuration

Edit `frigate.yml` with your camera streams:

```yaml
cameras:
  front_door:
    ffmpeg:
      inputs:
        - path: rtsp://{USER}:{PASS}@192.168.10.101:554/h264Preview_01_sub
          roles: [detect]
        - path: rtsp://{USER}:{PASS}@192.168.10.101:554/h264Preview_01_main
          roles: [record]
```

### Stream URLs

| Camera | Main Stream | Sub Stream |
|--------|-------------|------------|
| Reolink | `/h264Preview_01_main` | `/h264Preview_01_sub` |
| Tapo | `/stream1` | `/stream2` |

### Hardware Acceleration

Intel N150 QuickSync via VA-API:
```bash
docker exec frigate vainfo
```

### Future: Coral TPU

When adding Coral USB, update `frigate.yml`:
```yaml
detectors:
  coral:
    type: edgetpu
    device: usb
```

## Dependencies

- NFS mount must be ready for Frigate recordings
- Mosquitto (automation stack) must be running for MQTT
- Start automation stack before security stack
