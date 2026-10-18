# SR-IOV and passthrough plan (what I would do on a server)

## Hardware needed
NIC models with SR-IOV (e.g. Intel X710/E810, Mellanox ConnectX), BIOS: VT-d + SR-IOV enabled.

## Red Hat procedure (RHEL 9)
1. Kernel: grubby --update-kernel=ALL --args="intel_iommu=on iommu=pt" ; reboot
2. VFs: echo 4 > /sys/class/net/<pf>/device/sriov_numvfs  (persistent: nmcli connection modify <pf> sriov.total-vfs 4)
3. Give a VF to a VM: virsh attach-interface <vm> hostdev <pci-address-of-VF> --mac 52:54:00:xx:xx:xx --managed --live --config
   (a hand-written <hostdev> does NOT keep the MAC across host reboots)

## What my laptops have
(summary of docs/iommu-groups-kvm1.txt and -kvm2.txt; SR-IOV: none)

## Trade-offs
No live migration with a VF/passthrough device; host firewall bypassed; ...
