# helpers.sh : source this file on the HOST at the start of each part
#   source ~/kvm-course/level5/helpers.sh
# These are shell FUNCTIONS: never put sudo in front of them.
export LIBVIRT_DEFAULT_URI=qemu:///system
SSHOPT="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"

ip_of() { virsh domifaddr "$1" 2>/dev/null | awk '/ipv4/{sub("/.*","",$4); print $4; exit}'; }

vm_stop() {
  [ "$(virsh domstate "$1" 2>/dev/null)" = "shut off" ] && { echo ">>> $1 already shut off"; return 0; }
  virsh shutdown "$1" >/dev/null
  for _ in $(seq 60); do
    [ "$(virsh domstate "$1")" = "shut off" ] && { echo ">>> $1 shut off"; return 0; }
    sleep 2
  done
  echo "!!! $1 still running after 2 minutes: 'virsh console $1', or force with 'virsh destroy $1'"; return 1
}

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

# mk_vm NAME MEM_MIB VCPUS : small VM from the golden image (overlay in /data/vmstore), user devops + your key
mk_vm() {
  local n="$1" m="$2" c="$3" d="/data/vmstore/$1.qcow2"
  if virsh dominfo "$n" &>/dev/null; then echo ">>> $n already exists, skipped"; return 0; fi
  [ -e "$d" ] && { echo "!!! $d exists without a VM: remove it first"; return 1; }
  sudo mkdir -p /data/vmstore
  sudo qemu-img create -f qcow2 -b "$BASE" -F qcow2 "$d" 20G >/dev/null
  sudo virt-customize -q -a "$d" --hostname "$n" \
    --run-command 'useradd -m -G wheel devops' --ssh-inject devops:file:"$SSHKEY" \
    --write '/etc/sudoers.d/devops:devops ALL=(ALL) NOPASSWD:ALL' --run-command 'chmod 440 /etc/sudoers.d/devops' \
    --touch /etc/cloud/cloud-init.disabled --selinux-relabel
  sudo virt-install --name "$n" --memory "$m" --vcpus "$c" --osinfo "$OSINFO" \
    --disk path="$d",bus=virtio --import \
    --network network=default,model=virtio --graphics none --noautoconsole >/dev/null && echo ">>> $n created"
}
