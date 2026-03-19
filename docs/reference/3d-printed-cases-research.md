# 3D Printed Homelab Cases & Mini Racks Research

Research conducted: 2026-01-20

## RPi 5 Cases

### Stamos Case

| Feature | Details |
|---------|---------|
| Type | Minimalist enclosure |
| Cooling | Passive (vented) |
| NVMe | No (but remixes exist for HatDrive) |
| Difficulty | Easy |
| Platform | [Printables](https://www.printables.com/model/742926-raspberry-pi-5-case), [Thingiverse](https://www.thingiverse.com/thing:6633603), [Cults3D](https://cults3d.com/en/3d-model/gadget/raspberry-pi-5-case-stamos) |

### Fractal Baby North

| Feature | Details |
|---------|---------|
| Type | Miniature PC aesthetic (Fractal North style) |
| Cooling | Passive with wood-style front panel |
| Supports | RPi 3, 4, 5 + BIGTREETECH Pi 2 |
| Official Files | [Fractal Design](https://www.fractal-design.com/north-pi-3d-files/) |
| Community Remix | [Printables (by Nagrom)](https://www.printables.com/model/939709-fractal-baby-north-raspberry-pi-case-3-4-5-bigtree) |

### Active Cooler + NVMe Case

| Feature | Details |
|---------|---------|
| Type | Functional enclosure |
| Cooling | Active (official cooler compatible) |
| NVMe | Yes (nvme-base version) |
| VESA | 75 & 100mm mounting |
| Temps | Max 74C under load at 2.8GHz |
| Link | [Printables](https://www.printables.com/model/644063-raspberry-pi-5-case-designed-for-active-cooler-and) |

---

## Micro Options (Mobile Kit)

### Beryl AX Case Options

| Option | Details |
|--------|---------|
| 3D Printed | [Thingiverse](https://www.thingiverse.com/thing:6704495) - Vase mode, 21g, transparent PETG |
| GL.iNet Gadget Organizer | [Amazon](https://www.amazon.com/GL-iNet-GL-MT3000-Pocket-Sized-Wireless-Organizer/dp/B0BTP8ZC2Q) - EVA case, fits router + cables |
| CaseSack | [Amazon](https://www.amazon.com/CaseSack-GL-MT1300-Wireless-GL-AR750S-Ext-GL-MV1000/dp/B09K1RTPDZ) - PEVA material, water resistant |

### Micro Rack for Mobile

**Best option:** JetDev22's Modular Mini Rack

- ~73g PETG per level, 2.5h print time
- Stackable without glue
- Supports RPi Zero to Mini ITX
- Perfect for: Beryl AX + RPi 5 + MacBook dock
- Link: [Printables](https://www.printables.com/model/763694-modular-and-stackable-homelab-mini-rack)

---

## Small Options (2-3U Equivalent)

### Microlab 2

| Feature | Details |
|---------|---------|
| Footprint | 160x160mm base (smaller than 10") |
| Height | 4U or 6U options |
| Supports | RPi 4/5, TP-Link switches, N100 mini PCs, Mini-ITX |
| Cost | ~2 PLA rolls + M3 screws |
| Best for | Compact mobile kit |
| Links | [GitHub](https://github.com/canberkdurmus/microlab-2), [MakerWorld](https://makerworld.com/en/models/1792250-microlab-2-mini-modular-home-server-rack) |

#### Supported devices

- Raspberry Pi 4/5 (single & dual trays)
- TP-Link/Tenda 8-port switches
- ASRock DeskMini X300/X600
- GMKTec G3 N100 mini PC

### TinyRack

| Feature | Details |
|---------|---------|
| Design | Wire shelving inspired, maximum airflow |
| Assembly | No hardware required (snap-fit) |
| Best for | Mini PC clusters (heat management) |
| Links | [Blog Post](https://fangpenlin.com/posts/2025/11/26/tinyrack-a-3d-printable-modular-rack-for-mini-server/), [Printables](https://www.printables.com/model/1494272-tinyrack-a-modular-mini-server-rack) |

### RackStack

| Feature | Details |
|---------|---------|
| Design | OpenSCAD parametric |
| Sizes | Mini (~200mm3), Micro (~180mm3), Nano (~100mm3) |
| Mounting | Sliding hex nut (no cage nuts) |
| Best for | Custom dimensions |
| Link | [GitHub](https://github.com/jazwa/rackstack) |

---

## Medium Options (10" Mini Rack, 2U-4U)

### Lab Rax (by Michael Klements / The DIY Life)

| Feature | Details |
|---------|---------|
| Standard | 10" rack compatible |
| Height | 1U to 5U (stackable to 10U) |
| Cost | ~$21 total (580g filament + hardware) |
| Print bed | 250mm minimum |
| Versions | Standard (brass inserts) or Bolted (M6 only) |
| Extras | NAS shelves, SBC mounts available |
| Links | [Blog](https://the-diy-life.com/lab-rax-modular-10-3d-printed-rack/), [MakerWorld](https://makerworld.com/en/models/1294480-lab-rax-10-server-rack-5u) |

**Best for:** Fixed homelab, professional look, commercial compatibility

### HomeRacker

| Feature | Details |
|---------|---------|
| Design | Fully parametric (Fusion 360) |
| Standards | 10" and 19" (in development) |
| Assembly | Tool-free (supports + connectors + lock pins) |
| Extras | Gridfinity shelves, drawers, faceplates |
| License | Open source (commercial OK with attribution) |
| Links | [Website](https://homeracker.org/), [GitHub](https://github.com/kellervater/homeracker), [MakerWorld](https://makerworld.com/en/models/1317298-homeracker-core) |

### Mod10

| Feature | Details |
|---------|---------|
| Standard | 10" rack |
| Supports | No supports needed for printing |
| Best for | Ubiquiti gear, RPi clusters |
| Link | [Printables](https://www.printables.com/model/1225275-modular-10-server-rack-mod10) |

---

## Comparison Matrix

| Project | Size | Complexity | Cost | Best For |
|---------|------|------------|------|----------|
| JetDev22 | Micro | Low | ~$5 | Mobile kit |
| Microlab 2 | Small | Medium | ~$15 | Compact portable |
| RackStack | Variable | Medium | ~$10 | Custom sizes |
| TinyRack | Small | Low | ~$10 | Heat-sensitive gear |
| Lab Rax | 10" | Medium | ~$21 | Fixed homelab |
| HomeRacker | 10"/19" | High | ~$30 | Expandable systems |

---

## Recommendations

### Mobile Kit (Backpack)

#### Micro option - Just cases

- Beryl AX: 3D printed vase case or EVA organizer
- RPi 5: Active Cooler + NVMe case
- Samsung A13: Existing phone case

#### Small option - Microlab 2

- Holds Beryl AX + RPi 5 + switch
- 160x160mm footprint
- Fits in backpack

### Fixed Homelab (2U-4U)

#### Recommended: Lab Rax 3-4U

- Standard 10" compatibility
- $21 total cost
- Professional appearance
- Holds: Mini PC + NAS + Switch + RPi cluster

#### Alternative: HomeRacker

- Maximum modularity
- Future expansion to 19"
- Parametric customization

---

## Resources

### Jeff Geerling's Project MINI RACK

Community showcase of 200+ mini rack builds with 3D printed, commercial, and hybrid solutions.

- Website: <https://mini-rack.jeffgeerling.com/>
- GitHub: <https://github.com/geerlingguy/mini-rack>

### Sources

- [The Pi Hut - 3D Printed RPi 5 Cases](https://thepihut.com/blogs/raspberry-pi-roundup/3d-printed-raspberry-pi-5-cases)
- [Tom's Hardware - Fractal Baby North](https://www.tomshardware.com/raspberry-pi/raspberry-pi-cases/maker-community-takes-over-where-fractal-design-stopped-and-produces-miniature-north-case-for-raspberry-pi-users)
- [The DIY Life - Lab Rax](https://the-diy-life.com/introducing-lab-rax-a-3d-printable-modular-10-rack-system/)
- [Hackaday - HomeRacker](https://hackaday.com/2025/11/27/stack-n-rack-your-hardware-with-the-homeracker-project/)
- [Brian Moses - RackStack](https://blog.briancmoses.com/2025/03/rackstack-an-open-source-modular-and-3d-printed-miniature-rack.html)
