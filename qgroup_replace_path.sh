#!/bin/bash

mnt="/mnt/test"
dev="/dev/vdb5"

umount $dev &> /dev/null
mkfs.btrfs -f $dev
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

btrfs sub create $mnt/orig
for i in $(seq -w 0 1); do
	create_files inline_orig_${i} 2K 200 $mnt/orig/
	create_files large_orig_${i} 1M 4 $mnt/orig/
done

for i in $(seq -w 0 1); do
	btrfs sub snapshot $mnt/orig $mnt/subv_${i}
done

btrfs quota enable $mnt
btrfs quota rescan -w $mnt
btrfs qg show -prce --raw $mnt
sync

btrfs balance start -d $mnt
btrfs qg show -prce --raw $mnt
umount $mnt

btrfsck $dev
