#!/bin/sh

# NOTE: do not change this path w/o changing /etc/rc.local, too
AUTO_REBOOT_FLAG_FILE='/etc/rc.local.forcereboot'

clear_auto_reboot() {
    [ "${OFEAT_AUTO_REBOOT:-0}" -eq 1 ] || return 0

    if rm -- "${AUTO_REBOOT_FLAG_FILE}"; then
        return 0

    elif check_fs_lexists "${AUTO_REBOOT_FLAG_FILE}"; then
        return 1

    else
        return 0
    fi
}

want_auto_reboot() {
    [ "${OFEAT_AUTO_REBOOT:-0}" -eq 1 ] || return 0
    autodie touch "${AUTO_REBOOT_FLAG_FILE}"
}


check_auto_reboot_active() {
    # regardless of OFEAT_AUTO_REBOOT
    check_fs_lexists "${AUTO_REBOOT_FLAG_FILE}"
}
