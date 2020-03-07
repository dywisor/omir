#!/bin/sh
[ "${OFEAT_LOGIN_USER:-0}" -eq 0 ] || exit 0
[ -n "${OCONF_LOGIN_USER-}" ] || exit 0

autodie delete_user "${OCONF_LOGIN_USER}"
