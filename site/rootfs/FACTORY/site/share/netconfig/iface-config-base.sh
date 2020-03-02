#!/bin/sh

iface_zap_config() {
	iface_hostname=
	iface_resolv_search=
	iface_resolv_ns=

	iface_desc=
	iface_grp=

	iface_inet_addr=
	iface_inet_netmask=
	iface_inet_gw=

	iface_inet6_autoconf=
	iface_inet6_addr=
	iface_inet6_prefixlen=
	iface_inet6_gw=
}


iface_has_any_addr() {
	[ -n "${iface_inet_addr}" ] || \
	[ -n "${iface_inet6_addr}" ]
}


iface_configured() {
    iface_has_any_addr || [ "${iface_inet6_autoconf:-0}" -eq 1 ]
}


iface_add_resolv_ns() {
    local text

    text="${*}"
    [ -n "${text}" ] || return 1

    if [ -n "${iface_resolv_ns}" ]; then
        iface_resolv_ns="${iface_resolv_ns} ${text}"
    else
        iface_resolv_ns="${text}"
    fi
}
