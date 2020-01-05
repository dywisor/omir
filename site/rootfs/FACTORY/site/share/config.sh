#!/bin/sh

reload_localconfig() {
	[ -f "${FACTORY_SITE_LOCALCONFIG}" ] || return 0
	. "${FACTORY_SITE_LOCALCONFIG}" || die "Failed to load localconfig"
}

_load_config() {
	# base configuration file
	set -- "${FACTORY_SITE_CONFIG}"

	# local 'compile-time' configuration snippets
	if [ -d "${FACTORY_SITE_CONFD}" ]; then
		set +f
		set -- "${@}" "${FACTORY_SITE_CONFD}/"*.sh
		set -f
	fi

	while [ ${#} -gt 0 ]; do
		if [ -f "${1}" ]; then
			. "${1}" || die "Failed to load config file ${1}"
		fi
		shift
	done

	# install-time configuration
	reload_localconfig
}

autodie _load_config
