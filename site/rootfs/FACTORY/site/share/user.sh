#!/bin/sh

# _user_add_file ( user_name, src, [dst] )
_user_add_file() {
	# COULDFIX: query passwd for proper pri grp, home dir
	dst=''

	local user_name
	local src

	user_name="${1:?}"

	src="${2:?}"
	dst="/home/${user_name}/${3:-${2##*/}}"

	autodie install -D -m 0640 -g "${user_name}" -o "${user_name}" -- "${src}" "${dst}"
}


# root_add_file ( src, [dst] )
root_add_file() {
	dst=''

	local src

	src="${1:?}"
	dst="/root/${2:-${1##*/}}"

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


# _create_user ( user_name, uid, shell=/sbin/nologin )
_create_user() {
	local user_name
	local uid
	local shell

	user_name="${1:?}"
	uid="${2:?}"
	shell='/sbin/nologin'

	if ! grep -q -- "^${user_name}\:" /etc/passwd; then
		autodie useradd -g =uid -s "${shell}" -d "/home/${user_name}" -m -u "${uid}" "${user_name}"
	fi

	eval_user_funcs "${user_name}"
}
