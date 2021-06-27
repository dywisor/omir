#!/bin/sh
if clear_auto_reboot; then
    print_info "Removed reboot flag file"

else
    print_err "Failed to remove stale reboot flag file"
fi

# keep going
:
