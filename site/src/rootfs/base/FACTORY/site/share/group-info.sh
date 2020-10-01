#!/bin/sh

# check_valid_group_name ( name )
#
#  Strict user name checker, will only allow lowercase letters and dash "-".
#  Names must not start with "-".
#  (This will not accept underscore daemon group names like "_unbound").
#
check_valid_group_name() {
    printf '%s' "${1}" | grep -qE -- '^[a-z][a-z\-]*$'
}

# fetch_group_gid_by_name ( name )
fetch_group_gid_by_name() {
    < /etc/group awk -F : -v group="${1}" \
        'BEGIN{ m=1; } ($1 == group) { print $3; m=0; exit; } END{ exit m; }'
}

# fetch_group_name_by_gid ( gid )
fetch_group_name_by_gid() {
    < /etc/group awk -F : -v gid="${1}" \
        'BEGIN{ m=1; } ($3 == gid) { print $1; m=0; exit; } END{ exit m; }'
}
