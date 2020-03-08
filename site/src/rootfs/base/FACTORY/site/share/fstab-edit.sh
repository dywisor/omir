#!/bin/sh

__io_mounted() {
	awk -v mp="${1}" 'BEGIN{e=1;} ($2 == mp) { e=0; exit; } END{exit e;}'
}

_fstab_add_mfs() {
    fstab-add-mfs "${@}"
}

fstab_add_mfs() {
    local dst

    dst='/etc/fstab'

    [ ! -e "${dst}" ] || [ -e "${dst}.dist" ] || autodie cp -- "${dst}" "${dst}.dist"

    dofile_site "${dst}" 0644 'root:wheel' _fstab_add_mfs "${@}"
}


# _fstab_add_skel_mfs ( skel, mp, size_m, *opts )
_fstab_add_skel_mfs() {
    local skel
    local mp
    local size_m

    skel="${1:?}"; shift
    mp="${1:?}"; shift
    size_m="${1:?}"; shift

    [ ${#} -gt 0 ] || set -- '-o' 'rw,nodev,noexec,nosuid'

    mkdir -p -m 0555 -- "${mp}" || return
    mkdir -p -- "${skel}" || return

    fstab_add_mfs "${@}" -s "${size_m}m" -P "${skel}" "${mp}"
}


# fstab_add_skel_mfs ( mp, size_m, *opts )
fstab_add_skel_mfs() {
    local skel
    local mp

    mp="${1:?}"; shift
    skel="/skel/${mp##*/}"

    _fstab_add_skel_mfs "${skel}" "${mp}" "${@}"
}
