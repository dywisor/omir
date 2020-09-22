#!/bin/sh
[ "${OFEAT_PKG_PYTHON_LATEST:-0}" -eq 1 ] || exit 0

find_python3_pkg() {
    pkg_info -Q 'python--' \
        | awk '( $1 ~ /^python-3[.][0-9]+[.][0-9]+$/ ) { print $1; }' \
        | sort -Vr
}

pkg="$( find_python3_pkg | head -n 1 )"

if [ -n "${pkg}" ]; then
	print_action "Install Python: ${pkg}"
    if pkg_add "${pkg}"; then
        localconfig_add PYTHON_PKG "${pkg}"
    else
        print_err "Failed to install Python: ${pkg}"
    fi
else
	print_err "No Python package found."
fi
