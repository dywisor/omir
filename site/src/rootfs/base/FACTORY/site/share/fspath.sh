#!/bin/sh

fspath_check_abspath() {
    case "${1}" in
        /*) return 0 ;;
    esac

    return 1
}

fspath_check_parent_relpath() {
    case "${1}" in
        '..'|'../'*|*'/..'|*'/../'*) return 0 ;;
    esac

    return 1
}
