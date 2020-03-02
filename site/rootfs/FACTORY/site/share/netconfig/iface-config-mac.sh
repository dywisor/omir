#!/bin/sh

iface_conf_by_mac() {
    local lookup_domain

    iface_conf_by_mac__bootstrap_host || return ${?}

    # Fill out resolv search list if dynamic config is disabled
    if \
        [ "${OFEAT_NETCONFIG_DYNAMIC_AUTO:-0}" -ne 1 ] && \
        [ "${OFEAT_NETCONFIG_DYNAMIC_RESOLV_SEARCH:-0}" -ne 1 ]
    then
        iface_resolv_search="${lookup_domain}"
    fi

    iface_conf_by_mac__bootstrap_inet || :
    iface_conf_by_mac__bootstrap_inet6 || :

    iface_fillup_config_from_cur
    iface_configured
}


# iface_conf_by_mac__bootstrap_host ( **lookup_domain! )
iface_conf_by_mac__bootstrap_host() {
    local v0
    local lookup_key

    if ! iface_conf_by_mac__get_lookup_key "${iface_mac}"; then
        print_err "conf-by-mac: Failed to construct MAC address lookup key!"
        return 2
    fi

    lookup_key="${v0}"

    if ! dig_lookup_cname "${lookup_key}"; then
        print_err "conf-by-mac: Could not get hostname, aborting."
        return 2
    fi

    iface_hostname="${v0}"

    lookup_domain=''
    case "${iface_hostname}" in
        *.*)
            lookup_domain="${iface_hostname#*.}"
        ;;
    esac

    if [ -z "${lookup_domain}" ]; then
        print_err "conf-by-mac: Domain is empty, cannot proceed."
        return 2
    fi

    return 0
}


# iface_conf_by_mac__print_lookup_key ( mac_addr, **OCONF~ )
iface_conf_by_mac__print_lookup_key() {
    netconf-mac-key \
        -m "${OCONF_NETCONFIG_BY_MAC_LOOKUP_KEY:-default}" \
        -d "${OCONF_NETCONFIG_BY_MAC_LOOKUP_ZONE}" \
        "${@}"
}


# iface_conf_by_mac__get_lookup_key ( mac_addr )
iface_conf_by_mac__get_lookup_key() {
    v0="$( iface_conf_by_mac__print_lookup_key "${@}" )" && [ -n "${v0}" ]
}


iface_conf_by_mac__bootstrap_inet() {
    local vx_addr
    local vx_gw
    local vx_resolv_ns
    local vx_ntp

    iface_conf_by_mac__bootstrap_any_inet inet || return ${?}

    iface_inet_addr="${vx_addr}"
    iface_inet_gw="${vx_gw}"
    [ -z "${vx_resolv_ns}" ] || iface_add_resolv_ns "${vx_resolv_ns}"
    [ -z "${vx_ntp}" ] || print_err "STUB: cannot add NTP servers"

    return 0
}


iface_conf_by_mac__bootstrap_inet6() {
    local vx_addr
    local vx_gw
    local vx_resolv_ns
    local vx_ntp

    iface_conf_by_mac__bootstrap_any_inet inet6 || return ${?}

    iface_inet6_addr="${vx_addr}"
    iface_inet6_gw="${vx_gw}"
    [ -z "${vx_resolv_ns}" ] || iface_add_resolv_ns "${vx_resolv_ns}"
    [ -z "${vx_ntp}" ] || print_err "STUB: cannot add NTP servers"

    return 0
}


# iface_conf_by_mac__bootstrap_any_inet (
#   addr_type,
#   **vx_addr!, **vx_gw!, **vx_resolv_ns!, **vx_ntp!
# )
#
iface_conf_by_mac__bootstrap_any_inet() {
    vx_addr=
    vx_gw=
    vx_resolv_ns=
    vx_ntp=

    local v0
    local addr_type
    local f_lookup
    local name

    addr_type="${1-}"
    case "${addr_type}" in
        'inet') f_lookup='dig_lookup_a' ;;
        'inet6') f_lookup='dig_lookup_aaaa' ;;
        *) return 64 ;;
    esac


    # get vx_addr (required - abort if not found)
    if ! "${f_lookup}" "${iface_hostname}"; then
        print_info "conf-by-mac: ${iface_hostname} has no ${addr_type} record"
        return 2
    fi

    vx_addr="${v0}"
    print_info "conf-by-mac: Found ${addr_type} address ${vx_addr} for ${iface_hostname}"

    # get vx_gw (optional)
    if \
        [ "${OFEAT_NETCONFIG_BY_MAC_LOOKUP_GW:-0}" -eq 1 ] && \
        [ -n "${OCONF_NETCONFIG_BY_MAC_LOOKUP_GW-}" ] && \
        "${f_lookup}" "${OCONF_NETCONFIG_BY_MAC_LOOKUP_GW}.${lookup_domain}"
    then
        vx_gw="${v0}"
        print_info "conf-by-mac: Found ${addr_type} gateway ${vx_gw}"
    fi

    # get vx_resolv_ns (optional)
    if \
        [ "${OFEAT_NETCONFIG_BY_MAC_LOOKUP_NS:-0}" -eq 1 ] && \
        [ -n "${OCONF_NETCONFIG_BY_MAC_LOOKUP_NS-}" ]
    then
        for name in ${OCONF_NETCONFIG_BY_MAC_LOOKUP_NS}; do
            if "${f_lookup}" "${name}.${lookup_domain}"; then
                print_info "conf-by-mac: Found ${addr_type} nameserver ${v0}"
                vx_resolv_ns="${vx_resolv_ns} ${v0}"
            fi
        done
        vx_resolv_ns="${vx_resolv_ns# }"
    fi

    # get vx_ntp (optional)
    if \
        [ "${OFEAT_NETCONFIG_BY_MAC_LOOKUP_NTP:-0}" -eq 1 ] && \
        [ -n "${OCONF_NETCONFIG_BY_MAC_LOOKUP_NTP-}" ]
    then
        for name in ${OCONF_NETCONFIG_BY_MAC_LOOKUP_NS}; do
            if "${f_lookup}" "${name}.${lookup_domain}"; then
                print_info "conf-by-mac: Found NTP server ${v0}"
                vx_ntp="${vx_ntp} ${v0}"
            fi
        done
        vx_ntp="${vx_ntp# }"
    fi

    return 0
}
