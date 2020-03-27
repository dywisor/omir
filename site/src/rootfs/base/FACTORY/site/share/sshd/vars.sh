#!/bin/sh

SSHD_CONFDIR='/etc/ssh'
SSHD_CONF_FILE="${SSHD_CONFDIR}/sshd_config"

SSHD_USER_AUTH_KEYS_FILE='.ssh/authorized_keys'
SSHD_SYSTEM_AUTH_KEYS_DIR='/etc/ssh/authorized_keys'
SSHD_HOST_KEY_TYPES='rsa ed25519'
