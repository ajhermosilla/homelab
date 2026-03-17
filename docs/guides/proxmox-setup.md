# Proxmox VE Setup Guide

Mini PC configuration for running OPNsense router and Docker VM.

## Hardware Requirements

| Component | Spec | Notes |
|-----------|------|-------|

| CPU | Intel N150 | VT-x/VT-d enabled |
| RAM | 12GB | ~1GB host + 2GB OPNsense + 9GB Docker |
| Storage | 512GB SSD | VMs + ISO storage |
| NIC | Dual port | nic0/vmbr0 (WAN) + nic1/vmbr1 (LAN) |

---

## Installation

### 1. Download Proxmox VE

```bash
# Download from proxmox.com
# Latest stable: Proxmox VE 8.x
# Create bootable USB with balenaEtcher or Rufus
```

### 2. Boot from USB

- Enable UEFI boot in BIOS
- Disable Secure Boot
- Boot from Proxmox installer USB

### 3. Installation Wizard

| Setting | Value |
|---------|-------|

| Target Disk | 512GB SSD |
| Country | Paraguay |
| Timezone | America/Asuncion |
| Keyboard | us |
| Admin Password | (strong password) |
| Email | <augusto@cronova.dev> |
| Hostname | pve.cronova.local |
| Management IP | 192.168.0.237/24 |
| Gateway | 192.168.0.1 (temporary) |
| DNS | 1.1.1.1 |

**Note:** Initial IP is temporary. After OPNsense setup, DHCP will assign static IPs.

---

## Post-Installation

### 1. Access Web UI

```yaml
https://192.168.0.237:8006
Username: root
Password: (set during install)
```

### 2. Remove Subscription Notice

```bash
# SSH into Proxmox
ssh root@192.168.0.237

# Edit sources list
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Add no-subscription repo
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Update
apt update && apt full-upgrade -y
```

### 3. Enable IOMMU (optional, for future PCI passthrough)

```bash
# Edit GRUB config
nano /etc/default/grub

# Change line to:
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"

# Update GRUB
update-grub

# Add VFIO modules
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

# Reboot
reboot
```

### 4. Verify IOMMU

```bash
dmesg | grep -e DMAR -e IOMMU
# Should show: DMAR: IOMMU enabled
```

---

## Network Configuration

### Identify NICs

```bash
ip link show
# Example:
# enp1s0 - WAN (vmbr0 bridge)
# enp2s0 - LAN (vmbr1 bridge)
```

### Edit Network Config

```bash
nano /etc/network/interfaces
```

```bash
auto lo
iface lo inet loopback

# WAN Bridge (OPNsense WAN - public IP via DHCP)
auto vmbr0
iface vmbr0 inet manual
    bridge-ports enp1s0
    bridge-stp off
    bridge-fd 0

# LAN Bridge (OPNsense LAN + Docker VM + Proxmox mgmt)
auto vmbr1
iface vmbr1 inet static
    address 192.168.0.237/24
    gateway 192.168.0.1
    bridge-ports enp2s0
    bridge-stp off
    bridge-fd 0
```

```bash
# Apply changes
ifreload -a
```

---

## Storage Configuration

### Default Storage

| Storage | Path | Content |
|---------|------|---------|

| local | /var/lib/vz | ISO images, CT templates |
| local-lvm | LVM thin pool | VM disks |

### Upload ISOs

1. **Datacenter > Storage > local > ISO Images**
2. Upload:
   - OPNsense-24.x-amd64.iso
   - debian-12-amd64.iso (for Docker VM)

---

## Create OPNsense VM

### 1. Create VM

#### General

| Setting | Value |
|---------|-------|

| VM ID | 100 |
| Name | opnsense |

#### OS

| Setting | Value |
|---------|-------|

| ISO | OPNsense-24.x-amd64.iso |
| Type | Other |

#### System

| Setting | Value |
|---------|-------|

| Machine | q35 |
| BIOS | OVMF (UEFI) |
| Add EFI Disk | Yes |
| SCSI Controller | VirtIO SCSI |

#### Disks

| Setting | Value |
|---------|-------|

| Bus | SCSI |
| Size | 20 GB |
| Storage | local-lvm |
| Discard | Enabled |

#### CPU

| Setting | Value |
|---------|-------|

| Cores | 2 |
| Type | host |

#### Memory

| Setting | Value |
|---------|-------|

| Memory | 2048 MB |

**Network:**

| Setting | Value |
|---------|-------|

| Bridge | vmbr0 |
| Model | VirtIO |

### 2. Add Second NIC (WAN)

The OPNsense VM needs two bridged NICs — one for WAN (vmbr0) and one for LAN (vmbr1).
The first NIC (vmbr0) was added during VM creation. Now add the second:

#### VM > Hardware > Add > Network Device

| Setting | Value |
|---------|-------|

| Bridge | vmbr1 |
| Model | VirtIO |

### 3. VM Options

#### VM > Options

| Setting | Value |
|---------|-------|

| Start at boot | Yes |
| Start/Shutdown order | 1 |
| Startup delay | 0 |

### 4. Install OPNsense

See `docs/guides/opnsense-setup.md` for installation steps.

---

## Create Docker VM

### 1. Create VM

#### General

| Setting | Value |
|---------|-------|

| VM ID | 101 |
| Name | docker |

#### OS

| Setting | Value |
|---------|-------|

| ISO | debian-13-amd64.iso |
| Type | Linux |
| Version | 6.x - 2.6 Kernel |

#### System

| Setting | Value |
|---------|-------|

| Machine | q35 |
| BIOS | OVMF (UEFI) |
| Add EFI Disk | Yes |
| SCSI Controller | VirtIO SCSI |

#### Disks

| Setting | Value |
|---------|-------|

| Bus | SCSI |
| Size | 100 GB |
| Storage | local-lvm |
| Discard | Enabled |

#### CPU

| Setting | Value |
|---------|-------|

| Cores | 2 |
| Type | host |

#### Memory

| Setting | Value |
|---------|-------|

| Memory | 9216 MB |
| Ballooning | Disabled |

**Network:**

| Setting | Value |
|---------|-------|

| Bridge | vmbr1 |
| Model | VirtIO |

### 2. VM Options

#### VM > Options

| Setting | Value |
|---------|-------|

| Start at boot | Yes |
| Start/Shutdown order | 2 |
| Startup delay | 30 |

### 3. Install Debian

1. Boot from ISO
2. Graphical install (or text)
3. Hostname: `docker`
4. Domain: `cronova.local`
5. Root password: (set strong password)
6. User: `augusto`
7. Partitioning: Guided - entire disk
8. Software: SSH server, standard system utilities only
9. Install GRUB to disk

### 4. Post-Install Configuration

```bash
# SSH into Docker VM
ssh augusto@192.168.0.10

# Become root
su -

# Update system
apt update && apt upgrade -y

# Install Docker
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
usermod -aG docker augusto

# Enable Docker service
systemctl enable docker

# Install useful tools
apt install -y vim git htop ncdu nfs-common

# Configure static IP (if not using DHCP reservation)
# Edit /etc/network/interfaces
```

---

**Note:** OpenClaw runs on a dedicated Raspberry Pi 5 (not a Proxmox VM). See `docs/architecture/hardware.md` for RPi 5 specs and `ansible/playbooks/openclaw.yml` for automated setup.

---

## Intel QuickSync (Hardware Acceleration)

For Frigate and Jellyfin transcoding.

### Enable on Proxmox Host

```bash
# Verify Intel GPU
ls -la /dev/dri
# Should show: card0, renderD128

# Check GPU
lspci | grep -i vga
```

### Pass through to Docker VM

#### Method 1: Device Passthrough

Edit VM config:

```bash
nano /etc/pve/qemu-server/101.conf

# Add line:
args: -device vfio-pci,host=00:02.0
```

#### Method 2: LXC Container (Alternative)

If using LXC instead of VM:

```bash
# Edit container config
nano /etc/pve/lxc/101.conf

# Add:
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
```

### Verify in Docker VM

```bash
ls -la /dev/dri
# Should show renderD128

# Install vainfo
apt install -y vainfo
vainfo
# Should show Intel QuickSync capabilities
```

---

## Backup Configuration

### Enable VM Backups

#### Datacenter > Backup > Add

| Setting | Value |
|---------|-------|

| Storage | local |
| Schedule | Daily 03:00 |
| Selection Mode | Include selected VMs |
| VMs | 100 (opnsense), 101 (docker) |
| Mode | Snapshot |
| Compression | ZSTD |
| Retention | Keep last 7 |

### Manual Backup

```bash
# Backup specific VM
vzdump 100 --storage local --compress zstd

# List backups
ls /var/lib/vz/dump/
```

---

## Monitoring

### Enable Email Alerts

#### Datacenter > Options > Email from address

- Set to: `<pve@cronova.dev>`

#### User > root > Email

- Set to: `<augusto@cronova.dev>`

### System Metrics

Available in Proxmox web UI:

- CPU usage
- Memory usage
- Network I/O
- Disk I/O

### Integration with Uptime Kuma

Add Proxmox health check:

- Type: HTTP
- URL: <https://192.168.0.237:8006>
- Expected: 200

---

## Verification Checklist

### Proxmox Host

- [ ] Proxmox VE installed and accessible
- [ ] IOMMU enabled and verified
- [ ] Network bridge (vmbr0) configured
- [ ] WAN NIC identified for vmbr0 bridge
- [ ] ISOs uploaded

### OPNsense VM

- [ ] VM created with correct resources
- [ ] Dual bridged NICs configured (vmbr0 WAN, vmbr1 LAN)
- [ ] Boots successfully
- [ ] See `docs/guides/opnsense-setup.md` for configuration

### Docker VM

- [ ] VM created with 9GB RAM, 100GB disk
- [ ] Debian 13 (trixie) installed
- [ ] Docker and docker-compose installed
- [ ] User added to docker group
- [ ] NFS client installed
- [ ] Intel QuickSync accessible (if needed)

### Backups

- [ ] Automated backups scheduled
- [ ] Test restore performed

---

## Resource Summary

| VM | vCPU | RAM | Disk | Purpose |
|----|------|-----|------|---------|

| OPNsense | 2 | 2GB | 20GB | Router/Firewall |
| Docker | 2 | 9GB | 100GB | All containers |
| **Total** | 4 | 11GB | 120GB | |
| **Host Reserve** | - | ~1GB | 392GB | Proxmox + buffers |

---

## Troubleshooting

### Cannot Access Web UI

```bash
# Check if Proxmox is running
systemctl status pveproxy

# Check IP address
ip addr show vmbr0

# Restart networking
systemctl restart networking
```

### IOMMU Not Working

```bash
# Verify BIOS settings
# - VT-d: Enabled
# - IOMMU: Enabled

# Check kernel parameters
cat /proc/cmdline | grep iommu
```

### VM Won't Start

```bash
# Check VM status
qm status 100

# View VM config
qm config 100

# Start with debug
qm start 100 --debug
```

---

## Related Documentation

- `docs/guides/opnsense-setup.md` - OPNsense configuration
- `docs/guides/vlan-design.md` - Network segmentation
- `docs/guides/nfs-setup.md` - NFS for Frigate recordings
- `docs/architecture/hardware.md` - Hardware specifications
