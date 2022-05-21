#!/bin/sh

iface_conf_by_dhcp() {
    iface_fillup_config_from_cur

    iface_conf_by_dhcp__hostname
    iface_conf_by_dhcp__resolv_search
    iface_conf_by_dhcp__resolv_ns

    iface_configured
}

iface_conf_by_dhcp__hostname() {
    if [ -z "${iface_hostname}" ]; then
        iface_hostname="$( dhclient_lease_get_hostname "${iface}" )" || :
    fi
}

iface_conf_by_dhcp__resolv_search() {
    if [ -z "${iface_resolv_search}" ]; then
        iface_resolv_search="$( dhclient_lease_get_domain_search "${iface}" )" || :
        if [ -z "${iface_resolv_search}" ]; then
            iface_resolv_search="$( dhclient_lease_get_domain_name "${iface}" )" || :
        fi
    fi
}

iface_conf_by_dhcp__resolv_ns() {
    if [ -z "${iface_resolv_ns}" ]; then
        iface_resolv_ns="$( dhclient_lease_get_ns "${iface}" )" || :
    fi
}
