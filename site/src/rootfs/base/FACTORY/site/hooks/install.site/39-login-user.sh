#!/bin/sh
[ "${OFEAT_LOGIN_USER:-0}" -eq 1 ] || exit 0
[ -n "${OCONF_LOGIN_USER-}" ] || exit 0

load_lib sshd-user

# COULDFIX: get UID from /etc/passwd
autodie create_user "${OCONF_LOGIN_USER}" '1000'
user_real_home="${user_home:?}"
autodie eval_user_funcs "${OCONF_LOGIN_USER}"

if feat_check_sshd; then
    autodie user_set_ssh_access LOGIN_USER

    sshd_auth_keys_copy_keys_from_home=1
    autodie sshd_dofile_system_auth_keys
fi

# The login user gets usually created by the installer,
# so adjust ramdisk-home after creating the user and copying SSH auth keys.
using_ramdisk=0
if [ "${OFEAT_LOGIN_USER_RAMDISK:-0}" -eq 1 ]; then
    size="${OCONF_LOGIN_USER_RAMDISK_SIZE:-5}"

    if [ -z "${HW_USERMEM_M}" ] || [ $(( HW_USERMEM_M - size )) -lt 200 ]; then
        print_err "Disabling ramdisk for login user, not enough memory available."
    else
        # size, copy_skel, wipe_home
        autodie setup_ramdisk_home \
            "${size}" \
            1 \
            "${OFEAT_LOGIN_USER_RAMDISK_WIPE_HOME:-0}"

        user_home="${user_home_skel:?}"
        using_ramdisk=1
    fi
fi

# When using the home directory created by the installer,
# some site.tgz files may be missing.
if [ ${using_ramdisk} -eq 0 ]; then
    print_action "fixup home dir of user ${OCONF_LOGIN_USER}"
    autodie "${OCONF_LOGIN_USER}_add_file" /etc/skel/.profile
    autodie "${OCONF_LOGIN_USER}_add_file" /etc/skel/.vimrc
fi
