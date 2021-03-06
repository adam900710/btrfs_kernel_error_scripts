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

	echo btrfs:add_delayed_data_ref		>> $trace_dir/set_event
	echo btrfs:add_delayed_tree_ref		>> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_trace_extent >> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_account_extents >> $trace_dir/set_event
	echo btrfs:btrfs_transaction_commit >> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_account_extent  >> $trace_dir/set_event
	echo btrfs:qgroup_update_counters       >> $trace_dir/set_event

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
mkfs.btrfs $dev -f
#mkfs.btrfs $dev -f -n 4k
mount -o inode_cache $dev $mnt
#mount $dev $mnt
sync

#create_files inline 2K 1000 $mnt
#create_files large 4m 1 $mnt

sync
init_trace
dmesg -C
btrfs quota enable $mnt
sync
end_trace
btrfs qgroup show -prce --raw $mnt

btrfs quota rescan -w $mnt
sync
btrfs qgroup show -prce --raw $mnt

umount $mnt
btrfsck $dev
