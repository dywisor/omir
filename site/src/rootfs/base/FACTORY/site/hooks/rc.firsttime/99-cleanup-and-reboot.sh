#!/bin/sh
set -fu

NL='
'

if feat_all "${OFEAT_RAMDISK_VAR_LOG-}"; then
    if dodir_mode "/FACTORY/log" 0700 'root:wheel'; then
        cleanup_log_dst="/FACTORY/log"
    else
        cleanup_log_dst="/var/log"
    fi
else
    cleanup_log_dst="/var/log"
fi

run_cleanup_code=0
run_report_code=0
will_reboot=0
_script_header="
#!/bin/sh
set -fu
cd /
"
cleanup_code="${_script_header}"
report_code="${_script_header}"

add_cleanup_code() {

run_cleanup_code=1
cleanup_code="${cleanup_code}
mv -- /install.site.log ${cleanup_log_dst}/install.site.log || :
mv -- /upgrade.site.log ${cleanup_log_dst}/upgrade.site.log || :
mv -- /rc.firsttime.log ${cleanup_log_dst}/rc.firsttime.log

rm -rf -- \"${FACTORY_SITE}\"
rmdir -- \"${FACTORY_SITE%/*}\" 2>/dev/null || :

rm -f -- /OMIR_VERSION

rm -- /install.site
rm -- /upgrade.site
"
}


add_reboot_code() {

run_cleanup_code=1
will_reboot=1
cleanup_code="${cleanup_code}
rm -f -- /etc/rc.firsttime.run
sync
reboot
"
}

add_delayed_reboot_code() {
    local delay

    delay=600
    if [ -z "${1-}" ]; then
        :
    elif [ "${1}" -gt 0 ]; then
        delay="${1}"
    else
        print_err "Invalid delay: ${1}, defaulting."
    fi

# relink check from https://github.com/openbsd/src/blob/master/usr.sbin/syspatch/syspatch.sh

run_cleanup_code=1
will_reboot=1
cleanup_code="${cleanup_code}
/usr/local/bin/waitfor_reorder_kernel_exec -t \"${delay}\" -d reboot
"
}

add_report_http_installed_code() {
    local report_script

    report_script='/usr/local/bin/omir-report-http-installed'

    if ! load_lib report/http; then
        print_err "Failed to load code gen lib"

    elif dofile_site "${report_script}" 0755 'root:wheel' \
        report_http_installed_gen_script
    then
        run_report_code=1
        if feat_all "${OFEAT_UNPRIV_USER-}" && [ -n "${OCONF_UNPRIV_USER-}" ]; then
            report_code="${report_code}
/usr/local/bin/waitfor_reorder_kernel_exec su -s /bin/sh ${OCONF_UNPRIV_USER} -c '/usr/local/bin/omir-report-installed'
"
        else

            report_code="${report_code}
/usr/local/bin/waitfor_reorder_kernel_exec /usr/local/bin/omir-report-installed
"
        fi

    else
        print_err "Failed to generate ${report_script}"
    fi
}


if feat_all "${OFEAT_AUTO_CLEANUP_FILES-}"; then
    add_cleanup_code
fi

print_action "Cleanup and reporting"

if feat_all "${OFEAT_AUTO_REBOOT-}" && [ -e "${AUTO_REBOOT_FLAG_FILE}" ]; then
	if ! rm -- "${AUTO_REBOOT_FLAG_FILE}"; then
		print_err "Could not remove auto-reboot flag file, will not reboot."

    elif feat_all "${OFEAT_AUTO_REBOOT_DELAY-}"; then
		print_info "Adding delayed reboot code"
		add_delayed_reboot_code "${OCONF_AUTO_REBOOT_DELAY-}"
	else
		print_info "Adding reboot-now code"
		add_reboot_code
	fi
fi

if feat_all "${OFEAT_FLAG_FILE_INSTALLED-}"; then
    run_report_code=1
    report_code="${report_code}${NL}touch -- /OMIR_INSTALLED${NL}"
fi

if feat_all "${OFEAT_REPORT_HTTP_INSTALLED-}"; then
    add_report_http_installed_code
fi

# attach or run report code
if [ ${run_report_code} -eq 1 ]; then
    if [ ${run_cleanup_code} -eq 1 ]; then
        if [ ${will_reboot} -eq 1 ]; then
            # install report code as next rc.firsttime script
            dofile_site /etc/rc.firsttime 0700 'root:wheel' \
                printf '%s\n' "${report_code}"

        else
            # attach report code to cleanup code
            cleanup_code="${cleanup_code}${NL}${report_code}"
        fi

    else
        # run report code now
        /bin/sh -c "${report_code}" || :
    fi
fi

# run cleanup code
if [ ${run_cleanup_code} -eq 1 ]; then
	print_info "Running cleanup code"
	sync
	exec /bin/sh -c "${cleanup_code}"
fi
