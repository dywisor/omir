#!/bin/sh

zap_iface_cur_config() {
	iface=
	iface_mac=

	iface_cur_inet_addr=
	iface_cur_inet_netmask=
	iface_cur_inet_gw=

	iface_cur_inet6_addr=
	iface_cur_inet6_prefixlen=
	iface_cur_inet6_gw=

	iface_cur_resolv_search=
	iface_cur_resolv_ns=
}

get_iface_cur_config() {
	local iface_maybe
	local v0
	local v1

	zap_iface_cur_config

	iface="$( ifconfig egress | grep -Eo -- '^[a-z]+[0-9]+' | head -n 1 )"
	if [ -z "${iface}" ]; then
		for iface_maybe in ${OCONF_NETCONFIG_GUESS_IFACE_LIST-}; do
			if ifconfig "${iface_maybe}" 1>/dev/null 2>&1; then
				iface="${iface_maybe}"
				break
			fi
		done
	fi

	if [ -z "${iface}" ]; then
		print_err "Failed to get network interface, exiting."
		return 1
	fi

	print_action "Get current network configuration for ${iface}"

	# - MAC address
	iface_mac="$( ifconfig "${iface}" | awk '($1 == "lladdr") { print $2; }' )"
	if [ -z "${iface_mac}" ]; then
		die "Failed to get mac address"
	fi

	# - IPv4
	if ifconfig_get_first_inet "${iface}"; then
		iface_cur_inet_addr="${v0}"

		if [ -n "${v1}" ]; then
			if \
				v0="$( run_helper netmask-hex-to-dot "${v1}" )" && \
				[ -n "${v0}" ]
			then
				iface_cur_inet_netmask="${v0}"
			fi
		fi

		! route_get_first_gw || iface_cur_inet_gw="${v0}"
	fi

	# - IPv6
	if ifconfig_get_first_inet6 "${iface}"; then
		iface_cur_inet6_addr="${v0}"
		iface_cur_inet6_prefixlen="${v1}"
		! route_get_first_gw6 || iface_cur_inet6_gw="${v0}"
	fi

	# - DNS
	# read DNS config from /etc/resolv.conf,
	#  relies on prior configuration and does not parse the entire file
	if [ -r /etc/resolv.conf ]; then
		while read -r kw val; do
			case "${kw}" in
				'#'*)
					:
				;;

				search|domain)
					iface_cur_resolv_search="${val}"
				;;

				nameserver)
					if [ -z "${val}" ]; then
						:
					elif [ -n "${iface_cur_resolv_ns}" ]; then
						iface_cur_resolv_ns="${iface_cur_resolv_ns} ${val}"
					else
						iface_cur_resolv_ns="${val}"
					fi
				;;
			esac
		done < /etc/resolv.conf
	fi

	return 0
}
