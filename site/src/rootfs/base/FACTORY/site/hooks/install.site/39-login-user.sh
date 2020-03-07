#!/bin/sh
[ "${OFEAT_LOGIN_USER:-0}" -eq 1 ] || exit 0
[ -n "${OCONF_LOGIN_USER-}" ] || exit 0

# COULDFIX: get UID from /etc/passwd
autodie create_user "${OCONF_LOGIN_USER}" '1000'
autodie eval_user_funcs "${OCONF_LOGIN_USER}"

print_action "fixup home dir of user ${OCONF_LOGIN_USER}"
autodie "${OCONF_LOGIN_USER}_add_file" /etc/skel/.profile
autodie "${OCONF_LOGIN_USER}_add_file" /etc/skel/.vimrc
