export LIBVIRT_DEFAULT_URI=qemu:///system
export BASE=/var/lib/libvirt/images/base/rhel98-base.qcow2     # path of YOUR RHEL 9.8 guest image
export SSHKEY=$HOME/.ssh/id_ed25519.pub
export OSINFO=rhel9.8                                          # valid on a RHEL 9.8 host; otherwise rhel9-unknown
