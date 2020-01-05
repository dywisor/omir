S := ${.CURDIR}
X_OMIR_RUN := ${S}/../bin/omir-run

FORCE ?= 0
.if ${FORCE}
DEP_FORCE := FORCE
.else
DEP_FORCE :=
.endif

all: omir.mkenv

MKENV_SRC :=
MKENV_SRC += ${S}/omir.env
MKENV_SRC +!= { find '${S}/omir.env.local' -type f 2>/dev/null || true; }

omir.mkenv: ${MKENV_SRC} ${DEP_FORCE} ${X_OMIR_RUN}
	${X_OMIR_RUN} omir-mkenv > ${@}.make_tmp
	mv -f -- ${@}.make_tmp ${@}

FORCE:

.PHONY: all
