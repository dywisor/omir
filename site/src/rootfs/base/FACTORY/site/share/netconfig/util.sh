#!/bin/sh

_derive_ip_addr() {
    v0="$( run_helper derive-ip-addr "${@}" )" && [ -n "${v0}" ]
}

derive_inet_addr() {
    _derive_ip_addr -4 "${@}"
}

derive_inet6_addr() {
    _derive_ip_addr -6 "${@}"
}
