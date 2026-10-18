variable "node_count" {
  type    = number
  default = 3
}

variable "ssh_pubkey" {
  type = string
}

variable "base_image" {
  type = string
}

variable "vm_memory_mib" {
  type    = number
  default = 1024
}

variable "vm_vcpus" {
  type    = number
  default = 1
}
