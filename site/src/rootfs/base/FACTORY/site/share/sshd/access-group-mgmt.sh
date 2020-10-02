#!/bin/sh

# user_set_ssh_access ( var_ns )
#
#   Example usage: user_set_ssh_access LOGIN_USER
#
user_set_ssh_access() {
    local var_ns
    local var_feat
    local var_conf
    local user_name
    local can_login
    local can_shell
    local can_fwd
    local chroot_home

    var_ns="${1:?}"
    var_feat="OFEAT_${var_ns}"
    var_conf="OCONF_${var_ns}"

    eval "user_name=\"\${${var_conf}-}\""
    [ -n "${user_name}" ] || die "user name missing in namespace ${var_ns}"

    eval "can_login=\"\${${var_feat}_SSH-}\""

    # group mgmt disabled by empty value?
    [ -n "${can_login}" ] || return 0

    if test "${can_login}" -eq 1 2>/dev/null; then
        eval "can_shell=\"\${${var_feat}_SSH_SHELL:-0}\""
        eval "can_fwd=\"\${${var_feat}_SSH_FORWARDING:-0}\""
        eval "chroot_home=\"\${${var_feat}_SSH_CHROOT_HOME:-0}\""
    else
        can_shell=0
        can_fwd=0
        chroot_home=0   # debatable
    fi

    print_info "Configuring SSH access for user ${user_name}:"
    print_info "  login=${can_login} shell=${can_shell} forwarding=${can_fwd} chroot_home=${chroot_home}"
    autodie user_set_ssh_login "${user_name}" "${can_login}"
    autodie user_set_ssh_shell "${user_name}" "${can_shell}"
    autodie user_set_ssh_forwarding "${user_name}" "${can_fwd}"
    autodie user_set_ssh_chroot_home "${user_name}" "${chroot_home}"
}

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

# user_set_ssh_chroot_home ( user_name, status )
user_set_ssh_chroot_home() {
    _user_set_ssh_access "${OCONF_SSHD_GROUP_CHROOT_HOME:?}" "${@}"
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
