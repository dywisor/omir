#!/bin/sh

feat_check_sshd() {
    if [ "${OFEAT_SSHD_CONFIG:-0}" -eq 1 ]; then
        return 0

    elif \
        [ "${OFEAT_CTRL_USER:-0}" -eq 1 ] && \
        [ "${OFEAT_CTRL_USER_SSH:-1}" -eq 1 ]
    then
        localconfig_write_tag "SSH server implicitly enabled by ctrl user"
        localconfig_add "OFEAT_SSHD_CONFIG" "1"
        return 0

    else
        return 1
    fi
}
