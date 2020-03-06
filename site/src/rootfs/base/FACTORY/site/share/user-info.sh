#!/bin/sh

# check_valid_user_name ( name )
#
#  Strict user name checker, will only allow lowercase letters.
#
check_valid_user_name() {
    printf '%s' "${1}" | grep -qE -- '^[a-z]+$'
}

get_pwhash_disabled() {
    v0='*************'
}

check_user_exists() {
	grep -q -- "^${1}:" < /etc/passwd
}

fetch_user_home() {
    < /etc/passwd awk -F : -v user="${1}" \
        'BEGIN{ m=1; } ($1 == user) { print $6; m=0; exit; } END{ exit m; }'
}

get_user_home() {
    v0="$( fetch_user_home "${@}" )" && [ -n "${v0}" ]
}


fetch_user_info() {
    < /etc/passwd awk -F : -v user="${1}" \
        'BEGIN{ m=1; } ($1 == user) { print $1, $3, $4, $6, $7; m=0; exit; } END{ exit m; }'
}

get_user_info() {
    user_name=
    user_uid=
    user_gid=
    user_home=
    user_shell=

    local data

    data="$( fetch_user_info "${@}" )" && [ -n "${data}" ] || return 1

    case "$-" in
        *f*) set -- ${data} ;;
        *) set -f; set -- ${data}; set +f ;;
    esac

    # name, uid, gid, home must be present
    [ ${#} -ge 4 ] || return 2

    user_name="${1}"
    user_uid="${2}"
    user_gid="${3}"
    user_home="${4}"
    user_shell="${5-}"

    return 0
}
