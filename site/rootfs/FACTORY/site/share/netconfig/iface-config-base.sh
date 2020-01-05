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


iface_configured() {
	[ -n "${iface_inet_addr}" ] || \
	[ -n "${iface_inet6_addr}" ] || \
	[ "${iface_inet6_autoconf:-0}" -eq 1 ]
}
