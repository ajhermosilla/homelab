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

The **Mango** backup router (small orange box) is your emergency internet device.

```
┌───────────────────┐
│   GL-MT300N-V2    │  ← Bright orange color
│     (Mango)       │     58mm x 58mm
│                   │     (smaller than a
│ [WAN][LAN] [PWR]  │      deck of cards)
└───────────────────┘

Location: Office drawer (dedicated backup router)
```

You also need:
- 1x Ethernet cable (blue/gray cable with plastic clips on ends)
- Micro USB power cable (old Android phone charger works)

---

## Step-by-Step Recovery

### Step 1: Find the Mango

Look in the **office drawer** where the backup router is kept.

It's a **small bright orange box** (hard to miss!) about the size of a matchbox with "GL-iNet" on it.

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

### Step 3: Connect the Mango

1. **Plug the cable from ISP modem into Mango "WAN" port**
   - It's the port on the left side
   - Should click when inserted

2. **Connect Mango to the switch**
   - Use another Ethernet cable
   - Plug one end into Mango "LAN" port (middle port)
   - Plug other end into any free port on the big switch

3. **Power on the Mango**
   - Plug in Micro USB power cable (old Android charger)
   - Wait for lights to turn solid (about 1 minute)

```
AFTER (working):

[ISP Modem] ----cable----> [Mango] ----> [Switch] ----> [WiFi]
                              ^
                              |
                         BACKUP ROUTER
```

---

### Step 4: Reconnect to WiFi

The WiFi network name might change. Look for:

| Network Name | Password |
|--------------|----------|
| `GL-MT300N-V2-xxx` | On sticker under Mango |
| Or same as before | Same password |

**On your phone/laptop:**
1. Go to WiFi settings
2. Forget the old network if it's not connecting
3. Connect to the Mango network (look for GL-MT300N)
4. Enter password from sticker

---

### Step 5: Test Internet

Open a browser and go to any website (google.com).

**If it works:** You're done! Netflix and YouTube should work now.

**If it doesn't work:**
- Wait 2 more minutes for Mango to get internet from ISP
- Try restarting the ISP modem (unplug for 10 seconds, plug back in)
- Check that all cables are clicked in firmly

---

## What Works / What Doesn't Work

### Works with Mango (backup)

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
                    │   (black box)       │     use Mango instead
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
2. You used the Mango as backup
3. When it happened (date/time if you remember)

He'll need to:
- Fix the Mini PC / OPNsense
- Reconnect everything properly
- Put the Mango back in the drawer

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
│  1. Find Mango (small ORANGE router in office drawer)   │
│                                                         │
│  2. Unplug cable from Mini PC (black box)               │
│                                                         │
│  3. Plug that cable into Mango "WAN" port (left side)   │
│                                                         │
│  4. Connect Mango "LAN" (middle) to Switch              │
│                                                         │
│  5. Power on Mango (Micro USB / old Android charger)    │
│                                                         │
│  6. Connect to WiFi: GL-MT300N-V2-xxx                   │
│     Password: (on sticker under router)                 │
│                                                         │
│  7. Wait 1-2 minutes, test google.com                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### "No internet" after connecting to Mango WiFi

1. Wait 2 minutes - it takes time to connect to ISP
2. Check ISP modem has lights on
3. Unplug ISP modem for 10 seconds, plug back in
4. Try again in 5 minutes

### Can't find Mango WiFi network

1. Make sure Mango has power (lights on)
2. Make sure Micro USB cable is plugged in firmly
3. Try moving closer to the Mango
4. Wait 2 minutes for it to boot up

### Mango lights are blinking but no internet

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
| **Backup Router** | GL-iNet GL-MT300N-V2 (Mango) |
| **Color** | Bright orange |
| **Size** | 58 x 58 x 25mm (smaller than deck of cards) |
| **Power** | Micro USB (5V/1A - any old Android charger) |
| **Ports** | WAN (left), LAN (middle), USB (right) |
| **WiFi** | 2.4GHz only, 300Mbps (plenty for streaming) |

*Note: The Beryl AX (white router) stays in the mobile kit for travel.*

---

*Last updated: 2026-01-21*
*Created by: Augusto for family use*
