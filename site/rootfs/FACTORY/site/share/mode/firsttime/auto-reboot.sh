#!/bin/sh

AUTO_REBOOT_FLAG_FILE='/auto_reboot_after_install'

want_auto_reboot() {
	[ "${OFEAT_AUTO_REBOOT:-0}" -eq 1 ] || return 0
	autodie touch "${AUTO_REBOOT_FLAG_FILE}"
}
