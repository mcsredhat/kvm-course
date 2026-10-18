#!/bin/bash
# lab.sh : N-node lab in one command (Level 2 mini-project). TODO: static IPs, status, snap, restore
set -euo pipefail
ENVFILE="$HOME/kvm-course/env.sh"
[ -f "$ENVFILE" ] || { echo "missing $ENVFILE (Level 1, Part 2.1)" >&2; exit 1; }
# shellcheck source=/dev/null
source "$ENVFILE"
TPL=/data/vmstore/tpl-rhel98.qcow2
POOLDIR=/data/vmstore
PREFIX=lab

ensure_net() {
  virsh net-info lab-net >/dev/null 2>&1 && return 0
  virsh net-define /dev/stdin <<'XML'
<network><name>lab-net</name><bridge name="virbr10"/><ip address="10.10.10.1" netmask="255.255.255.0"/></network>
XML
  virsh net-start lab-net
  virsh net-autostart lab-net
}

up() {
  local n="${1:-3}" i name
  [ -r "$TPL" ] || { echo "template $TPL missing (Level 2, Part 7)" >&2; exit 1; }
  ensure_net
  for i in $(seq 1 "$n"); do
    name="$PREFIX$i"
    if virsh dominfo "$name" >/dev/null 2>&1; then echo "$name exists, skipped"; continue; fi
    sudo qemu-img create -f qcow2 -b "$TPL" -F qcow2 "$POOLDIR/$name.qcow2" >/dev/null
    sudo virt-customize -a "$POOLDIR/$name.qcow2" --hostname "$name" --selinux-relabel
    sudo qemu-img create -f qcow2 "$POOLDIR/$name-data.qcow2" 5G >/dev/null
    sudo virt-install --name "$name" --memory 1024 --vcpus 1 --osinfo "$OSINFO" \
      --disk path="$POOLDIR/$name.qcow2",bus=virtio --disk path="$POOLDIR/$name-data.qcow2",bus=virtio \
      --network network=default,model=virtio --network network=lab-net,model=virtio \
      --import --graphics none --noautoconsole
    # TODO: wait for SSH, find the lab-net NIC by MAC (Part 9.2), nmcli 10.10.10.$((20+i))/24
  done
}

down() {
  local vm
  for vm in $(virsh list --all --name | grep -E "^${PREFIX}[0-9]+$" || true); do
    virsh destroy "$vm" >/dev/null 2>&1 || true
    virsh undefine "$vm" --nvram --managed-save --snapshots-metadata --remove-all-storage >/dev/null
  done
  sudo find "$POOLDIR" -maxdepth 1 -regextype egrep -regex "$POOLDIR/${PREFIX}[0-9]+(-data)?\.qcow2" -delete
}

case "${1:-help}" in
  up)   up "${2:-3}" ;;
  down) down ;;
  # TODO: status, snap NAME, restore NAME
  *)    echo "usage: $0 {up [N]|status|snap NAME|restore NAME|down}" >&2; exit 2 ;;
esac
