#!/bin/sh
[ "${OFEAT_LOGIN_USER:-0}" -eq 1 ] || exit 0
[ -n "${OCONF_LOGIN_USER-}" ] || exit 0

load_lib sshd-user

# COULDFIX: get UID from /etc/passwd
autodie create_user "${OCONF_LOGIN_USER}" '1000'
autodie eval_user_funcs "${OCONF_LOGIN_USER}"

if feat_check_sshd; then
    autodie user_set_ssh_access LOGIN_USER
fi

print_action "fixup home dir of user ${OCONF_LOGIN_USER}"
autodie "${OCONF_LOGIN_USER}_add_file" /etc/skel/.profile
autodie "${OCONF_LOGIN_USER}_add_file" /etc/skel/.vimrc
