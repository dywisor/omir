S := ${.CURDIR}

all:

init: ${S}/config.local ${S}/config.autoinstall.local ${S}/profiles

${S}/config.local ${S}/config.autoinstall.local:
	touch ${@}

${S}/profiles:
	mkdir -p -- ${@}

.PHONY: all init
