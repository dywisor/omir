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

fspath_check_safe_relpath() {
    if fspath_check_abspath "${1}"; then
        return 1
    elif fspath_check_parent_relpath "${1}"; then
        return 1
    else
        return 0
    fi
}
