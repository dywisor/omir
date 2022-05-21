#!/bin/sh

# @stdout void einfo ( *msg )
einfo() {
    printf '%s\n' "${@}"
}


# @stderr void ewarn ( *msg )
ewarn() {
    printf '%s\n' "${@}" 1>&2
}


# @stderr void eerror ( *msg )
eerror() {
    printf '%s\n' "${@}" 1>&2
}


# @noreturn @stderr die ( [msg], [exit_code] )
die() {
    eerror "${1:+died: }${1:-died.}"
    exit "${2:-250}"
}


# void autodie ( *cmdv )
autodie() {
    "${@}" || die "command returned ${?}: ${*}" ${?}
}


# int fetch_stdout_nonempty ( *cmdv, **v0! )
fetch_stdout_nonempty() {
    v0="$( "${@}" )" && [ -n "${v0}" ]
}


# ~int openbsd_print_short_rel ( *release )
openbsd_print_short_rel() {
    printf '%s\n' "${@}" | tr -d '.'
}


# int openbsd_get_short_rel ( *release, **v0! )
openbsd_get_short_rel() {
    fetch_stdout_nonempty openbsd_print_short_rel "${@}"
}


# _dofilepath ( path, [mode], [owner:group] )
_dofilepath() {
    [ "${2:--}" = '-' ] || chmod -- "${2}" "${1}" || return
    [ "${3:--}" = '-' ] || chown -- "${3}" "${1}" || return
}


# dodir ( dirpath, [mode], [owner:group] )
dodir() {
    mkdir -p -- "${1:?}" || return
    _dofilepath "${@}"
}

# rmfile ( *path )
rmfile() {
    while [ ${#} -gt 0 ]; do
        if [ -f "${1}" ]; then
            # file or symlink
            autodie rm -- "${1}"

        elif [ -e "${1}" ]; then
            die "Cannot remove non-file ${1}"

        elif [ -h "${1}" ]; then
            # broken symlink
            autodie rm -- "${1}"
        fi

        shift
    done
}


# mkindex ( dirpath )
mkindex() {
    ( cd "${1}" && omir-mkindex > './index.txt'; )
}


# int join_fspath ( *path_element, **v0! )
join_fspath() {
    v0=""

    while [ ${#} -gt 0 ] && [ -z "${1}" ]; do shift; done

    [ ${#} -gt 0 ] || return 1

    v0="${1}"; shift
    while [ ${#} -gt 0 ]; do
        case "${1}" in
            ''|'/'|'.')
                :
            ;;

            *)
                v0="${v0%/}/${1#/}"
            ;;
        esac
        shift
    done
}

# int pick_config_file ( basepath, **v0! )
#
#   Sets v0 to "<basepath>.local" if present and "<basepath>" otherwise.
#   Returns 0 if any of these files exist, else non-zero.
#
pick_config_file() {
    if [ -z "${1-}" ]; then
        v0=""
        return 64

    elif [ -r "${1}.local" ]; then
        v0="${1}.local"
        return 0

    elif [ -r "${1}" ]; then
        v0="${1}"
        return 0

    else
        v0=""
        return 1
    fi
}
