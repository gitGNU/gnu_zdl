#!/bin/bash
#
# ZigzagDownLoader (ZDL)
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see http://www.gnu.org/licenses/. 
# 
# Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (author)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

path_usr="/usr/local/share/zdl"

source $path_usr/libs/core.sh
source $path_usr/libs/utils.sh
source $path_usr/libs/downloader_manager.sh

source $path_usr/ui/widgets.sh
init_colors


function set_mode {
    this_mode="$1"
    printf "%s $s\n" "$this_mode" "$url_in" >>"$path_tmp/irc_this_mode"
}

function get_mode {
    this_mode=$(grep "$url_in$" "$path_tmp/irc_this_mode" | tr -d' ' -f1)
    [ -z "$this_mode" ] && this_mode=stdout
}

function xdcc_cancel {
    [ -z "$ctcp_src" ] &&
	ctcp_src=$(grep "$url_in" "$path_tmp"/irc_xdcc 2>/dev/null |
			  cut -d' ' -f1 | tail -n1)
    irc_ctcp "PRIVMSG $ctcp_src" "XDCC CANCEL"
    irc_ctcp "PRIVMSG $ctcp_src" "XDCC REMOVE"
    kill_url "$url_in" "xfer-pids"
}

function irc_quit {
    [ -f "$path_tmp/${file_in}_stdout.tmp" ] &&
	kill $(head -n1 "$path_tmp/${file_in}_stdout.tmp") 2>/dev/null

    xdcc_cancel
    exec 4>&-
    irc_send "QUIT"
    exec 3>&-

    if [ -f /cygdrive ]
    then
	kill -9 $(children_pids $PID)

    else
	kill -9 $(ps -o pid --no-headers --ppid $PID)
    fi
    kill_url "$url_in" "irc-pids"
}

function irc_send {
    printf "%s\r\n" "$*" >&3
}


function irc_ctcp {
    ## \015 -> \r ; \012 -> \n
    printf "%s :\001%s\001\015\012" "$1" "$2" >&3
}

function get_irc_code {
    local msg="$@"
    local code
    code=$(grep -h "$msg" $path_usr/irc/* | cut -d' ' -f1)

    ## metodo alternativo (rivedere codifica dei file dei messaggi in $path_usr/irc/)
    # [[ "$(cat $path_usr/irc/*)" =~ ([0-9]+)' "'[^\"]*$msg ]] &&
    # 	code=${BASH_REMATCH[1]}

    if [[ "$code" =~ ^[0-9]+$ ]]
    then
	printf "%d" "$code"
	return 0

    else
	return 1
    fi
}

function check_notice {
    notice_883=(
	"Hai già richiesto questo pack"
	"Du hast diese Datei bereits angefordert"
	"You already requested that pack"
	"Vous demandez déjà ce paquet"
    )

    [[ "${notice_883[*]}" =~ "$1" ]] && return 1
    return 0
}

function check_ctcp {
    local irc_code key
    unset ctcp_msg ctcp_src

    ctcp_msg=( $(tr -d "\001\015\012" <<< "$@") )
    ctcp_src=$(grep "$url_in" "$path_tmp"/irc_xdcc 2>/dev/null |
		      cut -d' ' -f1 | tail -n1)
    
    #### da usare e modificare per filtrare problemi da messaggi NOTICE (vedere anche get_irc_code):
    ##    check_notice "${ctcp_msg[*]}" || irc_quit
    ##########
    
    if [ "${ctcp_msg[0]}" == 'DCC' ] &&
	   [ -n "$ctcp_src" ]
    then
	if [ "${ctcp_msg[1]}" == 'ACCEPT' ]
	then
	    print_c 1 "CTCP<< PRIVMSG $ctcp_src :${ctcp_msg[*]}"
	    set_resume
	
	elif [ "${ctcp_msg[1]}" == 'SEND' ]
	then
	    print_c 1 "CTCP<< PRIVMSG $ctcp_src :${ctcp_msg[*]}"
	    
	    ctcp[file]="${ctcp_msg[2]}"
	    ctcp[address]="${ctcp_msg[3]}"
	    ctcp[port]="${ctcp_msg[4]}"
	    ctcp[size]="${ctcp_msg[5]}"
	    ctcp[offset]=$(size_file "${ctcp[file]}")
	    [ -z "${ctcp[offset]}" ] && ctcp[offset]=0

	    if ctcp[address]=$(check_ip_xfer "${ctcp[address]}") &&
		    [[ "${ctcp[port]}" =~ ^[0-9]+$ ]]
	    then
		return 0
	    fi
	fi
    fi
    return 1
}

function set_resume {
    echo "$url_in" >>"$path_tmp"/irc_xdcc_resume
}

function get_resume {
    if [ -f "$path_tmp"/irc_xdcc_resume ]
    then
	grep -P "^$url_in$" "$path_tmp"/irc_xdcc_resume &>/dev/null
    fi
}

function init_resume {
    if [ -f "$path_tmp"/irc_xdcc_resume ]
    then
	sed -r "/^${url_in//\//\\/}$/d" -i "$path_tmp"/irc_xdcc_resume
    fi
}

function check_dcc_resume {
    if [ -f "${ctcp[file]}" ] &&
	   [ -f "${ctcp[file]}.zdl" ] &&
	   [ "$(cat "${ctcp[file]}.zdl")" == "$url_in" ] &&
	   (( ctcp[offset]<ctcp[size] ))
    then

	irc_ctcp "PRIVMSG $ctcp_src" "DCC RESUME ${ctcp[file]} ${ctcp[port]} ${ctcp[offset]}" >&3
	print_c 2 "CTCP>> PRIVMSG $ctcp_src :DCC RESUME ${ctcp[file]} ${ctcp[port]} ${ctcp[offset]}" 

	for ((i=0; i<10; i++))
	do		    
	    if [ -f "$path_tmp"/irc_xdcc_resume ] &&
		   get_resume
	    then
		init_resume
		return 0
	    fi
	    sleep 1
	done
    fi
    return 1
}

function check_ip_xfer {
    local ip_address="$1"

    if [[ "$ip_address" =~ ^[0-9]+$ ]]
    then
	ip_address=$(dotless2ip $ip_address)
	
    elif [[ "$ip_address" =~ ^[0-9a-zA-Z:]+$ ]]
    then
	ip_address="[$ip_address]"
    fi

    if [ -n "$ip_address" ]
    then
	printf "$ip_address"
	return 0

    else
	return 1
    fi
}

function dcc_xfer {
    local offset old_offset pid_cat
    unset resume

    check_dcc_resume && resume=true

    exec 4<>/dev/tcp/${ctcp[address]}/${ctcp[port]} &&
	{
	    if [ -n "$resume" ]
	    then
		unset resume
		cat <&4 >>"$file_in" &
		pid_cat=$!

	    else
		cat <&4 >"$file_in" &
		pid_cat=$!
	    fi
			
	    if [ -n "$pid_cat" ]
	    then
		print_c 1 "Connesso all'indirizzo: ${ctcp[address]}:${ctcp[port]}"
		set_mode "daemon"
		echo "$url_in"  >"$file_in.zdl"
		add_pid_url "$pid_cat" "$url_in" "xfer-pids"
					
		#echo "$pid_cat" >>"$path_tmp/external-dl_pids.txt"
		
		while [ ! -f "$path_tmp/${file_in}_stdout.tmp" ]
		do
		    sleep 0.1
		done
		sed -r "s,____PID_IN____,$pid_cat,g" -i "$path_tmp/${file_in}_stdout.tmp"
	    fi

	    this_mode=daemon
	    while [ ! -f "${file_in}" ]
	    do
		sleep 0.1
	    done
	    
	    while [ "$offset" != "${ctcp[size]}" ]
	    do
		! grep -P "^$url_in$" "$path_tmp/irc-timeout" &>/dev/null &&
		    echo "$url_in" >>"$path_tmp/irc-timeout"
		
		offset=$(size_file "$file_in")
		[ -z "$offset" ] && offset=0
		[ -z "$old_offset" ] && old_offset=$offset
		(( old_offset > offset )) && old_offset=$offset
		
		printf "XDCC %s %s %s XDCC\n" "$offset" "$old_offset" "${ctcp[size]}" >>"$path_tmp/${file_in}_stdout.tmp"

		old_offset=$offset

		## (offset - old_offset /1024) KB/s --> sleep 1 (ogni secondo)
		sleep 1		
	    done

	    if [ "$(size_file "$file_in")" == "${ctcp[size]}" ]
	    then
		rm -f "${file_in}.zdl"
		links_loop - "$url_in"
	    fi

	    irc_quit
	}
}

function irc_client {
    local line user from txt msg to
    
    if exec 3<>/dev/tcp/${irc[host]}/${irc[port]}
    then
	print_c 1 "host: ${irc[host]}\nchan: ${irc[chan]}\nmsg: ${irc[msg]}\nnick: ${irc[nick]}"
	
	irc_send "NICK ${irc[nick]}"
	irc_send "USER ${irc[nick]} localhost ${irc[host]} :${irc[nick]}"

	while read line
	do
	    get_mode
	    line=$(tr -d "\001\015\012" <<< "${line//\*}")

	    if [ "${line:0:1}" == ":" ]
	    then
		from="${line%% *}"
		line="${line#* }"
	    fi
	    from="${from:1}"
	    user=${from%%\!*}
	    txt="${line#*:}"

	    if [[ "$line" =~ (MODE ${irc[nick]}) ]] &&
		   [ -n "${irc[chan]}" ]
	    then
		print_c 1 "$line"
		
		irc_mode=true
	    fi

	    if [ -n "$irc_mode" ]
	    then
		irc_send "JOIN #${irc[chan]}"
	    fi

	    if [[ "$line" =~ (JOIN :) ]] &&
		   [ -n "${irc[msg]}" ]
	    then
		unset irc_mode irc[chan]
		
		print_c 1 "$line"

		read -r to msg <<< "${irc[msg]}"
		echo "$to $url_in" >>"$path_tmp"/irc_xdcc
		xdcc_cancel
		sleep 3
		irc_ctcp "PRIVMSG $to" "$msg"
		print_c 2 "-> $to> $msg"
		
		unset irc[msg]
	    fi

	    ## per ricerche e debug:
	    #print_c 3 "$line"

	    case "${line%% *}" in
		PING)
		    unset chunk
		    if [ -n "$txt" ]
		    then
			chunk=":$txt"

		    else
			chunk="${irc[nick]}"
		    fi
		    ## print_c 2 "PONG $chunk"
		    irc_send "PONG $chunk"
		    ;;
		NOTICE)
		    print_c 4 "$line"
		    
		    # [[ "$line" =~ (Auto-ignore) ]] && {
		    # 	countdown- 90
		    # 	irc_quit
		    # }
		    
		    ;;
		PRIVMSG)
		    ## messaggi dal canale
		    #
		    # ch="${line%% :*}"
		    # ch="${ch#* }"
		    #print_c 0 "<$user@$ch> $txt"

		    if check_ctcp "$txt"
		    then
			file_in="${ctcp[file]}"
			sanitize_file_in
			
			
			url_in_file="/dev/tcp/${ctcp[address]}/${ctcp[port]}"
			echo -e "$file_in\n$url_in_file" >"$path_tmp/${irc[nick]}"
			
			while [ ! -f "$path_tmp/${file_in}_stdout.tmp" ]
			do sleep 0.1
			done
			
			dcc_xfer &
			pid_xfer=$!
			add_pid_url "$pid_xfer" "$url_in" "xfer-pids"
		    fi
		    ;;
		# *)
		#     ## info del canale
		#     print_c 4 "$from >< $line"
		#     ;;
	    esac

	done <&3
	irc_pid=$!
	add_pid_url "$irc_pid" "$url_in" "irc-pids"
	echo "$irc_pid" >>"$path_tmp/external-dl_pids.txt"

	return 0

    else
	return 1
    fi
}

function start_timeout {
    local start=$(date +%s)
    local now
    local diff_now
    
    touch "$path_tmp/irc-timeout"
    sed -r "/^${url_in//\//\\/}$/d" -i "$path_tmp/irc-timeout" 
    
    for i in {0..10}
    do
	now=$(date +%s)
	diff_now=$(( now - start ))

	if grep -P "^$url_in$" "$path_tmp/irc-timeout" &>/dev/null
	then
	    exit

	elif (( diff_now >= 90 ))
	then
	    touch "$path_tmp/${irc[nick]}"
	    sed -r "/^.+ ${url_in//\//\\/}$/d" -i "$path_tmp/irc-timeout" 
	    kill_url "$url_in" 'xfer-pids'
	    kill_url "$url_in" 'irc-pids'
	    exit
	fi
		
	sleep 10
    done &
}


################ main:
PID=$$

set_mode "stdout"
this_tty=$(tty)
path_tmp=".zdl_tmp"

declare -A ctcp
declare -A irc

irc=(
    [host]="$1"
    [port]="$2"
    [chan]="$3"
    [msg]="$4"
    [nick]="$5"
)

url_in="$6"
add_pid_url "$PID" "$url_in" "irc-pids"
start_timeout
init_resume

exec 3>&-

irc_client ||
    {
	print_c 2 "Connessione al server IRC non riuscita"
	exit 1
    }
