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
    if [ -n "$ck_pid" ] &&
	   ps ax | grep -P '^[\ a-zA-Z]*'$ck_pid &>/dev/null
    then
	return 0 
    fi
    return 1
}

function size_file {
    stat -c '%s' "$1"
}


function check_instance_daemon {
    [ -d /cygdrive ] && cyg_condition='&& ($2 == 1)'
    if daemon_pid="$(ps ax | awk -f "$path_usr/libs/common.awk" -e "BEGIN{result = 1; pwd=\"$(urlencode "$PWD")\"} /bash/ $cyg_condition {check_instance_daemon()} END {exit result}")"
    then
	return 1
    fi
    return 0
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
	    return 1
	fi
    fi
    return 0
}

function scrape_url {
    url_page="$1"
    if url "$url_page"
    then
	print_c 1 "[--scrape-url] connessione in corso: $url_page"

	baseURL="${url_page%'/'*}"

	html=$(wget -qO-                         \
		    --user-agent="$user_agent"   \
		    "$url_page"                    |
		      tr "\t\r\n'" '   "'                             | 
		      grep -i -o '<a[^>]\+href[ ]*=[ \t]*"[^"]\+"'    | 
		      sed -e 's/^.*"\([^"]\+\)".*$/\1/g')

	while read line
	do
	    [[ ! "$line" =~ ^(ht|f)tp\:\/\/ ]] &&
		line="${baseURL}/$line"

	    if [[ "$line" =~ "$url_regex" ]]
	    then
		echo "$line"
		if [ -z "$links" ]
		then
		    links="$line"
		else
		    links="${links}\n$line"
		fi
		start_file="$path_tmp/links_loop.txt"
		links_loop + "$line"
	    fi
	done <<< "$html" 

	print_c 1 "Estrazione URL dalla pagina web $url_page completata"
    fi
}

function redirect_links {
    redirected_link="true"
    if [ -n "$links" ]
    then
	header_box "Links da processare"
	echo -e "${links}\n"
	separator-
    fi
    print_c 1 "\nLa gestione dei download è inoltrata a un'altra istanza attiva di $name_prog (pid $that_pid), nel seguente terminale: $that_tty"
    
    [ -n "$xterm_stop" ] && xterm_stop
    exit 1
}


function sanitize_url {
    data="${1%%'?'}"
    data="${data## }"
    data="${data%% }"
    data="${data%'#20%'}"
    data="${data%'#'}"
    data="${data// /%20}"
    data="${data//'('/%28}"
    data="${data//')'/%29}"
    data="${data//'['/%5B}"
    data="${data//']'/%5D}"
    
    echo "$data"
}

function sanitize_file_in {
    local ext ext0
    
    file_in="${file_in## }"
    file_in="${file_in%% }"
    file_in="${file_in// /_}"
    file_in="${file_in//\'/_}"
    file_in="${file_in//\"/_}"
    file_in="${file_in//[\[\]\(\)]/-}"
    file_in="${file_in//\/}"
    file_in="${file_in##-}"
    file_in="$(htmldecode "$file_in")"
    file_in="${file_in//'&'/and}"
    file_in="${file_in//'#'}"
    file_in="${file_in//';'}"
    file_in="${file_in//'?'}"
    file_in="${file_in//'!'}"
    file_in="${file_in//'$'}"
    file_in="${file_in//'%20'/_}"
    file_in="$(urldecode "$file_in")"
    file_in="${file_in//'%'}"
    file_in="${file_in//\|}"
    file_in="${file_in//'`'}"
    file_in="${file_in//[<>]}"
    file_in="${file_in::240}"
    file_in=$(sed -r 's|^[^0-9a-zA-Z\[\]()]*([0-9a-zA-Z\[\]()]+)[^0-9a-zA-Z\[\]()]*$|\1|g' <<< "$file_in")

    if ! dler_type "no-check-ext" "$url_in"
    then
	ext=$(set_ext "$file_in")
	file_in="${file_in%$ext}$ext"
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


function line_file { 	## usage with op=+|- : links_loop $op $link
    op="$1"                    ## operator
    item="$2"                  ## line
    file_target="$3"           ## file target
    rewriting="$3-rewriting"   ## to linearize parallel rewriting file target
    if [ "$op" != "in" ]
    then
	if [ -f "$rewriting" ]
	then
	    while [ -f "$rewriting" ]
	    do
		sleeping 0.1
	    done
	fi
	touch "$rewriting"
    fi

    if [ -n "$item" ]
    then
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
		    sed -e "s|^${item//'*'/\*}$||g" \
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

    if [ -n "${_domain//[0-9.]}" ]
    then
	[ "${_domain}" != "${_domain%'.'*}" ] && parser_domain="${_domain}"
    else 
	parser_ip="${_domain}"
    fi

    # extract the user and password (if any)
    userpass=`echo "$parser_url" | grep @ | cut -d@ -f1`
    parser_pass=`echo "$userpass" | grep : | cut -d: -f2`
    if [ -n "$pass" ]
    then
	parser_user=`echo $userpass | grep : | cut -d: -f1 `
    else
	parser_user="$userpass"
    fi

    # extract the path (if any)
    parser_path="$(echo $parser_url | grep / | cut -d/ -f2-)"

    if [[ "${parser_proto}" =~ ^(ftp|http) ]]
    then
	if ( [ -n "$parser_domain" ] || [ -n "$parser_ip" ] ) &&
	       [ -n "$parser_path" ]
	then
	    return 0
	fi
    fi
    return 1
}

function url {
    if grep_urls "$1" &>/dev/null
    then
	return 0
    else
	return 1
    fi
}

function grep_urls {
    local input result
    result=1
    
    if [ -f "$1" ] &&
	   [ "$(file -b --mime-type "$1")" == 'text/plain' ]
    then
	input=$(cat "$1")

    else
	input="$1"
    fi

    while read line
    do
        if [ -f "$line" ] &&
	       [[ "$line" =~ \.torrent$ ]]
	then
	    echo "$line" 
	    result=0
	fi

    done <<< "$input"
    
    grep -P '(magnet:.+|^\b(((http|https|ftp)://?|www[.]*)[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))[-_]*)$' <<< "$input" &&
	result=0

    return $result
    
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

function file_filter {
    ## opzioni filtro
    filtered=true
    if [ -n "$no_file_regex" ] &&
	   [[ "$1" =~ $no_file_regex ]]
    then
	_log 13
	return 1
    fi
    if [ -n "$file_regex" ] &&
	   [[ ! "$1" =~ $file_regex ]]
    then
	_log 14
	return 1
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
    this_mode="$1"
    this_tty="$2"

    if [ "$this_mode" != daemon ]
    then
	if [ ! -f "$path_tmp/.stop_stdout" ]
	then
	    that_tty="$this_tty"

	elif [ -f "$path_tmp/.stop_stdout" ]
	then
	    that_tty=$(cut -d' ' -f1 "$path_tmp/.stop_stdout")
	fi
	    
	if [ "$that_tty" == "$that_tty" ]
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

