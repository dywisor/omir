#!/bin/sh

# user_set_ssh_login ( user_name, status )
user_set_ssh_login() {
    _user_set_ssh_access "${OCONF_SSHD_GROUP_LOGIN:?}" "${@}"
}

# user_set_ssh_shell ( user_name, status )
user_set_ssh_shell() {
    _user_set_ssh_access "${OCONF_SSHD_GROUP_SHELL:?}" "${@}"
}

# user_set_ssh_forwarding ( user_name, status )
user_set_ssh_forwarding() {
    _user_set_ssh_access "${OCONF_SSHD_GROUP_FORWARDING:?}" "${@}"
}

# _user_set_ssh_access ( group_name, user_name, status )
_user_set_ssh_access() {
    local group_name
    local user_name
    local status
    local v0

    group_name="${1-}"
    [ -n "${group_name}" ] || return 64

    user_name="${2-}"
    [ -n "${user_name}" ] || return 64

    status="${3:-0}"

    if [ "${status}" -eq 1 ]; then
        # usermod -G (OpenBSD) == usermod -aG (Linux)
        print_info "Adding user ${user_name} to group ${group_name}"
        autodie usermod -G "${group_name}" "${user_name}"

    elif [ "${status}" -eq 0 ]; then
        # http://openbsd.7691.n7.nabble.com/How-to-remove-user-from-group-td96758.html
        print_info "Removing user ${user_name} from group ${group_name}"
        autodie remove_user_from_group "${group_name}" "${user_name}"

    else
        return 64
    fi
}
