#!/bin/sh
set -fu

[ -n "${__HAVE_FACTORY_SITE_ENV__-}" ] || . /FACTORY/site/env.sh || exit 8

. "${FACTORY_SITE_SHLIB:?}/base.sh" || exit 222

load_lib runtime-env
load_lib config
load_lib localconfig
load_lib fs
load_lib run-hook
load_lib run-helper
load_lib install
load_lib render-template
load_lib template
load_lib site-prep
load_lib site-dofile
load_lib site-cc
load_lib user-info
load_lib user-mgmt
load_lib user
load_lib pkg
load_lib git

if [ -f "${FACTORY_SITE_SHLIB:?}/mode/${FACTORY_SITE_MODE:?}.sh" ]; then
	load_lib "mode/${FACTORY_SITE_MODE}"
fi
