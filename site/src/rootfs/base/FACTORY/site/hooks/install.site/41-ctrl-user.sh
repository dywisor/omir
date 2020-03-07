#!/bin/sh
[ "${OFEAT_CTRL_USER:-0}" -eq 1 ] || exit 0
[ -n "${OCONF_CTRL_USER-}" ] || die "ctrl USER not set."
autodie check_valid_user_name "${OCONF_CTRL_USER}"
[ -n "${OCONF_CTRL_UID-}" ] || die "ctrl UID not set."

ssh_auth_keys='/etc/ssh/authorized_keys.ctrl'
doas_conf='/etc/doas.conf'

gen_ctrl_ssh_auth_keys() {
    local v0
    local can_login

    can_login=

    if locate_factory_file "${ssh_auth_keys##*/}"; then
        if grep -E -- '^[^#]' "${v0:?}"; then
            can_login='factory'

        elif [ ${?} -ne 1 ]; then
            die "Failed to read ${v0}"
        fi
    fi

    if [ -n "${OCONF_CTRL_SSH_KEY-}" ]; then
        printf '%s\n' "${OCONF_CTRL_SSH_KEY}" && can_login='config'
    fi

    [ -n "${can_login}" ] || die "No SSH keys allowed for ctrl user, will unable to login"

    return 0
}

gen_ctrl_doas_conf() {
    set -- 'SSH_CLIENT' 'SSH_CONNECTION' 'SSH_TTY'
    printf 'permit nopass setenv { %s } %s as root\n' \
        "${*}" \
        "${user_name}"
}

autodie create_user_empty_home \
    "${OCONF_CTRL_USER}" \
    "${OCONF_CTRL_UID}" \
    '/bin/sh'

autodie dofile_site "${ssh_auth_keys}" 0640 "root:${user_name}" gen_ctrl_ssh_auth_keys

autodie dofile_site "${doas_conf}" 0600 'root:wheel' gen_ctrl_doas_conf
