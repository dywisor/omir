#!/bin/sh
[ "${OFEAT_INSTALL_SCRIPTS:-0}" -eq 1 ] || exit 0

# chdir to scripts source dir so that globbing works
if ! cd "${FACTORY_SITE_FILES}/scripts"; then
	print_err "Failed to chdir to ${FACTORY_SITE_FILES}/scripts"
	exit 0  # HOOK-CONTINUE
fi

set +f
case "${OCONF_INSTALL_SCRIPTS-}" in
    'all'|'') set -- */* ;;
    *) set -- ${OCONF_INSTALL_SCRIPTS} ;;
esac
set -f

# fast-forward to first matched file
while [ $# -gt 0 ] && [ ! -f ${#} ]; do shift; done

if [ $# -eq 0 ]; then
    print_info "No scripts to install!"
    exit 0
fi

dst="/usr/local/bin"

if ! dodir "${dst}"; then
    print_err "Failed to create directory: ${dst}"
	exit 0  # HOOK-CONTINUE
fi

while [ $# -gt 0 ]; do
    if [ -f "${1}" ]; then
        doexe "${1}" "${dst}/${1##*/}" || \
            print_err "Failed to install script ${1}"
    fi
    shift
done

exit 0  # HOOK-CONTINUE
