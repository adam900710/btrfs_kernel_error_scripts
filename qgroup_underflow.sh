#!/bin/bash
SCRATCH_DEV=/dev/vdb5
SCRATCH_MNT=/mnt/scratch
trace_dir=/sys/kernel/debug/tracing

init_trace () {
	echo 0 > $trace_dir/tracing_on
	echo > $trace_dir/trace
#	echo function_graph > $trace_dir/current_tracer
	echo > $trace_dir/set_event

	echo btrfs:qgroup_update_reserve >> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_reserve_data >> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_release_data >> $trace_dir/set_event
	echo btrfs:btrfs_qgroup_free_delayed_ref >> $trace_dir/set_event
	echo btrfs:qgroup_meta_reserve >> $trace_dir/set_event

	echo 40960 > $trace_dir/buffer_size_kb

	echo 1 > $trace_dir/tracing_on
}

end_trace () {
	cp $trace_dir/trace $(dirname $0)
	echo 0 > $trace_dir/tracing_on
	echo > $trace_dir/set_ftrace_filter
	echo > $trace_dir/trace
}

umount $SCRATCH_DEV &> /dev/null
mkfs.btrfs -f $SCRATCH_DEV
mount -t btrfs $SCRATCH_DEV $SCRATCH_MNT
dmesg -C
cd $SCRATCH_MNT
btrfs quota enable $SCRATCH_MNT
btrfs subvolume create a
btrfs qgroup limit 20m a $SCRATCH_MNT
sync
init_trace
for c in {1..7}; do
dd if=/dev/zero  bs=1M count=5 of=$SCRATCH_MNT/a/file;
done
sync

end_trace
touch $SCRATCH_MNT/a/newfile

echo "Removing file"
rm $SCRATCH_MNT/a/file
