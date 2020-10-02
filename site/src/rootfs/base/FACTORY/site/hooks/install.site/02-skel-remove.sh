#!/bin/sh
print_action "remove files from /etc/skel"

skel=/etc/skel
skel_ssh="${skel}/ssh"

if feat_check_sshd; then
    fp="${skel_ssh}/authorized_keys"
    print_info "Removing ${fp}"
    rm -f -- "${fp}"

    # remove ssh dir if empty
    rmdir -- "${skel_ssh}" 2>/dev/null || :
fi
