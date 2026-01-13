# Hardware Inventory

## Mobile Homelab

Portable setup for travel/remote work.

| Device                 | Specs                                     | Role                           | Status                               |
| ---------------------- | ----------------------------------------- | ------------------------------ | ------------------------------------ |
| MacBook Air M1         | 16GB RAM, 1TB SSD macOS Sonoma            | Main workstation, Docker host  | Active                               |
| Beryl AX Travel Router | GL-MT3000                                 | Network gateway, VPN endpoint  | Active                               |
| Samsung A13            | Android                                   | USB tethering for connectivity | Active                               |
| Raspberry Pi 5         | 8GB RAM, 32GB SDHC, Official Cooler + PSU | Edge compute, services         | PSU is in transit (Miami → Asunción) |

### Mobile Network Diagram

```
[Internet] <---> [Samsung A13 USB Tether]
                        |
                [Beryl AX Router]
                   /         \
          [MacBook Air]    [RPi 5]
```

---

## Fixed Homelab

Always-on infrastructure at home.

| Device         | Specs   | Role           | Status      |
| -------------- | ------- | -------------- | ----------- |
| Mini PC        | Intel N150, 12GB RAM, 512GB SSD | Primary server | Active      |
| Raspberry Pi 4 | 4GB RAM | TBD            | Active      |
| Old PC         | TBD     | TBD            | Available   |
| Other laptops  | TBD     | TBD            | To document |
| Phones         | TBD     | TBD            | To document |

### Home Network Diagram

```
[Internet] <---> [Router]
                    |
    +---------------+---------------+
    |               |               |
[Mini PC]       [RPi 4]        [Old PC]
```

---

## Notes

- RPi 5 will join mobile kit once it arrives
- Document Old PC specs when convenient
- Consider: UPS for fixed setup, portable battery for mobile
