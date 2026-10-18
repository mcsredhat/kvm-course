#!/bin/bash
cd "$(dirname "$0")" || exit 1
# shellcheck source=/dev/null
source ../../lib.sh
check "role is idempotent"           bash -c 'ansible-playbook harden.yml -K >/dev/null; ansible-playbook harden.yml -K | grep -q "changed=0"'
check "checker runs and writes a report" bash -c 'sudo ./validate-security.sh >/dev/null; test -s security-report.md'
check "checker FAILS when SELinux is permissive" bash -c 'sudo setenforce 0; sudo ./validate-security.sh >/dev/null; r=$?; sudo setenforce 1; [ $r -ne 0 ]'
check "role repairs the violation"   bash -c 'sudo setenforce 0; ansible-playbook harden.yml -K >/dev/null; [ "$(getenforce)" = Enforcing ]'
check "threat model present"         test -s ../docs/threat-model.md
summary
