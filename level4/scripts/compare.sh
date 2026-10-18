#!/bin/bash
# compare.sh results.csv BASELINE_LABEL : mean per label, and % difference versus the baseline
# (for the *_p99_us latency columns, LOWER is better)
awk -F, -v base="${2:?usage: compare.sh FILE BASELINE_LABEL}" '
NR==1 { nf=NF; for(i=2;i<=NF;i++) h[i]=$i; next }
      { n[$1]++; labels[$1]=1; for(i=2;i<=NF;i++) s[$1,i]+=$i }
END {
  for (l in labels) for (i=2;i<=nf;i++) m[l,i]=s[l,i]/n[l]
  printf "%-20s", "label (runs)"; for (i=2;i<=nf;i++) printf "%18s", h[i]; printf "\n"
  for (l in labels) {
    printf "%-20s", l " (" n[l] ")"
    for (i=2;i<=nf;i++) { d=(m[base,i]>0)? 100*(m[l,i]-m[base,i])/m[base,i] : 0; printf "%10.0f (%+4.0f%%)", m[l,i], d }
    printf "\n"
  }
}' "${1:?usage: compare.sh FILE BASELINE_LABEL}"
