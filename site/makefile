S := ${.CURDIR}
FACTORY_SITE = ${S}/rootfs/FACTORY/site

# FIXME: hardcoded env path
.include "${S}/../etc/omir.mkenv"

X_DISOWN_TAR = ${OMIR_LIBEXEC}/disown-tar

GNU_TAR ?= 0

PHONY += all
all: site.tgz
	${OMIR_BIN_DIR}/omir-run omir-publish-site ./site.tgz

site.tgz: \
	${FACTORY_SITE}/bin/netconf-mac-key \
	${FACTORY_SITE}/etc/conf.sh \
	${FACTORY_SITE}/etc/localconf.sh \
	${FACTORY_SITE}/etc/conf.d/99-local.sh \
	FORCE

.if ${GNU_TAR}
	tar -c -f ${@}.make_tmp.tar --numeric-owner -v --one-file-system -C ${S}/rootfs ./
.else
	tar -c -e -f ${@}.make_tmp.tar -m -N -v -X -C ${S}/rootfs ./
.endif

	${X_DISOWN_TAR} ${@}.make_tmp.tar
	gzip -c < ${@}.make_tmp.tar > ${@}.make_tmp
	rm -f -- ${@}.make_tmp.tar
	mv -f -- ${@}.make_tmp ${@}

${FACTORY_SITE}/bin:
	mkdir -p -- ${@}

${FACTORY_SITE}/bin/netconf-mac-key: ${OMIR_LIBEXEC}/netconf-mac-key
	install -m 0755 -- ${OMIR_LIBEXEC}/netconf-mac-key ${@}

${FACTORY_SITE}/etc:
	mkdir -p -- ${@}

${FACTORY_SITE}/etc/conf.d: ${FACTORY_SITE}/etc
	mkdir -p -- ${@}

${FACTORY_SITE}/etc/conf.sh: ${OMIR_SITE_CONF_DIR}/config ${FACTORY_SITE}/etc
	cp -- ${OMIR_SITE_CONF_DIR}/config ${@}

${FACTORY_SITE}/etc/localconf.sh: ${FACTORY_SITE}/etc
	touch -- ${@}

${FACTORY_SITE}/etc/conf.d/99-local.sh: ${OMIR_SITE_CONF_DIR}/config.local ${FACTORY_SITE}/etc/conf.d
	cp -- ${OMIR_SITE_CONF_DIR}/config.local ${@}

${S}/config.local:
	touch -- ${@}


FORCE:

.PHONY: ${PHONY}
