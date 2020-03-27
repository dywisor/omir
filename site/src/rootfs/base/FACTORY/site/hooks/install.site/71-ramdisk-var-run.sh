#!/bin/sh
#
feat_all "${OFEAT_RAMDISK_VAR_RUN-}" || exit 0
test "${OCONF_RAMDISK_VAR_RUN:-0}" -gt 0 || die "Invalid ramdisk size for /var/run"

mp='/var/run'

print_action "Prepare ramdisk at ${mp}"

size="${OCONF_RAMDISK_VAR_RUN}"
skel="/skel${mp}"
# allow suid for sockets
mnt_opts='rw,noexec,nodev'

autodie mkdir -p -- "${skel}"
autodie dopath "${skel}" 0755 'root:wheel'

autodie fstab_add_skel_mfs "${skel}" "${mp}" "${size}" -o "${mnt_opts}"
