#!/bin/bash
# validate-level5.sh : run as your normal user, WITHOUT sudo (it calls sudo itself)
cd "$(dirname "$0")" || exit 1
if [ "$(id -u)" -eq 0 ]; then echo "Run this script as your normal user, WITHOUT sudo: $0" >&2; exit 1; fi
# shellcheck source=/dev/null
source ../lib.sh
export LIBVIRT_DEFAULT_URI=qemu:///system
echo "== Level 5 validation (RHEL 9.8) =="
check "SELinux enforcing"                 bash -c '[ "$(getenforce)" = Enforcing ]'
check "QEMU not running as root"          bash -c '! ps -o user= -C qemu-kvm | grep -q "^root"'
check "isol1 and isol2 running"           bash -c 'virsh domstate isol1 | grep -q running && virsh domstate isol2 | grep -q running'
check "running VMs have distinct MCS labels" bash -c '[ $(ps -eZ | grep qemu-kvm | awk "{print \$1}" | sort -u | wc -l) -ge 2 ]'
check "isol1: no sound/tablet/redirdev"   bash -c '! virsh dumpxml isol1 | grep -Eq "<sound|<redirdev|type=.tablet."'
check "no VNC on all interfaces"          bash -c '! ss -tln | grep -Eq "(0\.0\.0\.0|\*|\[::\]):59[0-9]{2}"'
check "isol2 VNC on 127.0.0.1"            bash -c "virsh dumpxml isol2 | grep -q \"<graphics type='vnc'.*listen='127.0.0.1'\""
check "no libvirt TCP listener"           bash -c '! ss -tln | grep -Eq ":(16509|16514)\b"'
check "polkit group rule installed"       test -f /etc/polkit-1/rules.d/80-libvirt-groups.rules
check "alice can manage VMs"              sudo -u alice virsh -c qemu:///system list
check "bob cannot manage VMs"             bash -c '! sudo -u bob virsh -c qemu:///system list'
check "carol read-only works"             sudo -u carol virsh -r -c qemu:///system list
check "carol read-write denied"           bash -c '! sudo -u carol virsh -c qemu:///system list'
check "lab users not in libvirt group"    bash -c '! getent group libvirt | grep -Eq "(alice|bob|carol)"'
check "encryption evidence: plain >= 1"   bash -c '[ $(sudo strings /var/lib/libvirt/images/plain.qcow2 | grep -c SECRET-MARKER) -ge 1 ]'
check "encryption evidence: enc = 0"      bash -c '[ $(sudo strings /var/lib/libvirt/images/enc.qcow2 | grep -c SECRET-MARKER) -eq 0 ]'
check "sec1 Secure Boot feature"          bash -c 'virsh dumpxml sec1 | grep -q "secure-boot"'
check "sec1 vTPM"                         bash -c 'virsh dumpxml sec1 | grep -q "<tpm"'
check "libvirt zone: ssh removed"         bash -c '! sudo firewall-cmd --zone=libvirt --list-services | grep -qw ssh'
check "auditd libvirt rule loaded"        bash -c 'sudo auditctl -l | grep -q libvirt-config'
check "no mitigations=off"                bash -c '! grep -q "mitigations=off" /proc/cmdline'
check "OpenSCAP report exists"            test -s host-report.html
check "security notes written"            test -s docs/security-notes.md
summary
