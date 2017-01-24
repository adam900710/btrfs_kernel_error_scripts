#!/bin/bash

mnt="/mnt/test"
dev=/home/adam/balance_level_2.img

umount $mnt &> /dev/null
rm $dev
fallocate $dev -l 256M
mkfs.btrfs -f $dev -n 4k -b 256M
mount $dev $mnt

create_files () {
	prefix=$1
	size=$2
	nr=$3
	dir=$4

	for i in $(seq $nr); do
		filename=$(printf "%s_%05d" "$prefix" $i)
		xfs_io -f -c "pwrite 0 $size" $dir/$filename > /dev/null
	done
}

create_files inline 2k 100 $mnt
create_files large 4k 5 $mnt

btrfs quota enable $mnt
btrfs quota rescan -w $mnt
btrfs qg show -pcre --raw $mnt
sync

umount $mnt
mount -t btrfs $dev $mnt
time btrfs balance start -d $mnt
btrfs qg show -pcre --raw $mnt
umount $mnt

btrfsck $dev
