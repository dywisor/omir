#!/bin/sh

iface_get_hostname_from_ptr() {
	local v0
	local hname4
	local hname6

	hname4=
	if [ -n "${iface_inet_addr}" ]; then
		dig_lookup_ptr "${iface_inet_addr}" && hname4="${v0}"
	fi

	hname6=
	if [ -n "${iface_inet6_addr}" ]; then
		dig_lookup_ptr "${iface_inet6_addr}" && hname6="${v0}"
	fi

	if [ -n "${hname4}" ]; then
		# prefer IPv4 name over IPv6 name, but check for inconsistencies
		if [ -n "${hname6}" ] && [ "${hname4}" != "${hname6}" ]; then
			print_err "IPv4/IPv6 PTR name mismatch:"
			print_err "  ${iface_inet_addr} -> ${hname4}"
			print_err "  ${iface_inet6_addr} -> ${hname6}"
		fi

		iface_hostname="${hname4}"
		return 0

	elif [ -n "${hname6}" ]; then
		iface_hostname="${hname6}"
		return 0

	else
		return 1
	fi
}
