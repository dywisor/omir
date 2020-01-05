#!/bin/sh

_get_template_filepath() {
	v0="${FACTORY_SITE_TEMPLATES}/${1:?}"
}

_get_template_file() {
	_get_template_filepath "${@}" && [ -f "${v0}" ]
}

render_template() {
	local name
	local v0

	name="${1:?}"; shift
	_get_template_file "${name}" || return
	render_template_file "${v0}" "${@}"
}
