# Pre-NAS Deployment Audit — 2026-02-21

**Context:** Post-OPNsense gateway cutover. Audit of codebase readiness before NAS deployment.

---

## CRITICAL (Blocks NAS deployment)

- [x] **Samba image unmaintained** — Migrated to `justinpatchett/samba` (maintained fork of dperson/samba).
- [x] **DNS architecture doc wrong** — Removed RPi 5 as Pi-hole, updated mobile kit to Beryl AX AdGuard only.

## HIGH (Fix before deployment)

- [x] **Syncthing pinned to 1.27** — Updated to 2.0.14. Fresh deployment, no migration risk (LevelDB→SQLite change only affects upgrades).
- [x] **Network topology doc stale** — Fixed RPi 5 location (Mobile→Fixed), corrected IPs, updated diagrams.
- [ ] **OPNsense DHCP static mapping for NAS** — Add MAC → 192.168.0.12 reservation (requires NAS MAC, do on deployment day).
- [ ] **Headscale pre-assignment** — Verify NAS Tailscale IP `100.64.0.12` reserved in Headscale before enrollment.

## MEDIUM (Nice to fix)

- [x] **NAS deployment plan post-cutover update** — Updated OPNsense access (SSH tunnel), repo clone URL (Soft Serve), DNS nameserver (Pi-hole).
- [ ] **OPNsense old config references** — `/conf/config.xml` has `192.168.1.126` and `192.168.1.250` entries from old subnet.
- [x] **README.md outdated** — Updated service counts, architecture diagram, status table. Also updated `docs/services.md` with Watchtower, Caddy VPS, headscale-backup.
- [ ] **Missing `.env` files for NAS** — `.env.example` templates exist, actual `.env` files needed before deployment.

## LOW (Cosmetic/future)

- [ ] **Pre-cutover session docs** — `docs/sessions/` has historical 192.168.1.x references. Add "PRE-CUTOVER" headers.
- [ ] **RPi 5 NVMe HAT** — Future upgrade noted in `docs/hardware.md`.

## Clean Results

- No stale 192.168.1.x IPs in active config files
- Ansible inventory has NAS host defined correctly
- SSH config has `nas` alias
- Docker compose files for NAS exist in `docker/fixed/nas/`
- Pi-hole DNS entries need NAS added (post-deployment)
