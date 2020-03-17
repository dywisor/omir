#!/bin/sh

# delete_user ( name )
delete_user() {
    local user_name
    local user_uid
    local user_gid
    local user_home
    local user_shell

    [ -n "${1-}" ] || die "missing user name"
    check_valid_user_name "${1}" || die "Invalid user name"

    if ! get_user_info "${1}"; then
        print_info "Not removing user ${1}: does not exist"
        return 0
    fi

    print_action "Removing user ${user_name:?}"

    # FIXME: chown remaining files belonging to that user to root?
    autodie userdel -r "${user_name}"
    groupdel "${user_name}" || :  # non-fatal; FIXME check beforehand
}
