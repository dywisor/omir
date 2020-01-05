#!/bin/sh
[ -n "${OCONF_LOGIN_USER-}" ] || exit 0

print_action "fixup home dir of user ${OCONF_LOGIN_USER}"
autodie eval_user_funcs "${OCONF_LOGIN_USER}"

autodie "${OCONF_LOGIN_USER}_add_file" /etc/skel/.profile
autodie "${OCONF_LOGIN_USER}_add_file" /etc/skel/.vimrc
