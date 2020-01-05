#!/bin/sh
# DEP: config env
# DEP: shlib  base
# DEP: shlib  omir-access


# void oink_init_vars ( **oink_! )
#
#  Initializes oink-build related variables.
#
oink_init_vars() {
	oink_statefile_rel="${OMIR_OINK_STATE_DIR}/openbsd_release"
	oink_statefile_have_sys_unpacked="${OMIR_OINK_STATE_DIR}/have_sys_unpacked"
	oink_statefile_have_src_unpacked="${OMIR_OINK_STATE_DIR}/have_src_unpacked"

	autodie fetch_stdout_nonempty uname -r
	oink_rel="${v0}"

	autodie openbsd_get_short_rel "${oink_rel}"
	oink_rel_short="${v0}"

	autodie fetch_stdout_nonempty uname -m
	oink_arch="${v0}"

	oink_build_ncpu="$( sysctl  -n hw.ncpufound )"
	: "${oink_build_ncpu:=1}"

	oink_bdir_distrib="${OMIR_OINK_BUILD_ROOT}/distrib"
	oink_bdir_miniroot="${oink_bdir_distrib}/miniroot"
	oink_bdir_special="${oink_bdir_distrib}/special"

	oink_bdir_arch="${oink_bdir_distrib}/${oink_arch}"

	oink_bdir_sys_arch="${OMIR_OINK_BUILD_ROOT}/sys/arch/${oink_arch}"
	oink_bdir_sys_arch_conf="${oink_bdir_sys_arch}/conf"
	oink_bdir_sys_arch_compile="${oink_bdir_sys_arch}/compile"

	oink_bdir_arch_ramdisk=""
	oink_bdir_sys_arch_conf_ramdisk=""
	oink_bdir_sys_arch_compile_ramdisk=""

	case "${oink_arch}" in
		'amd64'|'i386')
			oink_bdir_arch_ramdisk="${oink_bdir_arch}/ramdisk_cd"
			oink_bdir_sys_arch_conf_ramdisk="${oink_bdir_sys_arch_conf}/RAMDISK_CD"
			oink_bdir_sys_arch_compile_ramdisk="${oink_bdir_sys_arch_compile}/RAMDISK_CD"
		;;

		*)
			die "FIXME: set ramdisk build dir for arch ${oink_arch} in shlib/oink"
		;;
	esac

	oink_bdir_arch_ramdisk_flist="${oink_bdir_arch_ramdisk}/list"
}


# int oink_make ( dirpath, *args )
#
#   Runs make in dirpath.
#
oink_make() {
	local dirpath

	dirpath="${1:?}"; shift

	make ${oink_build_ncpu:+-j${oink_build_ncpu}} -C "${dirpath}/" "${@}"
}


# @autodie oink_unpack_omir_tgz_to_build_root ( fname )
#
#  Unpacks fname from the OpenBSD mirror directory to the build root.
#
oink_unpack_omir_tgz_to_build_root() {
	local v0
	local fname
	local tarball

	fname="${1:?}"

	autodie omira_get_file "${oink_rel}" "${fname}"
	tarball="${v0}"

	einfo "Unpacking ${fname} to build root"
	autodie tar -xez -f "${tarball}" -C "${OMIR_OINK_BUILD_ROOT}/"
}


# int oink_run_hook (
#    name, [workdir|"-"], {varname, value}, **oink_hook_did_run!
# )
#
#   Phases out for further modifications.
#
#   If <OMIR_OINK_HOOK_DIR>/<name>.sh exists, it will sourced in a subshell.
#   Otherwise, if <OMIR_OINK_HOOK_DIR>/<name> exists, it will be executed.
#   In either case, tThis function will return the hook's exit code
#   and set oink_hook_did_run to 1.
#
#   If neither file existed, then this function will return 0
#   and oink_hook_did_run will be set to 0.
#
#   The initial working directory may be specified via the <workdir> arg.
#
#   Any remaining arguments are interpreted as key-value pairs
#   and will be made available in the sourced/executed hooks.
#   (arg k is key, arg k + 1 is value)
#
oink_run_hook() {
	oink_hook_did_run=0

	local hook_name
	local hook_file
	local hook_is_sh
	local workdir

	hook_name="${1:?}"; shift

	workdir=""
	[ ${#} -eq 0 ] || { workdir="${1}"; shift; }
	case "${workdir}" in
		''|'-'|'.') workdir="${OMIR_OINK_TMPDIR}" ;;
	esac

	hook_file="${OMIR_OINK_HOOK_DIR}/${hook_name}.sh"
	if [ -f "${hook_file}" ]; then
		hook_is_sh=1

	else
		hook_is_sh=
		hook_file="${hook_file%.sh}"

		[ -x "${hook_file}" ] || return 0
	fi

	einfo "Running hook ${hook_name}"
	oink_hook_did_run=1  # no matter the outcome.

	(
		cd "${workdir}" || exit

		while [ ${#} -gt 0 ]; do
			eval "${1}=\"\${2}\""
			[ -n "${hook_is_sh}" ] || export "${1}"
			shift 2
		done

		if [ -n "${hook_is_sh}" ]; then
			. "${hook_file}"
		else
			exec "${hook_file}"
		fi
	)
}


# @autodie int check_file_not_modified ( a, b )
#
#  Returns 0 if a and b have the same content and 1 otherwise.
#
#  Any diff error results in die().
#
check_file_not_modified() {
	local rc

	# FIXME MAYBE: move to base
	diff -q -- "${@}" && return 0 || rc=${?}

	[ ${rc} -eq 1 ] || die "diff failed: ${*}" 
	return ${rc}
}


# @autodie void _oink_save_orig ( fpath )
#
#  Copies <fpath> to <fpath>.orig if that file does not exist yet.
#
_oink_save_orig() {
	autodie test -f "${1}"
	[ -f "${1}.orig" ] || autodie cp -- "${1}" "${1}.orig"
}

# @autodie void _oink_rotate_injected ( fpath )
#
#  Moves <fpath>.injected to <fpath> if modified,
#  deletes the injected file otherwise.
#
_oink_rotate_injected() {
	autodie test -f "${1}"
	autodie test -f "${1}.injected"

	if check_file_not_modified "${1}" "${1}.injected"; then
		rm -f -- "${1}.injected"
	else
		autodie mv -f -- "${1}.injected" "${1}"
	fi
}


# @autodie void _oink_inject ( fpath, io_modify_func, *args )
#
#  Code injection helper:
#  - creates a backup of fpath (if not backed up so far)
#  - calls io_modify_func, which should read the original 
#    file from stdin and write the modified file to stdout.
#    Any arguments in *args are passed to this function as-is.
#  - Moves to modified file to fpath if it differs from the original file.
#
_oink_inject() {
	local fpath

	fpath="${1:?}"; shift

	_oink_save_orig "${fpath}" || return
	"${@}" < "${fpath}" > "${fpath}.injected" || return
	_oink_rotate_injected "${fpath}" || return
}


# @autodie void oink_ramdisk_add_file ( src, ramdisk_fname )
oink_ramdisk_add_file() {
	local src
	local ramdisk_fname

	src="${1:?}"
	ramdisk_fname="${2:?}"

	_oink_inject "${oink_bdir_arch_ramdisk_flist}" \
		oink_ramdisk_add_file__io 'COPY' "${src}" "${ramdisk_fname#/}" \
		|| die "Failed to add file to ramdisk: ${src}"
}

# oink_install_sub_inject ( src, ramdisk_fname )
oink_install_sub_inject() {
	local install_sub
	local src_file
	local ramdisk_fname

	src_file="${1:?}"
	ramdisk_fname="${2:-${1##*/}}"

	oink_ramdisk_add_file "${src_file}" "${ramdisk_fname}" || return

	install_sub="${oink_bdir_miniroot}/install.sub"

	_oink_inject "${install_sub}" \
		oink_install_sub_inject_load_file__io "${ramdisk_fname}" \
		|| die "Failed to inject source-file instruction into ${install_sub}" ${?}
}


# oink_install_sub_inject_load_file__io ( inject_filepath )
#
#  Adds a source-file instruction to the install.sub file.
#  The file will be loaded after initializing vars,
#  just before checking whether to run autoinstall.
#
#  The line 
#    "# Interactive or automatic installation?"
#  will be used as anchor for injecting,
#  this might break on future OpenBSD releases.
#
#  Helper function - reads from stdin and writes to stdout.
#  Use oink_install_sub_inject() which also takes care
#  of adding the file to the ramdisk.
#
oink_install_sub_inject_load_file__io() {
	awk -v fname="${1:?}" \
'
BEGIN {
	entry_point_missing = 1;
	hook_missing = 2;
}


{ inject_now = 0; }

($1 == ".") && ($2 == fname) {
	hook_missing = 0;
}

($0 == "# Interactive or automatic installation?") {
	entry_point_missing = 0;
	inject_now = 1;
}

(hook_missing && inject_now) {
	printf(". %s\n", fname);
	hook_missing = 0;
}

{ print; }

END {
	exit (entry_point_missing + hook_missing);
}
'
}



# oink_ramdisk_add_file__io ( action, src, ramdisk_fname )
#
#  Add "<action> <src> <ramdisk_fname>" to end of file
#  if not already listed there.
#
oink_ramdisk_add_file__io() {
	awk \
		-v action="${1}" \
		-v src="${2}" \
		-v ramdisk_fname="${3}" \
'
BEGIN {
	file_missing = 1;
}


($1 == action) && ($2 == src) && ($3 == ramdisk_fname) {
	file_missing = 0;
}

{ print; }

END {
	if (file_missing) {
		printf("%s\t%s\t%s\n", action, src, ramdisk_fname);
	}
}
'
}
