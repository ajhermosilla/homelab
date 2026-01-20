# Beryl AX - Tailscale Persistence Fix

**Date:** 2026-01-19
**Implemented:** 2026-01-20
**Status:** Complete - tested and working
**Device:** GL.iNet Beryl AX (GL-MT3000)
**Issue:** Tailscale logs out after router reboot

## Problem Description

Tailscale connects successfully when configured via SSH using custom parameters (custom login server, accept routes, etc.), but **logs out completely after every reboot**. The router treats each reconnection as a new device, creating duplicate nodes in Headscale.

### Symptoms

- `tailscale status` shows "Logged out" after reboot
- State file (`/etc/tailscale/tailscaled.state`) exists but doesn't update with auth data
- File stays at ~2.2KB instead of growing to 10-20KB with full auth state
- Each reconnection creates new node identity (node_key changes)
- Connection works fine until reboot - then everything is lost

## Root Cause

**This is a confirmed known issue** with GL.iNet routers when using custom Tailscale configurations.

GL.iNet firmware uses a wrapper script (`/usr/sbin/gl_tailscale`) that manages Tailscale through the GUI. When you run `tailscale up` commands directly via SSH with custom parameters, these settings **are not saved** in GL.iNet's configuration system.

On reboot, the wrapper script restarts Tailscale with only the GUI-configured settings, effectively logging you out and ignoring your custom parameters.

### Why State File Doesn't Update

The tailscaled daemon **is working correctly** - it's the GL.iNet wrapper that's the problem. The daemon never gets a chance to write auth state because it's being managed by the wrapper script, which doesn't preserve SSH-configured settings across reboots.

## Research Sources

- GL.iNet Forum: https://forum.gl-inet.com/t/tailscale-settings-lost-on-reboot/31524
- Multiple users report identical behavior
- Community consensus: Must modify `/usr/sbin/gl_tailscale` script

## The Solution

Modify `/usr/sbin/gl_tailscale` to hardcode your custom `tailscale up` command with all required parameters.

### Implementation Steps

#### 1. First, Fix Current Crash Loop (if applicable)

```bash
# SSH into router
ssh root@192.168.8.1

# Restore clean state file from backup
cp /etc/tailscale/tailscaled.state.old /etc/tailscale/tailscaled.state

# Restart service
/etc/init.d/tailscale restart

# Verify daemon is running
ps | grep tailscale
```

#### 2. Back Up Original Script

```bash
# Back up the original wrapper script
cp /usr/sbin/gl_tailscale /usr/sbin/gl_tailscale.backup

# Verify backup
ls -lh /usr/sbin/gl_tailscale*
```

#### 3. Generate Pre-Auth Key (on VPS)

```bash
# SSH to VPS and generate a reusable pre-auth key
ssh vps
sudo docker exec headscale headscale preauthkeys create \
  --user augusto \
  --reusable \
  --expiration 90d

# Copy the key - you'll need it in step 4
```

#### 4. Modify gl_tailscale Script

```bash
# On Beryl AX, edit the wrapper script
vi /usr/sbin/gl_tailscale

# Find the section that runs 'tailscale up' (typically in start_tailscale function)
# Replace the existing 'tailscale up' command with:

tailscale up \
  --login-server=https://hs.cronova.dev \
  --authkey=<YOUR_PRE_AUTH_KEY> \
  --accept-routes \
  --accept-dns=false \
  --hostname=beryl-ax
```

**Important notes:**
- Replace `<YOUR_PRE_AUTH_KEY>` with the actual key from step 3
- Keep the `--authkey` parameter - this allows automatic re-registration
- Use `--reusable` and long expiration when generating the key
- This hardcodes your configuration into the script

#### 5. Test the Fix

```bash
# Restart Tailscale service
/etc/init.d/tailscale restart

# Check status
tailscale status

# Should show: connected to Headscale

# Test reboot persistence
reboot

# After reboot, SSH back in and check
tailscale status

# Should still show: connected (same node identity)
```

#### 6. Verify on Headscale

```bash
# On VPS, check node list
ssh vps 'sudo docker exec headscale headscale nodes list'

# Should see only ONE beryl-ax node (not duplicates)
# Node key should remain the same after reboot
```

## Alternative: Use GL.iNet GUI

If you only need basic Tailscale features (no custom login server), use the built-in GUI:

1. Web UI: http://192.168.8.1
2. Applications > Tailscale
3. Configure through GUI

**Limitation:** GUI doesn't support custom login servers (Headscale), so this doesn't work for our use case.

## Troubleshooting

### Script modification doesn't persist

- Check if `/usr/sbin/gl_tailscale` is in `/overlay/upper/`
- If in `/rom/`, you need to copy it to `/overlay/upper/usr/sbin/` first

### Still logs out after reboot

- Verify the modified script is actually being called: `which gl_tailscale`
- Check init script calls the right wrapper: `cat /etc/init.d/tailscale`
- Ensure pre-auth key is reusable and not expired

### Can't connect to Headscale

- Check VPS is reachable: `curl -I https://hs.cronova.dev`
- Verify pre-auth key is valid: regenerate if needed
- Check logs: `logread | grep tailscale`

## Documentation Updates

After successful implementation:

- [ ] Update `docs/hardware.md` - note Tailscale persistence fix applied
- [ ] Update `docker/mobile/rpi5/README.md` - reference this guide for Beryl AX setup
- [ ] Test disaster recovery procedure with this configuration

## References

- [GL.iNet Forum - Tailscale Settings Lost](https://forum.gl-inet.com/t/tailscale-settings-lost-on-reboot/31524)
- [Headscale Documentation](https://headscale.net/)
- [Tailscale on OpenWrt](https://tailscale.com/kb/1114/openwrt/)
- This homelab: `docs/hardware.md`, `docker/mobile/rpi5/README.md`

## Implementation Notes (2026-01-20)

**Actual script location:** `/usr/bin/gl_tailscale` (not `/usr/sbin/` as initially documented)

**Backup created:** `/usr/bin/gl_tailscale.backup`

**Line modified:** Near end of script, the `tailscale up` command:
```bash
timeout 10 /usr/sbin/tailscale up --reset --accept-routes $param --timeout 3s --accept-dns=false --login-server=https://hs.cronova.dev --authkey=<KEY> --hostname=beryl-ax > /dev/null
```

**Pre-auth key:** Created 2026-01-20, expires ~2026-04-20 (90 days, reusable)

**Beryl Tailscale IP:** 100.102.244.131

**Test result:** Reboot persistence confirmed - Beryl reconnects automatically to Headscale mesh.

## Completed

- [x] Implement fix (2026-01-20)
- [x] Test reboot persistence
- [ ] Set calendar reminder to regenerate key before 90-day expiration (~April 2026)
