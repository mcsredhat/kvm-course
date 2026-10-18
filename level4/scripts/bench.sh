#!/bin/bash
# bench.sh LABEL [DIR] : one fio run on DIR (default /bench), appends one CSV line to ~/results.csv
# run inside the guest as devops, WITHOUT sudo
set -euo pipefail
L="${1:?usage: ./bench.sh LABEL}"; D="${2:-/bench}"; F="$D/fio.test"; OUT="${OUT:-$HOME/results.csv}"
command -v fio >/dev/null || { echo "!!! fio is not installed (Part 4.1)"; exit 1; }
command -v jq  >/dev/null || { echo "!!! jq is not installed (Part 4.1)"; exit 1; }
mountpoint -q "$D" || { echo "!!! $D is not mounted (Part 4.3)"; exit 1; }
run() { fio --name=t --filename="$F" --size=1G --bs="$1" --rw="$2" --iodepth="$3" --ioengine=libaio \
        --direct=1 --ramp_time=5 --runtime=30 --time_based --output-format=json; }
rr=$(run 4k randread 32); rw=$(run 4k randwrite 32); sq=$(run 1M read 16)
[ -f "$OUT" ] || echo "label,rr_iops,rr_p99_us,rw_iops,rw_p99_us,seq_MBs" > "$OUT"
echo "$L,$(jq '.jobs[0].read.iops|floor' <<<"$rr"),$(jq '.jobs[0].read.clat_ns.percentile["99.000000"]/1000|floor' <<<"$rr"),$(jq '.jobs[0].write.iops|floor' <<<"$rw"),$(jq '.jobs[0].write.clat_ns.percentile["99.000000"]/1000|floor' <<<"$rw"),$(jq '.jobs[0].read.bw/1024|floor' <<<"$sq")" >> "$OUT"
rm -f "$F"; tail -1 "$OUT"
