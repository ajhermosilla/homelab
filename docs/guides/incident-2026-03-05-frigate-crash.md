# Incident Report: Frigate NVR Crash — VA-API Surface Sync Failure

**Date**: 2026-03-05 (discovered), 2026-03-03 ~15:26 PYT (actual crash)
**Duration**: ~38 hours unnoticed
**Severity**: Medium — NVR offline, no security camera recording
**Service**: Frigate v0.16.4 on Docker VM (VM 101)

---

## Summary

Frigate exited with code 128 after a sustained VA-API hardware decode failure loop. Over ~30 hours (March 2–3), the ffmpeg watchdog restarted ffmpeg processes **14,893 times** (~360/hour) due to `Failed to sync surface` errors on the Intel N150 iGPU. The crash loop eventually exhausted resources, causing the Frigate supervisor to exit. The container did not auto-restart despite `restart: unless-stopped`.

The root cause is a **driver version mismatch**: the Frigate container bundles `intel-media-va-driver-non-free` v24.3.3, which does not properly support the Intel N150 (Alder Lake-N, PCI device 46D4). The host has v25.2.3 installed, but Docker containers use their own bundled drivers.

---

## Timeline (PYT, UTC-3)

| Time | Event |
|------|-------|
| Mar 2, 10:06 | First `Failed to sync surface` error appears (both cameras) |
| Mar 2, 09:30 | Indoor camera (Tapo) already unreachable ("No route to host") — separate issue |
| Mar 2–3 | Continuous crash loop: ffmpeg crashes → watchdog restarts → crashes again (~6/min per camera) |
| Mar 3, 15:26 | Last log entry — Frigate supervisor exits with code 128 |
| Mar 3, 15:26 | Container status: `Exited (128)`, does NOT restart |
| Mar 5, 11:24 | Discovered during troubleshooting. Manual `docker compose up -d` restarts Frigate |
| Mar 5, 11:25 | Frigate healthy, cameras reconnected, VA-API errors resume at low rate (~1 every 3 min) |

---

## Root Causes

### 1. Intel VA-API Driver Too Old Inside Container (Primary)

**The Frigate container image (v0.16.4, built 2026-01-28) bundles `intel-media-va-driver-non-free` v24.3.3.** The Intel N150 (Alder Lake-N, device ID `8086:46D4`) requires v25.1+ for reliable VA-API surface sync. Older versions can initialize the GPU but fail intermittently under sustained decode workload.

The error signature:
```
[AVHWFramesContext] Failed to sync surface 0xe: 1 (operation failed)
[hwdownload] Failed to download frame: -5
[vf#0:0] Error while filtering: Input/output error
```

This means the VA-API driver tried to synchronize a decoded video frame from GPU memory back to CPU-accessible memory, but the GPU returned a busy/error status. The N150's device ID (46D4) is distinct from the N100 (46D3) and was added to the driver later.

**Evidence**: The host has `intel-media-va-driver` v25.2.3 and kernel 6.12.63 — both sufficient. But the Frigate container ignores the host driver and uses its own v24.3.3.

### 2. Dual iGPU Contention (Amplifying Factor)

The configuration uses the N150 iGPU for **both** tasks simultaneously:
- **VA-API** for hardware video decoding (`ffmpeg.hwaccel_args: preset-vaapi`)
- **OpenVINO GPU** for object detection (`detectors.ov.device: GPU`)

Both compete for the same 24 execution units on the N150. Under sustained load, the surface sync queue backs up, causing the decode pipeline to fail while inference is running.

### 3. Crash Loop → Resource Exhaustion (Cascade)

Each ffmpeg crash-and-restart cycle:
- Leaves behind "inactive_anon" memory pages that the kernel must reclaim
- Opens new file descriptors for `/dev/dri/renderD128`, RTSP sockets, IPC pipes
- Allocates new VA-API surface pools

At 360 restarts/hour over 30 hours (14,893 total), this overwhelmed the container's resources:
- **Memory**: 4GB limit was borderline even without crash loops. OpenVINO GPU mode uses ~500MB–1GB, face recognition adds ~200–400MB, leaving little headroom for ffmpeg churn
- **VA-API surface pool**: DRM handle pool on the kernel side has limited concurrent open handles
- **Shared memory**: 256MB SHM was adequate but under pressure

### 4. `restart: unless-stopped` Did Not Restart

Exit code 128 is a **supervisor-controlled exit** (not OOM kill, which would be 137). Docker's restart policy requires the container to run for >10 seconds before it enters the restart-eligible state. If Frigate's supervisor exited quickly after detecting an unrecoverable GPU state, Docker may have classified this as a startup failure rather than a running container crash.

Confirmed: `docker inspect frigate --format '{{.State.OOMKilled}}'` = `false`.

### 5. Indoor Camera Offline (Separate Issue)

The Tapo C110 (192.168.0.101) has been returning "No route to host" since at least Feb 28. This causes continuous ffmpeg restart loops for the `indoor` camera stream independent of the VA-API issue. The camera is on WiFi and may have disconnected or changed IP.

**Current status**: Camera is pingable as of Mar 5 — may have been a temporary WiFi dropout.

---

## Impact

- **38 hours without NVR recording** — no camera footage from Mar 3 15:26 to Mar 5 11:24
- **No alert** — Uptime Kuma monitors the Frigate web UI (HTTP 200), which still responded during the crash loop. The container crash at 15:26 was not detected because Uptime Kuma only checks every 60 seconds and the container was already dead
- **VA-API errors continue** after restart at ~1 every 3 minutes — the underlying driver issue is not resolved

---

## Actions Taken

| # | Action | Status |
|---|--------|--------|
| 1 | Restarted Frigate: `docker compose up -d frigate` | Done |
| 2 | Verified all 3 cameras reachable (ping) | Done |
| 3 | Verified VA-API loads (`vainfo` shows iHD 24.3.3) | Done |
| 4 | Verified NFS mount healthy (91% of 1.8TB used) | Done |
| 5 | Confirmed `OOMKilled: false` | Done |
| 6 | Identified driver version mismatch (container v24.3.3 vs host v25.2.3) | Done |

---

## Fixes

### Fix 1: Increase Memory Limit (Immediate)

Raise from 4GB to 6GB to provide headroom for crash loop recovery and OpenVINO + face recognition.

```yaml
# docker-compose.yml — frigate service
deploy:
  resources:
    limits:
      memory: 6G  # was 4G
```

### Fix 2: Switch from VA-API to QSV Preset (Immediate)

Intel QSV uses a different internal path than VA-API and is more reliable on the N150 with the bundled driver version. Community-confirmed fix for `Failed to sync surface`.

```yaml
# frigate.yml
ffmpeg:
  hwaccel_args: preset-intel-qsv-h264  # was preset-vaapi
```

**Tradeoff**: QSV may use slightly more CPU for format conversion, but eliminates the surface sync failures entirely.

**Alternative**: Wait for Frigate to update the bundled `intel-media-va-driver-non-free` to v25.1+ in a future release, which fixes VA-API on N150 natively.

### Fix 3: Add Docker Healthcheck That Catches Exit State (Short Term)

The current healthcheck (`curl -f http://localhost:5000/api/version`) only checks the web UI. A more robust check should also verify ffmpeg processes are running:

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -sf http://localhost:5000/api/version && curl -sf http://localhost:5000/api/stats | python3 -c 'import sys,json; d=json.load(sys.stdin); [exit(1) for c in d.get(\"cameras\",{}).values() if c.get(\"camera_fps\",0)==0]'"]
  interval: 60s
  timeout: 10s
  retries: 3
  start_period: 60s
```

This fails the healthcheck if any camera has 0 fps, which triggers Uptime Kuma alerts.

### Fix 4: Kernel Memory Reclaim Tuning (Short Term)

Add to Docker VM `/etc/sysctl.conf` to make the kernel reclaim memory more aggressively during ffmpeg churn:

```bash
# Aggressive memory reclaim for video processing workloads
vm.watermark_scale_factor = 500
```

Apply: `sudo sysctl -p`

### Fix 5: Separate OpenVINO from VA-API (Medium Term)

Move object detection to CPU, keeping VA-API/QSV only for decode. This eliminates iGPU contention:

```yaml
# frigate.yml
detectors:
  ov:
    type: openvino
    device: CPU  # was GPU
```

**Tradeoff**: Inference time increases from ~15ms (GPU) to ~100ms (CPU), but at 5fps detect rate this is still well within budget (200ms per frame). Only consider this if Fix 2 (QSV) doesn't fully resolve the issue.

### Fix 6: Monitor Frigate Container State (Short Term)

Add Uptime Kuma "Docker Container" monitor (if supported) or a script-based check:

```bash
# Cron on Docker VM — every 5 minutes
*/5 * * * * docker inspect frigate --format '{{.State.Status}}' | grep -q running || \
  curl -s "https://ntfy.cronova.dev/homelab-alerts" -d "Frigate is DOWN ($(docker inspect frigate --format '{{.State.Status}}'))"
```

---

## Recommended Fix Order

1. **Fix 1** (memory 4G→6G) + **Fix 2** (VA-API→QSV) — apply together, restart Frigate
2. **Fix 4** (sysctl tuning) — apply on Docker VM host
3. **Fix 6** (monitoring) — add ntfy alert for container state
4. **Fix 3** (healthcheck) — update compose file
5. **Fix 5** (CPU detection) — only if QSV doesn't resolve surface sync errors

---

## Diagnostic Data

| Metric | Value |
|--------|-------|
| Frigate version | 0.16.4 (image built 2026-01-28) |
| Container driver | intel-media-va-driver-non-free 24.3.3 |
| Host driver | intel-media-va-driver 25.2.3 |
| Host kernel | 6.12.63+deb13-amd64 |
| iGPU | Intel N150 (Alder Lake-N, 24 EU, device 46D4) |
| VA-API surface sync failures | 904 logged |
| ffmpeg restarts | 14,893 in ~30 hours |
| Memory limit | 4GB (47% used at steady state) |
| SHM size | 256MB |
| Cameras | 3 (2x Reolink PoE + 1x Tapo WiFi) |
| NFS storage | 91% of 1.8TB used |
| Exit code | 128 (supervisor exit, not OOM) |
| OOMKilled | false |
| Restart policy | unless-stopped (did not trigger) |

---

## References

- [Frigate Discussion #17441 — VAAPI Failing on Intel N150](https://github.com/blakeblackshear/frigate/discussions/17441)
- [Frigate Discussion #16503 — N150 requires intel-media-va-driver-non-free v25.1](https://github.com/blakeblackshear/frigate/discussions/16503)
- [Intel media-driver issue #1902 — VAAPI resource allocation failure N150](https://github.com/intel/media-driver/issues/1902)
- [Frigate Discussion #14571 — ffmpeg crashing causing OOM kills](https://github.com/blakeblackshear/frigate/discussions/14571)
- [Frigate Issue #8461 — Memory usage with OpenVINO](https://github.com/blakeblackshear/frigate/issues/8461)
- `docs/plans/frigate-improvement-plan-2026-03-02.md` — Phase 1/2 improvement plan
- `docs/guides/incident-2026-03-05-isp-outage.md` — ISP outage (same day, separate issue)
