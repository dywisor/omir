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


__retlatch__() {
    "${@}" && rc=0 || rc=${?}
    return ${rc}
}


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


_get_factory_path() {
	v0=

	if [ -n "${2-}" ] && [ -n "${1-}" ]; then
		v0="${1}/${2}"
		return 0
	else
		return 1
	fi
}


_locate_factory_path() {
	_get_factory_path "${@}" || return 1
	[ -f "${v0}" ]
}


locate_factory_file() {
	_locate_factory_path "${FACTORY_SITE_FILES}" "${@}"
}

locate_factory_src() {
	_locate_factory_path "${FACTORY_SITE_SRC}" "${@}"
}


# factory_site_mode ( name )
#
#  Returns true if site script mode equals %name.
#
factory_site_mode() {
    [ "${FACTORY_SITE_MODE:-_}" = "${1-}" ]
}

# macros for known factory site modes
factory_site_mode_is_install()    { factory_site_mode 'install'; }
factory_site_mode_is_upgrade()    { factory_site_mode 'upgrade'; }
factory_site_mode_is_firsttime()  { factory_site_mode 'firsttime'; }


# feat_all ( *args )
#
#  Returns true if all args are set to '1'
#  and at least one arg was given, otherwise false.
#
#  Empty args will be interpreted as '0'.
#
#  This can be used for feature checks:
#
#    if feat_all "${A:-0}" "${B:-0}"; then
#       ...
#    fi
#
feat_all() {
    [ ${#} -gt 0 ] || return 1

    while [ ${#} -gt 0 ]; do
        [ "${1:-0}" -eq 1 ] || return 1
        shift
    done

    return 0
}

# feat_not_all ( *args )
#   IS NEGATED feat_all()
#
feat_not_all() {
    ! feat_all "${@}"
}

# feat_any( *args )
#
#  Returns true if at least one arg is set to '1'.
#
feat_any() {
    while [ ${#} -gt 0 ]; do
        if [ "${1:-0}" -eq 1 ]; then
            return 0
        fi
        shift
    done

    return 1
}
