# OPNsense Gateway Cutover Plan

**Date:** 2026-02-08
**Goal:** Replace TP-Link AX50 as internet gateway with OPNsense. TP-Link becomes AP only.
**Constraint:** Zero Netflix downtime. Family, Sunday, minimal disruption.

---

## Current Topology

```
ISP coax → ARRIS TG2482 (bridge mode) → TP-Link AX50 (public IP, router/DHCP)
                                              ↓
                                           Switch
                                          ↓      ↓
                                  Proxmox (oga)   Wired devices
                                  192.168.0.237
                                    ↓         ↓
                            OPNsense VM    Docker-vm
                         WAN: 192.168.0.x  192.168.1.10
                         LAN: 192.168.1.x
```

## Target Topology

```
ISP coax → ARRIS TG2482 (bridge mode)
                ↓ ethernet
         Proxmox NIC 1 (vmbr0) → OPNsense WAN (public IP via DHCP)
         Proxmox NIC 2 (vmbr1) → OPNsense LAN (192.168.0.1/24)
                                        ↓
                                     Switch
                                    ↓      ↓
                           TP-Link AX50    Wired devices
                           (AP mode)       Docker-vm (192.168.0.10)
                               ↓           NAS (192.168.0.12)
                          WiFi devices
```

## Hardware Details

| Device | Role (current) | Role (target) |
|--------|---------------|---------------|
| ARRIS TG2482 | DOCSIS 3.0 modem (bridge mode already) | Bridge mode (no change) |
| TP-Link AX50 | Router, DHCP, WiFi (holds public IP) | AP mode (WiFi only) |
| OPNsense (VM) | Internal firewall/router | Internet gateway, DHCP, firewall |
| Proxmox (oga) | 2 NICs — nic0 (WAN), nic1 (LAN) | Same |

## Proxmox Network Mapping (verified 2026-02-08)

| Physical NIC | Bridge | MAC | Current state | Cable |
|-------------|--------|-----|---------------|-------|
| `nic0` | `vmbr0` | c8:ff:bf:06:13:f7 | UP | Switch (192.168.0.x network) |
| `nic1` | `vmbr1` | c8:ff:bf:06:13:f8 | **DOWN** | **No cable** |

| VM | ID | net0 | net1 |
|----|-----|------|------|
| OPNsense | 100 | `vmbr0` (WAN) | `vmbr1` (LAN) |
| Docker | 101 | `vmbr1` (LAN only) | — |

**Key findings:**
- `nic1`/`vmbr1` has no physical cable — Docker-vm reaches internet via OPNsense routing (vmbr1 → vmbr0)
- Proxmox management IP (`192.168.0.237/24`) is on `vmbr0` — must migrate to `vmbr1` before cutover
- After cutover: `vmbr0` = WAN (public IP), `vmbr1` = LAN (192.168.0.0/24)

## IP Plan (192.168.0.0/24)

| Device | Current IP | New IP |
|--------|-----------|--------|
| OPNsense LAN | 192.168.1.1 | **192.168.0.1** |
| Docker-vm | 192.168.1.10 | **192.168.0.10** |
| Pi-hole (container) | 192.168.1.10 (host) | **192.168.0.10** (host) |
| Caddy (container) | 192.168.1.10 (host) | **192.168.0.10** (host) |
| Proxmox (oga) mgmt | 192.168.0.237 (on vmbr0) | **192.168.0.237** (moved to vmbr1) |
| TP-Link AX50 | 192.168.0.1 | **192.168.0.2** (AP, static) |
| NAS (planned) | 192.168.1.12 | **192.168.0.12** |
| DHCP range | — | **192.168.0.100–192.168.0.250** |

---

## Phase 1: Prep (Weekday, No Downtime)

### 1a. Document Current State

- [ ] Screenshot TP-Link DHCP reservations
- [ ] Note TP-Link WiFi settings (SSID, password, channel, band)
- [ ] Back up OPNsense config (System → Configuration → Backups)

### 1b. Verify Proxmox Network — DONE

- [x] `nic0`/`vmbr0` = Switch (192.168.0.x), OPNsense WAN (net0)
- [x] `nic1`/`vmbr1` = No cable, OPNsense LAN (net1), Docker-vm (net0)
- [x] Proxmox mgmt: `192.168.0.237/24` on `vmbr0` (needs to move to `vmbr1`)

### 1b2. Stage Proxmox Management IP Migration

Proxmox management must move from `vmbr0` (becomes WAN) to `vmbr1` (becomes LAN).
**Cannot apply until cutover** — `nic1` has no cable, so `vmbr1` has no physical connectivity.

- [ ] Stage target config at `/etc/network/interfaces.cutover` on Proxmox
- [ ] Target config: `vmbr0` = manual (no IP), `vmbr1` = `192.168.0.237/24` gw `192.168.0.1`
- [ ] Applied during Phase 2 after cabling `nic1` to switch

### 1c. Verify OPNsense Settings — DONE

> **Note:** LAN IP change (`192.168.1.1` → `192.168.0.1`) and DHCP setup CANNOT be done during
> prep because OPNsense WAN is currently on `192.168.0.x` (from TP-Link). Having WAN and LAN
> on the same subnet causes routing conflicts. These must happen during Phase 2, after the
> cable swap gives WAN a public IP.

**Verified (prep):**
- [x] WAN interface: DHCP (IPv4 + IPv6), Block private/bogon networks enabled
- [x] Firewall: LAN → any allow-all (IPv4 + IPv6) rules exist
- [x] NAT: Automatic outbound NAT, covers GUEST/IOT/LAN networks
- [x] Existing interfaces: GUEST and IOT already configured

**Deferred to Phase 2 (after cable swap):**
- [ ] Change LAN interface: `192.168.1.1/24` → `192.168.0.1/24`
- [ ] Set up DHCP server on LAN:
  - Range: `192.168.0.100` – `192.168.0.250`
  - DNS server: `192.168.0.10` (Pi-hole on Docker-vm)
  - Gateway: `192.168.0.1`
- [ ] Add DHCP reservations:
  - Docker-vm: `192.168.0.10` (MAC: `BC:24:11:A8:E9:C5`)
  - NAS (future): `192.168.0.12`
  - TP-Link AP: `192.168.0.2`

### 1d. Re-IP Docker-vm (brief homelab downtime)

- [ ] Change static IP: `192.168.1.10` → `192.168.0.10`
- [ ] Update gateway: `192.168.1.1` → `192.168.0.1`
- [ ] Update DNS resolver to `192.168.0.1` or `127.0.0.1`

### 1e. Update Homelab Configs

Files referencing `192.168.1.x` that need updating:

**Compose files:**
- [ ] `docker/fixed/docker-vm/security/docker-compose.yml` — NFS mount IP, Restic repository URL
- [ ] `docker/fixed/docker-vm/networking/caddy/` — Caddy bind address
- [ ] `docker/fixed/nas/storage/docker-compose.yml` — NFS exports
- [ ] `docker/fixed/nas/backup/docker-compose.yml` — REST server references

**Infrastructure:**
- [ ] `ansible/inventory.yml` — Docker-vm host IP, local_network var
- [ ] `~/.ssh/config` — not affected (uses Tailscale IPs)
- [ ] Pi-hole TOML — `nas.home` DNS entry (192.168.1.12 → 192.168.0.12)
- [ ] Caddy config on Docker-vm — TLS bindings reference LAN IP
- [ ] NAS deployment plan — all 192.168.1.x references

**Documentation:**
- [ ] `docs/nas-deployment-plan.md`
- [ ] `docs/network-topology.md`
- [ ] `docs/vlan-design.md`

### 1f. Prepare TP-Link for AP Mode

- [ ] Log into TP-Link admin (192.168.0.1)
- [ ] Note exact WiFi settings: SSID, password, security type, channel, band
- [ ] Locate AP mode setting (Operation Mode → Access Point)
- [ ] **DON'T switch yet** — just know where the setting is
- [ ] Assign static IP `192.168.0.2` for management after AP mode

---

## Phase 2: Cutover (~15 Min Downtime)

**Do this when nobody is streaming. Ideally early morning.**

> **Note:** ARRIS TG2482 is already in bridge mode — no modem changes needed.
> Two cable changes + OPNsense LAN re-IP + Docker-vm re-IP required.
> Downtime is longer than originally estimated because LAN config can't be prepped
> (WAN and LAN would conflict on same 192.168.0.0/24 subnet).

### Step-by-step

1. **Announce:** "Internet will be down for 15 minutes"
2. **Cable changes (two operations):**
   - **Cable A:** Unplug ISP ethernet from TP-Link WAN port → plug into Proxmox `nic0`
   - **Cable B:** Connect Proxmox `nic1` to the switch (currently has no cable — use the cable that was going from switch to `nic0`, or a new one)
3. **Apply Proxmox network config:**
   ```bash
   ssh proxmox "sudo cp /etc/network/interfaces.cutover /etc/network/interfaces && sudo cp /etc/network/interfaces.d/vmbr1.cutover /etc/network/interfaces.d/vmbr1 && sudo ifreload -a"
   ```
   This moves Proxmox management IP from `vmbr0` (now WAN) to `vmbr1` (now LAN).
4. **Verify OPNsense gets public IP:**
   - Access OPNsense web UI (from Mac on WiFi, `https://192.168.1.1` — still LAN IP until step 6)
   - Check dashboard → WAN interface → should show public IP via DHCP from ARRIS
5. **Switch TP-Link to AP mode:**
   - Access TP-Link admin via WiFi
   - Switch to AP mode
   - Set static IP to `192.168.0.2`
   - Connect TP-Link LAN port to switch (NOT WAN port)
6. **Configure OPNsense LAN (web UI at `https://192.168.1.1`):**
   - Interfaces > LAN: change `192.168.1.1/24` → `192.168.0.1/24`, Save, Apply
   - *(Mac loses access to OPNsense — reconnect at `https://192.168.0.1` after WiFi reconnects)*
   - Services > DHCPv4 > LAN: enable, range `192.168.0.100`–`192.168.0.250`
   - Set DNS server: `192.168.0.10`, gateway: `192.168.0.1`
   - Add static mappings: Docker-vm `192.168.0.10` (MAC `BC:24:11:A8:E9:C5`)
7. **Re-IP Docker-vm:**
   ```bash
   ssh docker-vm  # via Tailscale (may still work briefly) or Proxmox qm terminal
   # Change static IP, gateway, DNS
   ```
   See Phase 1d for detailed commands.
8. **Test from phone:**
   - Disconnect/reconnect WiFi
   - Should get `192.168.0.x` IP
   - Open browser, check internet
9. **Test Netflix on TV**
10. **Verify homelab:**
    - SSH to docker-vm (via Tailscale or `192.168.0.10`)
    - Check Pi-hole resolving
    - Check Tailscale status
    - Verify Proxmox web UI at `https://192.168.0.237:8006`

---

## Phase 3: Verify (15 Min After Cutover)

- [ ] All WiFi devices have `192.168.0.x` IPs
- [ ] Netflix works on TV
- [ ] YouTube works on phone
- [ ] SSH to docker-vm works (Tailscale + local)
- [ ] Pi-hole resolving DNS (check `pihole` logs)
- [ ] Tailscale connected on all nodes
- [ ] Vaultwarden accessible
- [ ] Proxmox web UI accessible (`https://192.168.0.237:8006` or via tunnel)

---

## Rollback Plan (2 Minutes)

If anything breaks during cutover:

1. Revert Proxmox network config:
   ```bash
   ssh proxmox "sudo cp /etc/network/interfaces.original /etc/network/interfaces && sudo cp /etc/network/interfaces.d/vmbr1.original /etc/network/interfaces.d/vmbr1 && sudo ifreload -a"
   ```
2. Unplug ISP cable from Proxmox `nic0` → plug back into TP-Link WAN port
3. Reconnect Proxmox `nic0` to switch (restore original cable)
4. Switch TP-Link back to router mode (reboot restores if needed)
5. ARRIS stays in bridge mode (no change needed)
6. Everything back to normal — family resumes Netflix

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| OPNsense doesn't get public IP | No internet | Low | Plug cable back into TP-Link (1 min) |
| WiFi devices don't reconnect | No WiFi | Very low | Same SSID/password = auto-reconnect |
| OPNsense DHCP issues | Devices get no IPs | Low | Rollback to TP-Link |
| Docker-vm unreachable | Homelab only | Low | Tailscale fallback |
| TV loses Netflix | Family angry | Very low | Quick rollback, test early morning |

---

## Critical Detail

**Keep the same SSID and WiFi password** on TP-Link AP mode. Devices won't even notice the switch — they'll reconnect automatically and just get a new gateway IP via DHCP.

---

## Post-Cutover Tasks

- [ ] Verify OPNsense firewall rules are working
- [ ] Set up UPnP/NAT-PMP if needed for gaming/streaming
- [ ] Configure OPNsense DNS (forward to Pi-hole or use Unbound)
- [ ] Set up OPNsense automatic backup
- [ ] Update Uptime Kuma monitors
- [ ] Plan VLAN setup (IoT VLAN for cameras: 192.168.10.x)
