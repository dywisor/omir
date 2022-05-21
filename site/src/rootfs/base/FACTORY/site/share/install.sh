#!/bin/sh

zap_insvars() {
    EXEMODE='0755'
    DIRMODE='0755'
    INSMODE='0644'

    INSTALL_OWNER='0'
    INSTALL_GROUP='0'
}


_run_install() {
    autodie install -o "${INSTALL_OWNER}" -g "${INSTALL_GROUP}" "${@}"
}


dodir() {
    _run_install -m "${DIRMODE}" -d -- "${@}"
}


doexe() {
    _run_install -m "${EXEMODE}" -- "${@}"
}


doins() {
    _run_install -m "${INSMODE}" -- "${@}"
}
