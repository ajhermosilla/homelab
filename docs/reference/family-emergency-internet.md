# Family Emergency Internet Runbook

**For:** Family members when Augusto is unavailable and internet is down.

**Time to restore:** ~5 minutes

---

## Quick Check First

Before doing anything, check these:

| Check | How |
|-------|-----|
| Is the power out? | Look at the UPS (black box) - is it beeping? |
| Is the ISP down? | Check neighbors or use mobile data |
| Did the Mini PC crash? | Small black box near the switch - any lights? |

**If power is out:** Wait for power to return. The UPS will keep things running for ~30 minutes.

**If ISP is down:** Nothing we can do - use mobile data until it's back.

**If Mini PC is the problem:** Follow this guide!

---

## What You Need

The **Opal** backup router (small white box) is your emergency internet device.

```
┌───────────────────┐
│    GL-SFT1200     │  ← White color
│      (Opal)       │     with retractable
│                   │     antennas
│ [WAN][LAN] [PWR]  │
└───────────────────┘

Location: Office drawer (dedicated backup router)
```

You also need:
- 1x Ethernet cable (blue/gray cable with plastic clips on ends)
- USB-C power cable

---

## Step-by-Step Recovery

### Step 1: Find the Opal

Look in the **office drawer** where the backup router is kept.

It's a **small white box** with retractable antennas and "GL-iNet" on it.

---

### Step 2: Unplug the Mini PC from the ISP Modem

Find the cable going from the **ISP modem** (the box from Tigo/Personal/Claro) to the **Mini PC** (small black computer).

```
BEFORE (not working):

[ISP Modem] ----cable----> [Mini PC] ----> [Switch] ----> [WiFi]
                              ^
                              |
                         THIS IS DOWN
```

**Unplug the cable from the Mini PC side** (not from the ISP modem).

---

### Step 3: Connect the Opal

1. **Plug the cable from ISP modem into Opal "WAN" port**
   - It's the port on the left side
   - Should click when inserted

2. **Connect Opal to the switch**
   - Use another Ethernet cable
   - Plug one end into Opal "LAN" port (middle port)
   - Plug other end into any free port on the big switch

3. **Power on the Opal**
   - Plug in USB-C power cable
   - Extend the antennas upward for better signal
   - Wait for lights to turn solid (about 1 minute)

```
AFTER (working):

[ISP Modem] ----cable----> [Opal] ----> [Switch] ----> [WiFi]
                              ^
                              |
                         BACKUP ROUTER
```

---

### Step 4: Reconnect to WiFi

The WiFi network name might change. Look for:

| Network Name | Password |
|--------------|----------|
| `GL-SFT1200-xxx` | On sticker under Opal |
| Or same as before | Same password |

**On your phone/laptop:**
1. Go to WiFi settings
2. Forget the old network if it's not connecting
3. Connect to the Opal network (look for GL-SFT1200)
4. Enter password from sticker
5. **Tip:** Connect to 5GHz network for faster speeds if available

---

### Step 5: Test Internet

Open a browser and go to any website (google.com).

**If it works:** You're done! Netflix and YouTube should work now.

**If it doesn't work:**
- Wait 2 more minutes for Opal to get internet from ISP
- Try restarting the ISP modem (unplug for 10 seconds, plug back in)
- Check that all cables are clicked in firmly

---

## What Works / What Doesn't Work

### Works with Opal (backup)

| Service | Status |
|---------|--------|
| Netflix | Works |
| YouTube | Works |
| Web browsing | Works |
| Email | Works |
| Video calls | Works |

### Doesn't Work (needs Augusto to fix)

| Service | Why |
|---------|-----|
| Ad blocking | Pi-hole is on Mini PC |
| Smart home controls | Home Assistant is down |
| Jellyfin (local movies) | Server is down |
| Security cameras | Frigate is down |

---

## Diagram: Where Everything Is

```
                    ┌─────────────────────┐
                    │     ISP Modem       │
                    │  (Tigo/Personal)    │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
    NORMALLY ───────│     Mini PC         │ ◄── If this is dead,
                    │   (black box)       │     use Opal instead
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │    Big Switch       │
                    │  (8 port, silver)   │
                    └─────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
      ┌───────▼───────┐ ┌─────▼─────┐ ┌───────▼───────┐
      │   WiFi AP     │ │    NAS    │ │  Other stuff  │
      │ (TP-Link)     │ │ (storage) │ │               │
      └───────────────┘ └───────────┘ └───────────────┘
```

---

## When Augusto Gets Back

Let him know:
1. The Mini PC stopped working
2. You used the Opal as backup
3. When it happened (date/time if you remember)

He'll need to:
- Fix the Mini PC / OPNsense
- Reconnect everything properly
- Put the Opal back in the drawer

---

## Emergency Contacts

| Person | Contact | When |
|--------|---------|------|
| Augusto | [phone/WhatsApp] | Always try first |
| ISP Support | Tigo: 147 / Personal: *111 | If neighbors also have no internet |

---

## Quick Reference Card

Print this and keep near the router:

```
┌─────────────────────────────────────────────────────────┐
│           EMERGENCY INTERNET - QUICK STEPS              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Find Opal (small WHITE router in office drawer)     │
│                                                         │
│  2. Unplug cable from Mini PC (black box)               │
│                                                         │
│  3. Plug that cable into Opal "WAN" port (left side)    │
│                                                         │
│  4. Connect Opal "LAN" (middle) to Switch               │
│                                                         │
│  5. Power on Opal (USB-C), extend antennas up           │
│                                                         │
│  6. Connect to WiFi: GL-SFT1200-xxx (5GHz faster)       │
│     Password: (on sticker under router)                 │
│                                                         │
│  7. Wait 1-2 minutes, test google.com                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### "No internet" after connecting to Opal WiFi

1. Wait 2 minutes - it takes time to connect to ISP
2. Check ISP modem has lights on
3. Unplug ISP modem for 10 seconds, plug back in
4. Try again in 5 minutes

### Can't find Opal WiFi network

1. Make sure Opal has power (lights on)
2. Make sure USB-C cable is plugged in firmly
3. Try moving closer to the Opal
4. Wait 2 minutes for it to boot up

### Opal lights are blinking but no internet

1. Check the cable from ISP modem is in "WAN" port (not "LAN")
2. Make sure cable clicks in firmly
3. ISP might be down - check with neighbors

### I made it worse!

Don't worry! Nothing is permanently broken.
1. Unplug everything you connected
2. Put cables back where they were
3. Wait for Augusto
4. Use mobile data in the meantime

---

## Hardware Info

| Item | Details |
|------|---------|
| **Backup Router** | GL-iNet GL-SFT1200 (Opal) |
| **Color** | White |
| **Antennas** | Retractable (extend for better signal) |
| **Power** | USB-C (5V/2A) |
| **Ports** | WAN (left), LAN (middle) |
| **WiFi** | Dual-band: 2.4GHz (300Mbps) + 5GHz (867Mbps) |

*Note: The Beryl AX stays in the mobile kit for travel.*

---

*Last updated: 2026-01-22*
*Created by: Augusto for family use*
