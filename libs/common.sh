#!/bin/bash -i
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

function check_pid {
    ck_pid=$1
    if [ ! -z "$ck_pid" ]
    then
	if [[ ! -z $(ps ax | grep -P '^[\ a-zA-Z]*'$ck_pid 2>/dev/null) ]]
	then
	    return 0 
	else
	    return 1
	fi
    fi

}

function size_file {
    echo "$(stat -c '%s' "$1")"
}


function check_instance_daemon {
    [ -d /cygdrive ] && cyg_condition='&& ($2 == 1)'
    if daemon_pid="$(ps ax | awk -f "$path_usr/libs/common.awk" -e "BEGIN{result = 1} /bash/ $cyg_condition {check_instance_daemon()} END {exit result}")"
    then
	return 1
    else
    	return 0
    fi
}

function check_instance_prog {
    if [ -f "$path_tmp/pid.zdl" ]
    then
	test_pid="$(cat "$path_tmp/pid.zdl" 2>/dev/null)"
	if check_pid "$test_pid" && [ "$pid_prog" != "$test_pid" ]
	then
	    pid=$test_pid
	    if [ -e "/cygdrive" ]
	    then
		tty="$(cat /proc/$test_pid/ctty)"
	    else
		tty="$(ps ax |grep -P '^[\ ]*'$pid)"
		tty="${tty## }"
		tty="/dev/$(cut -d ' ' -f 2 <<< "${tty## }")"
	    fi
	    return 1
	else
	    return 0
	fi
    fi
}

function scrape_url {
    url_page="$1"
    if url? "$url_page"
    then
	print_c 1 "[--scrape-url] connessione in corso: $url_page"
	wget -q "$url_page" -O - |                                             \
	    tr "\t\r\n'" '   "' |                                              \
	    grep -i -o '<a[^>]\+href[ ]*=[ \t]*"\(ht\|f\)tps\?:[^"]\+"' |      \
	    sed -e 's/^.*"\([^"]\+\)".*$/\1/g' |                               \
	    grep "$url_regex" |                                                \
	    sort | uniq                                                        \
		       >> "$path_tmp/links_loop.txt" &&                                   \
	    print_c 1 "Estrazione URL dalla pagina web $url_page completata"
	start_file="$path_tmp/links_loop.txt"
    fi
}

function redirect_links {
    header_box "Links da processare"
    links="${links##\\n}"
    echo -e "${links//'\n'/\n\n}\n"
    separator-
    print_c 1 "\nLa gestione dei download è inoltrata a un'altra istanza attiva di $PROG (pid $test_pid), nel seguente terminale: $tty"
    [ ! -z "$xterm_stop" ] && xterm_stop
    exit 1
}

function is_rtmp {
    for h in ${rtmp[*]}; do
	[ "$1" != "${1//$h}" ] && return 1
    done
    return 0
}

function sanitize_file_in {
    file_in="${file_in// /_}"
    file_in="${file_in//\'/_}"
    file_in="${file_in//[\[\]\(\)]/-}"
    file_in="${file_in##*/}"
    file_in="$(htmldecode "$file_in")"
    file_in="${file_in//'&'/and}"
    file_in="${file_in//'#'}"
    file_in="${file_in//';'}"
    file_in="${file_in::240}"
    file_in=$(sed -r 's|^[^0-9a-zA-Z\[\]()]*([0-9a-zA-Z\[\]()]+)[^0-9a-zA-Z\[\]()]*$|\1|g' <<< "$file_in")
}

###### funzioni usate solo dagli script esterni per rigenerare la documentazione (zdl non le usa):
##
function zdl-ext {
    ## $1 == (download|streaming)
    while read line
    do
	test_ext_type=$(grep "## zdl-extension types:" < $path_usr/extensions/$line 2>/dev/null |grep "$1")
	if [ ! -z "$test_ext_type" ]
	then
	    grep '## zdl-extension name:' < $path_usr/extensions/$line 2>/dev/null | sed -r 's|.*(## zdl-extension name: )(.+)|\2|g' |sed -r 's|\, |\n|g'
	fi
    done <<< "$(ls -1 $path_usr/extensions/)"
}
function zdl-ext-sorted {
    local extensions
    while read line
    do
	extensions="${extensions}$line\n"
    done <<< "$(zdl-ext $1)"
    extensions=${extensions%\\n}

    echo $(sed -r 's|$|, |g' <<< "$(echo -e "${extensions}" |sort)") |sed -r 's|(.+)\,$|\1|g'
}
##
####################


function line_file { 	## usage with op=+|- : links_loop $op $link
    op="$1"                    ## operator
    item="$2"                  ## line
    file_target="$3"           ## file target
    rewriting="$3-rewriting"   ## to linearize parallel rewriting file target
    if [ "$op" != "in" ]; then
	if [ -f "$rewriting" ];then
	    while [ -f "$rewriting" ]; do
		sleeping 0.1
	    done
	fi
	touch "$rewriting"
    fi

    if [ ! -z "$item" ]; then
	case $op in
	    +)
		if ! line_file "in" "$item" "$file_target"
		then
		    echo "$item" >> "$file_target"
		fi
		rm -f "$rewriting"
		;;
	    -)
		if [ -f "$file_target" ]
		then
		    sed -e "s|^$item$||g" \
			-e '/^$/d' -i "$file_target"

		    if (( $(wc -l < "$file_target") == 0 ))
		    then
			rm "$file_target"
		    fi
		fi
		rm -f "$rewriting"
		;;
	    in) 
		if [ -f "$file_target" ]
		then
		    if [[ "$(cat "$file_target" 2>/dev/null)" =~ "$item" ]]
		    then 
			return 0
		    fi
		fi
		return 1
		;;
	esac
    fi
}

function trap_sigint {
    trap "trap SIGINT; stty echo ; echo; kill -9 $loops_pid &>/dev/null; exit" SIGINT
}

function clean_countdown {
    rm -f "$path_tmp"/.wise-code
}

function bindings {
    trap_sigint
    check_instance_prog
    bind -x "\"\ei\":\"change_mode interactive\"" 2>/dev/null
    bind -x "\"\ee\":\"change_mode editor\"" 2>/dev/null
    bind -x "\"\eq\":\"clean_countdown; kill -1 $loops_pid $pid_prog\"" &>/dev/null
    bind -x "\"\ek\":\"clean_countdown; kill_downloads; kill -9 $loops_pid $pid_prog $pid\"" &>/dev/null
}

function link_parser {
    local _domain userpass ext item param
    param="$1"

    # extract the protocol
    parser_proto=$(echo "$param" | grep '://' | sed -r 's,^([^:\/]+\:\/\/).+,\1,g' 2>/dev/null)

    # remove the protocol
    parser_url="${param#$parser_proto}"

    # extract domain
    _domain="${parser_url#*'@'}"
    _domain="${_domain%%\/*}"
    [ "${_domain}" != "${_domain#*:}" ] && parser_port="${_domain#*:}"
    _domain="${_domain%:*}"

    if [ ! -z "${_domain//[0-9.]}" ]; then
	[ "${_domain}" != "${_domain%'.'*}" ] && parser_domain="${_domain}"
    else 
	parser_ip="${_domain}"
    fi

    # extract the user and password (if any)
    userpass=`echo "$parser_url" | grep @ | cut -d@ -f1`
    parser_pass=`echo "$userpass" | grep : | cut -d: -f2`
    if [ -n "$pass" ]; then
	parser_user=`echo $userpass | grep : | cut -d: -f1 `
    else
	parser_user="$userpass"
    fi

    # extract the path (if any)
    parser_path="$(echo $parser_url | grep / | cut -d/ -f2-)"

    if [ "${parser_proto}" != "${parser_proto//ftp}" ] || [ "${parser_proto}" != "${parser_proto//http}" ]; then
	if ( [ ! -z "$parser_domain" ] || [ ! -z "$parser_ip" ] ) && [ ! -z "$parser_path" ]; then
	    return 0
	fi
    fi
    return 1
}

function url? {
    if [[ "$(grep -P '\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))' <<< "$1")" ]]
    then
	return 0
    else
	return 1
    fi
}

function clean_file { ## URL, nello stesso ordine, senza righe vuote o ripetizioni
    if [ -f "$1" ]
    then
	local file_to_clean="$1"

	## impedire scrittura non-lineare da più istanze di ZDL
	if [ -f "$path_tmp/rewriting" ]
	then
	    while [ -f "$path_tmp/rewriting" ]; do
		sleeping 0.1
	    done
	fi
	touch "$path_tmp/rewriting"

	local lines=$(
	    awk '!($0 in a){a[$0]; print}' <<< "$(grep -P '\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))' "$file_to_clean")"
	)
	if [ ! -z "$lines" ]
	then
	    echo -e "$lines" > "$file_to_clean"
	else
	    rm -f "$file_to_clean"
	fi

	rm -f "$path_tmp/rewriting"
    fi
}

