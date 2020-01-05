#!/bin/sh
[ "${OFEAT_SYSPATCH:-0}" -eq 1 ] || exit 0

print_action "syspatch"
syspatch && syspatch || print_err "syspatch failed."
want_auto_reboot
