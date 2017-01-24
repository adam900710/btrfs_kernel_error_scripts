#!/bin/bash

MNT="/mnt/test"
DEV="/dev/sda6"

umount $DEV &> /dev/null
mkfs.btrfs -f $DEV
mount -t btrfs $DEV $MNT

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

mkdir $MNT/snaps
echo "populate $MNT with some data"
#cp -a /usr/share/fonts $MNT/
#cp -a /usr/ $MNT/ &

for i in $(seq -w 0 10); do
	create_files inline_orig_${i} 2K 200 $MNT
	create_files large_orig_${i} 1M 40 $MNT
done &

for i in `seq -w 0 8`; do
        S="$MNT/snaps/snap$i"
        echo "create and populate $S"
        btrfs su snap $MNT $S;
        #cp -a /boot $S;
	for j in `seq -w 0 8`; do
		create_files inline_new_${i}_${j} 2K 10 $S
		create_files large_new_${i}_${j} 1M 2 $S
	done
done;

wait
btrfs fi sync $MNT

btrfs quota enable $MNT
btrfs quota rescan -w $MNT
btrfs qg show -pcre --raw $MNT
sync

umount $MNT
mount -t btrfs $DEV $MNT
time btrfs balance start --full-balance $MNT
btrfs qg show -pcre --raw $MNT
umount $MNT

ltrfsck $DEV
