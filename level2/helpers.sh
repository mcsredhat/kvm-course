# helpers.sh : source this file on the HOST at the start of each part
#   source ~/kvm-course/level2/helpers.sh
# These are shell FUNCTIONS: never put sudo in front of them.
export LIBVIRT_DEFAULT_URI=qemu:///system
SSHOPT="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"

# ip_of VM : the VM's IPv4 address on the "default" network
ip_of() { virsh domifaddr "$1" 2>/dev/null | awk '/ipv4/{sub("/.*","",$4); print $4; exit}'; }

# vm_stop VM : clean shutdown, wait until "shut off" (max 2 minutes)
vm_stop() {
  [ "$(virsh domstate "$1" 2>/dev/null)" = "shut off" ] && { echo ">>> $1 already shut off"; return 0; }
  virsh shutdown "$1" >/dev/null
  for _ in $(seq 60); do
    [ "$(virsh domstate "$1")" = "shut off" ] && { echo ">>> $1 shut off"; return 0; }
    sleep 2
  done
  echo "!!! $1 still running after 2 minutes: 'virsh console $1', or force with 'virsh destroy $1'"; return 1
}

# vm_start VM : start, wait until SSH answers (max 3 minutes)
vm_start() {
  virsh start "$1" >/dev/null 2>&1
  for _ in $(seq 60); do
    ip=$(ip_of "$1")
    if [ -n "$ip" ] && ssh $SSHOPT -o BatchMode=yes devops@"$ip" true 2>/dev/null; then
      echo ">>> $1 is up at $ip"; return 0
    fi
    sleep 3
  done
  echo "!!! $1 not reachable by SSH: 'virsh domstate $1', 'virsh console $1'"; return 1
}

# vm_ssh VM [command] : open a shell in the VM, or run one command in it
vm_ssh() { local vm="$1"; shift; ssh $SSHOPT devops@"$(ip_of "$vm")" "$@"; }
