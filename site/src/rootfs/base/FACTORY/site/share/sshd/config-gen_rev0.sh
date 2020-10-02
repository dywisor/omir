#!/bin/sh
##
## This is the legacy sshd config generator grants access on a per-user basis.
##
# Keep this file mostly self-sufficient - no external deps except for:
#
#   - vars.sh
#
# sshd config generator
#
# The gen_sshd_ functions write config fragments to stdout,
# combine them to get a complete configuration:
#
# Call gen_sshd_config_base() to create the baseline configuration.
# It creates a very restrictive configuration,
# allowing neither shell login nor port forwardings.
# Make sure to pass a list of allowed users to this function.
#
# Afterwards, the restrictions may be refined for individual users
# with per-user Match blocks that can be created with the following helpers:
#
#   - gen_sshd_login_user ( user )
#     For human users that may elevate to root using su(1):
#     - shell: yes
#     - port forwardings: no
#     - chroot: none
#     - authorized keys: in home directory [using default]
#
#   - gen_sshd_ctrl_user ( user )
#     For machine accounts, typically with doas(1) permissions:
#     - shell: yes
#     - port forwardings: no
#     - chroot: none
#     - authorized keys: /etc/ssh/authorized_keys/<user>
#
#   - gen_sshd_jump_user ( user )
#     For users that jump through this host,
#     without needing any shell access (ssh -J, ssh -o ProxyCommand=...):
#     - shell: no
#     - port forwardings: yes
#     - chroot: home directory
#     - authorized keys: /etc/ssh/authorized_keys/<user>
#
# Note that adding a Match block for a user that has not been given
# to gen_sshd_config_base() will have no effect.
#
# The authorized keys behavior can be changed by passing
# an override as second argument to these helpers,
# see gen_sshd_frag_auth_keys() for possible values.
#
# After starting a match block with one of these helpers,
# additional configuration can be appended to that block
# by calling gen_sshd_frag_() functions.
#
## Note on disabling port forwardings for most users:
##
##   Port forwardings are set up after successful SSH authentication,
##   but before running ForceCommand (if configured).
##   So, using a ForceCommand for multi-factor authentication
##   together with AllowTcpForwarding (and others) will allow
##   opening forwarded connections prior to passing the second auth factor.
##   On Linux, this can be circumvented with PAM,
##   I have yet to find an equivalent solution for OpenBSD.
##

# gen_sshd_config_base ( allow_users )
gen_sshd_config_base() {
    local allow_users
    local iter

    allow_users="${1:?}"

cat << EOF
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512
MACs hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com

EOF

for iter in ${SSHD_HOST_KEY_TYPES:?}; do
    printf 'HostKey %s/ssh_host_%s_key\n' "${SSHD_CONFDIR}" "${iter}"
done

cat << EOF

AllowUsers ${allow_users:?}
PermitRootLogin no

AuthenticationMethods publickey
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes

AuthorizedKeysFile	${SSHD_USER_AUTH_KEYS_FILE:?}

GatewayPorts no
PermitTunnel no

AllowAgentForwarding no
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
X11Forwarding no
PermitTTY no
PermitUserEnvironment no
PermitUserRC no

Banner none
PrintLastLog no
PrintMotd no

TCPKeepAlive yes
UseDNS no

Subsystem sftp internal-sftp
EOF
}

# gen_sshd_frag_match_user ( user )
gen_sshd_frag_match_user() {
cat << EOF

Match User ${1:?}
EOF
}

# __gen_sshd_user ( default_auth_key, user, [auth_key] )
__gen_sshd_user() {
    gen_sshd_frag_match_user "${2:?}" || return
    gen_sshd_frag_auth_keys "${3-${1?}}" || return
}

# gen_sshd_login_user ( user )
gen_sshd_login_user() {
    __gen_sshd_user '-' "${@}" || return
    gen_sshd_frag_permit_tty || return
}

# gen_sshd_ctrl_user ( user )
gen_sshd_ctrl_user() {
    __gen_sshd_user '%u' "${@}" || return
    gen_sshd_frag_permit_tty || return
}

# gen_sshd_jump_user ( user )
gen_sshd_jump_user() {
    __gen_sshd_user '%u' "${@}"
    gen_sshd_frag_chroot_home || return
    gen_sshd_frag_allow_tcp_forwarding || return
}


gen_sshd_frag_allow_tcp_forwarding() {
cat << EOF
    AllowTcpForwarding yes
EOF
}

gen_sshd_frag_permit_tty() {
cat << EOF
    PermitTTY yes
EOF
}

gen_sshd_frag_chroot_home() {
cat << EOF
    ChrootDirectory %h
EOF
}

gen_sshd_frag_auth_keys() {
    local arg
    local auth_keys

    arg="${1?}"

    case "${arg}" in
        /*)
            auth_keys="${arg}"
        ;;

        ''|'_'|'-')
            #auth_keys=
            return 0
        ;;

        '@')
            auth_keys='.ssh/authorized_keys'
        ;;

        *)
            auth_keys="${SSHD_SYSTEM_AUTH_KEYS_DIR}/${arg}"
        ;;
    esac

cat << EOF
    AuthorizedKeysFile ${auth_keys}
EOF
}
