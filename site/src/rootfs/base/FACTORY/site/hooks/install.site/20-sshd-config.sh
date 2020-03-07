#!/bin/sh
config_mode=
sshd_login_user=
sshd_login_from=

if [ "${OFEAT_CTRL_USER:-0}" -eq 1 ]; then
    config_mode='ctrl'
    sshd_login_user="${OCONF_CTRL_USER-}"
    sshd_login_from="${OCONF_CTRL_SSH_FROM-}"

elif [ "${OFEAT_SSHD_CONFIG:-0}" -eq 1 ]; then
    config_mode='login'
    sshd_login_user="${OCONF_LOGIN_USER-}"
    sshd_login_from=

else
    exit 0
fi

[ -n "${config_mode}" ] || die "assertion error (BUG)"
[ -n "${sshd_login_user}" ] || die "No ${config_mode} user configured!"
# sshd_login_from may be empty

gen_sshd_config() {
    local allow_users_from
    local hosts
    local user
    local host

    case "$-" in
        *f*) set -- ${sshd_login_from} ;;
        *) set -f; set -- ${sshd_login_from}; set +f ;;
    esac

    if [ ${#} -eq 0 ]; then
        allow_users_from="${sshd_login_user}"
    else
        hosts="${*}"
        set --
        for host in ${hosts}; do
            set -- "${@}" "${sshd_login_user}@${host}"
        done
        allow_users_from="${*}"
    fi

    [ -n "${allow_users_from}" ] || die "allow_users_from is empty (BUG)"

    {
        render_template "sshd_config.${config_mode}" \
            ALLOW_USERS "${allow_users_from}" \
            LOGIN_USER "${sshd_login_user}"
    } || return
}


print_action "Generate SSH server configuration"

autodie dodir /etc/ssh

dofile_site \
    '/etc/ssh/sshd_config' 0600 'root:wheel' \
    gen_sshd_config
