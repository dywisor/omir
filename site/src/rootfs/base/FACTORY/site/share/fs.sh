#!/bin/sh

check_fs_lexists() {
    [ -e "${1}" ] || [ -h "${1}" ]
}

# _dopath { dst, [mode], [owner] )
_dopath() {
    [ "${2:--}" = '-' ] || chmod -h -- "${2}" "${1}" || return
    [ "${3:--}" = '-' ] || chown -h -- "${3}" "${1}" || return
}

dopath() {
    [ -n "${1-}" ] || return 2
    check_fs_lexists "${1}" || return

    _dopath "${@}"
}

# _dofile ( dst, [mode], [owner] )
_dofile() {
    : "${1:?}"

    # racy
    rm -f -- "${1}" || return
    ( umask 0177 && :> "${1}"; ) || return

    _dopath "${@}"
}

# dofile ( dst, [mode], [owner], [cmdv...] )
dofile() {
    local dst
    dst="${1:?}"

    _dofile "${dst}" "${2-}" "${3-}" || return

    if [ ${#} -gt 3 ]; then
        shift 3 || return
        "${@}" > "${dst}" || return
    fi
}

# @BADLY_NAMED dodir_mode ( dst, [mode], [owner] )
dodir_mode() {
    : "${1:?}"

    mkdir -p -m "${2:-0755}" -- "${1}" || return
    dopath "${@}"
}
