#!/bin/bash
# mkvm.sh NAME BRIDGE... : linked clone of the Level 2 template, NIC 1 on "default" (NAT),
#                          one extra NIC per bridge, with MTU 1230 (VXLAN over Tailscale)
set -euo pipefail
export LIBVIRT_DEFAULT_URI=qemu:///system
# shellcheck source=/dev/null
source "$HOME/kvm-course/env.sh"
NAME="${1:?usage: mkvm.sh NAME BRIDGE...}"; shift
TPL=/data/vmstore/tpl-rhel98.qcow2
[ -r "$TPL" ] || { echo "template $TPL missing (Level 2, Part 7)" >&2; exit 1; }
if virsh dominfo "$NAME" >/dev/null 2>&1; then echo ">>> $NAME exists, skipped"; exit 0; fi
nets=(--network "network=default,model=virtio")
for br in "$@"; do nets+=(--network "bridge=$br,model=virtio,mtu.size=1230"); done
sudo qemu-img create -f qcow2 -b "$TPL" -F qcow2 "/data/vmstore/$NAME.qcow2" >/dev/null
sudo virt-customize -q -a "/data/vmstore/$NAME.qcow2" --hostname "$NAME" --selinux-relabel
sudo virt-install --name "$NAME" --memory 1024 --vcpus 1 --osinfo "$OSINFO" \
  --disk path="/data/vmstore/$NAME.qcow2",bus=virtio --import "${nets[@]}" \
  --graphics none --noautoconsole >/dev/null
echo ">>> $NAME created"
