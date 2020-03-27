#!/bin/sh
feat_any "${OFEAT_SSHD_CONFIG-}" "${OFEAT_CTRL_USER-}" || exit 0
load_lib sshd

sshd_allow_users=

sshd_login_users=
sshd_ctrl_users=
sshd_jump_users=

_sshd_add_allow_user() { sshd_allow_users="${sshd_allow_users:+${sshd_allow_users} }${1:?}"; }

_sshd_add_login_user() { sshd_login_users="${sshd_login_users:+${sshd_login_users} }${1:?}"; }
_sshd_add_ctrl_user() { sshd_ctrl_users="${sshd_ctrl_users:+${sshd_ctrl_users} }${1:?}"; }
_sshd_add_jump_user() { sshd_jump_users="${sshd_jump_users:+${sshd_jump_users} }${1:?}"; }


# sshd_add_user ( type, name:=, [from] )
sshd_add_user() {
    [ ${#} -le 3 ] && [ -n "${2-}" ] && [ -n "${1-}" ] || return 64

    local arg_user_type
    local arg_user_name
    local arg_sshd_from

    local allow_append
    local hosts

    arg_user_type="${1:?}"
    arg_user_name="${2-}"
    arg_sshd_from="${3-}"

    [ -n "${arg_user_name}" ] || return 0

    # unpack arg_sshd_from
    set --
    if [ -n "${arg_sshd_from}" ]; then
        case "$-" in
            *f*) set -- ${arg_sshd_from} ;;
            *) set -f; set -- ${arg_sshd_from}; set +f ;;
        esac
    fi

    # create list for AllowUsers directive
    if [ ${#} -eq 0 ]; then
        # no host restrictions
        allow_append="${arg_user_name}"
    else
        # apply host restrictions: user@host
        hosts="${*}"
        set --
        for host in ${hosts}; do
            set -- "${@}" "${arg_user_name}@${host}"
        done
        allow_append="${*}"
    fi

    [ -n "${allow_append}" ] || die "allow_append is empty (BUG)"

    "_sshd_add_${arg_user_type}_user" "${arg_user_name}" || return
    _sshd_add_allow_user "${allow_append}"
}

print_action "Preparing SSH server configuration"

if feat_all "${OFEAT_LOGIN_USER-}" "${OFEAT_LOGIN_USER_SSH-}"; then
    autodie sshd_add_user login "${OCONF_LOGIN_USER-}"
fi

if feat_all "${OFEAT_CTRL_USER-}"; then
    autodie sshd_add_user ctrl \
        "${OCONF_CTRL_USER-}" "${OCONF_CTRL_SSH_FROM-}"
fi

print_action "Creating SSH server configuration"

[ -n "${sshd_allow_users}" ] || die "Nobody would be able to log in, aborting."

autodie sshd_setup \
    "${sshd_allow_users}" \
    "${sshd_login_user}" \
    "${sshd_ctrl_users}" \
    "${sshd_jump_users}"
