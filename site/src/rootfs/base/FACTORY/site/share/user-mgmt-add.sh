#!/bin/sh

create_user() {
    _create_user 'skel' "${@}"
}

create_user_empty_home() {
    _create_user 'empty' "${@}"
}

create_user_ramdisk_home() {
    local user_ramdisk_size
    local user_ramdisk_copy_skel

    user_ramdisk_size="${1:?}"; shift
    user_ramdisk_copy_skel=1

    _create_user 'ramdisk' "${@}"
}

create_user_ramdisk_empty_home() {
    local user_ramdisk_size
    local user_ramdisk_copy_skel

    user_ramdisk_size="${1:?}"; shift
    user_ramdisk_copy_skel=0

    _create_user 'ramdisk' "${@}"
}

create_user_no_home() {
    _create_user 'none' "${@}"
}

# _create_user (
#    home_mode,
#    name,
#    uid,
#    shell:=/sbin/nologin,
#    home:=/home/<name>,
#    password_hash:=<login-disabled>,
#    **user_name!, **user_uid!, **user_gid!, **user_home!, **user_shell!
# )
#
_create_user() {
    user_name=
    user_uid=
    user_gid=
    user_home=
    user_shell=

    local arg_home_mode
    local arg_name
    local arg_uid
    local arg_shell
    local arg_home
    local arg_pwhash

    [ -n "${1-}" ] || die "empty home_mode? (BUG)"
    [ -n "${2-}" ] || die "missing user name"
    [ -n "${3-}" ] || die "missing user UID"

    arg_home_mode="${1:?}"
    arg_name="${2:?}"
    arg_uid="${3:?}"
    arg_shell="${4:-/sbin/nologin}"
    arg_home="${5-}"
    arg_pwhash="${6-}"

    if ! check_valid_user_name "${arg_name}"; then
        die "Invalid user name: ${arg_name}"
    fi

    case "${arg_home_mode}" in
        'none')
            arg_home='/var/empty'
        ;;
        'skel'|'empty'|'ramdisk')
            [ -n "${arg_home}" ] || arg_home="/home/${arg_name}"
        ;;
        *)
            die "Unknown home_mode ${arg_home_mode} (BUG)"
        ;;
    esac

    [ -n "${arg_pwhash}" ] || arg_pwhash='*************'

    if get_user_info "${arg_name}"; then
        print_info "User ${user_name:?} exists, skipping useradd."

    else
        print_action "Creating user ${arg_name}"
        # load options into ARGV
        set -- \
            -u "${arg_uid}" \
            -g '=uid' \
            -s "${arg_shell}" \
            -p "${arg_pwhash}" \
            -d "${arg_home}"

        case "${arg_home_mode}" in
            'skel') set -- "${@}" -m ;;
        esac

        autodie useradd "${@}" "${arg_name}"
        autodie get_user_info "${arg_name}"
    fi

    autodie "_init_user_home_${arg_home_mode}"
}


_init_user_home_none() {
    return 0
}

_init_user_home_skel() {
    _init_user_home_empty
}

_init_user_home_empty() {
    local DIRMODE

    DIRMODE=0700
    autodie dodir "${user_home:?}"
    autodie dopath "${user_home:?}" 0700 "${user_uid}:${user_gid}"
}

_init_user_home_ramdisk() {
    setup_ramdisk_home "${user_ramdisk_size-}" "${user_ramdisk_copy_skel-}"
}

# setup_ramdisk_home (
#    ramdisk_size_m:=10, ramdisk_copy_skel:=0,
#    **user_name, **user_uid, **user_gid, **user_home,
#    **user_home_skel!
# )
#
setup_ramdisk_home() {
    user_home_skel=

    local skel_root
    local ramdisk_size
    local ramdisk_copy_skel

    ramdisk_size="${1:-10}"
    ramdisk_copy_skel="${2:-0}"

    print_info "Setting up ramdisk home for ${user_name}"

    # try to remove empty home
    # race condition tolerated here
    if [ -h "${user_home}" ]; then
        # rm oder compare link dest
        autodie rm -- "${user_home}"

    elif [ -d "${user_home}" ]; then
        if ! rmdir -- "${user_home}" 2>/dev/null; then
            print_err "Manual cleanup of underlying ${user_home} required."

            # lock down old user home
            autodie dopath "${user_home}" 0750 "root:${user_gid}" "${user_home}"
        fi
    fi

    skel_root="/skel/home"
    autodie mkdir -p -- "${skel_root}"
    autodie dopath "${skel_root}" 0711 'root:wheel'

    user_home_skel="${skel_root}/${user_name}"
    autodie mkdir -p -- "${user_home_skel}"

    if [ "${ramdisk_copy_skel}" -eq 1 ] && [ -d /etc/skel ]; then
        autodie cp -a -- /etc/skel/. "${user_home_skel}/."
        autodie chown -R -- "${user_uid}:${user_gid}" "${user_home_skel}/"
    fi

    # chown/chmod after copy-skel
    autodie dopath "${user_home_skel}" 0770 "root:${user_gid}"

    autodie fstab_add_skel_mfs \
        "${user_home_skel}" "${user_home}" \
        "${ramdisk_size}" -o "rw,nodev,nosuid"
}
