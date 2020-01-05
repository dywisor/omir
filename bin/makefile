S := ${.CURDIR}

OMIR_SCRIPTS != find ${S}/../share/scripts -type f -not -name omir-run -print0 | xargs -r -0 -n 1 basename | sort

PROG_NAMES :=
PROG_NAMES += omir-env
PROG_NAMES += omir-mkenv
PROG_NAMES += ${OMIR_SCRIPTS}

PHONY =

PHONY += all
all: prog-links

PROG_LINKS :=
.for _prog in ${OMIR_SCRIPTS}
PROG_LINKS += ${S}/${_prog}
${S}/${_prog}: ${S}/omir-run
	ln -f -s -- omir-run ${@}
.endfor

PHONY += prog-links
prog-links: ${PROG_LINKS}

.PHONY: ${PHONY}
