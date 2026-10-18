#!/bin/bash
# validate-level4.sh : run as your normal user, WITHOUT sudo
cd "$(dirname "$0")" || exit 1
if [ "$(id -u)" -eq 0 ]; then echo "Run this script as your normal user, WITHOUT sudo: $0" >&2; exit 1; fi
# shellcheck source=/dev/null
source ../lib.sh
export LIBVIRT_DEFAULT_URI=qemu:///system
echo "== Level 4 validation (RHEL 9.8) =="
check "tuned virtual-host active on the host"   bash -c 'tuned-adm active | grep -q virtual-host'
check "host swappiness = 10 (not guest profile)" bash -c '[ "$(sysctl -n vm.swappiness)" = 10 ]'
check "perf1 and perf2 defined"                 bash -c 'virsh dominfo perf1 >/dev/null && virsh dominfo perf2 >/dev/null'
check "bench disk cache=none"                  bash -c "virsh dumpxml perf1 | grep -q \"cache='none'\""
check "bench disk io=native"                    bash -c "virsh dumpxml perf1 | grep -q \"io='native'\""
check "perf1 has an IOThread"                   bash -c 'virsh dumpxml perf1 | grep -q "<iothreads>"'
check "perf1 topology 1 socket x 2 cores"       bash -c "virsh dumpxml --inactive perf1 | grep -q \"sockets='1'.*cores='2'\""
check "vCPU pinning persistent"                 bash -c 'virsh dumpxml --inactive perf1 | grep -q "<vcpupin"'
check "NIC multi-queue in XML"                  bash -c "virsh dumpxml perf1 | grep -A6 '<interface' | grep -q \"queues='2'\""
check "hugepages released"                      bash -c 'grep -Eq "HugePages_Total: +0$" /proc/meminfo'
check "results.csv: >= 3 runs for every label"  bash -c "cut -d, -f1 results.csv | tail -n +2 | sort | uniq -c | awk '\$1<3 {bad=1} END{exit bad}'"
check "results.csv has the 7 disk labels"       bash -c '[ $(cut -d, -f1 results.csv | tail -n +2 | sort -u | wc -l) -ge 7 ]'
check "XML saved per step (>= 7)"               bash -c '[ $(ls xml/*.xml | wc -l) -ge 7 ]'
check "hardware notes present"                  test -s docs/hardware.md
check "report.md exists"                        test -s report.md
summary
