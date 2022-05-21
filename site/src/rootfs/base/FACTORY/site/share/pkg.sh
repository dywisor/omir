#!/bin/sh

pkg_add() {
    command pkg_add -IU "${@}"
}
