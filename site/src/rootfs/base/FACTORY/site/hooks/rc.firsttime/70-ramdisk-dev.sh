#!/bin/sh
# Cannot create device nodes while in chroot,
# so ./MAKEDEV has to be called during rc.firsttime and not install.site.
#
[ "${OFEAT_RAMDISK_DEV:-0}" -eq 1 ] || exit 0

print_action "Prepare ramdisk at /dev"

skel=/skel/dev

autodie mkdir -p -- "${skel}"
autodie install -m 0555 -- /dev/MAKEDEV "${skel}/MAKEDEV"
( cd "${skel}" && ./MAKEDEV all; ) || die "Failed to create device nodes in ${skel}"

print_action "Mount ramdisk at /dev"
autodie fstab_add_skel_mfs "${skel}" /dev 5 -o 'rw,nosuid,noexec' -i 128
autodie mount /dev
