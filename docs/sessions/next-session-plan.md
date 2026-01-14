# Next Session Plan

## Focus: High + Medium Priority Items

### High Priority

- [ ] **Document NAS hardware specs** - Get CPU, RAM, storage details for Old PC
- [ ] **Fixed homelab docker-compose files** - Create configs for Docker VM services
- [ ] **VPS RAM audit** - Document actual memory usage, evaluate if upgrade needed
- [ ] **Certificate strategy docs** - Document Caddy auto-SSL + Tailscale HTTPS flow

### Medium Priority

- [ ] **VLAN documentation** - OPNsense IoT isolation strategy
- [ ] **Monitoring alerts** - Configure Uptime Kuma checks + ntfy notifications
- [ ] **Backup test procedure** - Create runbook to validate DR works
- [ ] **Port 8080 conflict** - Reassign qBittorrent or Pi-hole alt port

## Suggested Order

1. NAS hardware specs (quick, unblocks storage planning)
2. Fixed homelab docker-compose (big task, core infrastructure)
3. VLAN documentation (security, pairs with fixed homelab)
4. Backup test procedure (validate DR runbook)
5. Monitoring alerts (operational readiness)
6. Certificate strategy (document existing Caddy setup)
7. VPS RAM audit (do after VPS deployed)
8. Port 8080 conflict (resolve during deployment)

## Prerequisites

- [ ] Access to Old PC to get specs
- [ ] Decide on Docker VM service list (finalize from services.md)

## Notes

- Fixed homelab docker-compose depends on NAS specs (for backup mounts)
- VLAN strategy depends on understanding home network layout
- VPS RAM audit requires actual deployment first
