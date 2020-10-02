#!/bin/sh

# sshd_dofile_system_auth_keys (
#    [gen_auth_keys_func:=<default>], [*func_args],
#    **user_name, **user_uid, **user_gid,
#    **sshd_auth_keys_path!, **sshd_auth_keys_dir!,
#    **sshd_auth_keys_mode!, **sshd_auth_keys_owner!
# )
#
sshd_dofile_system_auth_keys() {
    sshd_auth_keys_can_login=
    sshd_auth_keys_mode=
    sshd_auth_keys_owner=

    sshd_get_system_auth_keys_path || return

    sshd_auth_keys_mode='0640'
    sshd_auth_keys_owner="0:${user_gid:-0}"

    _sshd_lazy_dodir_auth_keys_dir 0710 "root:${OCONF_SSHD_GROUP_LOGIN:-wheel}" || return
    _sshd_dofile_auth_keys "${@}" || return
}


_sshd_get_auth_keys_path_prereq() {
    [ -n "${user_name-}" ] || return 1
}


_sshd_set_auth_keys_path() {
    sshd_auth_keys_path="${1-}"
    sshd_auth_keys_dir=

    case "${sshd_auth_keys_path}" in
        ?*/?*) sshd_auth_keys_dir="${sshd_auth_keys_path%/*}" ;;
    esac

    return 0
}


_sshd_lazy_dodir_auth_keys_dir() {
    [ -z "${sshd_auth_keys_dir}" ] || \
    [ -d "${sshd_auth_keys_dir}" ] || \
    dodir_mode "${sshd_auth_keys_dir}" "${@}"
}


sshd_get_system_auth_keys_path() {
    _sshd_set_auth_keys_path

    _sshd_get_auth_keys_path_prereq || return 1

    _sshd_set_auth_keys_path "${SSHD_SYSTEM_AUTH_KEYS_DIR}/${user_name}"
}


# @stdout sshd_default_gen_sshd_auth_keys (
#    [*extra_keys], **user_name
# )
#   also reads factory file authorized_keys.<user_name>
#
sshd_default_gen_sshd_auth_keys() {
    # redundant
    sshd_auth_keys_can_login=

    local v0

    if locate_factory_file "authorized_keys.${user_name}"; then
        if grep -E -- '^[^#]' "${v0:?}"; then
            sshd_auth_keys_can_login='factory'

        elif [ ${?} -ne 1 ]; then
            die "Failed to read ${v0}"
        fi
    fi

    while [ ${#} -gt 0 ]; do
        if [ -n "${1}" ]; then
            printf '%s\n' "${1}" && sshd_auth_keys_can_login='config'
        fi
        shift
    done

    return 0
}


_sshd_dofile_auth_keys() {
    if [ ${#} -eq 0 ]; then
        set -- sshd_default_gen_sshd_auth_keys
    else
        case "${1}" in
            'true'|'nop'|'null') set -- ;;
            'default')
                shift
                set -- sshd_default_gen_sshd_auth_keys "${@}"
            ;;
        esac
    fi

    dofile \
        "${sshd_auth_keys_path}" \
        "${sshd_auth_keys_mode}" \
        "${sshd_auth_keys_owner}" \
        "${@}"
}
