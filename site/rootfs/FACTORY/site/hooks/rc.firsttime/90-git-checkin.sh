#!/bin/sh
[ "${OFEAT_GIT:-0}" -eq 1 ] || exit 0
[ -n "${OCONF_GIT_USER_NAME-}" ] || die "git user name is not set."
[ -n "${OCONF_GIT_USER_EMAIL-}" ] || die "git user email is not set."

# install git if missing
if ! __have_cmd__ git; then
	print_action "Install package: git"
	autodie pkg_add 'git--'
fi

# git-config for root
print_action "git config for user root"
autodie git config --global user.name "${OCONF_GIT_USER_NAME}"
autodie git config --global user.email "${OCONF_GIT_USER_EMAIL}"

# git-config for unpriv user
if [ -n "${OCONF_UNPRIV_USER-}" ]; then
	print_action "git config for user ${OCONF_UNPRIV_USER}"
	autodie eval_user_funcs "${OCONF_UNPRIV_USER}"
	autodie "${OCONF_UNPRIV_USER}_do" "git config --global user.name '${OCONF_GIT_USER_NAME}'"
	autodie "${OCONF_UNPRIV_USER}_do" "git config --global user.email '${OCONF_GIT_USER_EMAIL}'"
fi

# check in /etc
if [ "${OFEAT_GIT_CHECKIN_ETC:-0}" -eq 1 ]; then
	print_action "git-checkin /etc"
	do_git_init /etc
fi
