#!/bin/sh
[ "${OFEAT_SYSPATCH:-0}" -eq 1 ] || exit 0

print_action "syspatch"
if __retlatch__ syspatch; then
    # signalize reboot required
    want_auto_reboot

    # run again in case there are more pending patches
    if __retlatch__ syspatch; then
        :

    elif [ ${rc} -eq 2 ]; then
        :  # no patches available

    else
        print_err "second syspatch failed."
    fi

elif [ ${rc} -eq 2 ]; then
    print_info "no patches available"

else
    print_err "syspatch failed"
fi
