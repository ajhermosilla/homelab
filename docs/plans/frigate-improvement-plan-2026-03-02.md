# Frigate Improvement Plan

**Date**: 2026-03-02
**Status**: Pending — most items blocked on new 8TB HDD purchase
**Cameras**: 2x Reolink RLC-520A (PoE), 1x TP-Link Tapo C110 (WiFi)

## Current State

iGPU passthrough completed (2026-03-02): Intel N150 passed to Docker VM, OpenVINO inference at ~15ms (was 102ms on CPU), VA-API hardware decode working for all 3 detect streams. Indoor camera go2rtc still uses software libx264 for rotation (54% CPU) — VA-API encode unstable on N150.

Recording storage: `/mnt/purple` (WD Red 8TB) at 100% — `red-recovery` 1.6T + `frigate` 195G + 7.5G free. Retention changes blocked until disk space is available.

## Hardware Assessment

The Intel N150 iGPU (24 EUs) is sufficient for the full improvement plan. No additional hardware (Coral TPU) needed.

- **Current load (2fps × 3 cameras)**: 6 detections/sec × 15ms = 9% GPU utilization
- **After Phase 1 (5fps × 3 cameras)**: 15 detections/sec × 15ms = 23% GPU utilization
- **Max capacity**: ~66 detections/sec before saturating
- VA-API video decode for 3 sub streams (640×480) adds minimal GPU load
- Recording streams use `-c:v copy` (no GPU)

A Coral TPU would only be needed if adding 6+ cameras, switching to a heavier model (YOLO), or running detect at 10+ fps. The current bottleneck is CPU (indoor camera software transcode at 54%), not GPU inference.

## High Priority

### 1. Increase detection FPS from 2 to 5

Current 2 fps means 500ms between frames. A person walking at normal pace moves ~0.7m between frames, risking missed zone entries and unstable bounding box tracking. Face recognition also gets fewer frames.

With OpenVINO GPU at ~15ms inference, detector capacity is barely used (~6% at 2fps). At 5fps it would be ~15% — still plenty of headroom.

**Change**: Set `fps: 5` globally and per-camera.
**Blocker**: None — can be applied now.

### 2. Add event-based recording retention

Current config retains 2 days of motion recordings with no separate alert/detection retention. Important events (person in driveway) are deleted with routine footage.

**Change**:
```yaml
record:
  enabled: true
  retain:
    days: 2
    mode: motion
  alerts:
    retain:
      days: 14
      mode: all
  detections:
    retain:
      days: 7
      mode: motion
```

**Blocker**: Disk space — longer retention needs more storage. Apply after new 8TB HDD.

### 3. Apply retention option C (immediate disk relief)

Reduce global retention to 1 day and disable indoor continuous recording. Frees ~125G.

**Change**:
```yaml
# Global
record:
  retain:
    days: 1      # was 2
    mode: motion

# Indoor camera
record:
  enabled: true
  retain:
    days: 1
  events:
    retain:
      default: 3  # keep event clips longer
```

**Blocker**: None — should be applied now to prevent `/mnt/purple` from filling completely.

## Medium Priority

### 4. Tune motion detection for outdoor cameras

Default `contour_area: 10` is very sensitive for outdoor use. Leaves, shadows, and wind trigger false motion, inflating storage.

**Change**: Add per-camera motion settings:
```yaml
cameras:
  front_door:
    motion:
      contour_area: 25
  back_yard:
    motion:
      contour_area: 25
```

**Blocker**: None — can be applied now. Tune live via Frigate UI motion debug view.

### 5. Add object filters for car/dog/cat

Only `person` has explicit filters. Cars generate tiny distant detections, animals have higher false positive rates with MobileNet v2.

**Change**:
```yaml
objects:
  filters:
    person:
      min_score: 0.5
      threshold: 0.7
    car:
      min_score: 0.5
      threshold: 0.7
      min_area: 2000
    dog:
      min_score: 0.6
      threshold: 0.75
    cat:
      min_score: 0.6
      threshold: 0.75
```

**Blocker**: None — tune thresholds after observing false positive rates in Frigate UI.

### 6. Indoor camera go2rtc CPU optimization

go2rtc software transcode with rotation (`transpose=2`) uses 54% CPU (libx264). VA-API h264_vaapi encode crashes after a few seconds (likely VA-API surface memory limitation on N150 iGPU).

**Options to revisit**:
- Check if Tapo C110 app supports image rotation (eliminates transcode entirely)
- Try `-preset ultrafast` instead of `-preset superfast` in go2rtc
- Reduce Tapo stream resolution to lower encode cost
- Revisit VA-API encode after Frigate/ffmpeg updates

## Low Priority

### 7. Improve snapshot settings

Current: 2-day retention, no timestamp, default quality (70).

**Change**:
```yaml
snapshots:
  enabled: true
  timestamp: true
  quality: 85
  retain:
    default: 7
```

Snapshots are single JPEGs per event — minimal storage cost.
**Blocker**: None.

### 8. Add loitering_time to street zones

Street zones currently generate detections for every passing car/person, even drive-bys. Adding `loitering_time: 8` filters transient traffic.

**Blocker**: None.

### 9. Add porch zone to front_door camera

Optimization journal (2026-02-24) recommended a dedicated porch/entrance zone. Allows tighter `loitering_time` and more specific alerts for someone at the door.

**Blocker**: None — requires drawing zone coordinates in Frigate UI.

### 10. Add car to front_door driveway alerts

Currently only `person` triggers alerts in the driveway. Adding `car` would notify on deliveries/visitors pulling in.

**Blocker**: None — depends on whether driveway zone excludes street traffic.

## What's Already Done Well

- Sub/main stream separation via go2rtc (correct pattern)
- OpenVINO GPU + VA-API hardware acceleration (optimal for N150)
- Zone design with inertia and loitering_time
- Alert/detection separation (alerts for primary zones only)
- Face recognition enabled
- Credential management via environment variables
- Consistent 4:3 aspect ratio between sub and main streams
- Docker Compose security hardening (no-new-privileges, resource limits, logging)

## Execution Plan

**Phase 1 — Now (no disk space needed)**:
- Item 1: Increase detect FPS to 5
- Item 3: Reduce retention to 1 day (option C)
- Item 4: Tune motion contour_area
- Item 5: Add object filters

**Phase 2 — After new 8TB HDD**:
- Item 2: Event-based retention (14 days alerts, 7 days detections)
- Item 7: Snapshot retention to 7 days
- Item 8-10: Zone and alert refinements

**Phase 3 — When time permits**:
- Item 6: Indoor camera CPU optimization
- Item 9: Porch zone (needs Frigate UI zone drawing)
