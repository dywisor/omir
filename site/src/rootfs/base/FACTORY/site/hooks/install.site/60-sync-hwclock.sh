#!/bin/sh
[ "${OFEAT_SYNC_HWCLOCK:-0}" -eq 1 ] || exit 0

name='sync-hwclock'

print_action "Compile program: ${name}"
if ! site_cc_prog sync-hwclock; then
    print_err "Failed to compile {name}"
    exit 0  # HOOK-CONTINUE
fi
x_prog="${v0:?}"

# FIXME / TODO MAYBE: ntp update

print_action "${name}"
"${x_prog}" || print_err "${name} failed"

exit 0  # HOOK-CONTINUE
