#!/bin/sh

# run_helper ( name )
run_helper() {
    local __NAME__
    local __FILE__

    __NAME__="${1:?}"; shift
    __FILE__="${FACTORY_SITE_BIN}/${__NAME__}"

    "${__FILE__}" "${@}"
}
