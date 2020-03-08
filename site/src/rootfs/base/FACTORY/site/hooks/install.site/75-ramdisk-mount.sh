#!/bin/sh
[ "${OFEAT_RAMDISK:-0}" -eq 1 ] || exit 0

print_action "prepare ramdisk mountpoint"

ramdisk_size=50
if [ -z "${HW_USERMEM_M}" ]; then
    :

elif [ ${HW_USERMEM_M} -gt 60000 ]; then
    ramdisk_size=2000

elif [ ${HW_USERMEM_M} -gt 30000 ]; then
    ramdisk_size=1000

elif [ ${HW_USERMEM_M} -gt 15000 ]; then
    ramdisk_size=500

elif [ ${HW_USERMEM_M} -gt 7500 ]; then
    ramdisk_size=250

elif [ ${HW_USERMEM_M} -gt 3750 ]; then
    ramdisk_size=125

elif [ ${HW_USERMEM_M} -gt 1875 ]; then
    ramdisk_size=60

else
    ramdisk_size=30

fi

autodie fstab_add_skel_mfs /skel/ram /ram "${ramdisk_size}"
autodie dopath /skel/ram 0755 'root:wheel'
