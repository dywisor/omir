#!/bin/sh
# Keep this file mostly self-sufficient - no external deps except for:
#
#   - vars.sh
#   - OCONF_SSHD_GROUP_* variables:
#      OCONF_SSHD_GROUP_LOGIN
#      OCONF_SSHD_GROUP_SHELL
#      OCONF_SSHD_GROUP_FORWARDING
#      OCONF_SSHD_GROUP_CHROOT_HOME
#
# sshd config generator
#
# Call gen_sshd_config_base() to create the baseline configuration.
# It creates a very restrictive configuration,
# allowing neither shell login nor port forwardings.
#
# Access is granted based on group membership:
#
#  - login group (OCONF_SSHD_GROUP_LOGIN)
#    Only users in this group may log in via SSH,
#    regardless of any other ssh access group membership.
#
#  - shell group (OCONF_SSHD_GROUP_SHELL)
#    Users in this group get a PTY.
#
#  - forwarding group (OCONF_SSHD_GROUP_FORWARDING)
#    Users in this group may use tcp forwarding.
#
#  - chroot-home group (OCONF_SSHD_GROUP_CHROOT_HOME)
#    Users in this group are restricted to their home directory
#    (using ChrootDirectory).
#
# Authorized keys are read from /etc/ssh/authorized_keys/<user_name>.
# By default, users of the login group may read but not modify
# their own authorized_keys file.
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

# gen_sshd_config_base ( allow_groups )
gen_sshd_config_base() {
    local iter

cat << EOF
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512
MACs hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com

EOF

for iter in ${SSHD_HOST_KEY_TYPES:?}; do
    printf 'HostKey %s/ssh_host_%s_key\n' "${SSHD_CONFDIR}" "${iter}"
done

cat << EOF

AllowGroups ${OCONF_SSHD_GROUP_LOGIN:?}
PermitRootLogin no

AuthenticationMethods publickey
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes

AuthorizedKeysFile	${SSHD_SYSTEM_AUTH_KEYS_DIR}/%u

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

Include ${SSHD_INCLUDE_CONFDIR}/*.conf
EOF

if [ -n "${OCONF_SSHD_GROUP_SHELL-}" ]; then
cat << EOF

Match Group ${OCONF_SSHD_GROUP_SHELL}
    PermitTTY yes
EOF
fi

if [ -n "${OCONF_SSHD_GROUP_FORWARDING-}" ]; then
cat << EOF

Match Group ${OCONF_SSHD_GROUP_FORWARDING}
    AllowTcpForwarding yes
EOF
fi

if [ -n "${OCONF_SSHD_GROUP_CHROOT_HOME-}" ]; then
cat << EOF

Match Group ${OCONF_SSHD_GROUP_CHROOT_HOME}
    ChrootDirectory %h
EOF
fi
}
