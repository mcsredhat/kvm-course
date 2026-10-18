#!/bin/bash
cd "$(dirname "$0")" || exit 1
if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as your normal user, WITHOUT sudo:  $0" >&2
  echo "(under sudo, ~ is /root: ~/kvm-course/env.sh is not found and BASE, SSHKEY, OSINFO are empty)" >&2
  exit 1
fi
[ -f ../lib.sh ] || { echo "Missing ~/kvm-course/lib.sh: create it first (section 0.3)"; exit 1; }
[ -f ../env.sh ] || { echo "Missing ~/kvm-course/env.sh: create it first (section 0.2)"; exit 1; }
# shellcheck source=/dev/null
source ../lib.sh
# shellcheck source=/dev/null
source ../env.sh
echo "== Level 1 validation (RHEL 9.8) =="
check "CPU virtualization flags present"   bash -c '[ "$(grep -E -c "(vmx|svm)" /proc/cpuinfo)" -gt 0 ]'
check "kvm module loaded"                  bash -c 'lsmod | grep -q "^kvm"'
check "/dev/kvm exists"                    test -c /dev/kvm
check "required packages installed"        rpm -q qemu-kvm libvirt virt-install guestfs-tools
check "libvirt daemon active"              bash -c 'systemctl is-active --quiet virtqemud.socket || systemctl is-active --quiet libvirtd'
check "virt-host-validate: no FAIL"        bash -c '! sudo virt-host-validate 2>&1 | grep -q FAIL'
check "URI is qemu:///system"              bash -c '[ "$(virsh uri)" = "qemu:///system" ]'
check "env.sh sourced from ~/.bashrc"      grep -q 'kvm-course/env.sh' "$HOME/.bashrc"
check "default network active"             bash -c 'virsh net-list | grep -qw default'
check "default pool active"                bash -c 'virsh pool-list | grep -qw default'
check "golden image in base/, read-only"   bash -c '[ -f "$BASE" ] && [ "$(stat -c %a "$BASE")" = 444 ] && [[ "$BASE" == */base/* ]]'
check "OS variant known"                   bash -c '[ -n "$OSINFO" ] && osinfo-query os short-id="$OSINFO" | grep -qw "$OSINFO"'
check "vm-a defined"                       virsh dominfo vm-a
check "vm-a running"                       bash -c '[ "$(virsh domstate vm-a)" = running ]'
check "vm-a has an IPv4 address"           bash -c 'virsh domifaddr vm-a | grep -q ipv4'
check "vm-a runs as unprivileged qemu"     bash -c 'ps -o user= -p "$(pgrep -f "guest=vm-a" | head -1)" | grep -q qemu'
check "vm-a disk is virtio (vda)"          bash -c 'virsh domblklist vm-a | grep -q vda'
check "devops can log in on vm-a"          bash -c 'ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new devops@"$(virsh domifaddr vm-a | awk "/ipv4/ {print \$4}" | cut -d/ -f1)" true'
summary
