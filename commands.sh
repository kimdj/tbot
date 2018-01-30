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

###################################################  Settings  ####################################################

AUTHORIZED='_sharp MattDaemon'

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
    say ${chan} 'usage: !channels [-p | --privmsg] [$NICK]'
}

# This subroutine handles incoming signals from tbot.

function signalSubroutine {
    arg1=$(echo ${msg} | cut -d ' ' -f 1)
    nick_chan=$(echo ${msg} | cut -d ' ' -f 2)
    target=$(echo ${msg} | cut -d ' ' -f 3)

    if [[ ! ${arg1} == '!signal_allchan' ]] ; then
        # if [ $(cat irc-output.log | grep 'No such nick/channel') ] ; then           # Case: $NICK not found
        #     say ${nick_chan} "No such nick/channel"
        # else                                                                        # Case: whois $NICK
        #     nick=$(tac irc-output.log | grep -n '319' | head -n 1 | sed 's|[^#]*tbot \(.*\) :\(.*\)|\1|')
        #     channels="$(tac irc-output.log | grep -n '319' | head -n 1 | sed 's|[^#]*tbot \(.*\) :\(.*\)|\2|')"
        #     # sorted_channels=$(echo "${channels}" | sed -r 's| |\n|g' | sort | tr '\n' ' ' | sed -e 's|\r ||g' | tr 'aeiostl' '43105+|' | tr 'AEIOSTL' '43105+|')
        #     sorted_channels=$(echo "${channels}" | sed -r 's| |\n|g' | sort | tr '\n' ' ' | sed -e 's|\r ||g')
        #     IFS=' ' read -r -a chan_array <<< "$sorted_channels"
        #     for chan in "${chan_array[@]}" ; do
        #         chan="$(echo "${chan}" | sed -r 's|\+||')"
        #         if [[ "${chan,,}" = *a* ]] ; then
        #           converted_chan="$(echo "${chan}" | tr 'a' '@' | tr 'A' '@')"
        #           sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
        #         elif [[ "${chan,,}" = *e* ]] ; then
        #           echo ${chan} >> chan.tmp
        #           converted_chan="$(echo "${chan}" | tr 'e' '3' | tr 'E' '3')"
        #           echo ${converted_chan} >> chan.tmp
        #           sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
        #           echo ${sorted_channels} >> chan.tmp
        #         elif [[ "${chan,,}" = *i* ]] ; then
        #           converted_chan="$(echo "${chan}" | tr 'i' '1' | tr 'I' '1')"
        #           sorted_channels="$(echo "${sorted_channels,,}" | sed -r "s|${chan}|${converted_chan}|")"
        #         elif [[ "${chan,,}" = *o* ]] ; then
        #           converted_chan="$(echo "${chan}" | tr 'o' '0' | tr 'O' '0')"
        #           sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
        #         elif [[ "${chan,,}" = *s* ]] ; then
        #           converted_chan="$(echo "${chan}" | tr 's' '$' | tr 'S' '$')"
        #           sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
        #         elif [[ "${chan,,}" = *t* ]] ; then
        #           converted_chan="$(echo "${chan}" | tr 't' '+' | tr 'T' '+')"
        #           sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
        #         elif [[ "${chan,,}" = *l* ]] ; then
        #           converted_chan="$(echo "${chan}" | tr 'l' '|' | tr 'L' '|')"
        #           sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
        #         elif [[ "${chan}" =~ [^a-zA-Z0-9] ]] ; then
        #           true
        #         else
        #           # ${str:${i}:1}
        #           rand=$[ ${RANDOM} % ${#chan} ]
        #           converted_chan=$(echo "${chan}" | sed s/./\*/${rand})
        #           # index="${#chan}"    # the last index
        #           # converted_chan=$(echo "${chan}" | sed s/./\*/${index})
        #           sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
        #         fi
        #     done
        #     say ${nick_chan} "${nick} is currently in: $(echo "${sorted_channels}")"
        # fi
        if [ $(cat irc-output.log | grep 'is using a secure connection') ] ; then           # Case: $NICK not found
            nick=$(tac irc-output.log | grep -n '319' | head -n 1 | sed 's|[^#]*tbot \(.*\) :\(.*\)|\1|')
            channels="$(tac irc-output.log | grep -n '319' | head -n 1 | sed 's|[^#]*tbot \(.*\) :\(.*\)|\2|')"
            # sorted_channels=$(echo "${channels}" | sed -r 's| |\n|g' | sort | tr '\n' ' ' | sed -e 's|\r ||g' | tr 'aeiostl' '43105+|' | tr 'AEIOSTL' '43105+|')
            sorted_channels=$(echo "${channels}" | sed -r 's| |\n|g' | sort | tr '\n' ' ' | sed -e 's|\r ||g')
            IFS=' ' read -r -a chan_array <<< "$sorted_channels"
            for chan in "${chan_array[@]}" ; do
                chan="$(echo "${chan}" | sed -r 's|\+||')"
                if [[ "${chan,,}" = *a* ]] ; then
                  converted_chan="$(echo "${chan}" | tr 'a' '4' | tr 'A' '4')"
                  sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
                elif [[ "${chan,,}" = *e* ]] ; then
                  echo ${chan} >> chan.tmp
                  converted_chan="$(echo "${chan}" | tr 'e' '3' | tr 'E' '3')"
                  echo ${converted_chan} >> chan.tmp
                  sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
                  echo ${sorted_channels} >> chan.tmp
                elif [[ "${chan,,}" = *i* ]] ; then
                  converted_chan="$(echo "${chan}" | tr 'i' '1' | tr 'I' '1')"
                  sorted_channels="$(echo "${sorted_channels,,}" | sed -r "s|${chan}|${converted_chan}|")"
                elif [[ "${chan,,}" = *o* ]] ; then
                  converted_chan="$(echo "${chan}" | tr 'o' '0' | tr 'O' '0')"
                  sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
                elif [[ "${chan,,}" = *s* ]] ; then
                  converted_chan="$(echo "${chan}" | tr 's' '5' | tr 'S' '5')"
                  sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
                elif [[ "${chan,,}" = *t* ]] ; then
                  converted_chan="$(echo "${chan}" | tr 't' '+' | tr 'T' '+')"
                  sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
                elif [[ "${chan,,}" = *l* ]] ; then
                  converted_chan="$(echo "${chan}" | tr 'l' '|' | tr 'L' '|')"
                  sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
                elif [[ "${chan}" =~ [^a-zA-Z0-9] ]] ; then
                  true
                else
                  # ${str:${i}:1}
                  rand=$[ ${RANDOM} % ${#chan} ]
                  converted_chan=$(echo "${chan}" | sed s/./\*/${rand})
                  # index="${#chan}"    # the last index
                  # converted_chan=$(echo "${chan}" | sed s/./\*/${index})
                  sorted_channels="$(echo "${sorted_channels}" | sed -r "s|${chan}|${converted_chan}|")"
                fi
            done
            say ${nick_chan} "${nick} is currently in: $(echo "${sorted_channels}")"
        else
            say ${nick_chan} "No such nick/channel"
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
    str1='running! '
    str2=$(ps aux | grep ./tbot | head -n 1 | awk '{ print "[%CPU "$3"]", "[%MEM "$4"]", "[START "$9"]", "[TIME "$10"]" }')
    str="${str1}${str2}"
    say ${chan} "${str}"

# Source.

elif has "${msg}" "^tbot: source$" ; then
    say ${chan} "Try -> https://github.com/kimdj/tbot -OR- ${DIR}"

# Get the list of all channels. [A]

elif has "${msg}" "^!chan(nel)?s?$" ; then
    allChannelSubroutine ${chan}

# Get the list of all channels. [A]

elif has "${msg}" "^!chan(nel)?s? -p$" || has "${msg}" "^!chan(nel)?s? --privmsg$" ; then
    allChannelSubroutine ${nick}

# Handle incoming msg from self (tbot => tbot).

elif has "${msg}" "^!signal_allchan " && [[ ${nick} = "tbot" ]] ; then
    signalSubroutine ${msg}

# Get a nick's channels (nick/chan => tbot).

elif has "${msg}" "^!chan(nel)?s? " ; then                    # !channels MattDaemon  -OR-  !channels -p MattDaemon
    target=$(echo ${msg} | sed -r 's/^!chan(nel)?s? //')         # MattDaemon  -OR-  -p MattDaemon
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

elif has "${msg}" "^tbot: injectcmd " && [[ "${AUTHORIZED}" == *"${nick}"* ]] ; then
    cmd=$(echo ${msg} | sed -r 's/^tbot: injectcmd //')
    send "${cmd}"

# Have tbot send a message.

elif has "${msg}" "^tbot: sendcmd " && [[ "${AUTHORIZED}" == *"${nick}"* ]] ; then
    buffer=$(echo ${msg} | sed -re 's/^tbot: sendcmd //')
    dest=$(echo ${buffer} | sed -e "s| .*||")
    message=$(echo ${buffer} | cut -d " " -f2-)
    say ${dest} "${message}"

fi

#################################################  Commands End  ##################################################
