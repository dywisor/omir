#!/bin/sh
# DEP: config env
# DEP: shlib  base

# void omira_get_filepath ( *path_components, **v0! )
#
omira_get_filepath() {
    join_fspath "${MIRROR_OPENBSD:?}" "${@}"
}


# int omira_get_file ( *path_components, **v0! )
#  USUALLY omira_get_filepath ( release, filename )
#  USUALLY omira_get_filepath ( release, <arch>, filename )
#
#   Interprets path_components relative to the OpenBSD mirror root
#   and checks whether the resulting path is a file.
#
omira_get_file() {
    omira_get_filepath "${@}" && [ -f "${v0}" ]
}
