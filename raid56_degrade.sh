#!/bin/bash

dev1=/dev/vdb6
dev2=/dev/vdb7
dev3=/dev/vdb8
mnt=/mnt/scratch

umount $mnt &> /dev/null
mkfs.btrfs -f -m raid5 -d raid5 $dev1 $dev2 $dev3

mount $dev1 $mnt -o nospace_cache

xfs_io -f -c "pwrite 0 1m" $mnt/tf1

umount $mnt
rmmod btrfs
modprobe btrfs
mount -o degraded,device=$dev2,nospace_cache $dev1 $mnt

xfs_io -f -c "pwrite 0 99m" $mnt/tf2

umount $mnt

btrfs device scan

#mount $dev1 $mnt -o nospace_cache

#btrfs balance start --full-balance $mnt

#umount $mnt
