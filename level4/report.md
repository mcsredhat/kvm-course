# Level 4 performance report — perf1 on <your laptop model>

## Hardware
(summary of docs/hardware.md: CPU, cores/threads, siblings, pinned CPUs)

## Method
fio on a dedicated 4 GiB bench disk (/bench, --direct=1), 3 runs per configuration, AC power,
tuned virtual-host (host) / virtual-guest (guest), one change per step, XML saved per step in xml/.

## Results
(paste the output of: ./scripts/compare.sh results.csv baseline)
(paste cpu.csv and net.csv as tables; give min and max for each label)

## qcow2 vs raw
(fmt-raw and fmt-qcow2-prealloc versus iothread: what the format changes on this SSD)

## Changes with no measurable gain
(every change whose difference is smaller than the run-to-run spread, and why)

## Recommendation
For this workload on this hardware I recommend: ...
Not worth it here: ...
What would change on a server: NUMA placement, 1 GiB pages, more IOThreads.
