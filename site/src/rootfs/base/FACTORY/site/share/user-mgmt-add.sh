#!/bin/sh

create_user() {
    _create_user 'skel' "${@}"
}

create_user_empty_home() {
    _create_user 'empty' "${@}"
}

create_user_no_home() {
    _create_user 'none' "${@}"
}

# _create_user (
#    home_mode,
#    name,
#    uid,
#    shell:=/sbin/nologin,
#    home:=/home/<name>,
#    password_hash:=<login-disabled>,
#    **user_name!, **user_uid!, **user_gid!, **user_home!, **user_shell!
# )
#
_create_user() {
    user_name=
    user_uid=
    user_gid=
    user_home=
    user_shell=

    local arg_home_mode
    local arg_name
    local arg_uid
    local arg_shell
    local arg_home
    local arg_pwhash

    [ -n "${1-}" ] || die "empty home_mode? (BUG)"
    [ -n "${2-}" ] || die "missing user name"
    [ -n "${3-}" ] || die "missing user UID"

    arg_home_mode="${1:?}"
    arg_name="${2:?}"
    arg_uid="${3:?}"
    arg_shell="${4:-/sbin/nologin}"
    arg_home="${5-}"
    arg_pwhash="${6-}"

    if ! check_valid_user_name "${arg_name}"; then
        die "Invalid user name: ${arg_name}"
    fi

    case "${arg_home_mode}" in
        'none')
            arg_home='/var/empty'
        ;;
        'skel'|'empty')
            [ -n "${arg_home}" ] || arg_home="/home/${arg_name}"
        ;;
        *)
            die "Unknown home_mode ${arg_home_mode} (BUG)"
        ;;
    esac

    [ -n "${arg_pwhash}" ] || arg_pwhash='*************'

    if get_user_info "${arg_name}"; then
        print_info "User ${user_name:?} exists, skipping useradd."

    else
        print_action "Creating user ${arg_name}"
        # load options into ARGV
        set -- \
            -u "${arg_uid}" \
            -g '=uid' \
            -s "${arg_shell}" \
            -p "${arg_pwhash}" \
            -d "${arg_home}"

        case "${arg_home_mode}" in
            'skel') set -- "${@}" -m ;;
        esac

        autodie useradd "${@}" "${arg_name}"
        autodie get_user_info "${arg_name}"
    fi

    autodie "_init_user_home_${arg_home_mode}"
}


_init_user_home_none() {
    return 0
}

_init_user_home_skel() {
    _init_user_home_empty
}

_init_user_home_empty() {
    local DIRMODE

    DIRMODE=0700
    autodie dodir "${user_home:?}"
    autodie dopath "${user_home:?}" 0700 "${user_uid}:${user_gid}"
}
