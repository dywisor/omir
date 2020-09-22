SHELL ?= sh

S := ${.CURDIR}

.include "${S}/../../etc/omir.mkenv"

SRC = ${S}/src
PROFILES_DIR = ${OMIR_SITE_CONF_DIR}/profiles

PROFILES != ( cd "${PROFILES_DIR}" && find ./ -type f -not -name '.keep' | sed -r -e 's=^[.]/==' )

PXE_USE_SYMLINK ?= 1
.if ${PXE_USE_SYMLINK}
PXE_DOLINK = ${OMIR_LIBEXEC}/ln-file-sym-rel
.else
PXE_DOLINK = cp -pP --
.endif

CONFIGV =
CONFIGV += ${OMIR_SITE_CONF_DIR}/config
CONFIGV += ${OMIR_SITE_CONF_DIR}/config.autoinstall

LOCALCONFIGV =
LOCALCONFIGV += ${OMIR_SITE_CONF_DIR}/config.local
LOCALCONFIGV += ${OMIR_SITE_CONF_DIR}/config.autoinstall.local

PHONY =

PHONY += all
all: all-install-conf


PHONY += list-config-vars
list-config-vars:
	< '${SRC}/gen-install-conf/common.sh' grep -Eo -- '(OFEAT|OCONF)[A-Z_]+' | sort -u

# helper script for creating install.conf files
gen-install-conf: ${SRC}/gen-install-conf/static.sh ${SRC}/gen-install-conf/common.sh
	cat -- ${.ALLSRC} > ${@}.make_tmp
	chmod -- 0755 ${@}.make_tmp
	mv -f -- ${@}.make_tmp ${@}


_SETUP_FILES =
ALL_INSTALL_CONF =
.for _rel in ${OMIR_REL}
.for _arch in ${OMIR_ARCH}

#ALL_INSTALL_FILES += ${MIRROR_PXE_OPENBSD}/${_rel}/gen-install-conf
#${MIRROR_PXE_OPENBSD}/${_rel}/gen-install-conf
#   from ramdisk + common

${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}:
	mkdir -p -- ${@}

# bsd.rd
_SETUP_FILES += ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/bsd.rd
${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/bsd.rd: \
	${MIRROR_OPENBSD}/${_rel}/${_arch}/bsd.rd \
	${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}

	rm -f -- ${@}
	${PXE_DOLINK}  ${MIRROR_OPENBSD}/${_rel}/${_arch}/bsd.rd ${@}

# etc/
_SETUP_FILES += ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc
${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc: ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}
	mkdir -p -- ${@}

# etc/boot.conf.default
_SETUP_FILES += ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc/boot.conf.default
${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc/boot.conf.default: \
	${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc

	mkdir -p -- ./tmp/${_rel}/${_arch}/etc
	rm -f -- ./tmp/${_rel}/${_arch}/etc/boot.conf.default
	{ set -e; \
		printf 'boot tftp://%s/%s/%s/bsd.rd\n' \
			'${MIRROR_PXE_OPENBSD:C/^${MIRROR_ROOT:/=}\/*//}' \
			'${_rel}' '${_arch}'; \
	} > ./tmp/${_rel}/${_arch}/etc/boot.conf.default

	chmod -- 0644 ./tmp/${_rel}/${_arch}/etc/boot.conf.default
	mv -f -- ./tmp/${_rel}/${_arch}/etc/boot.conf.default ${@}.make_tmp
	mv -f -- ${@}.make_tmp ${@}

# etc/boot.conf.com0
_SETUP_FILES += ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc/boot.conf.com0
${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc/boot.conf.com0: \
	${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc/boot.conf.default

	rm -f -- ./tmp/${_rel}/${_arch}/etc/boot.conf.com0
	{ set -e; \
		printf 'stty %s %s\n' 'com0' '115200'; \
		printf 'set tty %s\n' 'com0'; \
		cat ${.ALLSRC}; \
	} > ./tmp/${_rel}/${_arch}/etc/boot.conf.com0

	chmod -- 0644 ./tmp/${_rel}/${_arch}/etc/boot.conf.com0
	mv -f -- ./tmp/${_rel}/${_arch}/etc/boot.conf.com0 ${@}.make_tmp
	mv -f -- ${@}.make_tmp ${@}

# etc/boot.conf (only if new)
_SETUP_FILES += ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc/boot.conf
${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc/boot.conf: \
	${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/etc/boot.conf.default

	test -e '${@}' || test -h '${@}' || ln -s -- boot.conf.default ${@}


.for _variant in ${PROFILES}

# install.conf
ALL_INSTALL_CONF += ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/${_variant}/install.conf
${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/${_variant}/install.conf: \
	gen-install-conf \
	${CONFIGV} ${PROFILES_DIR}/${_variant} ${LOCALCONFIGV}
	
	mkdir -p -- ./tmp/${_rel}/${_arch}/${_variant}
	rm -f -- ./tmp/${_rel}/${_arch}/${_variant}/install.conf

	env \
		OCONF_INSTALL_ARCH='${_arch}' \
		OCONF_INSTALL_RELEASE='${_rel}' \
		OCONF_INSTALL_RELEASE_SHORT='${_rel:S/.//g}' \
		${SHELL} ${.ALLSRC} > ./tmp/${_rel}/${_arch}/${_variant}/install.conf

	chmod -- 0644 ./tmp/${_rel}/${_arch}/${_variant}/install.conf

	mkdir -p -- ${@D}
	mv -f -- ./tmp/${_rel}/${_arch}/${_variant}/install.conf ${@}.make_tmp
	mv -f -- ${@}.make_tmp ${@}


.if ("${_arch}" == "amd64") || ("${_arch}" == "i386")
# pxeboot
_SETUP_FILES += ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/${_variant}/pxeboot
${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/${_variant}/pxeboot: \
	${MIRROR_OPENBSD}/${_rel}/${_arch}/pxeboot

	mkdir -p -- ${@D}
	rm -f -- ${@}
	${PXE_DOLINK} ${.ALLSRC} ${@}

# auto_install
_SETUP_FILES += ${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/${_variant}/auto_install
${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/${_variant}/auto_install: \
	${MIRROR_PXE_OPENBSD}/${_rel}/${_arch}/${_variant}/pxeboot

	rm -f -- ${@}
	ln -s -- pxeboot ${@}
.endif

.endfor
.endfor
.endfor

SETUP_FILES = ${_SETUP_FILES}

SETUP_FILES += ${MIRROR_PXE_OPENBSD}/current
${MIRROR_PXE_OPENBSD}/current: ${_SETUP_FILES} FORCE
	test -d '${MIRROR_PXE_OPENBSD}/${OMIR_CUR_REL}'

	{ set -e; \
		if [ -h '${@}' ]; then \
			target="$$( readlink '${@}' )"; \
			if [ "$${target}" != '${OMIR_CUR_REL}' ]; then \
				rm -f -- '${@}'; \
				ln -s -- '${OMIR_CUR_REL}' '${@}'; \
			fi; \
		elif [ -e '${@}' ]; then \
			exit 2; \
		else \
			ln -s -- '${OMIR_CUR_REL}' '${@}'; \
		fi; \
	}


# FIXME: amd64 hardcoded
SETUP_FILES += ${MIRROR_ROOT}/etc
${MIRROR_ROOT}/etc: ${MIRROR_PXE_OPENBSD}/current
	test -e '${@}' || test -h '${@}' || \
		${OMIR_LIBEXEC}/ln-file-sym-rel \
		${MIRROR_PXE_OPENBSD}/current/amd64/etc \
		${@}

PHONY += all-install-conf
all-install-conf: ${ALL_INSTALL_CONF}

PHONY += setup
setup: ${SETUP_FILES} ${ALL_INSTALL_CONF}


FORCE:

.PHONY: ${PHONY}
