#!/bin/sh
: "${FACTORY_SITE_MODE:="undef"}"

FACTORY_SITE='/FACTORY/site'
FACTORY_SITE_BIN="${FACTORY_SITE}/bin"
FACTORY_SITE_SRC="${FACTORY_SITE}/src"
FACTORY_SITE_SHLIB="${FACTORY_SITE}/share"
FACTORY_SITE_HOOKS="${FACTORY_SITE}/hooks"
FACTORY_SITE_FILES="${FACTORY_SITE}/files"
FACTORY_SITE_TEMPLATES="${FACTORY_SITE}/templates"
FACTORY_SITE_ETC="${FACTORY_SITE}/etc"
FACTORY_SITE_CONFIG="${FACTORY_SITE_ETC}/conf.sh"
FACTORY_SITE_CONFD="${FACTORY_SITE_ETC}/conf.d"
FACTORY_SITE_LOCALCONFIG="${FACTORY_SITE_ETC}/localconf.sh"

export HOME='/root'

export PATH="${FACTORY_SITE_BIN}:${HOME}/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

__HAVE_FACTORY_SITE_ENV__=y