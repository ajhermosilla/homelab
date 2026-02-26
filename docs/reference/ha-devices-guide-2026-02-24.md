# Smart Home Devices for Home Assistant — Paraguay Budget Guide

**Date:** 2026-02-24
**Context:** Home Assistant on Docker VM, Frigate NVR with 3 cameras, MQTT via Mosquitto. Budget-friendly, hackable devices preferred. Paraguay uses Type B electrical outlets (same as US).

---

## 1. SONOFF Devices

### WiFi Switches & Relays (ESP-based, flashable)

| Device | Chip | Flashable? | Price (USD) | Notes |
|--------|------|-----------|-------------|-------|
| **SONOFF MINI R4** | ESP32 | Yes (Tasmota/ESPHome) | ~$10-15 | In-wall relay, decoupled switch. Requires soldering to flash. |
| **SONOFF MINI R4M** | ESP32-C3 | No (Matter-locked) | ~$12-15 | Matter-certified. Use via Matter integration, don't try to flash. |
| **SONOFF Basic R4** | ESP32 | Yes (Tasmota/ESPHome) | ~$8-12 | Basic relay, well-documented flashing. |
| **SONOFF S31** | ESP8266 | Yes (Tasmota/ESPHome) | ~$10-13 | Best flashable plug with energy monitoring. Exposed pin headers. **SAFETY**: GND connected to live AC — use isolated USB-serial adapter. |
| **SONOFF S26 R2** | ESP8266 | Yes (Tasmota) | ~$8-10 | Simple plug, no energy monitoring. Multiple regional versions. |
| **SONOFF TX Ultimate** | ESP32 | Yes (ESPHome) | ~$30-40 | Touch wall switch with LED effects. |

**Alternative to flashing:** The [Sonoff LAN integration](https://github.com/AlexxIT/SonoffLAN) (HACS) controls SONOFF devices locally on stock firmware via eWeLink LAN mode.

### Zigbee Sensors (no flashing needed)

| Device | Type | Price (USD) | Battery Life | Notes |
|--------|------|-------------|-------------|-------|
| **SNZB-04P** | Door/Window | ~$10-16 | 5+ years (CR2477) | Zigbee 3.0, ZHA/Z2M |
| **SNZB-03P** | Motion | ~$10-16 | 3 years | Includes ambient light sensor |
| **SNZB-02D** | Temp/Humidity | ~$10-16 | LCD display, CR2032 | Great for room climate |
| **SNZB-02P** | Temp/Humidity | ~$8-12 | No display, smaller | Budget option |
| **SNZB-06P** | Presence (mmWave) | ~$20-25 | Mains powered | Zigbee mmWave |

---

## 2. ESP32 / ESPHome Projects

Boards cost $2-4 on AliExpress. ESPHome turns YAML configs into fully integrated HA devices.

### Recommended Boards

| Board | Price | WiFi | BLE | Thread | Best For |
|-------|-------|------|-----|--------|----------|
| **ESP32-C3 Super Mini** | ~$2-3 | Yes | 5.0 | No | BLE proxy, sensors, relays |
| **ESP32-S3 Super Mini** | ~$3-4 | Yes | 5.0 | No | Camera, heavy processing |
| **ESP32-C6 Super Mini** | ~$3-5 | WiFi 6 | 5.0 | Yes | Future-proof, Thread support |
| **D1 Mini (ESP8266)** | ~$2 | Yes | No | No | Simple sensors, legacy |

**Warning:** Some ESP32-C3 Super Mini boards from AliExpress have a design flaw — check spacing between capacitor C3 and processor tip (good: ~3.3mm gap, bad: ~1.5mm).

### Top Projects

**Presence Detection (mmWave + ESP32):**
- **LD2410C** sensor (~$3-5) + ESP32-C3 Super Mini = ~$5-8 per room
- Detects stationary humans (breathing detection), range up to 5m
- Native ESPHome `ld2410` component
- vs $167 for commercial Aqara FP2

**BLE Bluetooth Proxy:**
- ESP32 with ESPHome Bluetooth Proxy firmware
- Extends HA's BLE range throughout the house
- ~$3 per proxy, place 2-4 around the house

**Temperature/Humidity Monitoring:**
- ESP32 + BME280 sensor = ~$5-7 per node
- Perfect for server room / rack monitoring

**Water Leak Detection:**
- ESP32 + water sensor module = ~$3-5 per detector
- ESPHome `binary_sensor` with `device_class: moisture`

**Smart Relay / Light Switch:**
- ESP32 + relay module = ~$4-6
- Controls any light or appliance

### Pre-flashed Option: Athom Technology

If you don't want to solder, [Athom](https://www.athom.tech/) sells devices pre-flashed with ESPHome/Tasmota on AliExpress: smart plugs with energy monitoring (~$10-13), relay modules, bulbs. Ready to pair with HA out of the box.

---

## 3. Zigbee vs WiFi vs Matter

| Factor | Zigbee | WiFi (ESPHome) | Matter (Thread) |
|--------|--------|----------------|-----------------|
| **Cost** | Cheapest sensors | Cheap (ESP-based) | Getting cheaper (IKEA) |
| **Battery life** | Excellent (years) | Poor (mains only) | Excellent |
| **Range** | Mesh extends | Router-dependent | Mesh extends |
| **Coordinator** | Yes ($15-25 dongle) | No (existing WiFi) | Thread border router |
| **Local control** | Always local | Local with ESPHome | Always local |
| **Maturity** | Very mature | Very mature | Maturing rapidly |

### Recommendation

**Start with Zigbee** for battery-powered sensors + **SONOFF ZBDongle-P** (~$15-20). Use **WiFi/ESPHome** for mains-powered DIY projects. **Matter** worth considering for new purchases (especially IKEA), but don't migrate existing setups.

### Zigbee Coordinators

| Coordinator | Chip | Price | Notes |
|------------|------|-------|-------|
| **SONOFF ZBDongle-P** | CC2652P | ~$15-20 | Most recommended, best Z2M support |
| **SONOFF ZBDongle-E** | EFR32MG21 | ~$15-20 | Works great with ZHA |
| **HA Connect ZBT-2** | - | ~$30 | Official, supports Zigbee + Thread |
| **SLZB-06** | CC2652P | ~$35-40 | Ethernet-based, best range |

For Docker VM HA: **ZBDongle-P** is the budget choice. Plug into Proxmox host, pass through USB to Docker VM.

---

## 4. Smart Plugs with Energy Monitoring

| Plug | Protocol | Energy Monitor | Flashable | Price | Notes |
|------|----------|---------------|-----------|-------|-------|
| **SONOFF S31** | WiFi | Yes | Yes (ESPHome) | ~$10-13 | Best hackable plug. US/Type B. |
| **Athom Smart Plug V3** | WiFi | Yes (HLW8032) | Pre-flashed ESPHome | ~$10-13 | Plug-and-play, US/EU/BR types |
| **SONOFF S40** | WiFi | Yes | No (BK chip) | ~$13-16 | Not flashable |
| **Tuya-based plugs** | WiFi | Some models | Depends on chip | ~$5-10 | Check chip first |

**For Paraguay (Type B):** SONOFF S31 or Athom US plug. S31 gives full ESPHome control with real-time watt/volt/amp readings — perfect for monitoring homelab power.

---

## 5. Tuya Ecosystem

Most "generic" smart home products in Paraguay are Tuya-based (sold under many brand names, all use Smart Life app).

### Integration Options (Best to Worst)

1. **LocalTuya (HACS)** — Controls devices over local network, no cloud. Requires one-time `local_key` extraction from Tuya Developer Platform. Works with stock firmware. [GitHub](https://github.com/xZetsubou/hass-localtuya)

2. **Flash with Cloudcutter + LibreTiny** — For BK7231 chip devices (most newer Tuya). OTA flashing, no soldering, won't brick on failure. Then runs ESPHome via [LibreTiny](https://esphome.io/components/libretiny/). [Cloudcutter GitHub](https://github.com/tuya-cloudcutter/tuya-cloudcutter)

3. **Official Tuya Integration (Cloud)** — Easiest but depends on Tuya cloud. Slower, privacy concerns. Fallback only.

### Check Chip Before Buying

- [Blakadder's device database](https://templates.blakadder.com/) for Tasmota templates
- [Cloudcutter device list](https://www.elektroda.com/rtvforum/topic3979215.html) for BK7231 support
- Avoid Realtek RTL8710BN chips (not flashable)

---

## 6. ESP32 BLE Presence Detection

### Option A: Bermuda BLE Trilateration (Recommended)

1. Place ESP32 boards with ESPHome Bluetooth Proxy in each room
2. Install [Bermuda BLE Trilateration](https://github.com/agittins/bermuda) from HACS
3. Bermuda reads RSSI from each proxy to determine which room a BLE device is in
4. Tracks phones, smartwatches, BLE beacons, pets with BLE tags

Hardware: 1x ESP32-C3 per room (~$2-3 each) + USB power. 2-4 proxies covers a typical house.

### Option B: mmWave Per-Room (Most Accurate)

- ESP32 + LD2410C per room (~$5-8)
- Detects actual human presence (not just BLE signal)
- Best for occupancy automations (lights, HVAC)
- Can combine with BLE proxy on the same ESP32

**Use both:** Bermuda for tracking *who* is in which room, mmWave for detecting *if anyone* is there.

---

## 7. DIY Projects for the Homelab

### Server Room Temperature

- ESP32-C3 + BME280 (temp/humidity/pressure) = ~$5-7
- Place near Proxmox host, NAS, network switch
- Alert via ntfy if temperature exceeds threshold

### Water Leak Detection

- ESP32-C3 + water sensor = ~$3-5 per sensor
- Place near NAS, under water heater, near AC units
- Instant ntfy notification on detection

### UPS Monitoring

- If UPS has USB/serial: use NUT (Network UPS Tools) via HA's [NUT integration](https://www.home-assistant.io/integrations/nut/)
- If no USB (like Forza): ESP32 + voltage divider on UPS output, ESPHome `adc` sensor
- Trigger graceful shutdown automations on power loss

### Power Monitoring for Homelab

- SONOFF S31 (flashed ESPHome) on each device
- Monitor real-time watt/volt/amp for: Proxmox host, NAS, switch, UPS
- HA Energy Dashboard tracks daily/monthly consumption
- Detect anomalies (e.g., disk failure causing power spike)

### Garage Door Controller

- ESP32 + relay + reed switch = ~$6-10
- ESPHome `cover` component with `device_class: garage`
- Optional: HC-SR04 ultrasonic to detect if car is parked

---

## 8. Availability in Paraguay

| Source | What You'll Find | Notes |
|--------|-----------------|-------|
| **MercadoLibre PY** | Tuya-based plugs, bulbs, switches | Most common, use LocalTuya |
| **Ciudad del Este** | SONOFF via [Mobile Zone](https://sonoff.tech/en-us/blogs/news/primer-proyecto-de-domotica-en-paraguay-mobile-zone) (Galeria Jebai) | Official SONOFF distributor |
| **TiendaMia** | Full Amazon catalog | Handles import/customs, good for SONOFF S31 |
| **AliExpress** | Everything: ESP32, sensors, Zigbee | 2-4 week shipping, lowest prices |

**Buy locally:** Tuya plugs/bulbs, USB power supplies, basic electronics.
**AliExpress:** ESP32 boards (bulk), LD2410C, BME280, SONOFF Zigbee sensors, ZBDongle-P, Athom plugs.
**TiendaMia:** SONOFF S31 (US plug = Paraguay Type B), items needing faster shipping.

---

## 9. Matter Protocol — Worth It?

- HA has **official Matter certification** (first open-source project to achieve this)
- **IKEA** launched 21 Matter-over-Thread devices at aggressive prices (temp sensor ~$10, motion ~$7, water leak ~$8)
- SONOFF MINIR4M works natively via Matter
- Matter guarantees local control, no cloud

**Recommendation:** Don't go all-in yet. Buy Matter for new purchases where cheap (IKEA). Keep Zigbee for existing investments. The HA Connect ZBT-2 ($30) bridges both Zigbee and Thread.

---

## 10. Recommended Starting Kit

### Phase 1: Foundation (~$25-35)

| Item | Source | Price | Purpose |
|------|--------|-------|---------|
| SONOFF ZBDongle-P | AliExpress | ~$15 | Zigbee coordinator |
| 3x ESP32-C3 Super Mini | AliExpress | ~$6-9 | BLE proxy + sensors |
| 2x LD2410C mmWave | AliExpress | ~$6-10 | Presence detection |
| BME280 sensor | AliExpress | ~$2-3 | Server room temp |

### Phase 2: Sensors (~$40-60)

| Item | Source | Price | Purpose |
|------|--------|-------|---------|
| 2x SONOFF SNZB-04P | AliExpress | ~$20-30 | Door/window sensors |
| 1x SONOFF SNZB-03P | AliExpress | ~$10-16 | Motion sensor |
| 1x SONOFF SNZB-02D | AliExpress | ~$10-16 | Temp/humidity LCD |
| Water sensor module | AliExpress | ~$1-2 | Leak detection (DIY) |

### Phase 3: Power & Control (~$30-50)

| Item | Source | Price | Purpose |
|------|--------|-------|---------|
| 2x SONOFF S31 | TiendaMia | ~$20-26 | Energy monitoring |
| 2x SONOFF MINI R4 | AliExpress | ~$20-30 | In-wall switches |

**Total: ~$95-145** for a comprehensive setup with full local control.
