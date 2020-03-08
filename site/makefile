S := ${.CURDIR}
SRC := ${S}/src
SRC_ROOTFS := ${SRC}/rootfs
LOCAL_ROOTFS := ${S}/local/rootfs

# include additional rootfs sources in addition to the 'base' overlay
#
# Each overlay <name> must exist in SRC_ROOTFS/<name> or LOCAL_ROOTFS/<name>.
# If it exists in both directories, both sources will be copied
# with contents from LOCAL_ROOTFS overwriting those from SRC_ROOTFS.
#
SITE_ROOTFS_OVERLAYS ?=

BUILD_ROOTFS = build-rootfs
BUILD_ROOTFS_TMP = ${BUILD_ROOTFS}.make_tmp
BUILD_ROOTFS_TMP_DEP = ${BUILD_ROOTFS_TMP}/OMIR_VERSION

FACTORY                = ${BUILD_ROOTFS_TMP}/FACTORY
FACTORY_SITE           = ${FACTORY}/site
FACTORY_SITE_BIN       = ${FACTORY_SITE}/bin
FACTORY_SITE_ETC       = ${FACTORY_SITE}/etc
FACTORY_SITE_ETC_CONFD = ${FACTORY_SITE_ETC}/conf.d

SITE_INSTALL_LIBEXEC =
SITE_INSTALL_LIBEXEC += derive-ip-addr
SITE_INSTALL_LIBEXEC += fstab-add-mfs
SITE_INSTALL_LIBEXEC += netconf-mac-key
SITE_INSTALL_LIBEXEC += netmask-hex-to-dot


# FIXME: hardcoded env path
.include "${S}/../etc/omir.mkenv"

X_DISOWN_TAR = ${OMIR_LIBEXEC}/disown-tar

GNU_TAR ?= 0

PHONY += all
all: site.tgz
	${OMIR_BIN_DIR}/omir-run omir-publish-site ./site.tgz

site.tgz: ${BUILD_ROOTFS} FORCE

.if ${GNU_TAR}
	tar -c -f ${@}.make_tmp.tar --numeric-owner -v --one-file-system -C ${BUILD_ROOTFS} ./
.else
	tar -c -e -f ${@}.make_tmp.tar -m -N -v -X -C ${BUILD_ROOTFS} ./
.endif

	${X_DISOWN_TAR} ${@}.make_tmp.tar
	gzip -c < ${@}.make_tmp.tar > ${@}.make_tmp
	rm -f -- ${@}.make_tmp.tar
	mv -f -- ${@}.make_tmp ${@}

${BUILD_ROOTFS}: ${BUILD_ROOTFS_TMP}
	[ ! -d '${@}' ] || rm -rf -- '${@}'
	mv -- '${BUILD_ROOTFS_TMP}' '${@}'


# BUILD_ROOTFS_TMP/OMIR_VERSION -- init rootfs, copy sources
${BUILD_ROOTFS_TMP_DEP}: FORCE
	[ ! -d '${@D}' ] || rm -rf -- '${@D}'
	mkdir -p -- ${@D}

# copy overlays
.for _name in base ${SITE_ROOTFS_OVERLAYS}
	{ set -e; \
		hit=0; \
		for src in '${SRC_ROOTFS}/${_name}' '${LOCAL_ROOTFS}/${_name}'; do \
			[ ! -d "$${src}" ] || { rsync -aH -- "$${src}/" '${@D}/' && hit=1; } || exit 8; \
		done; \
		[ "$${hit}" -eq 1 ] || exit 9; \
	}
.endfor

# create essential factory directories, chmod files
	install -d -m 0755 -- ${FACTORY}

	install -d -m 0700 -- ${FACTORY_SITE}
	find ${FACTORY_SITE}/ -type f -exec chmod a-w '{}' +
	find ${FACTORY_SITE}/ -type d -exec chmod go-w '{}' +

	install -d -m 0755 -- ${FACTORY_SITE_BIN}
	install -d -m 0700 -- ${FACTORY_SITE_ETC}
	install -d -m 0700 -- ${FACTORY_SITE_ETC_CONFD}

# create OMIR_VERSION file
	rm -f -- ${@}.make_tmp
	( umask 0077; { git describe --no-match --always --dirty && date '+%s'; } > ${@}.make_tmp; )
	chmod -- 0444 ${@}.make_tmp
	rm -f -- ${@}
	mv -f -- ${@}.make_tmp ${@}


FACTORY_SITE_DEP =

# install scripts from libexec
.for _name in ${SITE_INSTALL_LIBEXEC}
FACTORY_SITE_DEP += ${FACTORY_SITE_BIN}/${_name}

${FACTORY_SITE_BIN}/${_name}: ${OMIR_LIBEXEC}/${_name} ${BUILD_ROOTFS_TMP_DEP}
	install -m 0555 -- ${OMIR_LIBEXEC}/${_name} ${@}
.endfor

# install site config
FACTORY_SITE_DEP += ${FACTORY_SITE_ETC}/conf.sh
${FACTORY_SITE_ETC}/conf.sh: ${OMIR_SITE_CONF_DIR}/config ${BUILD_ROOTFS_TMP_DEP}
	install -m 0400 -- ${OMIR_SITE_CONF_DIR}/config ${@}

# install local site config
FACTORY_SITE_DEP += ${FACTORY_SITE_ETC_CONFD}/99-local.sh
${FACTORY_SITE_ETC_CONFD}/99-local.sh: ${OMIR_SITE_CONF_DIR}/config.local ${BUILD_ROOTFS_TMP_DEP}
	install -m 0400 -- ${OMIR_SITE_CONF_DIR}/config.local ${@}

# create site runtime config
FACTORY_SITE_DEP += ${FACTORY_SITE_ETC}/localconf.sh
${FACTORY_SITE_ETC}/localconf.sh: ${BUILD_ROOTFS_TMP_DEP} FORCE
	rm -f -- ${@}
	( umask 0077; touch -- ${@}; )
	chmod -- 0600 ${@}

${BUILD_ROOTFS_TMP}: \
	${BUILD_ROOTFS_TMP_DEP} \
	${FACTORY_SITE_DEP}


FORCE:

.PHONY: ${PHONY}
