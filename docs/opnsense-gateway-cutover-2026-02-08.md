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
| Proxmox (oga) | 2 NICs — NIC 1 (WAN), NIC 2 (LAN) | Same |

## IP Plan (192.168.0.0/24)

| Device | Current IP | New IP |
|--------|-----------|--------|
| OPNsense LAN | 192.168.1.1 | **192.168.0.1** |
| Docker-vm | 192.168.1.10 | **192.168.0.10** |
| Pi-hole (container) | 192.168.1.10 (host) | **192.168.0.10** (host) |
| Caddy (container) | 192.168.1.10 (host) | **192.168.0.10** (host) |
| Proxmox (oga) mgmt | 192.168.0.237 | **192.168.0.237** (no change) |
| TP-Link AX50 | 192.168.0.1 | **192.168.0.2** (AP, static) |
| NAS (planned) | 192.168.1.12 | **192.168.0.12** |
| DHCP range | — | **192.168.0.100–192.168.0.250** |

---

## Phase 1: Prep (Weekday, No Downtime)

### 1a. Document Current State

- [ ] Screenshot TP-Link DHCP reservations
- [ ] Note TP-Link WiFi settings (SSID, password, channel, band)
- [ ] Back up OPNsense config (System → Configuration → Backups)

### 1b. Verify Proxmox Network

- [ ] Confirm which bridge maps to which NIC (`vmbr0`/`vmbr1`)
- [ ] Confirm OPNsense WAN is on NIC 1 (currently facing ARRIS/TP-Link)
- [ ] Confirm OPNsense LAN is on NIC 2 (facing switch)
- [ ] Verify Proxmox management IP is on NIC 2 / LAN side

### 1c. Configure OPNsense (via web UI, no impact yet)

- [ ] Change LAN interface: `192.168.1.1/24` → `192.168.0.1/24`
- [ ] Set up DHCP server on LAN:
  - Range: `192.168.0.100` – `192.168.0.250`
  - DNS server: `192.168.0.10` (Pi-hole on Docker-vm)
  - Gateway: `192.168.0.1`
- [ ] Add DHCP reservations:
  - Docker-vm: `192.168.0.10`
  - NAS (future): `192.168.0.12`
  - TP-Link AP: `192.168.0.2`
- [ ] WAN interface: set to DHCP (will get public IP from ARRIS in bridge mode)
- [ ] Firewall: ensure LAN → WAN allow-all outbound rule exists (default)
- [ ] NAT: ensure outbound NAT is set to automatic

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

## Phase 2: Cutover (Sunday Morning, ~5 Min Downtime)

**Do this when nobody is streaming. Ideally early morning.**

> **Note:** ARRIS TG2482 is already in bridge mode — no modem changes needed.
> We're just moving the cable from TP-Link to Proxmox and switching TP-Link to AP mode.

### Step-by-step

1. **Announce:** "Internet will be down for 5 minutes"
2. **Cable change:**
   - Unplug ethernet from TP-Link WAN port
   - Plug into Proxmox NIC 1 (OPNsense WAN)
3. **Switch TP-Link to AP mode:**
   - Access TP-Link admin (still on old IP briefly via WiFi)
   - Switch to AP mode
   - Set static IP to `192.168.0.2`
   - Connect TP-Link LAN port to switch (NOT WAN port)
4. **Verify OPNsense gets public IP:**
   - Check OPNsense dashboard → WAN interface
   - Should show public IP via DHCP from ARRIS
5. **Test from phone:**
   - Disconnect/reconnect WiFi
   - Should get `192.168.0.x` IP
   - Open browser, check internet
6. **Test Netflix on TV**
7. **Verify homelab:**
   - SSH to docker-vm
   - Check Pi-hole resolving
   - Check Tailscale status

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

1. Unplug ISP cable from Proxmox NIC 1
2. Plug back into TP-Link WAN port
3. Switch TP-Link back to router mode (reboot restores if needed)
4. ARRIS stays in bridge mode (no change needed)
5. Everything back to normal — family resumes Netflix

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
