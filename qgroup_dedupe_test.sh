#!/bin/bash

dev=/dev/sdb5
mnt=/mnt/test
trace_dir=/sys/kernel/debug/tracing
btrfs_module=/home/adam/linux-btrfs/fs/btrfs/btrfs.ko

_fail () {
	echo "FAILLLED!!"
	exit 1
}

init_trace () {
	echo 0 > $trace_dir/tracing_on
	echo > $trace_dir/trace
#	echo function_graph > $trace_dir/current_tracer
	echo > $trace_dir/set_event

	echo btrfs:btrfs_space_reservation >> $trace_dir/set_event

	echo 1 > $trace_dir/tracing_on
}

end_trace () {
	cp $trace_dir/trace $(dirname $0)
	echo 0 > $trace_dir/tracing_on
	echo > $trace_dir/set_ftrace_filter
	echo > $trace_dir/trace
}


umount $dev &> /dev/null
rmmod btrfs
insmod $btrfs_module || _fail

mkfs.btrfs $dev -f
mount $dev $mnt -o nospace_cache,enospc_debug
btrfs sub create $mnt/sub
btrfs quota enable $mnt

init_trace
btrfs qgroup limit 512K 0/257 $mnt
dd if=/dev/urandom of=$mnt/sub/test bs=1M count=1
umount $mnt
rmmod btrfs
end_trace
