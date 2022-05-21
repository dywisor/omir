#!/bin/sh

# site_prep ( dst, [src] )
site_prep() {
    local dst
    local src

    dst="${1:?}"
    src="${2:-${dst}.site}"

    if [ -e "${src}" ] || [ -h "${src}" ]; then
        print_action "Installing site-specific file: ${src}"

        if [ -e "${dst}" ] || [ -h "${dst}" ]; then
            autodie rm -- "${dst}" || return
        fi
        autodie mv -f -- "${src}" "${dst}"
    fi
}
