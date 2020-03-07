#!/bin/sh
set -fu

run_cleanup_code=0
cleanup_code="
#!/bin/sh
set -fu
cd /
"

add_cleanup_code() {

run_cleanup_code=1
cleanup_code="${cleanup_code}
mv -- /install.site.log /var/log/install.site.log
mv -- /rc.firsttime.log /var/log/rc.firsttime.log

rm -rf -- "${FACTORY_SITE}"
rmdir -- "${FACTORY_SITE%/*}" 2>/dev/null || :

rm -f -- /OMIR_VERSION

rm -- /install.site
"
}


add_reboot_code() {

run_cleanup_code=1
cleanup_code="${cleanup_code}
rm -f -- /etc/rc.firsttime.run
sync
reboot
"
}

add_delayed_reboot_code() {

run_cleanup_code=1
cleanup_code="${cleanup_code}
shutdown -r '${1:?}'
"
}


[ "${OFEAT_AUTO_CLEANUP_FILES:-0}" -eq 0 ] || add_cleanup_code

print_action "Cleanup"

if [ "${OFEAT_AUTO_REBOOT:-0}" -eq 1 ] && [ -e "${AUTO_REBOOT_FLAG_FILE}" ]; then
	if ! rm -- "${AUTO_REBOOT_FLAG_FILE}"; then
		print_err "Could not remove auto-reboot flag file, will not reboot."
	elif [ "${OFEAT_AUTO_REBOOT_DELAY:-0}" -eq 1 ]; then
		add_delayed_reboot_code "${OCONF_AUTO_REBOOT_DELAY:-+2}"
	else
		add_reboot_code
	fi
fi


if [ ${run_cleanup_code} -eq 1 ]; then
	print_info "Running cleanup code"
	sync
	exec /bin/sh -c "${cleanup_code}"
fi
