#!/bin/sh
# DEP: env   config
# DEP: shlib base
# DEP: shlib omir-access
# DEP: shlib oink

# @autodie void oink_default_kconfig()
#
#  The default "kconfig" hook.
#
#  Copy kconfig from files dir if found, else no-op.
#
oink_default_kconfig() {
    local src

    src="${OMIR_OINK_FILES_DIR}/kconfig.${oink_arch}"
    if [ -f "${src}" ]; then
        einfo "Using kernel config ${src}"
        autodie cp -- "${src}" "${oink_bdir_sys_arch_conf_ramdisk}"
    fi
}

# @autodie void oink_code_init()
#
#  Initializes the default oink shell code file
#  and adds it to the ramdisk file list.
#
oink_code_init() {
    oink_code="${TMPDIR}/oink-default.sh"

    einfo "Creating default rd sh environment"

    rm -f -- "${oink_code}" || :

    printf '#!/bin/sh\n' > "${oink_code}" || die "Failed to create ${oink_code}"

    autodie oink_install_sub_inject "${oink_code}" 'oink.include'
}

# @autodie ~stdin void oink_code_cat ( *argv )
#
#  Adds code to the default oink shell code file via cat.
#
oink_code_cat() {
    { printf '\n# ---\n' && cat "${@}"; } >> "${oink_code}" \
        || die "Failed to append code to ${oink_code}"
}

# @autodie void oink_code_printf ( fmt, *argv )
#
#  Adds code to the default oink shell code file via printf.
#
oink_code_printf() {
    printf "${@}" >> "${oink_code}" \
        || die "Failed to append code to ${oink_code}"
}


# @autodie void oink_code_write ( *argv )
#  IS oink_code_printf ( "%s\n", *argv )
#
oink_code_write() {
    oink_code_printf '%s\n' "${@}"
}


oink_code_write_echo() {
    while [ ${#} -gt 0 ]; do
        oink_code_write "echo '${1}'"
        shift
    done
}


# @autodie void oink_default_inject()
#
#  The default "inject" hook.
#
#  - initializes and puts the oink shell script in place
#  - adds auto_install.conf or auto_upgrade.conf if found
#  - adds a custom signify keyring if found
#  - adds a DNS lookup program
#  - strips some firmware files to reduce miniroot size
# 
oink_default_inject() {
    oink_code_init
    _oink_default_inject
}


_oink_default_inject() {
    local v0

    autodie fetch_stdout_nonempty date -u +%F
    oink_code_write_echo \
        '' \
        '*****************************************' \
        "*  UNSUPPORTED oink build (${v0})  *" \
        '*****************************************' \
        ''

    # add auto_install.conf / auto_upgrade.conf if present
    _oink_default_inject_autoinstall

    # insert custom keyring if available
    _oink_default_inject_signify

    # add host lookup helper
    _oink_default_inject_add_looksie

    # make some extra space available
    _oink_default_inject_strip_firmware

    # autoinstall netconfig hacks - if configured
    if [ "${OMIR_OINK_AI_NET_HACKS:-0}" -eq 1 ]; then
        _oink_default_inject_ai_net_hacks
    fi
}

_oink_default_inject_signify() {
    local keyring_name
    local keyring_src
    local keyring_dst

    keyring_name="custom-${oink_rel_short}-base.pub"
    keyring_src="${OMIR_OINK_FILES_DIR}/${keyring_name}"
    keyring_dst="/etc/signify/${keyring_name}"

    if [ -r "${keyring_src}" ]; then
        einfo "Adding keyring ${keyring_name}"

        autodie oink_ramdisk_add_file "${keyring_src}" "${keyring_dst#/}"
        autodie oink_code_write "PUB_KEY=\"${keyring_dst}\""
    fi
}

_oink_default_inject_add_looksie() {
    local pn
    local build_dir

    pn='looksie'

    einfo "Building program: ${pn}"

    build_dir="${TMPDIR}/${pn}"
    autodie dodir "${build_dir}"
    autodie cp -- "${OMIR_OINK_FILES_DIR}/${pn}.c" "${build_dir}/${pn}.c"

    autodie oink_make "${build_dir}" CFLAGS="-Wall -Wextra -pedantic -static -Oz -pipe" ${pn}
    autodie strip -s "${build_dir}/${pn}"

    autodie oink_ramdisk_add_file "${build_dir}/${pn}" usr/sbin/${pn}
}

_oink_default_inject_strip_firmware() {
    einfo "Stripping firmware"
    _oink_inject "${oink_bdir_arch_ramdisk_flist}" \
        _oink_default_inject_strip_firmware__io || die "Failed to strip firmware"
}

_oink_default_inject_strip_firmware__io() {
    # XXX: probably x86-specific
    awk \
'
{ pass = 1; }

($1 == "COPY") && ($3 ~ "^etc/firmware/(kue$|bnx-|ral-|rum-|run-|zd1211b?$)") {
    pass = 0;
}

(pass) { print; }
'
}

_oink_default_inject_autoinstall() {
    local src
    local tfile

    set -- \
        auto_install.conf \
        auto_upgrade.conf

    # hit on first file
    while [ ${#} -gt 0 ]; do
        src="${OMIR_OINK_FILES_DIR}/${1}"
        tfile="${TMPDIR}/${1}"
        
        if [ -f "${src}" ]; then
            einfo "Using autoinstall file: ${src}"

            autodie cp -- "${src}" "${tfile}"
            oink_ramdisk_add_file "${tfile}" "${1}"
            return 0
        fi

        shift
    done
}


_oink_default_inject_ai_net_hacks() {
    local fname
    local install_sub
    local dot_profile

    install_sub="${oink_bdir_miniroot}/install.sub"
    dot_profile="${oink_bdir_miniroot}/dot.profile"

    einfo "ai net hacks: Adding custom get_responsefile code"
    fname="install.sub.get_responsefile"
    autodie cp -- "${OMIR_OINK_FILES_DIR}/${fname}" "${TMPDIR}/${fname}"
    oink_ramdisk_add_file "${TMPDIR}/${fname}" "${fname}"

    einfo "ai net hacks: Adding custom ai-ifconfig code"
    fname="ai-ifconfig"
    autodie cp -- "${OMIR_OINK_FILES_DIR}/${fname}" "${TMPDIR}/${fname}"
    oink_ramdisk_add_file "${TMPDIR}/${fname}" "${fname}"

    einfo "ai net hacks: Patching get_responsefile() in install.sub"
    _oink_inject "${install_sub}" \
        _oink_default_inject_install_sub_ai_net_hacks__io \
        || die "Failed to inject ai net hacks into ${install_sub}" ${?}

    einfo "ai net hacks: Patching dot.profile"
    _oink_inject "${dot_profile}" \
        _oink_default_inject_dot_profile_ai_net_hacks__io \
        || die "Failed to inject ai net hacks into ${dot_profile}" ${?}
}


_oink_default_inject_install_sub_ai_net_hacks__io() {
awk -v fun="get_responsefile" \
'
BEGIN {
    state = 3;
}

# begin of function
(state == 3) && ($0 ~ ("^" fun "[(][)][[:space:]]+[{]")) {
    state = 2;
}

# already injected?
(state == 2) && ($0 ~ ("^" fun "__override")) {
    state = 0;
}

# begin of dhclient code
(state == 2) && ($0 ~ "^[[:space:]]*for _if in") {
    state = 1;

    printf("%s__override || return\n", fun);
    printf("%s__run\n", fun);
    printf("}\n\n");
    printf(". /install.sub.%s\n\n", fun);
    printf("%s__dhclient() {\n", fun);
}

# end of dhclient code
(state == 1) && ($0 ~ "^[[:space:]]*#[[:space:]]*Try to fetch") {
    state = 0;

    printf("}\n\n");
    printf("%s__run() {\n", fun);
}


{ print; }

END {
    exit state;
}
'
}


_oink_default_inject_dot_profile_ai_net_hacks__io() {
awk -v xfile="/ai-ifconfig" \
'
BEGIN {
    state = 1;
}

($0 ~ xfile) {
    state = 0;
}

# anchor -- run script before autoinstall, but after r/w /tmp
(state == 1) && ($0 ~ "# try unattended install") {
    printf("/bin/sh %s\n", xfile);
    state = 0;
}

{ print; }

END {
    exit state;
}
'
}
