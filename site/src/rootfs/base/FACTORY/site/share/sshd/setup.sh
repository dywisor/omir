#!/bin/sh

# sshd_setup ( login_users, ctrl_users, jump_users )
#
sshd_setup() {
    dodir_mode /etc/ssh 0755 'root:wheel' || return
    sshd_setup_create_sshd_config "${@}" || return
    sshd_setup_create_host_keys || return
}


sshd_setup_create_host_keys() {
    local key_type
    local key_file

    print_action "Creating SSH host keys"

    for key_type in ${SSHD_HOST_KEY_TYPES:?}; do
        key_file="/etc/ssh/ssh_host_${key_type}_key"

        if check_fs_lexists "${key_file}"; then
            print_info "Skipping creation of SSH host key ${key_file}: exists"

        else
            # build ssh-keygen options
            # - common options
            set -- -N '' -t "${key_type}" -f "${key_file}"

            # - key-type specific options
            case "${key_type}" in
                'rsa') set -- "${@}" -b '4096' ;;
            esac

            autodie ssh-keygen "${@}"
        fi
    done
}


# _sshd_setup_gen_sshd_config ( allow_users, login_users, ctrl_users, jump_users )
#
#  Simple gen_sshd_config() wrapper that supports the various user types
#  but does not allow any further per-user customization.
#
#  All users must be listed in the "allow_users" list,
#  and also in one of the "{login,ctrl,jump}_users" lists.
#
_sshd_setup_gen_sshd_config() {
    local user

    [ -n "${1-}" ] || return
    gen_sshd_config_base "${1}" || return

    for user in ${2-}; do
        gen_sshd_login_user "${user}" || return
    done

    for user in ${3-}; do
        gen_sshd_ctrl_user "${user}" || return
    done

    for user in ${4-}; do
        gen_sshd_jump_user "${user}" || return
    done
}

sshd_setup_create_sshd_config() {
    dofile '/etc/ssh/sshd_config' 0600 'root:wheel' _sshd_setup_gen_sshd_config "${@}"
}
