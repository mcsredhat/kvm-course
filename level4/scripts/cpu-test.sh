#!/bin/bash
# cpu-test.sh [PARALLEL] : compute pi with bc in N parallel processes, print elapsed seconds
n="${1:-1}"; s=$(date +%s.%N)
for _ in $(seq "$n"); do echo 'scale=2500; 4*a(1)' | bc -l >/dev/null & done
wait
awk -v a="$s" -v b="$(date +%s.%N)" 'BEGIN{printf "%.2f\n", b-a}'
