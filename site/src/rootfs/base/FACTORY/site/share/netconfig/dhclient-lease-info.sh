#!/bin/sh

# _dhclient_get_lease_file ( iface, **lf! )
_dhclient_get_lease_file() {
    lf="/var/db/dhclient.leases.${1:?}" && [ -n "${lf}" ]
}


# @stdout _dhclient_lease_file_get ( key, **lf )
_dhclient_lease_file_get() {
    < "${lf}" sed -n -r -e "s=^[[:space:]]*${1:?}[[:space:]]+(.*);[[:space:]]*\$=\1=p"
}

# @stdout _dhclient_lease_get ( iface, key )
_dhclient_lease_get() {
    local lf

    _dhclient_get_lease_file "${1:?}" || return
    _dhclient_lease_file_get "${2:?}"
}

# @stdout _dhclient_lease_get_option ( iface, option )
_dhclient_lease_get_option() {
    _dhclient_lease_get "${1:?}" "option[[:space:]]+${2:?}"
}

# @stdio _dhclient_lease_val_unquote()
_dhclient_lease_val_unquote() {
    sed -r -e 's=^"(.*)"$=\1=g'
}

# @stdio _dhclient_lease_val_unquote_domain_search()
_dhclient_lease_val_unquote_domain_search() {
    # good enough (tm)
    perl -ne 'use feature qw(say); chomp; say (join " ", (map { s/^"(.*)"$/\1/mx; s/[.]$//mx; $_; } (split /,\s*/, $_)));'
}

# @stdio _dhclient_lease_val_split_list()
_dhclient_lease_val_split_list() {
    sed -r -e 's=,= =g'
}


dhclient_lease_get_address() {
    _dhclient_lease_get "${1}" fixed-address
}

dhclient_lease_get_netmask() {
    _dhclient_lease_get_option "${1}" subnet-mask
}

dhclient_lease_get_gw() {
    _dhclient_lease_get_option "${1}" routers
}

dhclient_lease_get_ntp() {
    _dhclient_lease_get_option "${1}" time-servers | _dhclient_lease_val_split_list
}

dhclient_lease_get_ns() {
    _dhclient_lease_get_option "${1}" domain-name-servers | _dhclient_lease_val_split_list
}

dhclient_lease_get_hostname() {
    _dhclient_lease_get_option "${1}" host-name | _dhclient_lease_val_unquote
}

dhclient_lease_get_domain_name() {
    _dhclient_lease_get_option "${1}" domain-name | _dhclient_lease_val_unquote
}

dhclient_lease_get_domain_search() {
    _dhclient_lease_get_option "${1}" domain-search | _dhclient_lease_val_unquote_domain_search
}
