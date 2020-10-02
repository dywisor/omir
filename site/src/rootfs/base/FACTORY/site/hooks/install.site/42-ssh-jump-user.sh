#!/bin/sh
[ "${OFEAT_SSH_JUMP_USER:-0}" -eq 1 ] || exit 0
[ -n "${OCONF_SSH_JUMP_USER-}" ] || die "ssh jump USER not set."
autodie check_valid_user_name "${OCONF_SSH_JUMP_USER}"
[ -n "${OCONF_SSH_JUMP_UID-}" ] || die "ssh jump UID not set."

load_lib sshd-user

# useradd
print_action "SSH jump user"
autodie create_user_empty_home "${OCONF_SSH_JUMP_USER}" "${OCONF_SSH_JUMP_UID}"
chown -h -- "root:${user_gid:?}" "${user_home:?}"
chmod -h -- 0750 "${user_home:?}"

# ssh jump user enables sshd, do feat_sshd check nonetheless
if feat_check_sshd; then
    autodie user_set_ssh_login "${user_name}" 1
    autodie user_set_ssh_shell "${user_name}" 0
    autodie user_set_ssh_forwarding "${user_name}" 1
    autodie user_set_ssh_chroot_home "${user_name}" 1

    sshd_auth_keys_copy_keys_from_home=0
    autodie sshd_dofile_system_auth_keys default "${OCONF_CTRL_SSH_KEY-}"

    [ -n "${sshd_auth_keys_can_login}" ] || \
        print_err "${user_name} will not be able to log in via SSH."
fi
