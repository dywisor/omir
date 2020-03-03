#!/bin/sh
KERN_OSRELEASE="$( sysctl -n kern.osrelease )" || KERN_OSRELEASE=""
