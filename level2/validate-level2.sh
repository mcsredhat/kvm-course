#!/bin/bash
cd "$(dirname "$0")" || exit 1
if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as your normal user, WITHOUT sudo:  $0" >&2
  echo "(under sudo, ~ is /root: ~/kvm-course/env.sh is not found and BASE, SSHKEY, OSINFO are empty)" >&2
  exit 1
fi
[ -f ../lib.sh ] || { echo "Missing ~/kvm-course/lib.sh (Level 1, Part 2.2)"; exit 1; }
[ -f ../env.sh ] || { echo "Missing ~/kvm-course/env.sh (Level 1, Part 2.1)"; exit 1; }
# shellcheck source=/dev/null
source ../lib.sh
# shellcheck source=/dev/null
source ../env.sh
echo "== Level 2 validation (RHEL 9.8) =="
check "pool vmstore running"            bash -c 'virsh pool-info vmstore | grep -q running'
check "SELinux label virt_image_t"      bash -c 'ls -dZ /data/vmstore | grep -q virt_image_t'
check "template exists, mode 444"       bash -c '[ "$(stat -c %a /data/vmstore/tpl-rhel98.qcow2)" = 444 ]'
check "golden image still 444"          bash -c '[ "$(stat -c %a "$BASE")" = 444 ]'
check "web1 has a data disk vdb"        bash -c 'virsh domblklist web1 | grep -q vdb'
for n in node1 node2 node3; do
  check "$n running"                    bash -c "[ \"\$(virsh domstate $n)\" = running ]"
  check "$n backed by the template"     bash -c "qemu-img info -U --backing-chain /data/vmstore/$n.qcow2 | grep -q 'backing file: /data/vmstore/tpl-rhel98.qcow2'"
  check "$n has a lab-net NIC"          bash -c "virsh domiflist $n | grep -q lab-net"
done
check "lab-net active"                  bash -c 'virsh net-list | grep -qw lab-net'
check "node3 external snapshot s1 (or fallback documented)" bash -c 'virsh snapshot-dumpxml node3 s1 2>/dev/null | grep -q "snapshot=.external." || grep -qi fallback README.md'
check "node1 has 2 live vCPUs"          bash -c '[ "$(virsh vcpucount node1 --live --current)" = 2 ]'
check "node1 balloon <= 800 MB"         bash -c '[ "$(virsh dommemstat node1 | awk "/^actual/ {print \$2}")" -le 819200 ]'
check "node1 reaches node2 on lab-net"  bash -c 'ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new devops@"$(virsh domifaddr node1 | awk "/ipv4/ {print \$4}" | cut -d/ -f1 | head -1)" ping -c1 -W2 10.10.10.12'
summary
