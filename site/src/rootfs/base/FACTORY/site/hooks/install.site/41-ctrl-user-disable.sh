#!/bin/sh
[ "${OFEAT_CTRL_USER:-0}" -eq 0 ] || exit 0
[ -n "${OCONF_CTRL_USER-}" ] || exit 0

# TODO / COULDFIX: remove mfs mount for /home/<ctrl_user>
autodie delete_user "${OCONF_CTRL_USER}"
