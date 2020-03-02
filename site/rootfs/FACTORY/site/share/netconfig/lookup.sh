#!/bin/sh
#
# str DIG_LOOKUP_NS
#   If set, use DIG_LOOKUP_NS as nameserver
#   instead of the default one read from /etc/resolv.conf.
#
# int dig_lookup_a ( name, **v0! )
# int dig_lookup_aaaa ( name, **v0! )
# int dig_lookup_cname ( name, **v0! )
# int dig_lookup_ptr ( addr, **v0! )
#
#   Look up A / AAAA / CNAME / PTR records.
#   PTR lookup results will not include the terminating root label '.'.
#
#   For technical reasons, only the final result is returned.
#
# ----------------------------------------------------------------------------

# __dig_lookup ( *argv, **DIG_LOOKUP_NS= )
__dig_lookup() {
    dig +noall +short ${DIG_LOOKUP_NS:+"@${DIG_LOOKUP_NS}"} "${@}"
}

# _dig_lookup ( rr_type, arg )
_dig_lookup() {
    local rr_type
    local arg

    [ -n "${1-}" ] || return 64
    rr_type="${1}"; shift

    [ -n "${1-}" ] || return 64
    arg="${1%.}"; shift
    [ -n "${arg}" ] || return 64
    arg="${arg}."

    [ $# -eq 0 ] || return 64

    __dig_lookup "${arg}" "${rr_type}"
}

_dig_lookup_a()     { _dig_lookup 'A'     "${@}"; }
_dig_lookup_aaaa()  { _dig_lookup 'AAAA'  "${@}"; }
_dig_lookup_cname() { _dig_lookup 'CNAME' "${@}"; }
#_dig_lookup_txt()   { _dig_lookup 'TXT'   "${@}"; }

_dig_lookup_ptr() {
    local arg

    [ -n "${1-}" ] || return 64
    arg="${1}"; shift

    [ $# -eq 0 ] || return 64

    __dig_lookup -x "${arg}"
}

# FIXME: filter returned value
dig_lookup_a() {
    v0="$( _dig_lookup_a "${@}" | __dig_filter_inet | __dig_filter_last )"

    [ -n "${v0}" ]
}

# FIXME: filter returned value
dig_lookup_aaaa() {
    v0="$( _dig_lookup_aaaa "${@}" | __dig_filter_inet6 | __dig_filter_last )"

    [ -n "${v0}" ]
}

dig_lookup_cname() {
    v0="$( _dig_lookup_cname "${@}" | __dig_filter_strip_dot | __dig_filter_last )"

    [ -n "${v0}" ]
}

dig_lookup_ptr() {
    v0="$( _dig_lookup_ptr "${@}" | __dig_filter_strip_dot | __dig_filter_last )"

    [ -n "${v0}" ]
}

# @stdio __dig_filter_last()
__dig_filter_last() { grep -q -- '.' | tail -n 1; }

# @stdio __dig_filter_strip_dot() {
__dig_filter_strip_dot() { sed -r -e 's=[.]$=='; }

# @stdio __dig_filter_inet()
__dig_filter_inet() { grep -E -- '^[0-9]'; }

# @stdio __dig_filter_inet6()
__dig_filter_inet6() { grep -E -- '^[0-9a-fA-F]'; }
