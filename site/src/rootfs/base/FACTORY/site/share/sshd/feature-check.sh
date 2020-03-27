#!/bin/sh

feat_check_sshd() {
    feat_any "${OFEAT_SSHD_CONFIG-}" "${OFEAT_CTRL_USER-}" || exit 0
}
