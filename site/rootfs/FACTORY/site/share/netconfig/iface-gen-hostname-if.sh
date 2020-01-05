#!/bin/sh
iface_gen_hostname_if() {
	have_addr=0

	[ -z "${iface_desc}" ] || printf 'description "%s"\n' "${iface_desc}"
	[ -z "${iface_grp}" ] || printf 'group "%s"\n' "${iface_grp}"

	if [ -n "${iface_inet_addr}" ] && [ -n "${iface_inet_netmask}" ]; then
		printf 'inet %s %s\n' "${iface_inet_addr}" "${iface_inet_netmask}"
		have_addr=1
	fi

	if [ "${iface_inet6_autoconf:-0}" -eq 1 ]; then
		printf 'inet6 autoconf\n'
		[ ${have_addr} -ne 0 ] || have_addr=2

		if [ -n "${iface_inet6_addr}" ] && [ -n "${iface_inet6_prefixlen}" ]; then
			printf 'inet6 alias %s %s\n' "${iface_inet6_addr}" "${iface_inet6_prefixlen}"
			have_addr=1
		fi
	else
		# keep nested-if for readability
		if [ -n "${iface_inet6_addr}" ] && [ -n "${iface_inet6_prefixlen}" ]; then
			printf 'inet6 %s %s\n' "${iface_inet6_addr}" "${iface_inet6_prefixlen}"
			have_addr=1
		fi
	fi

	[ ${have_addr} -ne 0 ] || printf 'up\n'
}
