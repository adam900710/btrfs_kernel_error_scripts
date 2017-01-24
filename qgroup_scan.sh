#!/bin/bash

dev=/home/adam/qgroup_scan.img
mnt=/mnt/test

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

umount $mnt &> /dev/null

rm $dev
fallocate -l 256M $dev
mkfs.btrfs -f $dev -n 4k

mount $dev $mnt
#create_files large 4k 128 $mnt
create_files small 2k 128 $mnt

btrfs quota enable $mnt
btrfs quota rescan -w $mnt
umount $mnt
