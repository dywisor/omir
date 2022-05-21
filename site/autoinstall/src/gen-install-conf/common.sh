#!/bin/sh
#
# This script is not meant to be executed directly,
# it contains the common code for creating an install.conf file,
# either statically (boot server) or dynamically (install ramdisk).
#
# It can be appended to a script that performs the necessary
# initialization in the load_env() function.
#
# All arguments are passed to the load_env() function.
#
# load_env() may reference the functions defined here,
# it must call set_outfile().
#

set -fu

die() {
    printf '%s\n' "${1:+died: }${1:-died.}" 1>&2
    exit "${2:-255}"
}


autodie() {
    "${@}" || die "command '${*}' returned ${?}." "${?}"
}


randpw() {
    < /dev/urandom tr -C -d '[a-zA-Z0-9_]' | dd bs=1 count="${1:-128}" status=none
}


maskpw() {
    v0=''
    case "${1}" in
        "${ODEF_NO_PASSWORD_LOGIN}")
            # password login disabled
            v0="${1}"
            return 0
            ;;
        '$'*)
            # encrypted
            v0="${1}"
            return 0
        ;;

        '')
            # empty password is not permitted
            return 5
        ;;

        *)
            v0="$( printf '%s' "${1}" | encrypt )" && [ -n "${v0}" ] || return 1
            return 0
        ;;
    esac
}


parse_installurl() {
    mirror_type=''
    mirror_proto=''
    mirror_server=''
    mirror_path=''
    mirror_dir=''

    local rem

    case "${1-}" in
        '')
            die "empty installurl"
        ;;

        'http://'?*|'https://'?*)
            mirror_type='http'
            mirror_proto="${1%%://*}"
            rem="${1#*://}"
        ;;

        *)
            die "unsupported installurl: ${1}"
        ;;
    esac

    rem="${rem%/}"
    case "${rem}" in
        ?*/*)
            mirror_server="${rem%%/*}"
            mirror_path="${rem#*/}"
            : "${mirror_path:=/}"
        ;;
        *)
            mirror_server="${rem}"
            mirror_path='/'
        ;;
    esac

    mirror_dir="${mirror_path%/}/${OCONF_INSTALL_RELEASE}/${OCONF_INSTALL_ARCH}"
}


_gen_reply() {
    printf '%s = %s\n' "${1:?}" "${2?}"
}


gen_reply_yesno() {
    local question
    local conf_value
    local word_yes
    local word_no
    local reply

    question="${1:?}"
    conf_value="${2:?}"
    word_yes="${3:-yes}"
    word_no="${4:-no}"

    autodie test "${conf_value}" -ge 0

    if [ "${conf_value}" -eq 0 ]; then
        reply="${word_no}"
    else
        reply="${word_yes}"
    fi

    gen_reply "${question}" "${reply}"
}

gen_reply_set_sel() {
    gen_reply 'Set name(s)' "${1:?}"
}

set_outfile() {
gen_install_conf_outfile="${1-}"

if [ "${gen_install_conf_outfile:--}" = '-' ]; then
gen_reply() {
    _gen_reply "${@}" || die "Failed to gen reply."
}

else
gen_reply() {
    _gen_reply "${@}" > "${gen_install_conf_outfile}" || die "Failed to write reply to outfile."
}
fi
}


ODEF_NO_PASSWORD_LOGIN='*************'

autodie load_env "${@}"

: "${OCONF_DEFAULT_HOSTNAME:=staging.local}"
: "${OCONF_KBD_LAYOUT:=us}"
: "${OCONF_INSTALL_IFACE=}"
: "${OCONF_INSTALL_NS=}"
: "${OCONF_HTTP_PROXY=}"
: "${OFEAT_DESKTOP:=0}"
: "${OFEAT_GAMES:=0}"
: "${OFEAT_CONSOLE_COM:=0}"
: "${OCONF_TIMEZONE:=Europe/Berlin}"
: "${OCONF_INSTALL_ROOT_PASS=}"
: "${OCONF_INSTALL_ROOT_SSH_PUB_KEY=}"
: "${OCONF_INSTALL_LOGIN_USER_PASS=}"
: "${OCONF_INSTALL_LOGIN_USER_SSH_PUB_KEY=}"
: "${OCONF_INSTALLURL_LOCAL=}"
: "${OCONF_INSTALL_DISKLABEL_URL=}"
: "${OCONF_INSTALL_DISK_DEV=}"


# FIXME:
: "${OCONF_INSTALL_ARCH:?}"
: "${OCONF_INSTALL_RELEASE:?}"
: "${OCONF_INSTALL_RELEASE_SHORT:?}"


## installurl
if [ -n "${OCONF_INSTALLURL_LOCAL}" ]; then
    : "${OFEAT_INSTALL_SITE:=1}"
else
    : "${OFEAT_INSTALL_SITE:=0}"
fi

if [ "${OFEAT_INSTALL_SITE}" -eq 1 ]; then
    site_tgz="site${OCONF_INSTALL_RELEASE_SHORT}.tgz"
else
    site_tgz=""
fi

parse_installurl "${OCONF_INSTALLURL_LOCAL:-${OCONF_INSTALLURL_UPSTREAM:?}}"


## login user
if [ -z "${OCONF_LOGIN_USER-}" ]; then
    :
elif [ -n "${OCONF_INSTALL_LOGIN_USER_PASS}" ]; then
    autodie maskpw "${OCONF_INSTALL_LOGIN_USER_PASS}"
    OCONF_INSTALL_LOGIN_USER_PASS="${v0:?}"

elif [ -n "${OCONF_INSTALL_LOGIN_USER_SSH_PUB_KEY}" ]; then
    OCONF_INSTALL_LOGIN_USER_PASS="${ODEF_NO_PASSWORD_LOGIN}"
else
    die "login user has no password"
fi


## root
if [ -n "${OCONF_INSTALL_ROOT_PASS}" ]; then
    autodie maskpw "${OCONF_INSTALL_ROOT_PASS}"
    OCONF_INSTALL_ROOT_PASS="${v0:?}"
    :
elif [ -n "${OCONF_INSTALL_ROOT_SSH_PUB_KEY}" ]; then
    OCONF_INSTALL_ROOT_PASS="${ODEF_NO_PASSWORD_LOGIN}"
else
    die "root user has no password"
fi


###> start install.conf gen
##> keyboard layout
gen_reply 'Choose your keyboard layout' "${OCONF_KBD_LAYOUT}"


##> hostname
gen_reply 'System hostname' "${OCONF_DEFAULT_HOSTNAME%%.*}"


##> network configuration
if [ -n "${OCONF_INSTALL_IFACE}" ]; then
    gen_reply 'Which network interface do you wish to configure' "${OCONF_INSTALL_IFACE}"
    gen_reply "IPv4 address for ${OCONF_INSTALL_IFACE}" 'dhcp'
    gen_reply "IPv6 address for ${OCONF_INSTALL_IFACE}" 'none'
fi

gen_reply 'Which network interface do you wish to configure' 'done'

gen_reply 'DNS domain name' "${OCONF_DEFAULT_HOSTNAME#*.}"
gen_reply 'DNS nameservers' "${OCONF_INSTALL_NS}"


##> root account
gen_reply 'Password for root account' "${OCONF_INSTALL_ROOT_PASS}"
gen_reply 'Public ssh key for root account' "${OCONF_INSTALL_ROOT_SSH_PUB_KEY:-none}"
gen_reply 'Start sshd(8) by default' 'yes'


##> X Window System
gen_reply_yesno 'Do you expect to run the X Window System' "${OFEAT_DESKTOP}"


##> com0
if [ ${OFEAT_CONSOLE_COM} -eq 1 ]; then
    # FIXME hardcoded -- low prio, only asked when com0 booted
    gen_reply 'Change the default console to com0' 'yes'
    gen_reply 'Which speed should com0 use' '115200'
fi


##> login user account
gen_reply 'Setup a user' "${OCONF_LOGIN_USER}"
gen_reply "Full name for user ${OCONF_LOGIN_USER}" "${OCONF_LOGIN_USER}"
gen_reply "Password for user ${OCONF_LOGIN_USER}" "${OCONF_INSTALL_LOGIN_USER_PASS}"
gen_reply "Public ssh key for user ${OCONF_LOGIN_USER}"  "${OCONF_INSTALL_LOGIN_USER_SSH_PUB_KEY:-none}"


##> root ssh login
# FIXME hardcoded
if [ -n "${OCONF_INSTALL_ROOT_SSH_PUB_KEY}" ]; then
    gen_reply 'Allow root ssh login' 'prohibit-password'
else
    gen_reply 'Allow root ssh login' 'no'
fi


##> disk partitioning
if [ -n "${OCONF_INSTALL_DISK_DEV}" ]; then
    gen_reply 'Which disk is the root disk' "${OCONF_INSTALL_DISK_DEV}"

    gen_reply 'Use (W)hole disk MBR, whole disk (G)PT or (E)dit' 'whole'
    gen_reply 'Use (W)hole disk MBR, whole disk (G)PT, (O)penBSD area or (E)dit' 'OpenBSD'

    if [ -n "${OCONF_INSTALL_DISKLABEL_URL}" ]; then
        gen_reply \
            'URL to autopartitioning template for disklabel' \
            "${OCONF_INSTALL_DISKLABEL_URL}"
    else
        gen_reply 'Use (A)uto layout, (E)dit auto layout, or create (C)ustom layout' 'a'
    fi

else
    die "no disk configuration"
fi


##> sets
gen_reply 'Location of sets' "${mirror_type}"
case "${mirror_type}" in
    'http')
        gen_reply 'HTTP proxy URL' "${OCONF_HTTP_PROXY:-none}"
        gen_reply 'HTTP Server' "${mirror_server}"
        gen_reply 'Server directory' "${mirror_dir}"
        gen_reply 'Unable to connect using https. Use http instead' 'yes'
    ;;

    *)
        die "mirror type not implemented: ${mirror_type}"
    ;;
esac

[ "${OFEAT_DESKTOP}" -eq 1 ] || gen_reply_set_sel '-x*'
[ "${OFEAT_GAMES}" -eq 1 ] || gen_reply_set_sel '-game*'
[ -z "${site_tgz}" ] || gen_reply_set_sel "${site_tgz}"
gen_reply_set_sel 'done'

gen_reply 'Cannot determine prefetch area. Continue without verification' 'yes'

if [ -n "${site_tgz}" ]; then
    gen_reply "Checksum test for ${site_tgz} failed. Continue anyway" 'yes'
    gen_reply "Unverified sets: ${site_tgz}. Continue without verification" 'yes'
fi

gen_reply 'Location of sets' 'done'


##> timezone
gen_reply 'What timezone are you in' "${OCONF_TIMEZONE}"
