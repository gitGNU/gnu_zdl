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
    if [[ "$ck_pid" =~ ^[0-9]+$ ]] &&
	   ps ax | grep -P '^[^0-9]*'$ck_pid'[^0-9]+' &>/dev/null
    then
	return 0 
    fi
    return 1
}

function check_instance_daemon {
    unset daemon_pid

    ## ritardare il controllo
    while (( $(date +%s) < $(cat "$path_tmp"/.date_daemon 2>/dev/null)+2 ))
    do
	echo -ne "$(sprint_c 2 "Avvio modalità demone...")\r"
	sleep 0.1
    done
    
    [ -d /cygdrive ] &&
	cyg_condition='&& ($2 == 1)'

    daemon_pid=$(ps ax | awk -f "$path_usr/libs/common.awk" \
			     -e "BEGIN{pwd=\"$PWD\"} /bash/ $cyg_condition {check_instance_daemon()}")
    
    if [[ "$daemon_pid" =~ ^([0-9]+)$ ]]
    then
	return 0

    else
	unset daemon_pid
	return 1
    fi
}

function check_instance_server {
    local socket_port="$1"
    
    ps ax | while read -a line
	    do
		if [[ "${line[0]}" =~ ^([0-9]+)$ ]] &&
		       grep -P "socat.+LISTEN:${socket_port}.+zdl_server\.sh" /proc/${line[0]}/cmdline &>/dev/null
		then
		    echo ${line[0]}
		    return 0
		fi
	    done
    return 1
}

function check_instance_prog {
    local test_pid
    
    if [ -f "$path_tmp/.pid.zdl" ]
    then
	test_pid="$(cat "$path_tmp/.pid.zdl" 2>/dev/null)"
	if check_pid "$test_pid" && [ "$pid_prog" != "$test_pid" ]
	then
	    that_pid=$test_pid
	    that_tty=$(tty_pid "$test_pid")
	    return 0
	fi
    fi
    return 1
}

function check_port {
    ## return 0 se la porta è libera (ancora chiusa)
    local port=$1
    local result
    
    if command -v nmap &>/dev/null
    then
	nmap -p $port localhost |grep closed -q &&
	    return 0

    elif command -v nc &>/dev/null
    then
	nc -z localhost $port ||
	    return 0

    elif command -v netstat &>/dev/null
    then
	result=$(netstat -nlp 2>&1 |
		     awk "/tcp/{if (\$4 ~ /:$port\$/) print \$4}")

	[ -z "$result" ] && return 0
    fi
    return 1
}

function run_web_client {
    local port=8080

    while ! check_port $port
    do
	((port++))
	sleep 0.1
    done

    zdl --socket=$port -d

    while check_port $port
    do
	sleep 0.1
    done
    x_www_browser localhost:$port &
}

function x_www_browser {
    if command -v x-www-browser &>/dev/null
    then
	x-www-browser "$@" &>/dev/null &&
	    return 0

    else
	print_c 3 "Non è stato impostato alcun browser predefinito.\nAvvia un browser all'indirizzo: $@"
	return 1	
    fi
}

###### funzioni usate solo dagli script esterni per rigenerare la documentazione (zdl non le usa):
##

function rm_deadlinks {
    local dir
    dir="$1"
    if [ -n "$dir" ]
    then
	sudo find -L "$dir" -type l -exec rm -v {} + 2>/dev/null
    fi
}

function zdl-ext {
    ## $1 == (download|streaming|...)
    #rm_deadlinks "$path_usr/extensions/$line"
    local path_git="$HOME"/zdl-git/code
    
    while read line
    do
	test_ext_type=$(grep "## zdl-extension types:" < $path_git/extensions/$line 2>/dev/null |
			       grep "$1")
	
	if [ -n "$test_ext_type" ]
	then
	    grep '## zdl-extension name:' < "$path_git/extensions/$line" 2>/dev/null |
		sed -r 's|.*(## zdl-extension name: )(.+)|\2|g' |
		sed -r 's|\, |\n|g'
	fi
    done <<< "$(ls -1 $path_git/extensions/)"
}

function zdl-ext-sorted {
    local extensions
    while read line
    do
	extensions="${extensions}$line\n"
    done <<< "$(zdl-ext $1)"
    extensions=${extensions%\\n}

    echo $(sed -r 's|$|, |g' <<< "$(echo -e "${extensions}" |sort)") |
	sed -r 's|(.+)\,$|\1|g'
}
##
####################


function set_line_in_file { 	#### usage: 
    local op="$1"                     ## operator (+|-|in)
    local item="$2"                   ## string
    local file_target="$3"            ## file target
    local rewriting="$3-rewriting"    #### <- to linearize parallel rewriting file target

    if [ "$op" != "in" ]
    then
	if [ -f "$rewriting" ]
	then
	    while [ -f "$rewriting" ]
	    do
		sleep 0.1
	    done
	fi
	touch "$rewriting"
    fi

    if [ -n "$item" ]
    then
	case $op in
	    +)
		if ! set_line_in_file "in" "$item" "$file_target"
		then
		    echo "$item" >> "$file_target"
		fi
		rm -f "$rewriting"
		;;
	    -)
		if [ -f "$file_target" ]
		then
		    item="${item//'*'/\\*}"
		    item="${item//','/\\,}"
		    
		    sed -e "s,^${item}$,,g" \
			-e '/^$/d' -i "$file_target" 2>/dev/null

		    if (( $(wc -l < "$file_target") == 0 ))
		    then
			rm "$file_target"
		    fi
		fi
		rm -f "$rewriting"
		;;
	    'in') 
		if [ -s "$file_target" ] &&
		       grep "^${item}$" "$file_target" &>/dev/null
		then 
		    return 0
		fi
		return 1
		;;
	esac
    fi
}

function check_link {
    local url_test="$1"

    if url "$url_test" &&
	    grep "^${url_test}$" "$path_tmp/links_loop.txt" &>/dev/null
    then
	return 0
    fi
    return 1
}

function set_link {
    local url_test="${2}"
    if [ "$1" == "+" ] &&
	   ! url "$url_test"
    then
	_log 12 "$url_test"
	set_link - "$url_test"

    else
	[ "$1" == "+" ] &&
	    url_test="${url_test%'#20\x'}"

	set_line_in_file "$1" "$url_test" "$path_tmp/links_loop.txt"
    fi
}


function clean_file { ## URL, nello stesso ordine, senza righe vuote o ripetizioni
    if [ -f "$1" ]
    then
	local file_to_clean="$1"

	## impedire scrittura non-lineare da più istanze di ZDL
	if [ -f "$path_tmp/rewriting" ]
	then
	    while [ -f "$path_tmp/rewriting" ]
	    do
		sleeping 0.1
	    done
	fi
	touch "${file_to_clean}-rewriting"

	local lines=$(
	    awk '!($0 in a){a[$0]; print}' < "$file_to_clean"
	)
	if [ -n "$lines" ]
	then
	    grep_urls "$lines" > "$file_to_clean"
	else
	    rm -f "$file_to_clean"
	fi

	rm -f "${file_to_clean}-rewriting"
    fi
}

function check_start_file {
    if [ -f "${start_file}-rewriting" ] ||
	   [ -f "${start_file}" ]
    then
	return 0

    else
	return 1
    fi
    
}

function pipe_files { 
    [ -z "$print_out" ] && [ -z "${pipe_out[*]}" ] && return

    if [ -f "$path_tmp"/pipe_files.txt ]
    then
	if [ -f "$path_tmp"/pid_pipe ]
	then
	    pid_pipe_out=$(cat "$path_tmp"/pid_pipe)
	else
	    pid_pipe_out=NULL
	fi
	
	if [ -n "$print_out" ] && [ -f "$path_tmp"/pipe_files.txt ]
	then
	    while read line
	    do
		if [ -z "$(grep -P '^$line$' $print_out)" ]
		then
		    echo "$line" >> "$print_out"
		fi
		
	    done < "$path_tmp"/pipe_files.txt 
	    
	elif [ -z "${pipe_out[*]}" ] || check_pid $pid_pipe_out 
	then
	    return

	else
	    outfiles=( $(cat "$path_tmp"/pipe_files.txt) )

	    if [ -n "${outfiles[*]}" ]
	    then
		nohup "${pipe_out[@]}" "${outfiles[@]}" 2>/dev/null &
		pid_pipe_out="$!"
		echo $pid_pipe_out > "$path_tmp"/pid_pipe
		pipe_done=1
	    fi
	fi
    fi
}

function pid_list_for_prog {
    cmd="$1"
    
    if [ -n "$cmd" ]
    then
	if [ -e /cygdrive ]
	then
	    ps ax | grep $cmd | awk '{print $1}'
	else
	    _text="$(ps -aj $pid_prog | grep -P "[0-9]+ $cmd")"
	    cut -d ' ' -f1 <<<  "${_text## }"
	fi
    fi
}

function ffmpeg_stdout {
    ppid=$2
    cpid=$(children_pids $ppid)
    trap_sigint $cpid $ppid
    
    pattern='frame.+size.+'

    [[ "$format" =~ (mp3|flac) ]] &&
	pattern='size.+kbits/s'
    
    while check_pid $cpid
    do
	tail $1-*.log 2>/dev/null             |
	    grep -oP "$pattern"               |
	    sed -r "s|^(.+)$|\1                                         \n|g" |
	    tr '\n' '\r'
	sleep 1
    done
}

# function children_pids {
#     local children
#     children=$(ps -o pid --no-headers --ppid $$1)

#     if [ -n "$children" ]
#     then
# 	printf "%s" "$children"
# 	return 0

#     else
# 	return 1
#     fi
# }

function children_pids {
    local result ppid 
    ppid=$1
    proc_pids=(
	$(ls -1 /proc |grep -oP '^[0-9]+$')
    )

    result=1
    
    for proc_pid in ${proc_pids[@]}
    do
	if [ -e /proc/$proc_pid/status ] &&
	       [ "$(awk '/PPid/{print $2}' /proc/$proc_pid/status)" == "${ppid}" ]
	then
	    echo $proc_pid
	    result=0
	fi
    done
    return $result
}


function set_downloader {
    if command -v ${_downloader[$1]} &>/dev/null
    then
	downloader_in=$1
	echo $downloader_in > "$path_tmp/downloader"

    else
	return 1
    fi
}


function tty_pid {
    local that_tty pid
    pid="$1"
    
    if [ -e "/cygdrive" ]
    then
	that_tty="$(cat /proc/$pid/ctty)"
    else
	that_tty=$(ps ax |grep -P '^[\ ]*'$pid)
	that_tty="${that_tty## }"
	that_tty="/dev/"$(cut -d ' ' -f 2 <<< "${that_tty## }")
    fi
    echo "$that_tty"
}

function grep_tty {
    ## regex -> tty

    local matched_tty

    ## gnu/linux
    if [ -z "$2" ]
    then
	matched_tty=$(ps ax | grep -v grep | grep -P "$1")

    else
	matched_tty=$(grep -P "$1" <<< "$2")
    fi
    matched_tty="${matched_tty## }"
    matched_tty=$(cut -d ' ' -f 2 <<< "${matched_tty## }")

    if [ -n "$matched_tty" ]
    then
	echo "/dev/$matched_tty"
	return 0

    else
	return 1
    fi
}

function grep_pid {
    ## regex -> pid
    local matched_pid

    ## gnu/linux
    if [ -z "$2" ]
    then
	matched_pid=$(ps ax | grep -v grep | grep -P "$1")

    else
	matched_pid=$(grep -P "$1" <<< "$2")
    fi

    matched_pid="${matched_pid## }"
    matched_pid="/dev/"$(cut -d ' ' -f 2 <<< "${matched_pid## }")

    if [[ "$matched_pid" =~ ^([0-9]+)$ ]]
    then
	echo "$matched_pid"
	return 0

    else
	return 1
    fi
}


function start_mode_in_tty {
    local this_mode this_tty
    this_mode="$1"
    this_tty="$2"

    if [ "$this_mode" != daemon ]
    then
	if [ -f "$path_tmp/.stop_stdout" ] &&
	       check_instance_prog
	then
	    that_tty=$(cut -d' ' -f1 "$path_tmp/.stop_stdout")

	else
	    that_tty="$this_tty"
	fi
	    
	if [ "$this_tty" == "$that_tty" ]
	then
	    echo "$that_tty $this_mode" >"$path_tmp/.stop_stdout"
	fi
    fi
}


## check: può stampare in stdout? (params: 1-modalità e 2-terminale)
function show_mode_in_tty {
    ## livelli: priorità di stampa in ordine crescente
    ## per sistema "on the fly" valido solo su gnu/linux
    ##
    # declare -A _mode
    # _mode['daemon']=0
    # _mode['stdout']=1
    # _mode['lite']=2
    # _mode['interactive']=3
    # _mode['configure']=4
    # _mode['list']=5
    # _mode['info']=6
    # _mode['editor']=7

    local this_mode this_tty B1 B2 pattern psax
    this_mode="$1"
    this_tty="$2"

    if  [ -f "$path_tmp/.stop_stdout" ]
    then
	that_tty=$(cut -d' ' -f1 "$path_tmp/.stop_stdout")
	that_mode=$(cut -d' ' -f2 "$path_tmp/.stop_stdout")
    fi

    [ "$this_tty" != "$that_tty" ] &&
	return 0
       

    if [ "$this_mode" == "daemon" ]
    then
	return 1

    elif [ -f "$path_tmp/.stop_stdout" ] &&
	     [ "$this_tty $this_mode" != "$that_tty $that_mode" ]
    then
	return 1

	###########################################
	## sistema "on the fly" valido solo su gnu/linux (a causa dell'output di `ps ax`, incompleto su cygwin
	##
	# else
	# 	level="${_mode[$this_mode]}"
	# 	pattern="${this_tty##'/dev/'}"
	# 	pattern="${pattern//\//\\/}\s+[^ ]+\s+[^ ]+\s+(?!grep).+"
	# 	B1='('
	
	# 	((level<2)) && {
	# 	    pattern+="${B1}zdl\s(-l|--lite)|" 
	# 	    unset B1
	# 	}
	# 	((level<3)) && {
	# 	    pattern+="${B1}zdl\s--interactive|"
	# 	    unset B1
	# 	}
	# 	((level<4)) && {
	# 	    pattern+="${B1}zdl\s--configure|"
	# 	    unset B1
	# 	}
	# 	((level<5)) && {
	# 	    pattern+="${B1}zdl\s--list-extensions|" 
	# 	    unset B1
	# 	}
	# 	((level<6)) && {
	# 	    pattern+="${B1}p*info.+zdl|" 
	# 	    unset B1
	# 	}
	# 	((level<7)) && {
	# 	    pattern+="${B1}\/links_loop\.txt|" 
	# 	    unset B1
	# 	}

	# 	[ -z "$B1" ] &&
	# 	    B2=')'
	
	# 	pattern=${pattern%'|'}"$B2"

	# 	ps ax | grep -P "$pattern" &>/dev/null &&
	# 	    return 1
    fi
    return 0
}

function zero_dl {
    [ "$1" == show ] &&
	unset hide_zero
    
    max_dl=$(cat "$path_tmp"/max-dl)

    if [ -n "$max_dl" ] && ((max_dl < 1))
    then
	if [ -z "$hide_zero" ]
	then
	    print_c 3 "$PROG in pausa"
	    print_c 4 "Per processare nuovi link, scarica un numero di file maggiore di zero:"
	    print_c 0 "usa l'opzione [-m|--multi [NUMERO]] oppure entra nella modalità interattiva e digita un numero da 1 a 9"
	    hide_zero=true
	fi
	return 0

    else
	unset hide_zero
	return 1
    fi
}

function input_xdcc {
    declare -A out_msg=(
	[host]="Indirizzo dell'host irc (il protocollo 'irc://' non è necessario):"
	[chan]="Canale (il cancelletto '#' non è necessario):"
	[msg]="Messaggio privato (il comando '/msg' non è necessario):"
    )
    
    header_box "Acquisizione dati mancanti per XDCC (inserisci 'quit' per annullare)"
    for index in host chan msg
    do
	while [ -z "${irc[$index]}" ]
	do
	    print_c 2 "${out_msg[$index]}"

	    cursor on
	    read -e irc[$index]
	    cursor off
	    
	    irc[$index]=$(head -n1 <<< "${irc[$index]}")
	    echo 
	    
	    if [ "$index" == host ]
	    then
		test_chan="${irc[$index]#'irc://'}"
		if [[ "${test_chan}" =~ ^.+\/([^/]+) ]] &&
		       [ -z "${irc[chan]}" ]
		then
		    irc[chan]=${BASH_REMATCH[1]}
		fi
	    fi
	    
	    if [ "${irc[$index]}" == quit ]
	    then
		unset irc
		return 1
	    fi
	done
    done
    return 0
}

function redirect {
    url_input="$1"
    sleeping 1

    if ! url "$url_input" 
    then
	return 1
    fi
    
    k=$(date +"%s")
    s=0
    while true
    do
    	if ! check_pid "$wpid" ||
		[ "$s" == 0 ] ||
		[ "$s" == "$max_waiting" ] ||
		[ "$s" == $(( $max_waiting*2 )) ]
    	then 
    	    kill -9 "$wpid" &>/dev/null
    	    rm -f "$path_tmp/redirect"
    	    wget -t 1 -T $max_waiting                       \
    		 --user-agent="$user_agent"                 \
    		 --no-check-certificate                     \
    		 --load-cookies="$path_tmp"/cookies.zdl     \
    		 --post-data="${post_data}"                 \
    		 "$url_input"                               \
    		 -SO /dev/null -o "$path_tmp/redirect" &
    	    wpid=$!
	    echo "$wpid" >> "$path_tmp"/pid_redirects
    	fi
	
    	if [ -f "$path_tmp/redirect" ]
	then
	    url_redirect="$(grep 'Location:' "$path_tmp/redirect" 2>/dev/null |head -n1)"
	    url_redirect="${url_redirect#*'Location: '}"
	    #url_redirect="$(sanitize_url "$url_redirect")"
	fi

	if url "$url_redirect" &&
		[ "$url_redirect" != "https://tusfiles.net" ] # || ! check_pid "$wpid"
    	then 
    	    kill -9 $(cat "$path_tmp"/pid_redirects) &>/dev/null
    	    break

	elif (( $s>90 ))
    	then
    	    kill -9 $(cat "$path_tmp"/pid_redirects) &>/dev/null
    	    return

	else
    	    [ "$s" == 0 ] &&
		print_c 2 "Redirezione (attendi massimo 90 secondi):"

	    sleeping 1
    	    s=`date +"%s"`
    	    s=$(( $s-$k ))
    	    print_c 0 "$s\r\c"
    	fi
    done

    url_in_file="${url_redirect}"

    rm -f "$path_tmp/redirect"
    unset url_redirect post_data
    return 0
}

function redirect_links {
    redirected_link="true"
    if [ -n "$links" ]
    then
	header_box "Links da processare"
	echo -e "${links}\n"
    fi
    
    if [ -n "$links" ] ||
	   [ -n "$post_readline" ]
    then
	[ -z "$stdbox" ] &&
	    header_dl "Downloading in $PWD"
	print_c 1 "La gestione dei download è inoltrata a un'altra istanza attiva di $name_prog (pid: $that_pid), nel seguente terminale: $that_tty\n"
    fi
    
    [ -n "$xterm_stop" ] && xterm_stop

    cursor on
    exit 1
}


function kill_external {
    local pid
    
    if [ -f "$path_tmp/external-dl_pids.txt" ]
    then
	cat "$path_tmp/external-dl_pids.txt" 2>/dev/null |
	    while read pid
	    do
		[[ "$pid" =~ ^[0-9]+$ ]] &&
		    kill -9 $pid 2>/dev/null
	    done &>/dev/null &
	rm -f "$path_tmp/external-dl_pids.txt"
    fi
}

function kill_downloads {
    kill_urls    
    kill_external
    
    if data_stdout
    then
	[ -n "${pid_alive[*]}" ] && kill -9 ${pid_alive[*]} &>/dev/null
    fi
}

function kill_urls {
    local test_url
    local type_pid="$2"
    [ -z "$type_pid" ] && type_pid='pid-url'

    if [ -f "$path_tmp/${type_pid}" ] &&
	   [ -f "$path_tmp/links_loop.txt" ]
    then
	cat "$path_tmp/links_loop.txt" 2>/dev/null |
	    while read test_url
	    do
		url "$test_url" &&
		    kill_url "$test_url"
	    done &>/dev/null &
    fi
}

function kill_url {
    local pid
    local url="$1"
    local type_pid="$2"
    [ -z "$type_pid" ] && type_pid='pid-url'

    if [ -f "$path_tmp/${type_pid}" ]
    then
	grep -P "^[0-9]+ $url$" "$path_tmp/${type_pid}" 2>/dev/null | cut -d' ' -f1 |
	    while read pid
	    do
		if [[ "$pid" =~ ^[0-9]+$ ]]
		then
		    kill -9 $pid &>/dev/null
		    del_pid_url "$url" "$type_pid"
		fi
	    done &>/dev/null &
    fi
}

function kill_pid_urls {
    local type_pid="$1"
    [ -z "$type_pid" ] && type_pid='pid-url'
    
    if [ -f "$path_tmp/${type_pid}" ]
    then
	cat "$path_tmp/${type_pid}" | cut -d' ' -f1 |
	    while read pid
	    do
		kill -9 "$pid" &>/dev/null
	    done &>/dev/null &
    fi
}

function add_pid_url {
    local pid="$1"
    local url="$2"
    local type_pid="$3"
    [ -z "$type_pid" ] && type_pid='pid-url'
    
    echo "$pid $url" >>"$path_tmp/${type_pid}"
}

function del_pid_url {
    local url="$1"
    local type_pid="$2"
    [ -z "$type_pid" ] && type_pid='pid-url'

    if [ -f "$path_tmp/${type_pid}" ]
    then
	sed -r "/^.+ ${url//\//\\/}$/d" -i "$path_tmp/${type_pid}" 2>/dev/null
    fi
}

function set_try_counter {
    (( try_counter[$1]++ ))
}

function get_try_counter {
    if [ -z "${try_counter[$1]}" ]
    then
    	try_counter[$1]=0
    	echo 0

    else
    	echo ${try_counter[$1]}
    fi
}

function set_exit {
    echo "$pid_prog" >"$path_tmp"/zdl_exit
}

function get_exit {
    if [ -f "$path_tmp"/zdl_exit ] &&
	   [ "$pid_prog" == $(cat "$path_tmp"/zdl_exit) ]
    then
	return 0

    else
	return 1
    fi
}

function reset_exit {
    rm -rf "$path_tmp"/zdl_exit
}

function check_connection {
    local i
    
    for i in {0..5}
    do
	ping -q -c 1 8.8.8.8 &>/dev/null && return 0
	sleep 1
    done
    return 1
}

function check_freespace {
    ## per spazio minore di 50 megabyte (51200 Kb), return 1
    
    test_space=( $(df .) )
    (( test_space[11] < 51200 )) &&
	return 1

    return 0
}

function kill_server {
    [ -s /tmp/zdl.d/pid_server ] &&
	kill $(cat /tmp/zdl.d/pid_server) &>/dev/null
}
