#!/bin/bash

dev=/dev/vdb5
mnt=/mnt/test/
trace_dir=/sys/kernel/debug/tracing
fsstress=/home/adam/xfstests/ltp/fsstress

_fail ()
{
	echo "FAILLLLLED"
	exit 1
}

init_trace () {
	echo 0 > $trace_dir/tracing_on
	echo > $trace_dir/trace
	echo > $trace_dir/set_event

	echo btrfs:btrfs_qgroup_reserve_data >> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_release_data >> $trace_dir/set_event
	echo btrfs:btrfs_transaction_commit >> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_free_delayed_ref >> $trace_dir/set_event
	echo qgroup_update_reserve >> $trace_dir/set_event
	echo qgroup_meta_reserve >> $trace_dir/set_event

	echo 1 > $trace_dir/tracing_on
}

end_trace () {
	cp $trace_dir/trace $(dirname $0)
	echo 0 > $trace_dir/tracing_on
	echo > $trace_dir/set_ftrace_filter
	echo > $trace_dir/trace
}

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
mkfs.btrfs $dev -f -n 16k
mount $dev $mnt
sync

mkdir $mnt/files
create_files small 4095 10 $mnt/files/
create_files large 128k 1 $mnt/files/
btrfs sub snap $mnt $mnt/snap1

mkdir $mnt/snap1/snap1-files
create_files small 4095 10 $mnt/snap1/snap1-files/
create_files large 128k 1 $mnt/snap1/snap1-files/
btrfs sub snap $mnt/snap1 $mnt/snap2

mkdir $mnt/snap2/snap2-files
create_files small 4095 10 $mnt/snap2/snap2-files/
create_files large 128k 1 $mnt/snap2/snap2-files/

#sync

btrfs quota enable $mnt
btrfs quota rescan -w $mnt
btrfs qgrou show -prce $mnt
umount $mnt

mount $dev $mnt
btrfs sub del $mnt/snap1
btrfs file sync $mnt

umount $mnt
btrfsck $dev
