
# dofile_site ( dst, mode, owner, func, *args )
dofile_site() {
    [ ${#} -ge 4 ] || return

    local dst

    dst="${1:?}"; shift

    dofile "${dst}.site" "${@}" || return
    [ -s "${dst}.site" ] || return
    site_prep "${dst}" || return
}
