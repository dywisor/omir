#!/bin/sh

print_err() {
	printf '%s\n' "${@}" 1>&2
}


print_info() {
	printf '%s\n' "${@}" 1>&2
}


print_action() {
	printf '\n*** %s ***\n' "${1}"
}


__nostdout__() { "${@}" 1>/dev/null; }
__nostderr__() { "${@}" 2>/dev/null; }
__quietly__()  { "${@}" 1>/dev/null 2>&1; }

__have_cmd__() { __quietly__ command -V "${1}"; }


main_die() {
	local die_msg

	print_err "${1:+died: }${1:-died.}"
	exit "${2:-255}"
}


hook_die() {
	print_err "died in ${__HOOK__:-???}${1:+:}${1:-.}"
	exit "${2:-255}"
}


die() {
	if [ -n "${__HOOK__-}" ]; then
		hook_die "${@}"
	else
		main_die "${@}"
	fi
}


autodie() {
	"${@}" || die "command '${*}' returned ${?}"
}


_load_lib() {
	local __FILE__

	__FILE__="${FACTORY_SITE_SHLIB}/${1}.sh"
	. "${__FILE__}" || die "Failed to load lib ${1}" 222
}


load_lib() {
	while [ ${#} -gt 0 ]; do
		[ -z "${1}" ] || _load_lib "${1}"
		shift
	done
}


load_mode_lib() {
	while [ ${#} -gt 0 ]; do
		[ -z "${1}" ] || _load_lib "mode/${FACTORY_SITE_MODE}/${1}"
		shift
	done
}
