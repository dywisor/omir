#!/bin/sh

fspath_check_parent_relpath() {
    case "${1}" in
        '..'|'../'*|*'/..'|*'/../'*) return 0 ;;
    esac

    return 1
}
