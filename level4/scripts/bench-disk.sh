#!/bin/bash
# bench-disk.sh : (re)prepare /dev/vdb as /bench, persistent by UUID (formats ONLY if vdb has no filesystem)
set -euo pipefail
DEV=/dev/vdb
sudo mkdir -p /bench
mountpoint -q /bench && sudo umount /bench
if ! sudo blkid "$DEV" >/dev/null; then echo ">>> $DEV is empty: formatting XFS"; sudo mkfs.xfs -q "$DEV"; fi
UUID=$(sudo blkid -s UUID -o value "$DEV")
[ -f /etc/fstab.bak ] || sudo cp /etc/fstab /etc/fstab.bak
sudo sed -i '\#[[:space:]]/bench[[:space:]]#d' /etc/fstab          # remove the old /bench line
echo "UUID=$UUID /bench xfs defaults,nofail 0 0" | sudo tee -a /etc/fstab >/dev/null
sudo systemctl daemon-reload
sudo mount -a
sudo chown devops: /bench
findmnt /bench
