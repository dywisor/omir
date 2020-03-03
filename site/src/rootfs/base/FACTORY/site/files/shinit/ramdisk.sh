#!/bin/sh
if [ -n "${USER-}" ]; then
	t0="/ram/users/${USER}"
	t1=''

	if [ -d "${t0}/." ]; then
		# assume that err~thing in RAMDISK is writable
		export RAMDISK="${t0}"

		t0="${RAMDISK}/tmp"
		if [ -d "${t0}" ]; then
			export TMPDIR="${t0}"
		fi

		t0="${RAMDISK}/tmux"
		[ ! -d "${t0}" ] || export TMUX_TMPDIR="${t0}"

		t0="${RAMDISK}/log"
		if [ -d "${t0}" ]; then
			t1="${t0}/sh_history"
			[ ! -f "${t1}" ] || export HISTFILE="${t1}"
		fi

	fi

	unset -v t0
	unset -v t1
fi
