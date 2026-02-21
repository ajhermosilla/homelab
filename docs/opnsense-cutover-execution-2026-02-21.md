# OPNsense Gateway Cutover — Execution Checklist

**Date:** 2026-02-21
**Window:** 30 minutes max
**Rollback time:** ~2 minutes
**Alternative internet:** Phone tethering (safety net only)

---

## Before You Start

- [ ] Open Proxmox web UI: `https://192.168.0.237:8006`
- [ ] Open this file on your phone (in case Mac loses connectivity)
- [ ] Have an Ethernet cable ready for nic1
- [ ] Announce: "Internet will be down for up to 30 minutes"
- [ ] Note current time: ________

---

## Step 1: Connect nic1 to Switch

**Physical:** Plug an Ethernet cable from Proxmox **nic1** (2nd port) into the MokerLink switch.

Verify from Mac terminal:

```bash
ssh augusto@192.168.0.237 "ip link show nic1 | grep 'state UP'"
```

Expected: `state UP`

- [ ] nic1 shows UP

---

## Step 2: Apply Proxmox Network Config

This moves management IP from vmbr0 → vmbr1 (now on the switch via nic1).

```bash
ssh augusto@192.168.0.237 "sudo cp /etc/network/interfaces.cutover /etc/network/interfaces && sudo cp /etc/network/interfaces.d/vmbr1.cutover /etc/network/interfaces.d/vmbr1 && sudo ifreload -a"
```

Verify:

```bash
ssh augusto@192.168.0.237 "ip -br addr show vmbr0 && ip -br addr show vmbr1"
```

Expected:
- `vmbr0` — no IP (manual)
- `vmbr1` — `192.168.0.237/24`

- [ ] vmbr0 has no IP
- [ ] vmbr1 has 192.168.0.237/24
- [ ] Proxmox web UI still works at `https://192.168.0.237:8006`

---

## Step 3: Swap Cables

**Physical — two cable changes:**

1. Unplug ISP Ethernet from **TP-Link WAN port** → plug into **Proxmox nic0**
2. Unplug the old switch cable from **Proxmox nic0** (no longer needed)

Result: nic0 faces ISP modem, nic1 faces switch.

> Internet is now DOWN for everyone. Clock is ticking.

- [ ] ISP cable in Proxmox nic0
- [ ] Old switch cable removed from nic0

---

## Step 4: Verify OPNsense Gets Public IP

Open **Proxmox web UI** → VM 100 (OPNsense) → **Console**.

In the OPNsense console (or web UI from the console browser):
- Dashboard → Interfaces → WAN → should show a public IP via DHCP

If no public IP: wait 30 seconds, then run in OPNsense console:

```
/usr/local/sbin/configctl interface reconfigure wan
```

- [ ] OPNsense WAN has a public IP

> If no public IP after 2 minutes → **ROLLBACK** (see bottom of this file)

---

## Step 5: Switch TP-Link to AP Mode

From Mac (still connected to WiFi):

1. Open `http://192.168.0.1` (TP-Link admin)
2. Operation Mode → **Access Point**
3. Set static IP: **192.168.0.2**
4. Apply (TP-Link reboots, ~1 minute)
5. After reboot: move TP-Link cable from **WAN port** to a **LAN port** on the switch

> WiFi will briefly drop and reconnect. Same SSID/password = auto-reconnect.

- [ ] TP-Link in AP mode
- [ ] TP-Link cable: LAN port → switch (NOT WAN port)
- [ ] Mac reconnected to WiFi

---

## Step 6: Configure OPNsense LAN

From **Proxmox web UI** → VM 100 (OPNsense) → **Console**:

Open OPNsense web UI inside the console (https://192.168.1.1):

### 6a. Change LAN IP
- Interfaces → LAN
- IPv4: `192.168.0.1/24`
- Save → Apply

### 6b. Enable DHCP
- Services → DHCPv4 → LAN
- Enable: checked
- Range: `192.168.0.100` – `192.168.0.250`
- DNS server: `192.168.0.10`
- Gateway: `192.168.0.1`
- Save

### 6c. Add Static Mappings
- Docker VM: MAC `BC:24:11:A8:E9:C5` → `192.168.0.10`
- TP-Link AP: (get MAC from lease list) → `192.168.0.2`
- Save → Apply

After applying, OPNsense LAN is at `192.168.0.1`. Proxmox gateway now works.

- [ ] LAN IP changed to 192.168.0.1
- [ ] DHCP enabled (range .100–.250, DNS .10, gateway .1)
- [ ] Docker VM static mapping added

---

## Step 7: Re-IP Docker VM

Docker VM's gateway (192.168.1.1) is gone. Fix from Proxmox:

```bash
ssh augusto@192.168.0.237 "sudo qm guest exec 101 -- bash -c 'ip addr del 192.168.1.10/24 dev ens18; ip addr add 192.168.0.10/24 dev ens18; ip route add default via 192.168.0.1'"
```

If `qm guest exec` fails, use Proxmox web UI → VM 101 → Console, then:

```bash
sudo ip addr del 192.168.1.10/24 dev ens18
sudo ip addr add 192.168.0.10/24 dev ens18
sudo ip route add default via 192.168.0.1
```

Make it persistent:

```bash
ssh augusto@192.168.0.237 "sudo qm guest exec 101 -- bash -c \"sed -i 's/192.168.1.10/192.168.0.10/g; s/gateway 192.168.1.1/gateway 192.168.0.1/g' /etc/network/interfaces\""
```

Or edit via Proxmox console if sed doesn't work.

Verify:

```bash
ssh augusto@192.168.0.10 "ip addr show ens18 | grep inet && ping -c1 8.8.8.8"
```

- [ ] Docker VM at 192.168.0.10
- [ ] Docker VM has internet (ping 8.8.8.8)

---

## Step 8: Verify — The Family Test

### Internet
- [ ] Reconnect phone WiFi → gets 192.168.0.x IP
- [ ] Phone can browse the web
- [ ] **Netflix works on TV** (the real test)

### Homelab
- [ ] SSH to Docker VM: `ssh docker-vm` (Tailscale) or `ssh augusto@192.168.0.10`
- [ ] Pi-hole resolving: `ssh augusto@192.168.0.10 "docker exec pihole dig google.com @127.0.0.1 +short"`
- [ ] Vaultwarden accessible
- [ ] Proxmox web UI: `https://192.168.0.237:8006`
- [ ] OPNsense web UI: `https://192.168.0.1` (from Mac)
- [ ] Tailscale: `tailscale status`

### Announce: "Internet is back!"

- [ ] Note completion time: ________

---

## Rollback (If Anything Goes Wrong)

### Before step 6 (OPNsense LAN still 192.168.1.x):

```bash
# 1. Revert Proxmox config
ssh augusto@192.168.0.237 "sudo cp /etc/network/interfaces.original /etc/network/interfaces && sudo cp /etc/network/interfaces.d/vmbr1.original /etc/network/interfaces.d/vmbr1 && sudo ifreload -a"

# 2. Physical: ISP cable back to TP-Link WAN, switch cable back to Proxmox nic0, unplug nic1
# 3. TP-Link: reboot to restore router mode (if AP mode was applied)
```

### After step 6 (OPNsense LAN already at 192.168.0.x):

1. OPNsense console: Interfaces → LAN → change back to `192.168.1.1/24`, Apply
2. Docker VM: `ip addr del 192.168.0.10/24 dev ens18; ip addr add 192.168.1.10/24 dev ens18; ip route add default via 192.168.1.1`
3. Then do the cable/config revert above

### Nuclear option:

Connect Mac to phone tethering, SSH to VPS, figure it out from there.
