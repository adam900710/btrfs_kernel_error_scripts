#!/bin/bash

dev1=/dev/vdb6
dev2=/dev/vdb7
dev3=/dev/vdb8
mnt=/mnt/test

umount $mnt &> /dev/null
mkfs.btrfs $dev1 $dev2 $dev3 -f -m raid5 -d raid5 2>&1 > /dev/null
mount $dev1 $mnt -o nospace_cache
#xfs_io -f -c "pwrite 0 256k" $mnt/file1 2>&1 > /dev/null
xfs_io -f -c "pwrite -S 0x01 0 64k" $mnt/file1 2>&1 > /dev/null
xfs_io -f -c "pwrite -S 0x10 64k 64k" $mnt/file1 2>&1 > /dev/null
sync
umount $mnt

dmesg -C
# Destory parity stripe
#dd if=/dev/urandom of=$dev1 bs=1 count=64k seek=566231040

# Destory data stripe (64K or 4K)
#dd status=none if=/dev/urandom of=$dev2 bs=1 count=4k seek=546308096 
xfs_io -c "pwrite -S 0xff 546308096 64K" $dev2

# btrfs-progs scrub
btrfs check --scrub $dev1

# scrub
mount $dev1 $mnt -o nospace_cache
btrfs scrub start -B $mnt
#cat $mnt/file1 > /dev/null
umount $mnt

dd if=$dev1 of=/tmp/parity bs=1 count=64k skip=566231040

echo "===final fsck scrub==="

# btrfs-progs scrub recheck
btrfs check --scrub $dev1
