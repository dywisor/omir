S := ${.CURDIR}
SRC := ${S}/src

# FIXME: hardcoded env path
.include "${S}/../../etc/omir.mkenv"

GNU ?= 0
USE_MKINDEX_C ?= ${GNU}

CC ?= cc
CPPFLAGS ?=
CFLAGS ?= -O2 -Wall -Wextra

PHONY = all
all: ${S}/omir-mkindex

.if ${USE_MKINDEX_C}
${S}/omir-mkindex: ${SRC}/omir-mkindex.c
	${CC} -std=c99 ${CPPFLAGS} ${CFLAGS} -o ${@} ${.ALLSRC}

.else
${S}/omir-mkindex: ${SRC}/omir-mkindex.sh
	install -m 0755 -- ${.ALLSRC} ${@}

.endif

FORCE:

.PHONY: ${PHONY}
