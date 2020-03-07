#!/bin/sh

# _user_add_file ( user_name, src, [dst] )
_user_add_file() {
	# COULDFIX: query passwd for proper pri grp, home dir
	dst=''

	local user_name
	local src
	local dst_rel

	user_name="${1:?}"

	src="${2:?}"
	dst_rel="${3:-${2##*/}}"
	dst_rel="${dst_rel#/}"
	dst="/home/${user_name}/${dst_rel}"

	case "${dst_rel}" in
		*/*)
			# bogus relpath -> don't care.
			autodie install -d -g "${user_name}" -o "${user_name}" -- "${dst%/*}"
		;;
	esac

	autodie install -m 0640 -g "${user_name}" -o "${user_name}" -- "${src}" "${dst}"
}


# root_add_file ( src, [dst] )
root_add_file() {
	dst=''

	local src
	local dst_rel

	src="${1:?}"
	dst_rel="${2:-${1##*/}}"
	dst_rel="${dst_rel#/}"
	dst="/root/${dst_rel}"

	case "${dst_rel}" in
		*/*)
			# bogus relpath -> don't care.
			autodie install -d -g wheel -o root -- "${dst%/*}"
		;;
	esac

	autodie install -D -m 0640 -g wheel -o root -- "${src}" "${dst}"
}


# _user_do ( user_name, *safe_cmd_str )
_user_do() {
	local user_name

	user_name="${1:?}"; shift

	[ ${#} -gt 0 ] || return 2

	su -s /bin/ksh -l "${user_name}" -c "${*}"
}


eval_user_funcs() {
	while [ ${#} -gt 0 ]; do
		if [ -n "${1-}" ]; then
			eval "${1}_add_file() { _user_add_file '${1}' \"\${@}\"; }"
			eval "${1}_do() { _user_do '${1}' \"\${@}\"; }"
		fi
		shift
	done
}
