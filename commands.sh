#!/usr/bin/env bash
# tbot ~ Subroutines/Commands
# Copyright (c) 2017 David Kim
# This program is licensed under the "MIT License".
# Date of inception: 1/14/17

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
      if [ "${prevdate}" = "${currdate}" ] ; then  # If 0.5 seconds hasn't elapsed since the last loop iteration, sleep. (i.e. force 0.5 sec send intervals).
        sleep $(bc -l <<< "(${prevdate} - ${currdate}) / ${nanos}")
        currdate=$(date +%s%N)
      fi
      prevdate=${currdate}+${interval}
      echo "-> ${1}"
      echo "${line}" >> ${BOT_NICK}.io
    done <<< "${1}"
}

function allChannelSubroutine {
    send "list"                               # Send an internal IRC command.
                                              # In tbot.sh, the response will be logged in irc-output.log.
    say tbot "!signal_allchan ${1}"        # Send a signal msg to self, which will cause irc-output.log
                                                      # to be parsed for user information and sent back to the user.
}

function channelSubroutine {      # channelSubroutine _sharp MattDaemon  -OR-  channelSubroutine #bingobobby MattDaemon p
    nick_chan=${1}
    target=${2}
    send "whois ${target}"                        # Send an internal IRC command.
                                                # In tbot.sh, the response will be logged in irc-output.log.
    if [ ${3} ] ; then
        say tbot "!signal ${nick_chan} ${target} p"    # Send a signal msg to self, which will cause irc-output.log
                                                # to be parsed for user information and sent back to the user.
    else
        say tbot "!signal ${nick_chan} ${target}"
    fi
}

# This subroutine displays documentation for tbot's functionalities.

function helpSubroutine {
    # say ${chan} "I am a test bot; nothing to see here. Move along."
    say ${chan} 'usage: !channels [-p | --privmsg][$NICK]'
}

# This subroutine handles incoming signals from tbot.

function signalSubroutine {
    arg1=$(echo ${msg} | cut -d ' ' -f 1)
    nick_chan=$(echo ${msg} | cut -d ' ' -f 2)
    target=$(echo ${msg} | cut -d ' ' -f 3)

    if [[ ! ${arg1} == '!signal_allchan' ]] ; then
        if [ $(cat irc-output.log | grep 'No such nick/channel') ] ; then           # Case: $NICK not found
            say ${nick_chan} "No such nick/channel"
        else                                                                        # Case: whois $NICK
            nick=$(tac irc-output.log | grep -n '319' | head -n 1 | sed 's|[^#]*tbot \(.*\) :\(.*\)|\1|')
            channels="$(tac irc-output.log | grep -n '319' | head -n 1 | sed 's|[^#]*tbot \(.*\) :\(.*\)|\2|')"
            say ${nick_chan} "${nick} is currently in: ${channels}"
        fi
    else                                                                            # Case: list all channels
        channels="$(cat irc-output.log | grep 322 | sed 's|^==>.*322 tbot ||g' | sed 's| :.*||g' | tr '\n' ' ' | sed 's| \([0-9]*\) |\(\1\) |g' | fold -s -w448)"

        while read -r line; do
            say ${nick_chan} "${line}"
        done <<< "${channels}"
    fi

    rm irc-output.log
}

################################################  Subroutines End  ################################################

# Ω≈ç√∫˜µ≤≥÷åß∂ƒ©˙∆˚¬…ææœ∑´®†¥¨ˆøπ“‘¡™£¢∞••¶•ªº–≠«‘“«`
# ─━│┃┄┅┆┇┈┉┊┋┌┍┎┏┐┑┒┓└┕┖┗┘┙┚┛├┝┞┟┠┡┢┣┤┥┦┧┨┩┪┫┬┭┮┯┰┱┲┳┴┵┶┷┸┹┺┻┼┽┾┿╀╁╂╃╄╅╆╇╈╉╊╋╌╍╎╏
# ═║╒╓╔╕╖╗╘╙╚╛╜╝╞╟╠╡╢╣╤╥╦╧╨╩╪╫╬╭╮╯╰╱╲╳╴╵╶╷╸╹╺╻╼╽╾╿

################################################  Commands Begin  #################################################

# Help Command.

if has "${msg}" "^!tbot$" || has "${msg}" "^tbot: help$" ; then
    helpSubroutine

# Alive.

elif has "${msg}" "^!alive(\?)?$" || has "${msg}" "^tbot: alive(\?)?$" ; then
    say ${chan} "running!"

# Source.

elif has "${msg}" "^tbot: source$" ; then
    say ${chan} "Try -> https://github.com/kimdj/tbot -OR- /u/dkim/tbot"

# Get the list of all channels. [A]

elif has "${msg}" "^!channels$" ; then
    allChannelSubroutine ${chan}

# Get the list of all channels. [A]

elif has "${msg}" "^!channels -p$" || has "${msg}" "^!channels --privmsg$" ; then
    allChannelSubroutine ${nick}

# Handle incoming msg from self (tbot => tbot).

elif has "${msg}" "^!signal_allchan " && [[ ${nick} = "tbot" ]] ; then
    signalSubroutine ${msg}

# Get a nick's channels (nick/chan => tbot).

elif has "${msg}" "^!channels " ; then                    # !channels MattDaemon  -OR-  !channels -p MattDaemon
    target=$(echo ${msg} | sed -r 's/^!channels //')         # MattDaemon  -OR-  -p MattDaemon
    if [[ ${target} == *-p* ]] || [[ ${target} == *--privmsg* ]] ; then
        target=$(echo ${target} | sed -r 's/ *--privmsg//' | sed -r 's/ *-p//' | xargs)
        channelSubroutine ${nick} ${target} 'p'              # channelSubroutine _sharp MattDaemon p
    else
        channelSubroutine ${chan} ${target}                  # channelSubroutine #bingobobby MattDaemon
    fi

# Handle incoming msg from self (tbot => tbot).

elif has "${msg}" "^!signal " && [[ ${nick} = "tbot" ]] ; then
    signalSubroutine ${msg}

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
