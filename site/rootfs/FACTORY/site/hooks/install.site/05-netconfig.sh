#!/bin/sh
[ "${OFEAT_NETCONFIG:-0}" -eq 1 ] || exit 0
load_lib netconfig

if ! get_iface_cur_config; then
	print_err "Failed to get primary network interface configuration"
	exit 0  # HOOK-CONTINUE
fi


# strategies.
set -- \
	"${OFEAT_NETCONFIG_BY_MAC:-0}"  iface_conf_by_mac \
	"${OFEAT_NETCONFIG_BY_DHCP:-0}" iface_conf_by_dhcp

have_config=0
iface_zap_config
while [ ${#} -gt 0 ] && [ ${have_config} -eq 0 ]; do
	if [ "${1}" -eq 1 ]; then
		if "${2}"; then
			have_config=1
			print_info "Using interface configuration from ${2}"
		else
			iface_zap_config
		fi
	fi
	shift 2
done


if [ -z "${iface_hostname}" ]; then
	print_err "Failed to retrieve hostname"
	iface_hostname="${OCONF_DEFAULT_HOSTNAME}"
fi

# normalize hostname -- strip terminating "."
[ -z "${iface_hostname}" ] || iface_hostname="${iface_hostname%.}"

# normalize domain search list -- append "." to each name
set --
for arg in ${iface_resolv_search}; do set -- "${@}" "${arg%.}."; done
iface_resolv_search="${*}"

localconfig_add NETCONF_HOSTNAME    "${iface_hostname}"
if [ ${have_config} -eq 1 ]; then
localconfig_add NETCONF_DNS_SEARCH  "${iface_resolv_search}"
localconfig_add NETCONF_DNS_NS      "${iface_resolv_ns}"
localconfig_add NETCONF_INET        "${iface_inet_addr}"
localconfig_add NETCONF_GW          "${iface_inet_gw}"
localconfig_add NETCONF_INET6       "${iface_inet6_addr}"
localconfig_add NETCONF_GW6         "${iface_inet6_gw}"
fi

print_info "Using hostname ${iface_hostname}"
printf '%s\n' "${iface_hostname}" > /etc/myname.site || die "Failed to create myname"
autodie hostname "${iface_hostname}"
autodie site_prep /etc/myname

if [ ${have_config} -eq 0 ]; then
	print_err "No configuration for interface ${iface}, exiting."
	exit 0 # EXIT-IF-NOT-CONFIGURED
fi


print_action "ifconfig ${iface}"
have_addr=0
iface_gen_hostname_if > "/etc/hostname.${iface}.site"
autodie test -s "/etc/hostname.${iface}.site"
autodie chmod -- 0600 "/etc/hostname.${iface}.site"
autodie site_prep "/etc/hostname.${iface}"

if [ ${have_addr} -eq 1 ]; then
	print_action "mygate"
	{
		[ -z "${iface_inet_gw}"  ] || printf '%s\n' "${iface_inet_gw}"
		[ -z "${iface_inet6_gw}" ] || printf '%s\n' "${iface_inet6_gw}"
	} > /etc/mygate.site

	if [ -s /etc/mygate.site ]; then
		autodie site_prep /etc/mygate
	else
		rm -f -- /etc/mygate.site
	fi
fi


print_action "/etc/hosts"
{
	printf '%s\t%s\n' '127.0.0.1' 'localhost'
	printf '%s\t%s\n' '::1' 'localhost'

	if [ -n "${iface_inet_addr}" ]; then
		printf '%s\t%s %s\n' \
			"${iface_inet_addr}" \
			"${iface_hostname%%.*}" "${iface_hostname}"
	fi

	if [ -n "${iface_inet6_addr}" ]; then
		printf '%s\t%s %s\n' \
			"${iface_inet6_addr}" \
			"${iface_hostname%%.*}" "${iface_hostname}"
	fi
} > /etc/hosts.site
autodie test -s /etc/hosts.site
autodie site_prep /etc/hosts


# COULDFIX: iface_ntp?
if [ -n "${iface_resolv_ns}" ]; then
	print_action "ntp config"
	{
		printf 'sensor *\n'
		printf 'server %s\n' ${iface_resolv_ns}  # implicit loop
	} > /etc/ntpd.conf.site
	autodie test -s /etc/ntpd.conf.site
	autodie site_prep /etc/ntpd.conf
fi

if [ -n "${iface_resolv_ns}" ]; then
	print_action "resolv.conf"
	{
		printf 'lookup file bind\n'
		[ -z "${iface_resolv_search}" ] || printf 'search %s\n' "${iface_resolv_search}"
		printf 'nameserver %s\n' ${iface_resolv_ns}  # implicit loop
	} > /etc/resolv.conf.site
	autodie test -s /etc/resolv.conf.site
	autodie site_prep /etc/resolv.conf
fi
