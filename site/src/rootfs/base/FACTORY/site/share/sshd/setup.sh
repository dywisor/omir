#!/bin/sh

# sshd_setup()
#
sshd_setup() {
    dodir_mode "${SSHD_CONFDIR}" 0755 'root:wheel' || return
    dodir_mode "${SSHD_SYSTEM_AUTH_KEYS_DIR}" 0710 "root:${OCONF_SSHD_GROUP_LOGIN:-wheel}" || return
    sshd_setup_create_sshd_config || return
    sshd_setup_create_host_keys || return
    sshd_setup_disable_rc_keygen || return
}


sshd_setup_create_host_keys() {
    local key_type
    local key_file

    print_action "Creating SSH host keys"

    if \
        [ "${OFEAT_SSHD_FORCE_REGEN_KEYS:-0}" -eq 1 ] && \
        factory_site_mode_is_install
    then
        (
            set +f
            set -- "${SSHD_CONFDIR}/"ssh_host_*_key*
            set -f

            if [ $# -gt 0 ] && [ -f "${1}" ]; then
                print_info "Removing old ssh keys (forced): ${*}"
                rm -f -- "${@}"
            fi
        ) || print_err "Failed to remove old ssh keys"
    fi

    for key_type in ${SSHD_HOST_KEY_TYPES:?}; do
        key_file="${SSHD_CONFDIR}/ssh_host_${key_type}_key"

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


# _sshd_setup_gen_sshd_config()
#
#  Simple gen_sshd_config() wrapper that supports the various access groups
#  but does not allow any further per-user customization.
#
_sshd_setup_gen_sshd_config() {
    gen_sshd_config_base || return
}

sshd_setup_create_sshd_config() {

    if factory_site_mode_is_upgrade; then
        if [ -f "${SSHD_CONF_FILE}" ]; then
            autodie cp -f -Hpv -- "${SSHD_CONF_FILE}" "${SSHD_CONF_FILE}.old"
        fi
    fi

    dofile "${SSHD_CONF_FILE}" 0600 'root:wheel' _sshd_setup_gen_sshd_config "${@}"
}

# sshd_setup_disable_rc_keygen()
#
#  Disable ssh-keygen in /etc/rc so that
#  unwanted keys do not get recreated on every boot.
#
sshd_setup_disable_rc_keygen() {
    dofile_site '/etc/rc' 0644 'root:wheel' _sshd_setup_gen_disable_rc_keygen
}

_sshd_setup_gen_disable_rc_keygen() {
    < /etc/rc sed -r -e 's,^([[:space:]]*)(ssh-keygen.*)$,\1#\2,'
}
