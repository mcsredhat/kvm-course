#!/bin/bash
# dc-validate.sh : connectivity matrix over the VXLAN segments; exit code = number of failures
export LIBVIRT_DEFAULT_URI=qemu:///system
FAILS=0
A10=$(virsh domifaddr v10a | awk '/ipv4/{sub("/.*","",$4); print $4; exit}')
expect() {  # expect allow|deny DEST_IP [ping options]
  local want=$1 dst=$2 got; shift 2
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "devops@$A10" "ping -c1 -W3 $* $dst" >/dev/null 2>&1; then got=allow; else got=deny; fi
  if [ "$got" = "$want" ]; then echo "  [PASS] v10a -> $dst $* ($want)"
  else echo "  [FAIL] v10a -> $dst $* wanted $want got $got"; FAILS=$((FAILS+1)); fi
}
expect allow 192.168.10.12                    # VNI 10 across the VPN
expect deny  192.168.20.12                    # VNI 10 -> VNI 20
expect allow 192.168.10.12 -M "do" -s 1202      # full-size frame fits the segment MTU
expect deny  192.168.10.12 -M "do" -s 1203      # one byte more does not
echo "failures: $FAILS"; exit $FAILS
