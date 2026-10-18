resource "libvirt_pool" "lab" {
  name = "tf-lab"
  type = "dir"
  target {
    path = "/var/lib/libvirt/images/tf-lab"
  }
}

resource "libvirt_volume" "base" {
  name   = "rhel-base.qcow2"
  pool   = libvirt_pool.lab.name
  source = var.base_image
  format = "qcow2"
}

resource "libvirt_volume" "node" {
  count          = var.node_count
  name           = "node${count.index + 1}.qcow2"
  pool           = libvirt_pool.lab.name
  base_volume_id = libvirt_volume.base.id
  size           = 21474836480 # 20 GiB
}

resource "libvirt_cloudinit_disk" "init" {
  count = var.node_count
  name  = "node${count.index + 1}-init.iso"
  pool  = libvirt_pool.lab.name
  user_data = templatefile("${path.module}/cloud-init/user-data.tftpl", {
    hostname   = "node${count.index + 1}"
    ssh_pubkey = var.ssh_pubkey
  })
  meta_data = "instance-id: node${count.index + 1}-001\nlocal-hostname: node${count.index + 1}\n"
}

resource "libvirt_domain" "node" {
  count      = var.node_count
  name       = "node${count.index + 1}"
  memory     = var.vm_memory_mib
  vcpu       = var.vm_vcpus
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.init[count.index].id

  cpu {
    mode = "host-model"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.node[count.index].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  # The provider adds SPICE by default; RHEL 9 QEMU has no SPICE -> force VNC on localhost
  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }
}

output "ips" {
  value = { for d in libvirt_domain.node : d.name => d.network_interface[0].addresses }
}
