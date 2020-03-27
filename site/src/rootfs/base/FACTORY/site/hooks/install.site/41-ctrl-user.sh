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

setup_ctrl_ramdisk_home() {
    local skel
    local ramdisk_size

    ramdisk_size=120

    print_info "Setting up ramdisk home for ${user_name}"

    # try to remove empty home
    rmdir -- "${user_home}" 2>/dev/null || \
        print_err "Manual cleanup of underlying ${user_home} required."

    skel="/skel/home"
    autodie mkdir -p -- "${skel}"
    autodie dopath "${skel}" 0711 'root:wheel'

    skel="${skel}/${user_name}"
    autodie mkdir -p -- "${skel}"
    autodie dopath "${skel}" 0771 "root:${user_gid}"

    autodie fstab_add_skel_mfs "${skel}" "${user_home}" "${ramdisk_size}" -o "rw,nodev,nosuid"
}


autodie create_user_empty_home \
    "${OCONF_CTRL_USER}" \
    "${OCONF_CTRL_UID}" \
    '/bin/sh'

autodie chmod 0711 "${user_home}"

# ctrl user enables sshd, do feat_sshd check nonetheless
if feat_check_sshd; then
    autodie sshd_dofile_system_auth_keys default "${OCONF_CTRL_SSH_KEY-}"

    if [ -z "${sshd_auth_keys_can_login}" ]; then
        die "No SSH keys allowed for ctrl user, will be unable to login"
    fi
fi

autodie dofile_site "${doas_conf}" 0600 'root:wheel' gen_ctrl_doas_conf

if [ "${OFEAT_CTRL_USER_RAMDISK:-0}" -eq 1 ]; then
    if [ -n "${HW_USERMEM_M}" ] && [ ${HW_USERMEM_M} -gt 300 ]; then
        autodie setup_ctrl_ramdisk_home
    fi
fi
