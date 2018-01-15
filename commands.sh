#!/usr/bin/env bash
# tbot ~ Subroutines/Commands
# Copyright (c) 2017 David Kim
# This program is licensed under the "MIT License".
# Date of inception: 11/21/17

read nick chan msg      # Assign the 3 arguments to nick, chan and msg.

IFS=''                  # internal field separator; variable which defines the char(s)
                        # used to separate a pattern into tokens for some operations
                        # (i.e. space, tab, newline)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BOT_NICK="$(grep -P "BOT_NICK=.*" ${DIR}/tbot.sh | cut -d '=' -f 2- | tr -d '"')"

if [ "${chan}" = "${BOT_NICK}" ] ; then chan="${nick}" ; fi

###############################################  Subroutines Begin  ###############################################

function has { $(echo "${1}" | grep -P "${2}" > /dev/null) ; }

function say { echo "PRIVMSG ${1} :${2}" ; }

function send {
    while read -r line; do                          # -r flag prevents backslash chars from acting as escape chars.
      currdate=$(date +%s%N)                         # Get the current date in nanoseconds (UNIX/POSIX/epoch time) since 1970-01-01 00:00:00 UTC (UNIX epoch).
      if [ "${prevdate}" -gt "${currdate}" ] ; then  # If 0.5 seconds hasn't elapsed since the last loop iteration, sleep. (i.e. force 0.5 sec send intervals).
        sleep $(bc -l <<< "(${prevdate} - ${currdate}) / ${nanos}")
        currdate=$(date +%s%N)
      fi
      prevdate=${currdate}+${interval}
      echo "-> ${1}"
      echo "${line}" >> ${BOT_NICK}.io
    done <<< "${1}"
}

# This subroutine executes the print script.

function printSubroutine {
    if [ "$#" -eq 0 ] ; then

        say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick})"

    else

        str="$@"
        IFS=' '                          # space is set as delimiter
        read -ra arr <<< "${str}"        # str is read into an array as tokens separated by IFS
        for arg in "${arr[@]}"; do       # access each element of array
            case "${arg}" in
                fab)
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} fab8201bw1)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} fabc8802bw1)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} fab6001bw1)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} fab5517bw1)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} fab5517bw2)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} fab5517clr1)"
                    ;;
                eb)
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} eb325bw1)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} eb325bw2)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} eb325clr1)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} eb420bw1)"
                    say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} eb420clr1)"
                    ;;
                *)
                    if [[ "${arg}" == "fab8201bw1" ]] ||
                       [[ "${arg}" == "fabc8802bw1" ]] ||
                       [[ "${arg}" == "fab6001bw1" ]] ||
                       [[ "${arg}" == "fab5517bw1" ]] ||
                       [[ "${arg}" == "fab5517bw2" ]] ||
                       [[ "${arg}" == "fab5517clr1" ]] ||
                       [[ "${arg}" == "eb325bw1" ]] ||
                       [[ "${arg}" == "eb325bw2" ]] ||
                       [[ "${arg}" == "eb325clr1" ]] ||
                       [[ "${arg}" == "eb420bw1" ]] ||
                       [[ "${arg}" == "eb420clr1" ]] ; then
                        say ${chan} "$(ssh -oConnectTimeout=4 stargate /u/dkim/sandbox/scripts/printer-script.sh -u ${nick} ${arg})"
                    else
                        say ${chan} "${arg} not found"
                    fi
                    ;;
            esac
        done

    fi

}

# This subroutine displays documentation for tbot's functionalities.

function helpSubroutine {
    say ${chan} "Usage: !print -a | !print --all | !print fab eb | !print fab8802bw1 eb325bw1 ... | !print list | tbot: source"
}

# List all the printers.

function listSubroutine {
    for printer in "fab5517bw1    (Intel Lab/FAB MCECS General Lab)" "fab5517bw2    (Intel Lab/FAB MCECS General Lab)" "fab5517clr1   (Intel Lab/FAB MCECS General Lab)" "fab6001bw1    (Tektronix Lab)" "fab8201bw1    (Doghaus)" "fabc8802bw1   (Linux Lab)" "eb325bw1      (MCECS General Lab, West)" "eb325bw2      (MCECS General Lab, East)" "eb325clr1     (MCECS General Lab, West)" "eb420bw1      (MCAE Lab)" "eb420clr1     (MCAE Lab)" ; do
        say ${nick} ${printer}
    done
}

################################################  Subroutines End  ################################################

# Ω≈ç√∫˜µ≤≥÷åß∂ƒ©˙∆˚¬…ææœ∑´®†¥¨ˆøπ“‘¡™£¢∞••¶•ªº–≠«‘“«`
# ─━│┃┄┅┆┇┈┉┊┋┌┍┎┏┐┑┒┓└┕┖┗┘┙┚┛├┝┞┟┠┡┢┣┤┥┦┧┨┩┪┫┬┭┮┯┰┱┲┳┴┵┶┷┸┹┺┻┼┽┾┿╀╁╂╃╄╅╆╇╈╉╊╋╌╍╎╏
# ═║╒╓╔╕╖╗╘╙╚╛╜╝╞╟╠╡╢╣╤╥╦╧╨╩╪╫╬╭╮╯╰╱╲╳╴╵╶╷╸╹╺╻╼╽╾╿

################################################  Commands Begin  #################################################

# Help Command.

if has "${msg}" "^!tbot$" || has "${msg}" "^tbot: help$" || has "${msg}" "^!print$" || has "${msg}" "^tbot: print$" || has "${msg}" "^tbot: print$" ; then
    helpSubroutine

# Alive.

elif has "${msg}" "^!alive(\?)?$" || has "${msg}" "^tbot: alive(\?)?$" ; then
    say ${chan} "running!"

# Source.

elif has "${msg}" "^tbot: source$" ; then
    say ${chan} "Try -> https://github.com/kimdj/tbot -OR- /u/dkim/tbot"

# Print script.

elif has "${msg}" "^!print -a$" || has "${msg}" "^!print --all$" || has "${msg}" "^tbot: print -a$" || has "${msg}" "^tbot: print --all$" ; then
    printSubroutine

elif has "${msg}" "^!print list$" || has "${msg}" "^tbot: print list$" || has "${msg}" "^tbot: print -l$" || has "${msg}" "^tbot: list$" ; then
    listSubroutine

elif has "${msg}" "^!print " || has "${msg}" "^tbot: print " ; then
    arg=$(echo ${msg} | sed -r 's/^!print //')                # cut out the leading part from ${msg}
    arg=$(echo ${arg} | sed -r 's/^tbot: print //')         # cut out the leading part from ${msg}

    printSubroutine ${arg}

# Have tbot send an IRC command to the IRC server.

elif has "${msg}" "^tbot: injectcmd " && [[ ${nick} = "_sharp" ]] ; then
    cmd=$(echo ${msg} | sed -r 's/^tbot: injectcmd //')
    send "${cmd}"

# Have tbot send a message.

elif has "${msg}" "^tbot: sendcmd " && [[ ${nick} = "_sharp" ]] ; then
    buffer=$(echo ${msg} | sed -re 's/^tbot: sendcmd //')
    dest=$(echo ${buffer} | sed -e "s| .*||")
    message=$(echo ${buffer} | cut -d " " -f2-)
    say ${dest} "${message}"

fi

#################################################  Commands End  ##################################################
