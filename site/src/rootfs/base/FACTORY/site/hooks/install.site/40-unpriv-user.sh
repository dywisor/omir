#!/bin/sh
[ -n "${OCONF_UNPRIV_USER-}" ] || exit 0
[ -n "${OCONF_UNPRIV_UID-}" ] || die "unpriv UID not set."

# useradd
print_action "Create user ${OCONF_UNPRIV_USER}"
autodie _create_user "${OCONF_UNPRIV_USER}" "${OCONF_UNPRIV_UID}"


# /root/bin/<user>
x_unpriv="/root/bin/${OCONF_UNPRIV_USER}"

print_action "Create switch-user script: ${x_unpriv}"
autodie mkdir -p -- /root/bin
rm -f -- "${x_unpriv}.site" || :

{
cat << EOF
#!/bin/sh
exec su -s /bin/ksh -l '${OCONF_UNPRIV_USER}' "\${@}"
EOF
} > "${x_unpriv}.site" || die "Failed to create su-unpriv script!"
autodie chmod -- 0750 "${x_unpriv}.site"
autodie site_prep "${x_unpriv}"
