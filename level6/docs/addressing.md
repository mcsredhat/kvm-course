# Addressing
| Host | Tailscale | Segment VNI 10 (br10) | Segment VNI 20 (br20) |
|---|---|---|---|
| kvm1 | 100.106.156.103 | v10a 192.168.10.11 | - |
| kvm2 | 100.108.161.47 | v10b 192.168.10.12 | v20b 192.168.20.12 |
NFS: 100.108.161.47:/export/vms -> /var/lib/libvirt/images/nfs (both hosts)
iSCSI: iqn.2026-10.lab.local:storage1 on 100.108.161.47:3260, initiator iqn.2026-10.lab.local:kvm1
