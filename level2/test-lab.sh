#!/bin/bash
cd "$(dirname "$0")" || exit 1
# shellcheck source=/dev/null
source ../lib.sh
check "up creates 3 running VMs"   bash -c './lab.sh up 3; [ "$(virsh list --name --state-running | grep -cE "^lab[0-9]+$")" -eq 3 ]'
check "up is idempotent"           ./lab.sh up 3
check "lab IPs answer"             bash -c 'sleep 30; for a in 21 22 23; do ping -c1 -W2 10.10.10.$a >/dev/null || exit 1; done'
check "data disk present"          bash -c 'ssh -o BatchMode=yes devops@10.10.10.21 lsblk | grep -q 5G'
check "snap and restore"           bash -c './lab.sh snap clean && ./lab.sh restore clean'
check "down leaves nothing"        bash -c './lab.sh down; ! virsh list --all --name | grep -qE "^lab[0-9]+$"; ! ls /data/vmstore/lab[0-9]*.qcow2 2>/dev/null'
check "down is idempotent"         ./lab.sh down
check "template untouched (444)"   bash -c '[ "$(stat -c %a /data/vmstore/tpl-rhel98.qcow2)" = 444 ]'
summary
