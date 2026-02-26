# Mobile Homelab Backpack Kit Design

Created: 2026-01-20

## Overview

A portable homelab setup that fits in a backpack, featuring:
- GL.iNet Beryl AX (travel router)
- Raspberry Pi 5 (compute)
- Samsung A13 (USB tethering for mobile internet)
- Anker Nano 3-in-1 Power Bank (power)

---

## Power Topology

```
Anker Nano 3-in-1 (10,000mAh)
├── USB-A (5V/3A) → Beryl AX (15W needed ✓)
└── USB-C (30W PD) → RPi 5 (requires 27W PSU in transit)

Note: Powering both simultaneously from Anker may work but
      RPi 5 at full load needs stable 5A - use dedicated 27W PSU
      when available for reliable operation.
```

### Power Requirements
| Device | Power | Port |
|--------|-------|------|
| Beryl AX | 5V/3A (15W) | USB-C |
| RPi 5 | 5V/5A (27W) | USB-C |
| Samsung A13 | Self-powered | - |

### Anker Nano 3-in-1 Specs
- Capacity: 10,000mAh
- USB-A Output: 22.5W max (5V/3A capable)
- USB-C Output: 30W PD
- Combined Output: 24W max

---

## USB Tethering Chain

```
Samsung A13 (USB-C) → USB-C to USB-A Dongle → Beryl AX (USB-A port)
```

### USB-C to USB-A Adapter Options (~$8-12)
| Option | Notes |
|--------|-------|
| Anker USB-C to USB-A Adapter | Compact, reliable |
| Apple USB-C to USB-A Adapter | Small, premium |
| UGREEN USB-C to USB-A Dongle | Budget option |

---

## Micro Rack: JetDev22 Modular Mini Rack

**Link:** [Printables](https://www.printables.com/model/763694-modular-and-stackable-homelab-mini-rack)

### Why JetDev22 over Microlab 2
- Lighter (~73g vs ~150g per level)
- Faster print time (2.5h vs 4h+ per module)
- No glue/hardware needed (snap-fit)
- More compact for backpack

### Print Plan (PETG on Ender 3 Neo)

| Component | Quantity | Filament | Time |
|-----------|----------|----------|------|
| Base plate | 1 | ~40g | 1.5h |
| Rack level (Beryl) | 1 | ~73g | 2.5h |
| Rack level (RPi 5) | 1 | ~73g | 2.5h |
| Cable clips | 4-6 | ~10g | 0.5h |
| **Total** | | **~196g** | **~7h** |

---

## RPi 5 Case Options

### Recommended: Active Cooler + NVMe Case
- Compatible with official Active Cooler
- NVMe support for future expansion
- Fits JetDev22 rack dimensions
- Link: [Printables](https://www.printables.com/model/644063-raspberry-pi-5-case-designed-for-active-cooler-and)

### Alternative: Stamos Case
- Simpler print, passive cooling
- Remixes available for HatDrive
- Minimalist aesthetic
- Link: [Printables](https://www.printables.com/model/742926-raspberry-pi-5-case)

---

## Cable Management

### 3D Printed Options
1. **Velcro strap holders** - Print slots to organize cables with velcro
2. **Cable clips** - Snap onto rack edges
3. **USB cable organizer** - Honeycomb or spiral design

### Search Terms (Printables)
- "USB cable organizer travel"
- "cable management clip"
- "cable wrap holder"

---

## Backpack Layout

```
┌─────────────────────────────┐
│  Laptop compartment         │
├─────────────────────────────┤
│  ┌─────────────────────┐    │
│  │ JetDev22 Micro Rack │    │
│  │ ┌─────────────────┐ │    │
│  │ │   Beryl AX      │ │    │
│  │ ├─────────────────┤ │    │
│  │ │   RPi 5 + Case  │ │    │
│  │ └─────────────────┘ │    │
│  └─────────────────────┘    │
│                             │
│  Anker Nano    Samsung A13  │
│  (side pocket) (phone slot) │
└─────────────────────────────┘
```

---

## Bill of Materials

### To Purchase
| Item | Source | Est. Cost |
|------|--------|-----------|
| USB-C to USB-A adapter | Amazon | $8-12 |
| Short USB-C cable (6") | Amazon | $6-8 |
| M3 screws (if needed) | Hardware store | $3-5 |
| **Total** | | **$17-25** |

### Already Owned
- Anker Nano 3-in-1 Power Bank
- RPi 5 Active Cooler
- RPi 5 27W PSU (in transit)
- Samsung A13
- GL.iNet Beryl AX
- PETG Filament

### 3D Printing Cost
- ~200g PETG @ ~$25/kg = ~$5-6

**Total Estimated Cost: $22-31**

---

## Related Documentation
- [3D Printed Cases Research](./3d-printed-cases-research.md)
