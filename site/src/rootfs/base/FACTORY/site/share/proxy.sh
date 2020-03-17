#!/bin/sh

_WEB_PROXY_VARS="FTP_PROXY HTTP_PROXY HTTPS_PROXY ftp_proxy http_proxy https_proxy"
_WEB_NO_PROXY_VARS="NO_PROXY no_proxy"

web_proxy_check_feature() {
     [ "${OFEAT_WEB_PROXY:-0}" -eq 1 ]
}

web_proxy_check_enabled() {
    [ -n "${OCONF_WEB_PROXY-}" ]
}

web_proxy_init_env() {
    web_proxy_check_feature || return 0

    if web_proxy_check_enabled; then
        web_proxy_set_env
    else
        web_proxy_unset_env
    fi
}

_web_proxy_get_no_proxy() {
    v0=

    v0="localhost,127.0.0.1"
    [ -z "${OCONF_WEB_NO_PROXY-}" ] || v0="${v0},${OCONF_WEB_NO_PROXY}"
}

web_proxy_gen_env() {
    local vname
    local v0

    for vname in ${_WEB_PROXY_VARS}; do
        printf 'export %s="%s"\n' "${vname}" "${OCONF_WEB_PROXY}"
    done

    _web_proxy_get_no_proxy
    for vname in ${_WEB_NO_PROXY_VARS}; do
        printf 'export %s="%s"\n' "${vname}" "${v0}"
    done
}

web_proxy_set_env() {
    local v0

    v0="$( web_proxy_gen_env )" || return
    eval "${v0}"
}

web_proxy_unset_env() {
    unset -v ${_WEB_PROXY_VARS}
    unset -v ${_WEB_NO_PROXY_VARS}
}
