# Frigate Improvement Plan

**Date**: 2026-03-02
**Updated**: 2026-03-10
**Status**: Phase 1 complete, Phase 2 blocked on 8TB HDD
**Cameras**: 2x Reolink RLC-520A (PoE), 1x TP-Link Tapo C110 (WiFi)

## Current State

iGPU passthrough completed (2026-03-02): Intel N150 passed to Docker VM, OpenVINO inference at ~15ms (was 102ms on CPU), VA-API hardware decode working for all 3 detect streams. Indoor camera go2rtc uses software libx264 for rotation — downscaled from 1080x1920 to 360x640 (2026-03-09), reducing CPU from 54% to ~7%.

Recording storage: `/mnt/purple` (WD Red 8TB) at 100% — `red-recovery` 1.6T + `frigate` 195G + 7.5G free. Retention changes blocked until disk space is available.

## Hardware Assessment

The Intel N150 iGPU (24 EUs) is sufficient for the full improvement plan. No additional hardware (Coral TPU) needed.

- **Current load (5fps × 3 cameras, post-Phase 1)**: 15 detections/sec × 15ms = 23% GPU utilization
- **Max capacity**: ~66 detections/sec before saturating
- VA-API video decode for 3 sub streams (640×480) adds minimal GPU load
- Recording streams use `-c:v copy` (no GPU)

A Coral TPU would only be needed if adding 6+ cameras, switching to a heavier model (YOLO), or running detect at 10+ fps. The current bottleneck is CPU (indoor camera software transcode at 54%), not GPU inference.

## High Priority

### 1. ~~Increase detection FPS from 2 to 5~~ — DONE (2026-03-02)

Applied `fps: 5` globally and per-camera. OpenVINO GPU at ~15ms handles 15 detections/sec (~23% utilization) with headroom to spare.

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

### 3. ~~Apply retention option C (immediate disk relief)~~ — DONE (2026-03-02)

Applied 1-day global retention and indoor events-only recording.

## Medium Priority

### 4. ~~Tune motion detection for outdoor cameras~~ — DONE (2026-03-02)

Applied `contour_area: 25` for front_door and back_yard.

### 5. ~~Add object filters for car/dog/cat~~ — DONE (2026-03-02)

Applied min_score/threshold filters for person, car, dog, cat.

### 6. ~~Indoor camera go2rtc CPU optimization~~ — DONE (2026-03-09)

Downscaled go2rtc transcode from 1080x1920 to 360x640 (`scale=360:640` in ffmpeg filter chain). CPU dropped from 54% to ~7% (8x reduction). VA-API/QSV cannot do transpose — Intel driver limitation, not a bug. Frigate detection uses 300x300, so 360x640 is more than sufficient.

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

**Phase 1 — COMPLETE (2026-03-02)**:

- ~~Item 1: Increase detect FPS to 5~~
- ~~Item 3: Reduce retention to 1 day (option C)~~
- ~~Item 4: Tune motion contour_area~~
- ~~Item 5: Add object filters~~
- ~~Item 6: Indoor camera CPU optimization~~ (2026-03-09)

**Phase 2 — After new 8TB HDD (blocked on purchase)**:

- Item 2: Event-based retention (14 days alerts, 7 days detections)
- Item 7: Snapshot retention to 7 days
- Item 8-10: Zone and alert refinements
- Item 9: Porch zone (needs Frigate UI zone drawing)
