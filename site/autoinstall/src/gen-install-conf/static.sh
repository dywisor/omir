#!/bin/sh

load_env() {
	autodie set_outfile

	while [ ${#} -gt 0 ]; do
		. "${1}" || die "Failed to load file: ${1}"
		shift
	done
}
