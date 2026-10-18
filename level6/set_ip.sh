#!/bin/bash
# set_ip.sh VM BRIDGE CIDR : static address + MTU 1230 on the VM NIC attached to BRIDGE
#   e.g.  ./set_ip.sh v10a br10 192.168.10.11/24
set -euo pipefail
export LIBVIRT_DEFAULT_URI=qemu:///system
vm="${1:?vm}"; br="${2:?bridge}"; cidr="${3:?cidr}"
mac=$(virsh domiflist "$vm" | awk -v b="$br" '$3==b {print $5}')
ip=$(virsh domifaddr "$vm" | awk '/ipv4/ {print $4}' | cut -d/ -f1 | head -1)
[ -n "$mac" ] && [ -n "$ip" ] || { echo "cannot find NIC/IP for $vm on $br" >&2; exit 1; }
nic=$(ssh -o StrictHostKeyChecking=accept-new "devops@$ip" 'ip -o link' | awk -v m="$mac" 'tolower($0) ~ tolower(m) {gsub(":","",$2); print $2}')
ssh "devops@$ip" "sudo nmcli con delete t-$br >/dev/null 2>&1; sudo nmcli con add type ethernet ifname $nic con-name t-$br ipv4.method manual ipv4.addresses $cidr 802-3-ethernet.mtu 1230 && sudo nmcli con up t-$br"
echo ">>> $vm: $nic on $br = $cidr (mtu 1230)"
