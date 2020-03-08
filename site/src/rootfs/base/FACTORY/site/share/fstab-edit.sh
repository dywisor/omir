#!/bin/sh

__io_mounted() {
	awk -v mp="${1}" 'BEGIN{e=1;} ($2 == mp) { e=0; exit; } END{exit e;}'
}

_fstab_add_mfs() {
    fstab-add-mfs "${@}" < "${fstab_dst:?}"
}

fstab_add_mfs() {
    local fstab_dst

    fstab_dst='/etc/fstab'

    [ ! -e "${fstab_dst}" ] || [ -e "${fstab_dst}.dist" ] || autodie cp -- "${fstab_dst}" "${fstab_dst}.dist"

    dofile_site "${fstab_dst}" 0644 'root:wheel' _fstab_add_mfs "${@}"
}


# fstab_add_skel_mfs ( skel, mp, size_m, *opts )
fstab_add_skel_mfs() {
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
