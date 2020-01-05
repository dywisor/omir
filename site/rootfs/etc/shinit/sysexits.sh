#!/bin/sh

shinit_static_get_sysexit_name() {
   v0=""

   case "${1}" in
      (64) v0='EX_USAGE' ;;
      (*) return 1 ;;
   esac

   return 0
}


shinit_eval_get_sysexit_name() {
   local fp
   local code

   fp='/usr/include/sysexits.h'

   if \
      [ -r "${fp}" ] && \
      code="$( < "${fp}" sed -nr -e 's,^\#define[[:space:]]+(EX_[A-Z]+)[[:space:]]+([0-9]+)([[:space:]]+.*)?$,(\2) v0="\1" ;;,p' )" && \
      [ -n "${code}" ]
   then
eval "shinit_get_sysexit_name() {
   v0=""

   case \"\${1}\" in
      ${code}
      (*) return 1 ;;
   esac

   return 0
}"
   else
      eval "shinit_get_sysexit_name() { shinit_static_get_sysexit_name \"\${@}\"; }"
   fi
}
	 

unset -f shinit_get_sysexit_name
shinit_eval_get_sysexit_name || :

__SHINIT_HAVE_SYSEXITS=y
