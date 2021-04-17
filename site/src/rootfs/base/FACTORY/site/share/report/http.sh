#!/bin/sh

# @stdout report_http_installed_gen_script()
#
report_http_installed_gen_script() {
    _report_http_gen_script "${OCONF_REPORT_HTTP_INSTALLED-}" "${@}"
}

# @stdout _report_http_gen_script (
#    report_url,
#    **OCONF_REPORT_HTTP_IP_PROTO,
#    **OCONF_REPORT_HTTP_SSL_OPTIONS,
#    **OFEAT_REPORT_HTTP_USE_PROXY,
#    **OCONF_REPORT_HTTP_TIMEOUT,
#    **OCONF_REPORT_HTTP_RETRY_DELAY,
#    **OCONF_REPORT_HTTP_RETRY_COUNT,
# )
#
_report_http_gen_script() {
    local v0
    local report_url
    local report_cmd
    local sleep_cmd

    report_url="${1-}"

    set -- ftp -MnVi -o /dev/null \
        ${OCONF_REPORT_HTTP_IP_PROTO:+-${OCONF_REPORT_HTTP_IP_PROTO}} \
        ${OCONF_REPORT_HTTP_TIMEOUT:+-w ${OCONF_REPORT_HTTP_TIMEOUT}} \
        ${OCONF_REPORT_HTTP_SSL_OPTIONS:+-S ${OCONF_REPORT_HTTP_SSL_OPTIONS}}

    # assuming default IFS
    report_cmd="${*}"

    # script header
cat << EOF
#!/bin/sh
set -fu
EOF

    if feat_all "${OFEAT_REPORT_HTTP_USE_PROXY-}"; then
        # use proxy
        # profile.d or OCONF_WEB_PROXY?
cat << EOF

[ -r /etc/profile.d/proxy.sh ] && . /etc/profile.d/proxy.sh || :
EOF

    else
        # force-disable proxy
cat << EOF

unset -v http_proxy
unset -v https_proxy
unset -v ftp_proxy
unset -v no_proxy
unset -v HTTP_PROXY
unset -v HTTPS_PROXY
unset -v FTP_PROXY
unset -v NO_PROXY
EOF
    fi

cat << EOF

run_report() {
    ${report_cmd} '${report_url}' || return 1
}

if run_report; then
    exit 0
fi
EOF

    if \
        [ -n "${OCONF_REPORT_HTTP_RETRY_COUNT-}" ] && \
        [ "${OCONF_REPORT_HTTP_RETRY_COUNT}" -gt 0 ]
    then
        if [ "${OCONF_REPORT_HTTP_RETRY_DELAY:-0}" -gt 0 ]; then
            sleep_cmd="sleep ${OCONF_REPORT_HTTP_RETRY_DELAY}"
        else
            sleep_cmd="true"
        fi
cat << EOF

retry=0
while [ \${retry} -lt ${OCONF_REPORT_HTTP_RETRY_COUNT} ]; do
    retry=\$(( retry + 1 ))

    1>&2 printf 'Could not report to %s, retrying (%d/%d)\n' \\
        "${report_url}" \\
        "\${retry}" \\
        "${OCONF_REPORT_HTTP_RETRY_COUNT}"

    ${sleep_cmd}

    if run_report; then
        exit 0
    fi
done
EOF
    fi

cat << EOF

1>&2 printf 'Failed to report to %s\n' "${report_url}"
exit 5
EOF
}
