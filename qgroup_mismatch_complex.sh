#!/bin/bash

MNT="/mnt/test"
DEV="/dev/vdb5"

mkfs.btrfs -f $DEV -n 4k
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
echo 3 > /proc/sys/vm/drop_caches
#cp -a /usr/share/fonts $MNT/
cp -a /usr/ $MNT/ &
for i in `seq -w 0 8`; do
        S="$MNT/snaps/snap$i"
        echo "create and populate $S"
        btrfs su snap $MNT $S;
        cp -a /boot $S;
done;

#let the cp from above finish
wait

btrfs fi sync $MNT

btrfs quota enable $MNT
btrfs quota rescan -w $MNT
btrfs qg show $MNT

umount $MNT

mount -t btrfs $DEV $MNT


time btrfs balance start --full-balance $MNT

umount $MNT

btrfsck $DEV
