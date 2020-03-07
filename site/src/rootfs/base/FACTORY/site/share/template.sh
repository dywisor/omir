#!/bin/sh

render_template() {
	local name
	local v0

	name="${1:?}"; shift
	locate_factory_template "${name}" || return
	render_template_file "${v0}" "${@}"
}
