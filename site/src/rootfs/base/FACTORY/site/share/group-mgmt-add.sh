#!/bin/sh

# create_group ( name, gid )
create_group() {
    _create_group "${@}"
}

# _create_group ( name, gid, **group_name!, **group_gid! )
#
_create_group() {
    group_name=
    group_gid=

    local arg_name
    local arg_gid
    local v0

    [ -n "${1-}" ] || die "missing group name"
    [ -n "${2-}" ] || die "missing group UID"

    arg_name="${1:?}"
    arg_gid="${2:?}"

    if ! check_valid_group_name "${arg_name}"; then
        die "Invalid group name: ${arg_name}"
    fi

    if v0="$( fetch_group_gid_by_name "${arg_name}" )" && [ -n "${v0}" ]; then
        print_info "Group ${arg_name:?} exists, skipping groupadd."
        group_name="${arg_name}"
        group_gid="${v0}"
        return 0
    fi

    if v0="$( fetch_group_name_by_gid "${arg_gid}" )" && [ -n "${v0}" ]; then
        die "Group gid ${arg_gid} already taken: want=${arg_name} is=${v0}"
    fi

    print_action "Creating group ${arg_name} gid ${arg_gid}"
    autodie groupadd -g "${arg_gid}" "${arg_name}"

    group_name="${arg_name}"
    group_gid="${arg_gid}"
    return 0
}
