#!/bin/sh
[ "${OFEAT_SSHD_CONFIG:-0}" -eq 1 ] || exit 0
[ -n "${OCONF_LOGIN_USER-}" ] || die "no login user configured"

gen_sshd_config() {
	render_template sshd_config \
		ALLOW_USERS "${OCONF_LOGIN_USER}"
}

autodie dodir /etc/ssh

dst='/etc/ssh/sshd_config'

# init empty file with sane mode
rm -f -- "${dst}.site"
:> "${dst}.site" || die "Failed to init ${dst}.site"
autodie chmod -- 0600 "${dst}.site"

# gen sshd_config
gen_sshd_config > "${dst}.site" || die "Failed to generate ${dst}.site"

# install
autodie site_prep "${dst}"
