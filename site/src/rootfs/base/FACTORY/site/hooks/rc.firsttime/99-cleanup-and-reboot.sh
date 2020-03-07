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
    local delay
    if [ -z "${1-}" ]; then
        delay=60

    elif [ "${1}" -gt 0 ]; then
        delay="${1}"

    else
        print_err "Invalid delay: ${1}, defaulting."
        delay=60
    fi

run_cleanup_code=1
cleanup_code="${cleanup_code}
perl -e '
use strict;
use warnings;
use feature qw( say );

use POSIX ();

my \$pid = fork;
if ( \$pid < 0 ) {
       exit 1;
} elsif ( \$pid > 0 ) {
       exit 0;
} else {
       my \$devnull = \"/dev/null\";
       my @cmdv = ( \"shutdown\", \"-r\", \"now\" );

       POSIX::setsid or warn;

       close STDIN;
       open STDIN, \"<\", \$devnull;

       close STDOUT;
       open STDOUT, \">>\", \$devnull;

       close STDERR;
       open STDERR, \">&STDOUT\";

       sleep ${delay};
       exec @cmdv;
}
'
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
	print_info "Running cleanup code"
	sync
	exec /bin/sh -c "${cleanup_code}"
fi
