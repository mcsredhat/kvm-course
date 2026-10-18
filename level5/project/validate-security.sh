#!/bin/bash
# validate-security.sh : run with sudo; exits non-zero if any control fails; writes security-report.md
[ "$(id -u)" -eq 0 ] || { echo "run with sudo: sudo $0" >&2; exit 2; }
cd "$(dirname "$0")" || exit 2
export LIBVIRT_DEFAULT_URI=qemu:///system
REPORT=security-report.md ; FAILS=0
echo "# KVM host security report ($(date -Is))" > "$REPORT"
ctl() {  # ctl "control name" "rationale" command...
  local name="$1" why="$2"; shift 2
  if "$@" >/dev/null 2>&1; then echo "- [PASS] $name: $why" | tee -a "$REPORT"
  else echo "- [FAIL] $name: $why" | tee -a "$REPORT"; FAILS=$((FAILS+1)); fi
}
ctl "SELinux enforcing"    "sVirt isolation depends on it"          bash -c '[ "$(getenforce)" = Enforcing ]'
ctl "QEMU unprivileged"    "limits the impact of a VM escape"       bash -c '! ps -o user= -C qemu-kvm | grep -q "^root"'
ctl "No libvirt TCP"       "no unauthenticated remote management"   bash -c '! ss -tln | grep -Eq ":(16509|16514)\b"'
ctl "No VNC on 0.0.0.0"    "consoles reachable only via tunnel"     bash -c '! ss -tln | grep -Eq "(0\.0\.0\.0|\*):59[0-9]{2}"'
ctl "libvirt group empty"  "group membership is root-equivalent"    bash -c '[ -z "$(getent group libvirt | cut -d: -f4)" ]'
ctl "Polkit rule present"  "least-privilege VM administration"      bash -c 'ls /etc/polkit-1/rules.d/*libvirt*'
ctl "Audit rules loaded"   "evidence of configuration changes"      bash -c 'auditctl -l | grep -q libvirt-config'
ctl "SSH: no passwords"    "management plane uses keys"             bash -c 'sshd -T | grep -qi "^passwordauthentication no"'
ctl "No mitigations=off"   "CPU side-channel mitigations stay on"   bash -c '! grep -q "mitigations=off" /proc/cmdline'
ctl "firewalld active"     "host firewall enforced"                 systemctl is-active --quiet firewalld
ctl "libvirt zone: no ssh" "guests cannot reach host SSH"           bash -c '! firewall-cmd --zone=libvirt --list-services | grep -qw ssh'
ctl "No pending security updates" "known CVEs are patched"          bash -c '[ "$(dnf -q updateinfo list security 2>/dev/null | wc -l)" -eq 0 ]'
echo; echo "Failed controls: $FAILS"; exit $((FAILS>0))
