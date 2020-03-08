#!/bin/sh
KERN_OSRELEASE="$( sysctl -n kern.osrelease )" || KERN_OSRELEASE=""

HW_USERMEM="$( sysctl -n hw.usermem )" || HW_USERMEM=""
HW_USERMEM_M=""
if [ -n "${HW_USERMEM}" ]; then
    HW_USERMEM_M="$(( HW_USERMEM / (1024*1024) ))"
    { test "${HW_USERMEM_M:-X}" -gt 0; } 2>/dev/null || HW_USERMEM_M=""
fi
