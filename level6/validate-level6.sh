#!/bin/bash
# validate-level6.sh : run on kvm1 as your normal user, WITHOUT sudo (it calls sudo itself)
cd "$(dirname "$0")" || exit 1
if [ "$(id -u)" -eq 0 ]; then echo "Run as your normal user, WITHOUT sudo: $0" >&2; exit 1; fi
# shellcheck source=/dev/null
source ../lib.sh ; source ./net.env
export LIBVIRT_DEFAULT_URI=qemu:///system
A10=$(virsh domifaddr v10a | awk '/ipv4/{sub("/.*","",$4); print $4; exit}')
vm() { ssh -o BatchMode=yes -o ConnectTimeout=5 "devops@$A10" "$@"; }
echo "== Level 6 validation (two laptops over Tailscale) =="
check "kvm2 reachable over Tailscale"      tailscale ping -c 1 kvm2
check "SSH to kvm2 without password"       ssh -o BatchMode=yes kvm2 true
check "tailscale0 in firewalld trusted"    bash -c 'sudo firewall-cmd --zone=trusted --list-interfaces | grep -qw tailscale0'
check "NFS pool running on kvm1"           bash -c 'virsh pool-info nfspool | grep -q running'
check "NFS pool running on kvm2"           ssh -o BatchMode=yes kvm2 'virsh -c qemu:///system pool-info nfspool | grep -q running'
check "iSCSI session logged in"            bash -c 'sudo iscsiadm -m session | grep -q storage1'
check "iSCSI pool lists the LUN"           bash -c 'virsh vol-list iscsipool | tail -n +3 | grep -q .'
check "vxlan10/20 on kvm1, mtu 1230"       bash -c 'ip link show vxlan10 | grep -q "mtu 1230" && ip link show vxlan20 | grep -q "mtu 1230"'
check "vxlan10/20 on kvm2"                 ssh -o BatchMode=yes kvm2 'ip link show vxlan10 && ip link show vxlan20'
check "vxlan-lab.service enabled (both)"   bash -c 'systemctl is-enabled -q vxlan-lab && ssh -o BatchMode=yes kvm2 systemctl is-enabled -q vxlan-lab'
check "no host IP on br10/br20 (kvm1)"     bash -c '! ip -4 addr show br10 | grep -q inet && ! ip -4 addr show br20 | grep -q inet'
check "VNI 10 across the VPN works"        vm ping -c2 -W3 192.168.10.12
check "VNI 10 -> VNI 20 is blocked"        bash -c "! ssh -o BatchMode=yes devops@$A10 ping -c2 -W2 192.168.20.12"
check "segment MTU 1202 passes"            vm ping -M "do" -s 1202 -c2 -W3 192.168.10.12
check "segment MTU 1203 fails"             bash -c "! ssh -o BatchMode=yes devops@$A10 ping -M do -s 1203 -c2 -W2 192.168.10.12"
check "IOMMU groups documented"            bash -c 'ls docs/iommu-groups-*.txt >/dev/null'
check "SR-IOV plan written"                test -s docs/sriov-plan.md
check "link measured"                      test -s docs/link.md
summary
