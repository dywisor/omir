#!/bin/sh

ifconfig_io_first_inet() {
    # inet <addr> netmask <netmask> ..ignored..
    #   ignore IPv4 link-local adress 169.254.0.0/16
    awk '($1 == "inet" && (!($2 ~ "^169[.]254[.]")) && $3 == "netmask") { print $2, $4; exit; }'
}

ifconfig_io_first_inet6() {
    # inet6 <addr> prefixlen <prefixlen> ..ignored..
    #   ignore IPv6 link-local adress fe80::/10 (fe80 - febf)
    awk '($1 == "inet6" && (!($2 ~ "^fe[89ab][a-f0-9]:")) && $3 == "prefixlen") { print $2, $4; exit; }'
}


route_io_first_gw() {
    awk '($1 == "gateway:") { print $2; exit; }'
}


_ifconfig_get_first_inetx() {
    v0=""
    v1=""

    local func
    local iface

    func="${1:?}"
    iface="${2:?}"

    set -- $( ifconfig "${iface}" | "${func}" )

    v0="${1-}"
    v1="${2-}"

    [ -n "${v0}" ]
}


ifconfig_get_first_inet() {
    _ifconfig_get_first_inetx ifconfig_io_first_inet "${@}"
}


ifconfig_get_first_inet6() {
    _ifconfig_get_first_inetx ifconfig_io_first_inet6 "${@}"
}


route_get_first_gw() {
    v0="$( route -n get -inet 0.0.0.0/0 2>/dev/null | route_io_first_gw )" && [ -n "${v0}" ]
}

route_get_first_gw6() {
    v0="$( route -n get -inet6 0::0/0 2>/dev/null | route_io_first_gw )" && [ -n "${v0}" ]
}
