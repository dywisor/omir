#!/bin/sh
[ "${OFEAT_RAMDISK:-0}" -eq 1 ] || exit 0

print_action "prepare ramdisk mountpoint"

ramdisk_size=50
if ! hw_usermem="$(sysctl -n hw.usermem)"; then
	:

elif [ -n "${hw_usermem}" ]; then
	mem_m="$(( hw_usermem / (1024*1024) ))"

	if ! { test "${mem_m:-X}" -gt 0; } 2>/dev/null; then
		:

	elif [ ${mem_m} -gt 60000 ]; then
		ramdisk_size=2000

	elif [ ${mem_m} -gt 30000 ]; then
		ramdisk_size=1000

	elif [ ${mem_m} -gt 15000 ]; then
		ramdisk_size=500

	elif [ ${mem_m} -gt 7500 ]; then
		ramdisk_size=250

	elif [ ${mem_m} -gt 3750 ]; then
		ramdisk_size=125

	elif [ ${mem_m} -gt 1875 ]; then
		ramdisk_size=60

	else
		ramdisk_size=30
	fi
fi

autodie fstab_add_skel_mfs /ram "${ramdisk_size}"
autodie dopath /skel/ram 0755 'root:wheel'
