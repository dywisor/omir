#!/bin/sh
[ "${OFEAT_RAMDISK:-0}" -eq 1 ] || exit 0

D=/skel/ram
RAMLIVE_ROOT=/ram

print_action "prepare ramdisk skel"

## users dir
if [ "${OFEAT_RAMDISK_USERDIR:-0}" -eq 1 ]; then
    autodie mkdir -p -- "${D}/users"
    autodie chmod -- 0711 "${D}/users"

    {
    < /etc/passwd awk -F : \
        -v ramskel_home="/skel/home" \
        -v ramskel_users="${D}/users" \
        -v ramlive_users="${RAMLIVE_ROOT}/users" \
        -v min_uid=999 \
        -v max_uid=5000 \
    '
    BEGIN {
        printf("{\n");
    }

    {
        hot = 0;
        ramskel = "";
        ramlive = "";
    }

    ($3 == 0) || (($3 > min_uid) && ($3 < max_uid)) {
        ramskel = (ramskel_users "/" $1);
        ramlive = (ramlive_users "/" $1);

        hot = 1;
    }

    (hot) {
        printf("mkdir -p -- \"%s\"\n", ramskel);
        printf("chmod -- 0750 \"%s\"\n", ramskel);
    }

    (hot) {
        printf("mkdir -p -- \"%s\"\n", (ramskel "/log"));
        printf("mkdir -p -- \"%s\"\n", (ramskel "/tmux"));
        printf("mkdir -p -- \"%s\"\n", (ramskel "/vim"));
    }

    (hot && ($3 != 0)) {
        printf("mkdir -p -- \"%s\"\n", (ramskel "/tmp"));
    }

    (hot && ($6 ~ "^/(root$|home/)")) {
        printf("d=\"%s/%s\"\n", ramskel_home, $1);
        printf("[ -d \"${d}\" ] || d=\"%s\"\n", $6);
        printf("[ ! -d \"${d}\" ] || ln -fs -- \"%s\" \"${d}/ram\"\n", ramlive);
    }

    (hot) {
        printf("chown -R -- %s:%s \"%s\"\n", $3, $4, ramskel);
    }

    END {
        printf("}\n");
    }
    '
    } | sh -e || die "Failed to create per-user directories"

    autodie dodir /etc/shinit
    autodie doins "${FACTORY_SITE_FILES}/shinit/ramdisk.sh" "/etc/shinit/ramdisk.sh"
fi


if [ "${OFEAT_RAMDISK_LOG:-0}" -eq 1 ]; then
    ## log dir
    autodie mkdir -p -m 0755 -- "${D}/log"
    autodie touch -- "${D}/log/messages"

    # newsyslog: duplicate /var/log/messages line for /ram/log/messages
    < /etc/newsyslog.conf sed -r -e '/\/var\/log\/messages/{p;s=/var/=/ram/=g;}' > /etc/newsyslog.conf.site || die "Failed to edit newsyslog.conf"
    autodie site_prep /etc/newsyslog.conf
fi
