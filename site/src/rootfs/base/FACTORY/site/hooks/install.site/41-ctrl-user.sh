#!/bin/sh
[ "${OFEAT_CTRL_USER:-0}" -eq 1 ] || exit 0
[ -n "${OCONF_CTRL_USER-}" ] || die "ctrl USER not set."
autodie check_valid_user_name "${OCONF_CTRL_USER}"
[ -n "${OCONF_CTRL_UID-}" ] || die "ctrl UID not set."

load_lib sshd-user

doas_conf='/etc/doas.conf'

gen_ctrl_doas_conf() {
    set -- 'SSH_CLIENT' 'SSH_CONNECTION' 'SSH_TTY'
    printf 'permit nopass setenv { %s } %s\n' \
        "${*}" \
        "${user_name}"
}

set -- "${OCONF_CTRL_USER}" "${OCONF_CTRL_UID}" '/bin/sh'

if \
    [ "${OFEAT_CTRL_USER_RAMDISK:-0}" -eq 1 ] && \
    [ -n "${HW_USERMEM_M}" ] && [ ${HW_USERMEM_M} -gt 300 ]
then
    autodie create_user_ramdisk_empty_home 120 "${@}"
    user_real_home="${user_home:?}"
    user_home="${user_home_skel:?}"

else
    autodie create_user_empty_home "${@}"
    user_real_home="${user_home:?}"
fi

# for Ansible temporary directories: other users must be able to cross user_home
autodie chmod -h -- a+x "${user_home}"

# ctrl user enables sshd, do feat_sshd check nonetheless
if feat_check_sshd; then
    autodie user_set_ssh_access CTRL_USER

    sshd_auth_keys_copy_keys_from_home=0
    autodie sshd_dofile_system_auth_keys default "${OCONF_CTRL_SSH_KEY-}"

    [ -n "${sshd_auth_keys_can_login}" ] || \
        print_err "${user_name} will not be able to log in via SSH."
fi

autodie dofile_site "${doas_conf}" 0600 'root:wheel' gen_ctrl_doas_conf
