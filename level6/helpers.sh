# helpers.sh : source on each host.  Shell FUNCTIONS: never put sudo in front of them.
export LIBVIRT_DEFAULT_URI=qemu:///system
SSHOPT="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"
ip_of()  { virsh domifaddr "$1" 2>/dev/null | awk '/ipv4/{sub("/.*","",$4); print $4; exit}'; }
vm_ssh() { local vm="$1"; shift; ssh $SSHOPT devops@"$(ip_of "$vm")" "$@"; }
vm_wait() {
  for _ in $(seq 60); do
    ip=$(ip_of "$1")
    [ -n "$ip" ] && ssh $SSHOPT -o BatchMode=yes devops@"$ip" true 2>/dev/null && { echo ">>> $1 is up at $ip"; return 0; }
    sleep 3
  done
  echo "!!! $1 not reachable by SSH"; return 1
}
