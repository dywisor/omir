#!/bin/sh

# site_cc ( outfile, *src_files )
site_cc() {
    local outfile

    outfile="${1:?}"; shift

    print_action "Compiling program: ${outfile} from ${*}"
    if ! cc -std=c99 -O2 -static -o "${outfile}" "${@}"; then
        print_err "Failed to compile ${outfile}"
        return 1
    fi

    strip -s "${outfile}" || :
    return 0
}


# site_cc_prog ( name, **v0! )
site_cc_prog() {
    v0=

    local name
    local src
    local outfile

    name="${1:?}"
    src="${FACTORY_SITE_SRC}/${name}.c"
    outfile="${FACTORY_SITE_BIN}/${name}"

    if [ ! -x "${outfile}" ]; then
        [ -f "${src}" ] || die "Program source missing: ${src}"
        site_cc "${outfile}" "${src}" || return
    fi

    v0="${outfile}"
}
