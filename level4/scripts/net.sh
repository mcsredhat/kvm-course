#!/bin/bash
# net.sh SERVER_IP : 4 parallel TCP streams for 20 s, prints Gbit/s
iperf3 -c "${1:?usage: ./net.sh SERVER_IP}" -t 20 -P 4 -J | jq '.end.sum_received.bits_per_second/1e9'
