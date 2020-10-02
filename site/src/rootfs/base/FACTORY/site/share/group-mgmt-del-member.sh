#!/bin/sh

# remove_user_from_group ( group_name, user_name )
remove_user_from_group() {
    # http://openbsd.7691.n7.nabble.com/How-to-remove-user-from-group-td96758.html
    # >> How to remove user from group?
    # > edit /etc/group
    # --

    [ -n "${1-}" ] || die "Empty group name"
    [ -n "${2-}" ] || die "Empty user name"

    dofile_site /etc/group 0644 'root:wheel' gen_remove_user_from_group "${@}"
}

gen_remove_user_from_group() {
< /etc/group awk -F ':'  -v g="${1}" -v u="${2}" \
'
BEGIN { OFS = FS; }

{ pass_through = 1; }

($1 == g) {
    pass_through = 0;

    split($4, user_list, ",");

    printf "%s:%s:%s:", $1, $2, $3;

    first = 1;
    for (user_idx in user_list) {
        user_name = user_list[user_idx];
        if (user_name && user_name != u) {
            if (!first) { printf ","; }
            printf "%s", user_name;
            first = 0;
        }
    }

    printf "\n";
}

(pass_through) { print; }
'
}
