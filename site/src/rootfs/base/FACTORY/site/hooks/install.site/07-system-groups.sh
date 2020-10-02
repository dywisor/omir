#!/bin/sh

print_action "Create system groups"

# load ARGV: flat list of 2-tuples (group_name, group_gid)
set --

if feat_check_sshd; then
    print_info "Adding groups for SSH access"

    # declared as mandatory in the config, but don't be a ... about it
    set -- \
        "${OCONF_SSHD_GROUP_LOGIN-}" "${OCONF_SSHD_GID_LOGIN-}" \
        "${OCONF_SSHD_GROUP_SHELL-}" "${OCONF_SSHD_GID_SHELL-}" \
        "${OCONF_SSHD_GROUP_FORWARDING-}" "${OCONF_SSHD_GID_FORWARDING-}" \
        "${OCONF_SSHD_GROUP_CHROOT_HOME-}" "${OCONF_SSHD_GID_CHROOT_HOME-}"
fi

while [ $# -gt 0 ]; do
    if [ -n "${1}" ] && [ -n "${2}" ]; then
        autodie create_group "${1}" "${2}"
    fi
    shift 2 || die
done
