#!/bin/bash
cd "$(dirname "$0")" || exit 1
# shellcheck source=/dev/null
source ../lib.sh
check "XML for every step (>= 7)"      bash -c '[ $(ls xml/*.xml | wc -l) -ge 7 ]'
check "3 runs per label"               bash -c "cut -d, -f1 results.csv | tail -n +2 | sort | uniq -c | awk '\$1<3 {bad=1} END{exit bad}'"
check "compare.sh runs"                bash -c './scripts/compare.sh results.csv baseline | grep -q baseline'
check "report has a recommendation"    bash -c "grep -qi 'recommend' report.md"
check "report names a no-gain change"  bash -c "grep -Eqi 'no (measurable )?(gain|improvement)|did not help|within (the )?noise' report.md"
check "report compares qcow2 and raw"  bash -c "grep -qi 'raw' report.md && grep -qi 'qcow2' report.md"
check "hardware notes present"         test -s docs/hardware.md
summary
