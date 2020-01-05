#!/bin/sh
[ "${OFEAT_INSTALL_FW:-0}" -eq 1 ] || exit 0

[ -n "${KERN_OSRELEASE-}" ] || exit 0
[ -n "${OCONF_INSTALLURL_LOCAL-}" ] || exit 0

print_action "Install firmware from local mirror"
fw_update -p "${OCONF_INSTALLURL_LOCAL}/firmware/${KERN_OSRELEASE}/" || print_err "Failed to get firmware!"
