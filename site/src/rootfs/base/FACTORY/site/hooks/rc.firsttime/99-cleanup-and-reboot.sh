#!/bin/sh
set -fu

RC_FIRSTTIME='/etc/rc.firsttime'


if feat_all "${OFEAT_RAMDISK_VAR_LOG-}"; then
    if dodir_mode "/FACTORY/log" 0700 'root:wheel'; then
        cleanup_log_dst="/FACTORY/log"
    else
        cleanup_log_dst="/var/log"
    fi
else
    cleanup_log_dst="/var/log"
fi


autodie rm -f -- "${RC_FIRSTTIME}.next"
exec 5>"${RC_FIRSTTIME}.next" || die "Failed to open ${RC_FIRSTTIME}.next"
autodie chmod -- 0700 "${RC_FIRSTTIME}.next"

rc_firsttime_cat() {
    cat "${@}" >&5 || die "Failed to write to ${RC_FIRSTTIME}.next"
}

rc_firsttime_printf() {
    printf "${@}" >&5 || die "Failed to write to ${RC_FIRSTTIME}.next"
}


add_script_header() {
rc_firsttime_cat << EOF
#!/bin/sh
set -fu
cd /
EOF
}

add_cleanup_code() {
rc_firsttime_cat << EOF
mv -- /install.site.log \"${cleanup_log_dst}/install.site.log\" || :
mv -- /upgrade.site.log \"${cleanup_log_dst}/upgrade.site.log\" || :
mv -- /rc.firsttime.log \"${cleanup_log_dst}/rc.firsttime.log\" || :

rm -rf -- \"${FACTORY_SITE}\"
rmdir -- \"${FACTORY_SITE%/*}\" 2>/dev/null || :

rm -f -- /OMIR_VERSION

rm -- /install.site
rm -- /upgrade.site
EOF
}


add_report_http_installed_code() {
    local report_script

    report_script='/usr/local/bin/omir-report-http-installed'

    if ! load_lib report/http; then
        print_err "Failed to load code gen lib"

    elif dofile_site "${report_script}" 0755 'root:wheel' \
        report_http_installed_gen_script
    then
        # NOTE: will not exec - TODO
        true

    else
        print_err "Failed to generate ${report_script}"
    fi
}


print_action "Cleanup and reporting"

#> script header
add_script_header

#> cleanup code
if feat_all "${OFEAT_AUTO_CLEANUP_FILES-}"; then
    add_cleanup_code
fi

#> installed flag file
if feat_all "${OFEAT_FLAG_FILE_INSTALLED-}"; then
    rc_firsttime_printf 'touch -- /OMIR_INSTALLED\n'
fi

#> report installed via http
if feat_all "${OFEAT_REPORT_HTTP_INSTALLED-}"; then
    add_report_http_installed_code
fi

#> close rc.firsttime.next file
exec 5>&-


# run now or on next boot?
if check_auto_reboot_active; then
    print_info "Delaying cleanup code until next reboot (pending)"
    mv -f -- "${RC_FIRSTTIME}.next" "${RC_FIRSTTIME}"

else
	print_info "Running cleanup code"
	sync
	exec /bin/sh -c ". ${RC_FIRSTTIME}.next; rm -f -- ${RC_FIRSTTIME}.next"
fi
