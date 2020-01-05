#!/bin/sh

_localconfig_write_var() {
	printf "%s='%s'\n" "${1}" "${2}" >> "${FACTORY_SITE_LOCALCONFIG}" \
		|| die "Failed to add var to localconfig"
}

# localconfig_write_tag ( *tag )
localconfig_write_tag() {
	[ ${#} -gt 0 ] || return 0

	printf '# %s\n' "${1}" >> "${FACTORY_SITE_LOCALCONFIG}" \
		|| die "Failed to write tag to localconfig"
}


# localconfig_add ( varname, value )
localconfig_add() {
	local varname
	local value

	varname="${1:?}"
	value="${2?}"

	_localconfig_write_var "${varname}" "${value}" || return
	eval "${varname}=\"\${value}\"" || die "Failed to eval var"
}
