#!/bin/sh
feat_check_sshd || exit 0
load_lib sshd

print_action "Creating SSH server configuration"

autodie sshd_setup
