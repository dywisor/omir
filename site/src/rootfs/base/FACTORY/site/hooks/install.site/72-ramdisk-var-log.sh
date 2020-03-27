#!/bin/sh
#
feat_all "${OFEAT_RAMDISK_VAR_LOG-}" || exit 0
test "${OCONF_RAMDISK_VAR_LOG:-0}" -gt 0 || die "Invalid ramdisk size for /var/log"

mp='/var/log'

print_action "Prepare ramdisk at ${mp}"

size="${OCONF_RAMDISK_VAR_LOG}"
skel="/skel${mp}"

prog_copy_skel="${FACTORY_SITE_BIN}/update-log-skel"

autodie mkdir -p -- "${skel}"

if [ -d "${mp}" ]; then
    # move install.resp files to /FACTORY/log (non-fatal)
    if dodir_mode "/FACTORY/log" 0700 'root:wheel'; then
        set +f
        set -- "${mp}/install.resp."*
        set -f

        for resp_file in "${@}"; do
            if [ -f "${resp_file}" ]; then
                mv -- "${resp_file}" "/FACTORY/log/${resp_file##*/}" || \
                    print_err "Failed to move ${resp_file}"
            fi
        done
    fi

    autodie "${prog_copy_skel}" "${mp}" "${skel}"
else
    autodie dopath "${skel}" 0755 'root:wheel'
fi

# make update-log-skel script available to installed system
autodie install -D -m 0755 -- \
    "${prog_copy_skel}" "/usr/local/bin/${prog_copy_skel##*/}"

autodie fstab_add_skel_mfs "${skel}" "${mp}" "${size}"
