#!/bin/sh
web_proxy_check_feature || exit 0

dst='/etc/profile.d/proxy.sh'

if web_proxy_check_enabled; then
    autodie dodir "${dst%/*}"
    dofile_site "${dst}" 0644 'root:wheel' web_proxy_gen_env
else
    autodie rm -f -- "${dst}"
fi
