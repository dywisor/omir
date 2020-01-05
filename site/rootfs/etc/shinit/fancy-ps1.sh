#!/bin/sh
#  do not include this file if your console does not support colors.
#
FANCY_PS1_FALLBACK='\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] '
PS1="${FANCY_PS1_FALLBACK}"

if [ "${__SHINIT_HAVE_PS1_COLORS:-X}" != "y" ]; then
   [ -r /etc/shinit/ps1-colors.sh ] && . /etc/shinit/ps1-colors.sh || :
fi

if [ "${__SHINIT_HAVE_SYSEXITS:-X}" != "y" ]; then
   [ -r /etc/shinit/sysexits.sh ] && . /etc/shinit/sysexits.sh || :
fi


if [ "${__SHINIT_HAVE_PS1_COLORS:-X}" = "y" ]; then

FANCY_PS1_FALLBACK="\
${PS1_COLOR_PURPLE_LIGHT}\\u${PS1_COLOR_WHITE_LIGHT}@\h${COLOR_DEFAULT_PS1} \
${PS1_COLOR_WHITE_LIGHT}\\w${COLOR_DEFAULT_PS1} \
${PS1_COLOR_PURPLE}\\$ \
${COLOR_DEFAULT_PS1}"

__mkps1__() {
   local _who
   local _whorkdir
   local _cmdsep
   local _retps
   local _uid
   local _gid
   local c

   c="${COLOR_DEFAULT_PS1}"
   _workdir="${PS1_COLOR_BLUE_LIGHT}"

   _uid="${UID:-$(id -u 2>/dev/null)}"
   if [ "${_uid:-X}" = "0" ]; then
      _who="${PS1_COLOR_YELLOW_DARK}"'\h'
      _cmdsep="${PS1_COLOR_YELLOW_LIGHT}"
   else
      _who="${PS1_COLOR_PURPLE}${PS1_COLOR_PURPLE_LIGHT}"'\u'"${PS1_COLOR_WHITE_LIGHT}"'@\h'
      _cmdsep="${PS1_COLOR_PURPLE}"
      _workdir="${PS1_COLOR_WHITE_LIGHT}"
   fi

   _who="${_who}${c}"
   _cmdsep="${_cmdsep}\\\$${c}"
   _workdir="${_workdir}\\w${c}"

   ## "hardcoded" colors in $_retps -- could change $COLORVAR to \$COLORVAR
   _retps="\$( \
      _rc=\${?:-0}

      __printrc() {
         printf '%s%s%s ' \
            \"\${1}\" \"[\${2:-\${_rc}}]\" \"${COLOR_DEFAULT_PS1}\"
      }

      __printfail() {
         __printrc \"\${2:-\${PS1_COLOR_RED_LIGHT}}\" \"\${1-}\"
      }

      __retps() {
         local v0

         case \${_rc} in
            (0)   : ;;
            (127) __printrc \"${PS1_COLOR_YELLOW_LIGHT}\" \"CNF\" ;;
            (130) __printrc \"${PS1_COLOR_YELLOW_LIGHT}\" \"^C\" ;;
            (255) __printfail \"DIED\" ;;
            (*)
               if \
                  [ \"\${__SHINIT_HAVE_SYSEXITS:-X}\" = 'y' ] && \
                  shinit_get_sysexit_name \${_rc}
               then
                  __printfail \"\${v0}\"
               else
                  __printfail
               fi
            ;;
         esac
      }

      __retps
   )"

   PS1="${_retps}${_who} ${_workdir} ${_cmdsep} "
   #PS1="(${SHLVL:-_}) ${PS1}"
   return 0
}

__mkps1__ || PS1="${FANCY_PS1_FALLBACK}"
fi
