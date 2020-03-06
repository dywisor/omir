#!/bin/sh
[ "${OFEAT_LOGIN_USER:-0}" -eq 0 ] || exit 0
[ -n "${OCONF_LOGIN_USER-}" ] || exit 0

get_user_info "${OCONF_LOGIN_USER}" || exit 0

print_action "Remove login user ${user_name}"

# FIXME: chown files belonging to login user outside of home to root?
autodie userdel -r "${user_name}"
groupdel "${user_name}" || :  # non-fatal FIXME check beforehand
