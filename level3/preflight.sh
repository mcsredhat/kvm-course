#!/bin/bash
# preflight.sh : FAIL = fix before continuing; WARN = only needed for that method (Ansible / Terraform)
# shellcheck source=/dev/null
source ~/kvm-course/env.sh 2>/dev/null
FAIL=0
ok()  { echo "  [PASS] $1"; }
bad() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
warn(){ echo "  [WARN] $1"; }
t() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
w() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else warn "$d"; fi; }

echo "== Level 3 preflight =="
t "virsh talks to qemu:///system"                      bash -c '[ "$(virsh uri)" = "qemu:///system" ]'
t "golden image readable (BASE=${BASE:-unset})"        bash -c '[ -n "$BASE" ] && [ -r "$BASE" ]'
t "SSH public key exists (SSHKEY=${SSHKEY:-unset})"    bash -c '[ -n "$SSHKEY" ] && grep -q "^ssh-" "$SSHKEY"'
t "virt-install >= 3.0 (needed for --cloud-init)"      bash -c '[ "$(virt-install --version | cut -d. -f1)" -ge 3 ]'
w "virt-install >= 4.1 (needed for network-config=)"   bash -c 'v=$(virt-install --version); [ "$(printf "%s\n4.1.0\n" "$v" | sort -V | head -1)" = "4.1.0" ]'
t "OS variant known (OSINFO=${OSINFO:-unset})"         bash -c 'osinfo-query os short-id="$OSINFO" | grep -q "$OSINFO"'
t "xorriso installed (seed ISO)"                       rpm -q xorriso
w "mkisofs or xorrisofs in PATH (Terraform cloud-init disk)" bash -c 'command -v mkisofs || command -v xorrisofs'
w "ansible-playbook installed"                         command -v ansible-playbook
w "system python imports libvirt and lxml (Ansible)"   /usr/bin/python3 -c 'import libvirt, lxml'
w "terraform installed"                                command -v terraform
t ">= 20 GiB free in /var/lib/libvirt/images"          bash -c '[ "$(df -BG --output=avail /var/lib/libvirt/images | tail -1 | tr -dc 0-9)" -ge 20 ]'
echo
if [ "$FAIL" -eq 0 ]; then echo "Preflight OK"; else echo "$FAIL check(s) FAILED"; fi
exit "$FAIL"
