#!/bin/sh
cd "${FACTORY_SITE_FILES}/etc" || exit 0

OLDIFS="${IFS}"

IFS='
'

print_action "Copy default /etc"

# create directories
find . -type d -print | (
    while read -r dirpath; do
        dst="/etc/${dirpath#./}"

        sb="$( stat -s "${dirpath}" )" && [ -n "${sb}" ] || exit
        eval "${sb}" || exit

        dec_mode="$(( st_mode & 07777 ))"
        mode="$( printf '%05o' "${dec_mode}" )"

        print_info "mkdir ${dst}"
        if mkdir -m "${mode}" -- "${dst}" 2>/dev/null; then
            # new directory, change owner
            chown -h -- "${st_uid}:${st_gid}" "${dst}"
        fi
    done
)


if factory_site_mode_is_install; then
    # install: copy files and symlinks
    find . \( -type f -or -type l \) -print | (
        while read -r filepath; do
            dst="/etc/${filepath#./}"

            print_info "import file/symlink ${dst}"
            cp -a -- "${filepath}" "${dst}"
        done
    )

#elif factory_site_mode_is_upgrade; then
else
    # upgrade: copy new/default files and symlinks
    find . \( -type f -or -type l \) -print | (
        while read -r filepath; do
            dst="/etc/${filepath#./}"

            if \
                ! check_fs_lexists "${dst}" || \
                grep -q -- 'OMIR_DEFAULT_CONFIG' "${dst}"
            then
                print_info "import/update file/symlink ${dst}"
                rm -f -- "${dst}"
                cp -a -- "${filepath}" "${dst}"

            else
                print_info "keep previous file/symlink ${dst}"
            fi
        done
    )
fi
