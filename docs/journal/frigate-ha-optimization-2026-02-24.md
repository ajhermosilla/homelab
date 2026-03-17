# Frigate + Home Assistant Optimization Report

**Date:** 2026-02-24
**Context:** Frigate 0.16.4 on Docker VM (Proxmox VM 101, Intel N150), 3 cameras, Home Assistant with MQTT integration, ntfy notifications.

---

## Part 1: Reducing Notification Noise

### Problem

Current automations trigger on every person detection across the full camera frame. Family members entering/exiting home generate constant notifications. Goal: alert for unknown persons and security events, suppress known family activity.

### Strategy 1: Frigate Zones + `required_zones` (Highest Impact)

Zones restrict where in the camera frame a detection must occur before triggering an event. Key settings:

- **`inertia: 3`** -- object must be in zone for 3 consecutive frames (filters bounding box jitter)
- **`loitering_time: 4`** -- object must stay 4+ seconds (filters passersby on the street)
- **`required_zones`** on `review.alerts` -- Frigate only creates reviewable events for those zones

Example for front_door camera:

```yaml
cameras:
  front_door:
    zones:
      porch:
        coordinates: 0.2,0.6,0.8,0.6,0.8,1.0,0.2,1.0
        objects:
          - person
        inertia: 3
        loitering_time: 4
      driveway:
        coordinates: ...
        objects:
          - person
          - car
    review:
      alerts:
        labels:
          - person
        required_zones:
          - porch
      detections:
        labels:
          - person
          - car
        required_zones:
          - driveway
```

Zone coordinates are defined via Frigate's web UI zone editor. The bottom center of the bounding box determines zone presence.

### Strategy 2: Frigate Native Face Recognition (Built into 0.16+)

Frigate 0.16 added built-in face recognition. When a person is detected, Frigate runs face detection on the person crop and assigns a `sub_label` (e.g., "augusto") if the face matches a trained individual. No external tools needed.

Configuration:

```yaml
face_recognition:
  enabled: true
  model_size: small          # "small" for CPU, "large" for GPU
  detection_threshold: 0.7
  recognition_threshold: 0.9
  unknown_score: 0.8
  min_faces: 1
  min_area: 500
  save_attempts: 100
  blur_confidence_filter: true
```

Training:

- Start with 10-30 front-facing photos per person via Frigate's "Train" tab
- Build to 50-100 for optimal accuracy
- Avoid hats, sunglasses, extreme angles, IR images
- Face database lives at `/media/frigate/clips/faces`

Sub-labels in MQTT events: `"sub_label": ["augusto", 0.92]`

Automation filtering:

```yaml
# Only notify for UNKNOWN persons
condition:
  - condition: template
    value_template: >-
      {{ trigger.payload_json["after"]["sub_label"] is none or
         trigger.payload_json["after"]["sub_label"][0] not in
         ["augusto", "andre"] }}
```

**Timing gotcha:** Face recognition takes a few seconds after initial person detection. The first MQTT event will have `sub_label: null`. Sub-labels arrive in subsequent `update` events. Automations should use a repeat-wait loop or process `update` events.

### Strategy 3: SgtBatten Blueprint (Community Gold Standard)

The [SgtBatten Frigate Camera Notifications Blueprint](https://github.com/SgtBatten/HA_blueprints) is the most widely used notification automation. It handles:

- Zone filtering with required zones
- Cooldown timer per camera (prevents spam)
- Silence/snooze timer (manual suppression)
- Presence-based suppression (disable when family is home)
- Time-based restrictions (different behavior day vs night)
- Sub-label support (recognized face name in notification)
- Rich media (thumbnails, snapshots, GIFs, video clips with bounding boxes)
- Actionable notification buttons (snooze, view clip, dismiss)
- Multi-device support (Android, iOS)

Install via HACS or import from the GitHub repo. Creates one automation per camera.

### Strategy 4: Presence-Based Suppression

Use HA Companion App (phone GPS) to track `person.augusto` and `person.andre`. Suppress outdoor camera notifications when family is home.

```yaml
# Suppress when anyone is home
condition:
  - condition: state
    entity_id: group.family
    state: "not_home"
```

Key: suppress **notifications** only, not recordings. Recordings should always run for security.

Frigate also exposes MQTT topics for per-camera notification control:

- `frigate/<camera>/notifications/set` -- ON/OFF
- `frigate/<camera>/notifications/suspend` -- minutes to suspend

### Strategy 5: Time-Based Rules

```yaml
# Sun-based (better than fixed times)
condition:
  - condition: sun
    after: sunset
    after_offset: "-01:00:00"
    before: sunrise
    before_offset: "00:30:00"
```

Community patterns:

- **Night:** Notify on ALL person detections, use critical/high-priority alerts that break through DND
- **Day:** Only notify for persons in required zones (porch, front door)
- **Away:** All cameras, all zones, all alerts regardless of time

### Strategy 6: Cooldown / Rate Limiting

Manual cooldown via `last_triggered`:

```yaml
condition:
  - condition: template
    value_template: >-
      {{ not state_attr('automation.frigate_front_door', 'last_triggered') or
         (now() - state_attr('automation.frigate_front_door', 'last_triggered') >
         timedelta(minutes=3)) }}
```

The SgtBatten blueprint has this built-in with a configurable cooldown parameter.

### What NOT to Use

| Tool | Status | Recommendation |
|------|--------|----------------|

| Double-Take (original) | Last commit Feb 2024, abandoned | Skip |
| Double-Take (skrashevich fork) | Community fork, somewhat active | Only if native doesn't work |
| CompreFace | HA add-on broken after Core 2025 | Avoid |
| DeepStack | No longer available | Dead |
| LLM-based filtering | Promising but unreliable per Frigate devs | Wait for Frigate 0.17 |

### Recommended Implementation Order

1. **Zones + required_zones** -- highest impact, no new software
2. **Face recognition** -- enable in frigate.yml, train family faces
3. **SgtBatten blueprint** -- replace custom YAML automations
4. **Presence suppression** -- after Companion App is installed
5. **Time-based rules** -- via blueprint or custom conditions
6. **Cooldown tuning** -- 3-5 min per camera

---

## Part 2: Hardware Acceleration (OpenVINO + VAAPI)

### Problem

Frigate reports "CPU is Slow" because it's using the default TFLite CPU detector (~100 ms inference). The Intel N150 has an integrated GPU that's sitting idle.

### Intel N150 Capabilities

| Spec | Value |
|------|-------|

| CPU | 4 E-cores (Gracemont), 3.6 GHz boost |
| iGPU | Intel UHD Graphics, 24 EUs, Xe-LP architecture |
| TDP | 6W base |
| OpenVINO | Fully supported (CPU + GPU inference) |
| VAAPI/QuickSync | Fully supported (H.264/H.265 decode) |

### Change 1: Switch to OpenVINO GPU Detector (High Impact)

The standard `ghcr.io/blakeblackshear/frigate:stable` image already includes OpenVINO and the default SSDLite MobileNet v2 model. No image change needed.

#### Current config

```yaml
detectors:
  cpu:
    type: cpu
    num_threads: 2
```

#### Recommended config

```yaml
detectors:
  ov:
    type: openvino
    device: GPU

model:
  width: 300
  height: 300
  input_tensor: nhwc
  input_pixel_format: bgr
  path: /openvino-model/ssdlite_mobilenet_v2.xml
  labelmap_path: /openvino-model/coco_91cl_bkgr.txt
```

Expected improvement:

| Config | Inference Speed |
|--------|----------------|

| CPU TFLite (current) | ~100 ms |
| OpenVINO GPU, MobileNet v2 | ~15 ms |
| OpenVINO GPU, YOLO-NAS-S | ~25-30 ms |
| Coral USB TPU (comparison) | ~10 ms |

At 15 ms inference, capacity is ~66 detections/second. With 3 cameras at 2 fps detect = 6 frames/second needed. That's 10x headroom.

**Important:** Do NOT use `device: AUTO` -- there is a known bug. Explicitly set `GPU` or `CPU`.

### Change 2: Enable VAAPI Hardware Video Decoding (High Impact)

The Docker Compose already passes `/dev/dri:/dev/dri`, but VAAPI is commented out in the Frigate config. Enabling it offloads H.264/H.265 decoding from CPU to iGPU.

#### Current config (commented out)

```yaml
# ffmpeg:
#   hwaccel_args: preset-vaapi
```

#### Recommended config

```yaml
ffmpeg:
  hwaccel_args: preset-vaapi
```

VAAPI is preferred over QSV for the N150 because it auto-detects the codec (H.264 vs H.265). QSV requires codec-specific presets per camera.

Verify after enabling:

```bash
docker exec frigate vainfo
# Should show VAProfileH264High : VAEntrypointVLD
```

### Change 3: Drop the Coral USB TPU Plan

The Google Coral USB Accelerator is discontinued and no longer recommended by Frigate. OpenVINO on the N150's iGPU matches or approaches Coral performance (~15 ms vs ~10 ms) without any additional hardware.

### GPU Resource Sharing

Both VAAPI decoding and OpenVINO inference share the N150's 24 EU iGPU. With 3 cameras at 2 fps detect, this is well within capacity. Monitor with:

```bash
docker exec frigate intel_gpu_top  # may need CAP_PERFMON
```

If running many more cameras, consider adding `CAP_PERFMON` to Docker Compose:

```yaml
cap_add:
  - CAP_PERFMON
```

### Optional: YOLO-NAS-S Model (Better Accuracy)

For improved detection accuracy (especially for small/distant objects), YOLO-NAS-S can replace MobileNet v2 at the cost of ~25-30 ms inference (still fast enough):

```yaml
detectors:
  ov:
    type: openvino
    device: GPU

model:
  width: 320
  height: 320
  input_tensor: nchw
  input_pixel_format: bgr
  model_type: yolonas
  path: /config/model_cache/yolo_nas_s.onnx
```

Requires exporting the model via Python `super_gradients` package. Consider this if MobileNet v2 produces too many false positives/negatives.

### Net Effect

With OpenVINO GPU + VAAPI enabled, the heaviest workloads (video decoding + object detection) run on the iGPU, freeing the 4 CPU cores for motion detection, recording, go2rtc, and other Docker containers on the VM.

| Workload | Before | After |
|----------|--------|-------|

| Object detection | CPU (~100 ms) | iGPU (~15 ms) |
| Video decoding | CPU (ffmpeg software) | iGPU (VAAPI hardware) |
| Motion detection | CPU | CPU (unchanged) |
| Recording/encoding | CPU | CPU (unchanged) |

---

## Summary: Priority Actions

| Priority | Action | Impact |
|----------|--------|--------|

| 1 | Enable OpenVINO GPU detector | Inference 100 ms -> 15 ms |
| 2 | Enable VAAPI hardware decoding | Major CPU reduction |
| 3 | Define zones + required_zones per camera | Biggest notification noise reduction |
| 4 | Enable face recognition, train family faces | Suppress known person alerts |
| 5 | Install SgtBatten blueprint | Rich notifications with cooldown/presence/time |
| 6 | Add Companion App for presence | Suppress alerts when home |
| 7 | Configure time-based rules | Night = full alerts, Day = zones only |

---

## References

- [Frigate Zones Documentation](https://docs.frigate.video/configuration/zones/)
- [Frigate Face Recognition](https://docs.frigate.video/configuration/face_recognition/)
- [Frigate Object Detectors](https://docs.frigate.video/configuration/object_detectors/)
- [Frigate Hardware Acceleration](https://docs.frigate.video/configuration/hardware_acceleration_video/)
- [Frigate Recommended Hardware](https://docs.frigate.video/frigate/hardware/)
- [SgtBatten Frigate Notifications Blueprint](https://github.com/SgtBatten/HA_blueprints)
- [Frigate HA Notifications Guide](https://docs.frigate.video/guides/ha_notifications/)
