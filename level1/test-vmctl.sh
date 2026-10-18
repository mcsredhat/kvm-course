#!/bin/bash
cd "$(dirname "$0")" || exit 1
# shellcheck source=/dev/null
source ../lib.sh
check "create t1"                ./vmctl create t1 1 1024
check "create duplicate refused" bash -c '! ./vmctl create t1'
check "ip returns IPv4"          bash -c './vmctl ip t1 | grep -Eq "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"'
check "ssh works"                bash -c './vmctl ssh t1 hostname | grep -q t1'
check "stop"                     ./vmctl stop t1
check "rm -f"                    bash -c 'sleep 20; ./vmctl rm -f t1'
check "disk removed"             bash -c '! sudo test -e /var/lib/libvirt/images/t1.qcow2'
check "bad command exits 2"      bash -c './vmctl nonsense; [ $? -eq 2 ]'
summary
