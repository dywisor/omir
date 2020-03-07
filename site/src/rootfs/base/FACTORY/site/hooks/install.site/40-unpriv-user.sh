#!/bin/sh
[ -n "${OCONF_UNPRIV_USER-}" ] || exit 0
[ -n "${OCONF_UNPRIV_UID-}" ] || die "unpriv UID not set."

# useradd
print_action "Unprivileged user"
autodie create_user "${OCONF_UNPRIV_USER}" "${OCONF_UNPRIV_UID}"


# /root/bin/<user>
x_unpriv="/root/bin/${OCONF_UNPRIV_USER}"

gen_unpriv_su() {
cat << EOF
#!/bin/sh
exec su -s /bin/ksh -l '${OCONF_UNPRIV_USER}' "\${@}"
EOF
}

print_action "Create switch-user script: ${x_unpriv}"
autodie dodir "${x_unpriv%/*}"
autodie dofile "${x_unpriv}" 0750 'root:wheel' gen_unpriv_su
