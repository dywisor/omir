
# dofile_site ( dst, ... )
dofile_site() {
    local dst

    dst="${1:?}"; shift

    dofile "${dst}.site" "${@}" || return
    site_prep "${dst}" || return
}
