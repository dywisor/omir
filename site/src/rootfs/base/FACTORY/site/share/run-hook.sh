#!/bin/sh

_subshell_run_hook() {
    __HOOK__="${__NAME__:?}"

    set --

    unset -v S
    for t0 in \
        "${FACTORY_SITE_FILES}/${__NAME__}" \
        "${FACTORY_SITE_FILES}" \
    ; do
        if [ -d "${t0}" ]; then
            S="${t0}"
            autodie cd "${S}"
            break
        fi
    done
    [ -n "${S+SET}" ] || autodie cd /

    D='/'
    T='/tmp'

    autodie zap_insvars
    umask 0022

    . "${__FILE__:?}"
}


# run_hooks ( phase )
run_hooks() {
    local __NAME__
    local __FILE__
    local hook_dir
    local fail

    hook_dir="${FACTORY_SITE_HOOKS}/${1:?}"

    [ -d "${hook_dir}" ] || return 0

    set +f; set -- "${hook_dir}/"*.sh; set -f
    [ ${#} -eq 0 ] || [ -f "${1}" ] || shift # strip failglob

    [ ${#} -gt 0 ] || return 0

    print_info "Running hooks from ${hook_dir}"
    while [ ${#} -gt 0 ]; do
        __FILE__="${1}"
        __NAME__="${__FILE__##*/}"
        __NAME__="${__NAME__%.sh}"

        autodie localconfig_write_tag "hook: ${__FILE__}"

        fail=0
        ( _subshell_run_hook; ) || fail=${?}

        # localconfig could have been modified by hook
        autodie reload_localconfig

        [ ${fail} -eq 0 ] || die "Failed to run hook ${__NAME__}" || return
        shift
    done
}
