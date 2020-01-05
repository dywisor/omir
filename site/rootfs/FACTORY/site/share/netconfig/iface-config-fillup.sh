#!/bin/sh

iface_fillup_config_from_cur() {
	iface_fillup_config_from_cur__inet
	iface_fillup_config_from_cur__inet6
	iface_fillup_config_from_cur__hostname

	if [ ${OFEAT_NETCONFIG_DYNAMIC_AUTO:-0} -eq 1 ]; then
		iface_fillup_config_dynamic
	fi

	iface_fillup_config_from_cur__inet_gw
	iface_fillup_config_from_cur__inet6_gw
	iface_fillup_config_from_cur__dns
}


iface_fillup_config_from_cur__inet() {
	: "${iface_inet_addr:=${iface_cur_inet_addr}}"
	: "${iface_inet_netmask:=${iface_cur_inet_netmask}}"
}

iface_fillup_config_from_cur__inet_gw() {
	: "${iface_inet_gw:=${iface_cur_inet_gw}}"
}


iface_fillup_config_from_cur__inet6() {
	: "${iface_inet6_addr:=${iface_cur_inet6_addr}}"
	: "${iface_inet6_prefixlen:=${iface_cur_inet6_prefixlen}}"
}


iface_fillup_config_from_cur__inet6_gw() {
	case "${iface_cur_inet6_gw}" in
		'')
			# redundant
			: "${iface_inet6_autoconf:=0}"
		;;

		fe[89ab]?:*)
			if [ -z "${iface_inet6_gw}" ]; then
				: "${iface_inet6_autoconf:=1}"
			else
				: "${iface_inet6_autoconf:=0}"
			fi
		;;
		*)
			: "${iface_inet6_autoconf:=0}"
			: "${iface_inet6_gw:=${iface_cur_inet6_gw}}"
		;;
	esac
}


iface_fillup_config_from_cur__hostname() {
	[ -n "${iface_hostname}" ] || iface_get_hostname_from_ptr || :
}


iface_fillup_config_from_cur__dns() {
	: "${iface_resolv_search:=${iface_cur_resolv_search}}"
	: "${iface_resolv_ns:=${iface_cur_resolv_ns}}"
}
