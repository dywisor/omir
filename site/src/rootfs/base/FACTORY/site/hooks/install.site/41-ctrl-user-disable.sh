#!/bin/sh
[ "${OFEAT_CTRL_USER:-0}" -eq 0 ] || exit 0
[ -n "${OCONF_CTRL_USER-}" ] || exit 0

autodie delete_user "${OCONF_CTRL_USER}"
