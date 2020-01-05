#!/bin/sh
# no external dependencies here

# render_template_file ( template_file, *vardef )
render_template_file() {
	local infile

	infile="${1:?}"; shift
	< "${infile}" _render_template_io "${@}"
}


_render_template_guess_sep() {
	sep=

	local alpha
	local word
	local mask
	local usable

	word="${1:?}"

	# prefer '=' over alpha
	case "${word}" in
		*=*)
			:
		;;
		*)
			sep='='
			return 0
		;;
	esac

	alpha='#_!'

	mask="$( printf '%s' "${word}" | tr -C -d "[${alpha}]" )" || :

	if [ -n "${mask}" ]; then
		usable="$( printf '%s' "${alpha}" | tr -C -d "${mask}" )" || :
	else
		usable="${alpha}"
	fi

	if [ -n "${usable}" ]; then
		sep="$( printf '%s' "${usable}" | fold -w 1 | head -n 1 )"
	fi

	if [ -z "${sep}" ]; then
		printf 'render_template: could not guess sep\n' 1>&2
		return 1
	fi

	return 0
}


# @stdio _render_template_io ( *vardef )
#   vardef := 2 args, varname X value
#
#  Note varnames/value should not contain '=' chars
#  and must not contain all-of {'=', '#', '_', '!'}.
#
_render_template_io() {
	local varname
	local value
	local sep

	# @paranoid
	#for arg; do [ "${arg}" != "_" ] || return 2; done

	if [ ${#} -eq 0 ]; then
		cat

	else
		set -- "${@}" '_'

		while [ ${#} -gt 0 ] && [ "${1}" != '_' ]; do
			varname="${1:?}"
			value="${2?}"

			_render_template_guess_sep "${varname}${value}" || return 3

			set -- "${@}" -e "s${sep}@@${varname}@@${sep}${value}${sep}g"

			shift 2 || return 2
		done

		shift || return

		sed -r "${@}"
	fi
}
