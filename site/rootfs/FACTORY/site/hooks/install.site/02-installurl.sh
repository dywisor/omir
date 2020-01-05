#!/bin/sh
if \
	[ ${OFEAT_SHALLOW_LOCAL_MIRROR:-1} -eq 1 ] && \
	[ -n "${OCONF_INSTALLURL_UPSTREAM-}" ]
then
	fpath="/etc/installurl"

	print_action "Switching installurl to official mirror"
	printf '%s\n' "${OCONF_INSTALLURL_UPSTREAM}" > "${fpath}.site" || \
		die "Failed to write installurl"
	site_prep "${fpath}"
fi
