#!/bin/sh

iface_set_config_dynamic() {
    iface_fillup_config_dynamic__inet_gw
    iface_fillup_config_dynamic__inet6_gw

    iface_fillup_config_dynamic__resolv_ns
    iface_fillup_config_dynamic__resolv_search
}


iface_fillup_config_dynamic() {
    [ -n "${iface_inet_gw}" ] || iface_fillup_config_dynamic__inet_gw
    [ -n "${iface_inet6_gw}" ] || iface_fillup_config_dynamic__inet6_gw

    [ -n "${iface_resolv_ns}" ] || iface_fillup_config_dynamic__resolv_ns
    [ -n "${iface_resolv_search}" ] || iface_fillup_config_dynamic__resolv_search
}


iface_derive_inet_addr() {
    if [ ${#} -eq 0 ]; then
        print_err "Cannot derive inet addr due to empty args."

    elif [ -z "${iface_inet_addr}" ] || [ -z "${iface_inet_netmask}" ]; then
        print_err "Cannot derive inet addr due to empty addr/netmask."
        return 2
    fi

    derive_inet_addr "${iface_inet_addr}" "${iface_inet_netmask}" "${@}"
}


iface_derive_inet6_addr() {
    if [ ${#} -eq 0 ]; then
        print_err "Cannot derive inet6 addr due to empty args."

    elif [ -z "${iface_inet6_addr}" ] || [ -z "${iface_inet6_prefixlen}" ]; then
        print_err "Cannot derive inet6 addr due to empty addr/prefixlen."
        return 2
    fi

    derive_inet6_addr "${iface_inet6_addr}" "${iface_inet6_prefixlen}" "${@}"
}


iface_fillup_config_dynamic__inet_gw() {
    local v0

    if [ "${OFEAT_NETCONFIG_DYNAMIC_INET_GW:-0}" -eq 0 ]; then
        return 0

    elif iface_derive_inet_addr ${OCONF_NETCONFIG_DYNAMIC_INET_GW-}; then
        set -- ${v0}
        [ -n "${1-}" ] || { print_err "gw is empty."; return 2; }

        iface_inet_gw="${1}"
        print_info "derived inet gw: ${iface_inet_gw}"
        return 0

    else
        print_err "Failed to derive inet gw from addr/netmask"
        return 1
    fi
}


iface_fillup_config_dynamic__inet6_gw() {
    local v0

    if [ "${OFEAT_NETCONFIG_DYNAMIC_INET6_GW:-0}" -eq 0 ]; then
        return 0

    elif iface_derive_inet6_addr ${OCONF_NETCONFIG_DYNAMIC_INET6_GW-}; then
        set -- ${v0}
        [ -n "${1-}" ] || { print_err "gw is empty."; return 2; }

        iface_inet6_gw="${1}"
        print_info "derived inet6 gw: ${iface_inet6_gw}"
        return 0

    else
        print_err "Failed to derive inet6 gw from addr/prefixlen"
        return 1
    fi
}


iface_fillup_config_dynamic__resolv_ns() {
    local v0

    [ "${OFEAT_NETCONFIG_DYNAMIC_RESOLV_NS:-0}" -eq 1 ] || return 0

    set --

    if [ -n "${OCONF_NETCONFIG_DYNAMIC_INET_RESOLV_NS-}" ]; then
        if iface_derive_inet_addr ${OCONF_NETCONFIG_DYNAMIC_INET_RESOLV_NS-}; then
            set -- "${@}" ${v0}
        else
            print_err "Failed to derive inet nameserver, skipping."
        fi
    fi

    if [ -n "${OCONF_NETCONFIG_DYNAMIC_INET6_RESOLV_NS-}" ]; then
        if iface_derive_inet6_addr ${OCONF_NETCONFIG_DYNAMIC_INET6_RESOLV_NS-}; then
            set -- "${@}" ${v0}
        else
            print_err "Failed to derive inet6 nameserver, skipping."
        fi
    fi

    if [ ${#} -gt 0 ]; then
        iface_resolv_ns="${*}"
        print_info "derived resolv.conf ns: ${iface_resolv_ns}"
        return 0

    else
        print_err "Could not derive any nameserver."
        return 1
    fi
}


# - local-domain:
#    for a hostname HNAME "a.b.c..k..u.v",
#    add "b..v", "c..v", ..., "k..v" to the search domain list
#
#    The cut point 'k' is controlled by
#    OCONF_NETCONFIG_DYNAMIC_RESOLV_SEARCH_CUT, it defaults to 2.
#
#    The (short) hostname 'a' gets always discarded.
#    Further parts at the beginning may be discarded by setting
#    OCONF_NETCONFIG_DYNAMIC_RESOLV_SEARCH_SKIP to the appropriate number.
#
#    Additional search domains may be prepended or appended to the
#    search list via OCONF_NETCONFIG_DYNAMIC_RESOLV_SEARCH_PREPEND
#    and OCONF_NETCONFIG_DYNAMIC_RESOLV_SEARCH_APPEND, respectively.
#
iface_fillup_config_dynamic__resolv_search() {
    [ "${OFEAT_NETCONFIG_DYNAMIC_RESOLV_SEARCH:-0}" -eq 1 ] || return 0

    local oldifs
    oldifs="${IFS-}"

    local IFS
    IFS="${oldifs}"

    local search_list
    local k
    local s

    search_list="${OCONF_NETCONFIG_DYNAMIC_RESOLV_SEARCH_PREPEND-}"

    IFS='.'
    set -- ${iface_hostname}
    set -- ${*}
    IFS="${oldifs}"

    if [ ${#} -gt 0 ]; then
        shift  # discard short hostname

        k=${OCONF_NETCONFIG_DYNAMIC_RESOLV_SEARCH_SKIP:-0}
        while [ ${#} -gt 0 ] && [ ${k} -gt 0 ]; do
            shift
            k=$(( k - 1 ))
        done

        k=${OCONF_NETCONFIG_DYNAMIC_RESOLV_SEARCH_CUT:-2}
        [ ${k} -ge 0 ] || k=0
        while [ ${#} -ge ${k} ]; do
            IFS='.'
            s="${*}"
            IFS="${oldifs}"

            search_list="${search_list:+${search_list} }${s}"

            shift
        done
    fi

    s="${OCONF_NETCONFIG_DYNAMIC_RESOLV_SEARCH_APPEND-}"
    [ -z "${s}" ] || search_list="${search_list:+${search_list} }${s}"

    if [ -n "${search_list}" ]; then
        iface_resolv_search="${search_list}"
        print_info "derived resolv.conf search: ${search_list}"
        return 0
    else
        print_err "Dynamic domain search list is empty."
        return 1
    fi
}
