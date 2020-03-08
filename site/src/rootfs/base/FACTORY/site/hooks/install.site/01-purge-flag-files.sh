#!/bin/sh
[ "${OFEAT_FLAG_FILE_INSTALLED:-0}" -eq 1 ] || exit 0

rm -f -- /OMIR_INSTALLED || :

if check_fs_lexists /OMIR_INSTALLED; then
    die "Failed to remove installed flag file."
fi
