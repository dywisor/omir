#!/bin/sh

sshd_dofile_auth_keys_login_user() {
    sshd_dofile_user_auth_keys "${@}"
}

sshd_dofile_auth_keys_ctrl_user() {
    sshd_dofile_system_auth_keys "${@}"
}

sshd_dofile_auth_keys_jump_user() {
    sshd_dofile_system_auth_keys "${@}"
}
