# Family Emergency Internet Runbook

**For:** Family members when internet is down and Augusto is unavailable.

**Good news:** Most outages fix themselves automatically. You only need this guide for streaming/Netflix during an ISP outage.

---

## Which Scenario Are You In?

| What you see | Likely cause | What to do |
|---|---|---|

| **No internet, Mini PC lights ON**| ISP is down | →**Scenario A** (most common) |
| **No internet, Mini PC lights OFF**| Proxmox/power issue | →**Scenario B** |
| **Internet is slow or keeps dropping**| ISP issue | →**Scenario C** |

---

## Scenario A: No Internet, Mini PC Lights Are ON

#### This is the most common case — the ISP (Tigo) is down

Augusto's remote access works automatically via LTE backup (he gets an alert on his phone). But for **Netflix, YouTube, and video calls**, the family needs to activate the emergency WiFi:

### What You Need

1. **Your phone** — turn on WiFi hotspot
2. **The Opal** — small white router on the shelf near the switch

```text
┌───────────────────┐
│    GL-SFT1200     │  ← Small white box
│      (Opal)       │     with antennas
│                   │
│     [USB-C PWR]   │  ← Just plug in power
└───────────────────┘

Location: Shelf near the network switch (NOT in a drawer)
Label: "Emergency Internet"
```

### Steps (< 5 minutes)

1. **Turn on your phone's WiFi hotspot**
   - iPhone: Settings → Personal Hotspot → Allow Others
   - Android: Settings → Connections → Mobile Hotspot → Turn on
   - Hotspot name should be the one pre-configured in the Opal

1. **Plug in the Opal's power cable (USB-C)**
   - That's it — just power. No other cables to connect
   - Wait ~1 minute for it to boot (lights go solid)

1. **Connect your devices to EmergencyWiFi**

   | Network | Password |
   |---------|----------|

   | `EmergencyWiFi` (2.4GHz) | *(written on the label)* |
   | `EmergencyWiFi-5G` (faster) | *(same password)* |

   **Tip:** Use 5G for streaming — it's faster.

1. **Test it** — open Netflix or YouTube

#### No cable swapping. No touching the modem or switch. Just power + phone hotspot

### When ISP Comes Back

1. Unplug the Opal
2. Turn off phone hotspot
3. Reconnect devices to normal WiFi
4. Put the Opal back on the shelf

---

## Scenario B: No Internet, Mini PC Lights Are OFF

#### The Mini PC (Proxmox) has crashed or lost power

This is rarer. The Opal needs to connect directly to the ISP modem:

### Steps

1. Find the Opal (shelf near the switch)
2. **Unplug the ethernet cable from the Mini PC** (black box) — leave the ISP modem end connected
3. **Plug that cable into the Opal's WAN port** (left side port)
4. **Connect Opal LAN port** (middle) to the switch with another ethernet cable
5. **Plug in Opal power** (USB-C)
6. Wait 1-2 minutes
7. Connect devices to the Opal's WiFi (`EmergencyWiFi` or `EmergencyWiFi-5G`)

```text
NORMAL (not working):
[ISP Modem] ──cable──► [Mini PC] ──► [Switch] ──► WiFi
                            ✗ DEAD

EMERGENCY:
[ISP Modem] ──cable──► [Opal WAN] ──► [Switch] ──► WiFi
                         ✓ BACKUP
```

---

## Scenario C: Internet Is Slow or Keeps Dropping

**Don't touch anything.** This usually fixes itself.

1. Wait 10-15 minutes
2. If still bad, text/call Augusto
3. If you can't reach Augusto, try restarting the ISP modem:
   - Unplug the modem power for 10 seconds
   - Plug it back in
   - Wait 3-5 minutes

---

## What Works / What Doesn't

### With Emergency WiFi (Opal + phone hotspot)

| Service | Status | Notes |
|---------|--------|-------|

| Netflix | ✓ Works | Uses phone data |
| YouTube | ✓ Works | Uses phone data |
| Web browsing | ✓ Works | |
| Video calls | ✓ Works | May use lots of data |
| Social media | ✓ Works | |

### Needs Augusto to Fix

| Service | Why |
|---------|-----|

| Ad blocking | Pi-hole runs on Mini PC |
| Smart home | Home Assistant is on Mini PC |
| Security cameras | Frigate is on Mini PC |
| Local movies (Jellyfin) | Server is on Mini PC |

---

## How the Automatic Backup Works (FYI)

You don't need to do anything for this — it's automatic:

- A small **LTE router** (TP-Link, white box with antennas) is plugged into the network switch
- When the ISP goes down, it automatically switches to mobile data
- This keeps Augusto's remote access working (so he can fix things from anywhere)
- It does NOT provide enough bandwidth for Netflix — that's why the Opal + phone hotspot exists for streaming

```text
Layer 1 (automatic, invisible):
  ISP down → LTE modem takes over → Augusto has remote access

Layer 2 (manual, family activates):
  Family needs Netflix → Phone hotspot + Opal → EmergencyWiFi
```

---

## Where Everything Is

```text
                    ┌─────────────────────┐
                    │     ISP Modem       │
                    │  (Tigo — ARRIS)     │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │     Mini PC         │
                    │   (black box)       │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │   MokerLink Switch  │ ← Opal + LTE router
                    │   (8 port, silver)  │   on the shelf nearby
                    └─────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
      ┌───────▼───────┐ ┌─────▼─────┐ ┌───────▼───────┐
      │   WiFi AP     │ │    NAS    │ │  Other stuff  │
      │  (TP-Link)    │ │ (storage) │ │               │
      └───────────────┘ └───────────┘ └───────────────┘
```

---

## Emergency Contacts

| Person | Contact | When |
|--------|---------|------|

| Augusto | [phone/WhatsApp] | Always try first |
| ISP Support | Tigo: 147 / Personal: *111 | If neighbors also have no internet |

---

## Quick Reference Card

#### Print this, laminate it, and keep it on the shelf near the Opal

```text
┌──────────────────────────────────────────────────────────────┐
│          🌐 EMERGENCY INTERNET — QUICK STEPS                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ❓ Is the Mini PC (black box) ON?                           │
│     Lights visible = YES                                     │
│                                                              │
│  ✅ YES (ISP is down — most common):                         │
│                                                              │
│     1. Turn on phone WiFi hotspot                            │
│     2. Plug in Opal power (USB-C) — NO other cables          │
│     3. Connect to "EmergencyWiFi-5G"                         │
│        Password: ______________________                      │
│     4. Wait 1 min, test Netflix                              │
│                                                              │
│  ❌ NO (Mini PC is dead — rare):                              │
│                                                              │
│     1. Unplug cable from Mini PC                             │
│     2. Plug that cable into Opal "WAN" (left port)           │
│     3. Connect Opal "LAN" (middle) to switch                 │
│     4. Plug in Opal power (USB-C)                            │
│     5. Connect to "EmergencyWiFi-5G"                         │
│     6. Wait 2 min, test Netflix                              │
│                                                              │
│  ⏳ Internet is just SLOW? Don't touch anything.              │
│     Wait 15 min. If still bad, call Augusto.                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### "No internet" after connecting to EmergencyWiFi

1. Is your phone hotspot still on? Check it
2. Is the phone connected to mobile data? (Check signal bars)
3. Move the phone closer to the Opal
4. Wait 2 minutes — the Opal may still be connecting
5. Try turning the phone hotspot off and on again

### Can't see EmergencyWiFi network

1. Check the Opal has power (lights on?)
2. Wait 1-2 minutes for it to boot
3. Move closer to the Opal

### I made things worse

Don't worry — nothing is permanently broken.

1. Unplug everything you connected
2. Put cables back where they were
3. Use mobile data on your phone for now
4. Wait for Augusto

---

## Hardware Info

| Item | Details |
|------|---------|

| **Emergency Router** | GL-iNet GL-SFT1200 (Opal) |
| **Color** | White, small box with antennas |
| **Power** | USB-C (5V/2A) |
| **Ports** | WAN (left), LAN (middle) |
| **WiFi** | `EmergencyWiFi` (2.4GHz) + `EmergencyWiFi-5G` (5GHz) |
| **Mode** | Repeater (connects to phone hotspot wirelessly) |
| **LTE Router** | TP-Link TL-MR100 (plugged into switch — don't touch) |

*Note: The Beryl AX stays in the mobile kit for travel.*

---

*Last updated: 2026-03-05*
*Created by: Augusto for family use*
