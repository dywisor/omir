#!/bin/sh
[ "${OFEAT_PKG_INSTALL:-0}" -eq 1 ] || exit 0

# load list of packages to be installed
set -- ${OCONF_PKG_INSTALL-}

if [ ${#} -gt 0 ]; then
	print_action "Install packages: ${*}"
	pkg_add "${@}" || print_err "Failed to install packages: ${*}"
else
	print_info "No packages to be installed configured."
fi
