# KVM course — from foundations to two-site high availability (RHEL 9.8)

Hands-on lab on two real laptops linked only by Tailscale:
**kvm1** (Dell, at work, on a phone hotspot) and **kvm2** (MacBook 2013, at home).
Every level ends with a validation script; every problem met in the field is documented.

| Level | Topic | Highlights |
|---|---|---|
| 1 | Foundations | KVM/libvirt install, first VMs, helper scripts |
| 2 | Core administration | lifecycle, storage pools, networks, snapshots |
| 3 | Automation | cloud-init seeds, Ansible build/destroy of VMs |
| 4 | Performance and tuning | CPU pinning, huge pages, multiqueue virtio-net |
| 5 | Security and isolation | sVirt/SELinux, LUKS-encrypted disks, OpenSCAP |
| 6 | Advanced storage and networking | VXLAN over Tailscale, NFS/iSCSI pools, Ansible roles → [kvm-two-site-dc](https://github.com/mcsredhat/kvm-two-site-dc) |
| 7 | Production and HA | live migration between sites, online backups + automated restore tests, Pacemaker cluster with fencing, Prometheus alerts |

## Level 7 measured results
| | Target | Measured |
|---|---|---|
| Live migration outage | ≤ 5 s | 445 ms |
| Node-crash RTO | ≤ 5 min | 22 s |
| Restore + boot | ≤ 15 min | 36 s |
| Validation | — | 24/24, acceptance 10/10 |

Not in this repo on purpose: disk images, ISOs and cloud-init seeds, secrets,
scan reports with host details, and downloaded binaries (see `.gitignore`).
