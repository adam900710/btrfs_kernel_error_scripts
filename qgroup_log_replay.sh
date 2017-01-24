#!/bin/bash

real_dev=/dev/sdb5
real_dev_size=$(blockdev --getsz $real_dev)
flakey_dev=/dev/mapper/flakey-test
flakey_table="0 $real_dev_size flakey $real_dev 0 180 0"
flakey_table_drop="0 $real_dev_size flakey $real_dev 0 0 180 1 drop_writes"
mnt=/mnt/test/
trace_dir=/sys/kernel/debug/tracing

_fail ()
{
	echo "FAILLLLLED"
	exit 1
}

init_dm_flakey ()
{
	local blk_dev_size=$(blockdev --getsz $real_dev)

	dmsetup create flakey-test --table "$flakey_table" || _fail
}

drop_write ()
{
	dmsetup suspend flakey-test || _fail
	dmsetup load flakey-test --table "$flakey_table_drop" || _fail
	dmsetup resume flakey-test || _fail
}

clean_dm_flakey ()
{
	dmsetup resume flakey-test
	umount $mnt &> /dev/null
	udevadm settle
	dmsetup remove flakey-test
	dmsetup mknodes
}

init_trace () {
	echo 0 > $trace_dir/tracing_on
	echo > $trace_dir/trace
	echo > $trace_dir/set_event

	echo btrfs:add_delayed_data_ref		>> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_insert_dirty_extent >> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_account_extent  >> $trace_dir/set_event

	echo 1 > $trace_dir/tracing_on
}

end_trace () {
	cp $trace_dir/trace $(dirname $0)
	echo 0 > $trace_dir/tracing_on
	echo > $trace_dir/set_ftrace_filter
	echo > $trace_dir/trace
}
clean_dm_flakey
init_dm_flakey

mkfs.btrfs $flakey_dev -f 
mount -o nospace_cache $flakey_dev $mnt
btrfs quota enable $mnt
btrfs quota rescan -w $mnt
sync

xfs_io -f -c "pwrite 0 64K" -c "fsync" $mnt/file1

btrfs qgroup show -prce $mnt
drop_write
umount $mnt

btrfsck $flakey_dev
btrfs-debug-tree $flakey_dev >  $(dirname $0)/debug_tree

clean_dm_flakey

init_trace
mount $real_dev $mnt -o nospace_cache
btrfs qg show -prce $mnt
end_trace
umount $mnt
btrfsck $real_dev
