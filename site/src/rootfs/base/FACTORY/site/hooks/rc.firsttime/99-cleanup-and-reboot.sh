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
will_reboot=0
cleanup_code="
#!/bin/sh
set -fu
cd /
"

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


[ "${OFEAT_AUTO_CLEANUP_FILES:-0}" -eq 0 ] || add_cleanup_code

print_action "Cleanup"

if [ "${OFEAT_AUTO_REBOOT:-0}" -eq 1 ] && [ -e "${AUTO_REBOOT_FLAG_FILE}" ]; then
	if ! rm -- "${AUTO_REBOOT_FLAG_FILE}"; then
		print_err "Could not remove auto-reboot flag file, will not reboot."
	elif [ "${OFEAT_AUTO_REBOOT_DELAY:-0}" -eq 1 ]; then
		print_info "Adding delayed reboot code"
		add_delayed_reboot_code "${OCONF_AUTO_REBOOT_DELAY-}"
	else
		print_info "Adding reboot-now code"
		add_reboot_code
	fi
fi


if [ ${run_cleanup_code} -eq 1 ]; then
    if [ "${OFEAT_FLAG_FILE_INSTALLED:-0}" -eq 1 ]; then
        if [ ${will_reboot} -eq 1 ]; then
            dofile_site /etc/rc.firsttime 0700 'root:wheel' \
                printf '%s\n' '#!/bin/sh' 'touch -- /OMIR_INSTALLED'
        else
            cleanup_code="${cleanup_code}${NL}touch -- /OMIR_INSTALLED${NL}"
        fi
    fi

	print_info "Running cleanup code"
	sync
	exec /bin/sh -c "${cleanup_code}"

else
    if [ "${OFEAT_FLAG_FILE_INSTALLED:-0}" -eq 1 ]; then
        touch -- /OMIR_INSTALLED
    fi
fi
