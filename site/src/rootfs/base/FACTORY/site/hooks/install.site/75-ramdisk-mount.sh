#!/bin/sh
[ "${OFEAT_RAMDISK:-0}" -eq 1 ] || exit 0

print_action "prepare ramdisk mountpoint"

autodie mkdir -p -m 0755 -- /skel/ram
autodie mkdir -p -m 0555 -- /ram

__io_mounted() {
	awk -v mp="${1}" 'BEGIN{e=1;} ($2 == mp) { e=0; exit; } END{exit e;}'
}

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


if ! __io_mounted /ram < /etc/fstab; then
	autodie cp -- /etc/fstab /etc/fstab.site
	printf '\nswap /ram mfs rw,nodev,noexec,nosuid,-s=%sm,-P=/skel/ram 0 0\n' "${ramdisk_size}" >> /etc/fstab.site || die
	autodie site_prep /etc/fstab
fi
