#!/bin/sh
# DEP: config env
# DEP: shlib  base

# sacrifice consistency for speed
OMIR_RSYNC_EXTRA_OPTS="--progress --size-only"


# ~int __omir_rsync_check_exist ( base_url, relpath )
#
#  Checks whether the given path exists on the remote end.
#
__omir_rsync_check_exist() {
	rsync --quiet --dry-run "${1}/${2#/}"
}


# ~int __omir_rsync ( *argv, **OMIR_RSYNC_EXTRA_OPTS= )
#
#  Rsync helper for omir-sync that applies sync-related
#  options, suitable for mirroring release directories.
#
#  %argv should at least include a src and a dst argument.
#
__omir_rsync() {
	rsync \
		-rv \
		--delete --delete-delay --delay-updates --fuzzy \
		--exclude '.~tmp~' --exclude '.*' \
		${OMIR_RSYNC_EXTRA_OPTS-} \
		--chmod=F0644,D0755 \
		\
		"${@}"
}


# int omir_fetch_openbsd_releases (
#   <releases>:=**OMIR_REL,
#   **OMIR_UPSTREAM_MIRROR_URI, **OMIR_FILTER_LIST, **MIRROR_OPENBSD
# )
#
#  Fetches releases from the upstream mirror (%OMIR_UPSTREAM_MIRROR_URI)
#  and stores them in the local mirror directory (%MIRROR_OPENBSD).
#
#  By default, releases listed in %OMIR_REL will be fetched,
#  this can be overridden by passing specific release versions as argument(s).
#
#  If any of the given releases does not exist on the remote end,
#  then this function will abort without fetching anything,
#  preventing rsync from nuking the locally mirrored release directory.
#
#  Only the requested release versions will be mirrored,
#  other releases existing below %MIRROR_OPENBSD will be left untouched.
#  It should be safe to call this function several times for different releases.
#
#  -> Old releases have to be cleaned up manually:
#     (1) this function will refuse to sync until OMIR_REL has been fixed
#     (2) from the local mirror directory
#
omir_fetch_openbsd_releases() {
	local releases
	local rel
	local rel_filter_list

	set -- ${*}
	[ ${#} -gt 0 ] || set -- ${OMIR_REL:?}

	if [ ${#} -eq 0 ]; then
		eerror "ABORTING - no releases specified."
		return 4
	fi
	releases="${*}"

	# loop over releases and check whether they exist on the remote end
	set --
	for rel in ${releases}; do
		# pick a file that should exist on the remote mirror -- .../amd64/bsd
		__omir_rsync_check_exist "${OMIR_UPSTREAM_MIRROR_URI}" "${rel}/amd64/bsd" || set -- "${@}" "${rel}"
	done

	if [ ${#} -gt 0 ]; then
		eerror "ABORTING - missing releases on remote server: ${*}"
		return 5
	fi

	# collect filter lists
	#   start with the 'base begin' list
	set --
	set -- "${@}" --filter ". ${OMIR_FILTER_LIST}.head"

	# loop over releases and add individual filter lists
	#   if there's no list for a release, create a new one from template
	for rel in ${releases}; do
		rel_filter_list="${OMIR_FILTER_LIST}.${rel}"

		if [ -f "${rel_filter_list}" ]; then
			# exists, ok
			:

		elif [ -e "${rel_filter_list}" ] || [ -h "${rel_filter_list}" ]; then
			# not a file
			return 225

		elif ! {
			sed -r -e "s=@@REL@@=${rel}=g" \
				< "${OMIR_FILTER_LIST}.skel" \
				> "${rel_filter_list}.new"
		}; then
			# failed to render template
			return 230

		elif ! mv -- "${rel_filter_list}.new" "${rel_filter_list}"; then
			# failed to put new filter list file into place
			return 231
		fi

		# add filter list to argv
		set -- "${@}" --filter ". ${OMIR_FILTER_LIST}.${rel}"
	done

	# add 'base end' list
	set -- "${@}" --filter ". ${OMIR_FILTER_LIST}.tail"

	__omir_rsync "${@}" -- "${OMIR_UPSTREAM_MIRROR_URI%/}/" "${MIRROR_OPENBSD%/}/"
}


# int omir_fetch_openbsd_firmware (
#   <releases>:=**OMIR_REL,
#   **OMIR_UPSTREAM_FW_URI, **MIRROR_OPENBSD_FW
# )
#
#  Fetches firmware files for specific releases
#  from the upstream mirror (%OMIR_UPSTREAM_FW_URI)
#  and stores them in the local firmware mirror directory (%MIRROR_OPENBSD_FW).
#
#  This function's behavior regarding other/old release versions
#  is mostly similar to omir_fetch_openbsd_releases(),
#  but all files below the firmware mirror directory will be affected by chmod().
#
omir_fetch_openbsd_firmware() {
	local releases
	local firmware_dst
	local rel

	set -- ${*}
	[ ${#} -gt 0 ] || set -- ${OMIR_REL:?}

	if [ ${#} -eq 0 ]; then
		eerror "ABORTING - no releases specified."
		return 4
	fi
	releases="${*}"

	mkdir -p -- "${MIRROR_OPENBSD_FW}/" || return

	for rel in ${releases}; do
		firmware_dst="${MIRROR_OPENBSD_FW}/${rel}"

		mkdir -p -- "${firmware_dst}" || return
		einfo "Fetching firmware for ${rel}"
		shamir --base64 -C "${firmware_dst}" "${OMIR_UPSTREAM_FW_URI}/${rel}" || return
	done

	find "${MIRROR_OPENBSD_FW}" -mindepth 1 -type f -exec chmod 0644 '{}' +
	find "${MIRROR_OPENBSD_FW}" -mindepth 1 -type d -exec chmod 0755 '{}' +
}


# FIXME: move to base
__omir_sync_xargs_mkindex() {
	xargs -0 -r -n 1 sh -c 'cd "${1}" && omir-mkindex > ./index.txt' _
}


# int omir_mirror_mkindex ( **MIRROR_OPENBSD )
#
#  Recursively refreshes index.txt files for all directories
#  in the local mirror, except for the firmware directory
#  which is assumed to already contain proper index files.
#
#  COULDFIX: all directories named "firmware" will be skipped.
#
omir_mirror_mkindex() {
	find "${MIRROR_OPENBSD%/}/" -type d -not -empty \
		\( -name firmware -prune -or -print0 \) \
		| __omir_sync_xargs_mkindex
}
