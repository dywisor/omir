#!/bin/sh

# _do_git_init ( dirpath )
_do_git_init() {
	print_action "git init-repo ${1:?}"

	(
		cd "${1}" && \
		\
		{ [ -d ./.git ] || git init; } && \
		\
		{ [ ! -f ./.gitignore ] || git add .gitignore; } && \
		\
		git add . && \
		\
		git commit -m 'init'
	)
}


do_git_init() {
	autodie _do_git_init "${1:?}"
}
