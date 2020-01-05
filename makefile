S := ${.CURDIR}
X_OMIR_RUN := ${S}/bin/omir-run

FORCE ?= 0
.if ${FORCE}
DEP_FORCE := FORCE
.else
DEP_FORCE :=
.endif

PHONY =

PHONY += all
all: init

PHONY += mkenv
mkenv: ${S}/etc/omir.mkenv

PHONY += init
init: ${S}/etc/omir.mkenv
	make -C ${S}/bin/
	make -C ${S}/etc/site/ init

PHONY += site
site: ${S}/etc/omir.mkenv
	make -C ${S}/site/


PHONY += autoinstall
autoinstall: ${S}/etc/omir.mkenv
	make -C ${S}/site/autoinstall/ setup

MKENV_SRC :=
MKENV_SRC += ${S}/etc/omir.env
MKENV_SRC +!= { find '${S}/etc/omir.env.local' -type f 2>/dev/null || true; }

${S}/etc/omir.mkenv: ${MKENV_SRC} ${DEP_FORCE} ${X_OMIR_RUN}
	${X_OMIR_RUN} omir-mkenv > ${@}.make_tmp
	mv -f -- ${@}.make_tmp ${@}

FORCE:

.PHONY: ${PHONY}
