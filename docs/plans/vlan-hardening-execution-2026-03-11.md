# VLAN Hardening Execution Checklist

**Date**: 2026-03-11
**Status**: Pending (requires home access)
**Prerequisite**: OPNsense web UI via SSH tunnel or LAN
**Reference**: [vlan-design.md](../guides/vlan-design.md)
**Risk level**: Medium — incorrect rules can isolate cameras or break guest WiFi

## Current State

- VLAN interfaces created: IOT (vtnet1.10, 192.168.10.1/24), GUEST (vtnet1.20, 192.168.20.1/24)
- DHCP configured per VLAN
- MokerLink switch trunks configured (P1, P7 trunk; P6 IoT access)
- TP-Link PoE switch connected to MokerLink P6 (IoT VLAN)
- **Firewall rules: NOT applied** — VLANs exist but have no rules (default deny)
- **Cameras: Still on Management VLAN** (192.168.0.110, .111, .101) — not yet moved to IoT VLAN

## Before You Start

1. **Open OPNsense web UI** via SSH tunnel:
   ```bash
   ssh -L 8443:192.168.0.1:443 proxmox
   # Browser: https://localhost:8443
   ```

2. **Backup OPNsense config** (System → Configuration → Backups → Download):
   Save as `config-pre-vlan-rules-YYYYMMDD.xml`

3. **Have a rollback plan**: If you lose access, connect directly to MokerLink P8 (Management VLAN) via Ethernet from MacBook. OPNsense LAN is always reachable at 192.168.0.1.

---

## Phase 1: Create Aliases

Aliases simplify rule management. Create these before writing rules.

**Firewall → Aliases → Add:**

| Name | Type | Content | Description |
|------|------|---------|-------------|
| `RFC1918` | Network(s) | `10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16` | All private networks |
| `Cameras` | Host(s) | `192.168.10.101, 192.168.10.102, 192.168.10.103` | IoT cameras |
| `Frigate_Host` | Host(s) | `192.168.0.10` | Docker VM (Frigate) |
| `PiHole_DNS` | Host(s) | `192.168.0.10` | Docker VM (Pi-hole) |

**Note:** OPNsense may already have a built-in RFC1918 alias — check before creating.

**Apply changes** after adding aliases.

---

## Phase 2: LAN (Management) Rules

LAN should already have a default "allow all" rule. Verify:

**Firewall → Rules → LAN:**

| # | Action | Source | Dest | Port | Protocol | Description |
|---|--------|--------|------|------|----------|-------------|
| 1 | Pass | LAN net | any | any | any | Default allow all |

This should exist from the initial OPNsense setup. If not, create it.

**Anti-lockout rule**: OPNsense has a built-in anti-lockout rule (System → Settings → Administration). Ensure it's enabled — prevents accidentally blocking web UI access.

---

## Phase 3: IoT VLAN Rules

**Firewall → Rules → IOT:**

Rules are evaluated **top to bottom, first match wins**. Order matters.

| # | Action | Protocol | Source | Dest | Port | Description |
|---|--------|----------|--------|------|------|-------------|
| 1 | Pass | TCP/UDP | IOT net | PiHole_DNS | 53 | Allow DNS to Pi-hole |
| 2 | Pass | UDP | IOT net | PiHole_DNS | 123 | Allow NTP |
| 3 | Pass | TCP | Cameras | Frigate_Host | 5000 | Cameras → Frigate RTSP |
| 4 | Block | any | IOT net | RFC1918 | any | Block all private networks |
| 5 | Block | any | IOT net | any | any | Block internet (default deny) |

### How to create each rule:

**Firewall → Rules → IOT → Add (+ icon at top for first position):**

For each rule:
- **Action**: Pass or Block
- **Interface**: IOT
- **Direction**: in
- **TCP/IP Version**: IPv4
- **Protocol**: as specified
- **Source**: Select alias or "IOT net"
- **Destination**: Select alias or "any"
- **Destination port range**: as specified (53, 123, 5000, or "any")
- **Description**: as specified
- **Log**: Enable on Block rules (helps debugging)

**Click Apply Changes** after adding all rules.

### Verification:

```
Expected behavior:
✓ IoT device → Pi-hole DNS (53)     = PASS
✓ Camera → Frigate (5000)            = PASS
✗ IoT device → internet              = BLOCKED
✗ IoT device → NAS                   = BLOCKED
✗ IoT device → Docker VM (other)     = BLOCKED
✗ Camera → camera                    = BLOCKED (no IoT→IoT rule)
```

---

## Phase 4: Guest VLAN Rules

**Firewall → Rules → GUEST:**

| # | Action | Protocol | Source | Dest | Port | Description |
|---|--------|----------|--------|------|------|-------------|
| 1 | Pass | TCP/UDP | GUEST net | PiHole_DNS | 53 | Allow DNS to Pi-hole |
| 2 | Block | any | GUEST net | RFC1918 | any | Block all private networks |
| 3 | Pass | TCP | GUEST net | any | 80 | Allow HTTP |
| 4 | Pass | TCP | GUEST net | any | 443 | Allow HTTPS |
| 5 | Block | any | GUEST net | any | any | Block all else |

**Apply Changes.**

### Verification:

```
Expected behavior:
✓ Guest → Pi-hole DNS (53)           = PASS
✓ Guest → internet HTTP/HTTPS        = PASS
✗ Guest → LAN devices                = BLOCKED
✗ Guest → Docker VM                  = BLOCKED
✗ Guest → NAS                        = BLOCKED
✗ Guest → SSH anywhere               = BLOCKED
```

---

## Phase 5: Move Cameras to IoT VLAN

**This is the disruptive step.** Cameras will lose connectivity until re-IPed.

### 5a. Verify physical path

Cameras are connected via:
```
Camera → TP-Link PoE Switch → MokerLink P6 (VLAN 10 access) → Proxmox P1 (trunk)
```

This means cameras **already receive VLAN 10 at Layer 2**. They just need VLAN 10 IPs.

### 5b. Reserve static IPs in OPNsense DHCP

**Services → DHCPv4 → IOT → Static Mappings:**

| MAC Address | IP | Hostname | Description |
|-------------|-----|----------|-------------|
| (from cam 1) | 192.168.10.101 | front-door | Reolink front door |
| (from cam 2) | 192.168.10.102 | back-yard | Reolink back yard |

**Get MAC addresses** from current DHCP leases:
- Services → DHCPv4 → Leases → find 192.168.0.110 and .111

**Tapo C110** (192.168.0.101) is WiFi — it's on VLAN 1 via the TP-Link AP (HomeNet SSID). Moving it to IoT VLAN requires either:
- A separate IoT SSID on the AP (needs OpenWrt or multi-SSID support)
- Leave it on Management VLAN for now (still accessible to Frigate)

### 5c. Re-IP Reolink cameras

**Option A: Via Reolink app/web UI** (simplest)
1. Access each camera's web UI (192.168.0.110, .111)
2. Settings → Network → change IP to 192.168.10.101/.102, gateway 192.168.10.1, DNS 192.168.0.10
3. Camera reboots on new IP

**Option B: Let DHCP handle it**
1. Cameras already connected to PoE switch on VLAN 10
2. If cameras use DHCP, they'll get 192.168.10.x from OPNsense IOT DHCP
3. Static mapping ensures they always get .101/.102

### 5d. Update Frigate config

After cameras move to 192.168.10.x, update Frigate:

```bash
ssh docker-vm
# Edit Frigate config
nano /opt/homelab/repo/docker/fixed/docker-vm/security/frigate/config.yml
```

Change camera IPs:
```yaml
cameras:
  front_door:
    ffmpeg:
      inputs:
        - path: rtsp://user:pass@192.168.10.101:554/...   # was 192.168.0.110
  back_yard:
    ffmpeg:
      inputs:
        - path: rtsp://user:pass@192.168.10.102:554/...   # was 192.168.0.111
  indoor:
    # Leave as-is if Tapo stays on Management VLAN
```

Restart Frigate: `docker restart frigate`

### 5e. Verify camera feeds

- Check Frigate UI (`taguato.cronova.dev`) — all streams should reconnect
- Check Firewall → Log Files → Live View — camera traffic should match IoT rules
- Verify no internet access: Firewall logs should show BLOCKED for camera → WAN

---

## Phase 6: Test Everything

### From Management VLAN (MacBook on LAN):
```bash
# Should work
ping 192.168.0.1        # OPNsense
ping 192.168.0.10       # Docker VM
curl https://jara.cronova.dev  # HA
```

### From IoT VLAN (camera perspective):
Check OPNsense Firewall → Live Log, filter by IOT interface:
- DNS queries to 192.168.0.10:53 → PASS ✓
- RTSP to 192.168.0.10:5000 → PASS ✓
- Anything else → BLOCK ✓

### From Guest VLAN:
Connect a phone to Guest WiFi (if configured) or test later:
- `nslookup google.com` → should resolve (DNS passes) ✓
- `curl https://google.com` → should work (443 passes) ✓
- `ping 192.168.0.10` → should fail (RFC1918 blocked) ✓

---

## Post-Execution

- [ ] Update `security-hardening.md`: change "IoT VLAN (10): Configured, rules pending" → active
- [ ] Update `vlan-design.md`: fix Phase 1 checklist if needed, mark Phase 3 done
- [ ] Update Frigate config in repo if camera IPs changed
- [ ] Update Uptime Kuma monitors if camera IPs changed
- [ ] Take OPNsense config backup (post-rules)

## Rollback

If something breaks:
1. **Cameras offline**: Check Firewall → Rules → IOT — ensure rule 3 (Cameras → Frigate) exists and is above the Block rules
2. **Guest WiFi broken**: Check GUEST rules — DNS (rule 1) must be above RFC1918 block (rule 2)
3. **Nuclear option**: Firewall → Rules → IOT/GUEST → delete all rules → Apply. Returns to default deny (safe but cameras offline)
4. **Restore config**: System → Configuration → Backups → restore pre-rules XML
