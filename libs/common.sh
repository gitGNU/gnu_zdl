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
    if [ -n "$ck_pid" ]
    then
	if [[ -n $(ps ax | grep -P '^[\ a-zA-Z]*'$ck_pid 2>/dev/null) ]]
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
    if [ -f "$path_tmp/.pid.zdl" ]
    then
	test_pid="$(cat "$path_tmp/.pid.zdl" 2>/dev/null)"
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
    header_box "Links da processare"
    echo -e "${links}\n"
    separator-
    print_c 1 "\nLa gestione dei download è inoltrata a un'altra istanza attiva di $PROG (pid $test_pid), nel seguente terminale: $tty"
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
    local ext
    local title
    local length
    
    ext0=$(grep -o '\.'"${file_in##*.}" $path_usr/mimetypes.txt)
    file_in="${file_in%$ext0}"

    if (( $(( ${#file_in}%2 ))==1 ))
    then
	length=$(( (${#file_in}-1)/2 ))
	[ "${file_in:0:$length}" == "${file_in:$(( $length+1 )):$length}" ] &&
	    file_in="${file_in:0:$length}"
    fi
    
    file_in="${file_in## }"
    file_in="${file_in%% }"
    file_in="${file_in// /_}"
    file_in="${file_in//\'/_}"
    file_in="${file_in//[\[\]\(\)]/-}"
    file_in="${file_in##*/}"
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

    ext=$(set_ext "$file_in")    
    file_in="${file_in%$ext}$ext"
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
    #    if [[ "$(grep -P '^\b(((http|https|ftp)://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))$' <<< "$1")" ]]
    if [[ "$(grep_urls "$1")" ]]
    then
	return 0
    else
	return 1
    fi
}

function grep_urls {
    grep -P '^\b(((http|https|ftp)://?|www[.]*)[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))[-_]*$' <<< "$1"
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
	    awk '!($0 in a){a[$0]; print}' <<< "$(grep -P '^\b(((http|https|ftp)://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))[-_]*$' "$file_to_clean")"
	)
	if [ -n "$lines" ]
	then
	    echo -e "$lines" > "$file_to_clean"
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
    ppid=$1
    proc_pids=(
	$(ls -1 /proc |grep -oP '^[0-9]+$')
    )

    for proc_pid in ${proc_pids[@]}
    do
	if [ -e /proc/$proc_pid/status ] &&
	       [ "$(awk '/PPid/{print $2}' /proc/$proc_pid/status)" == "${ppid}" ]
	then
	    echo $proc_pid
	fi
    done
}

function post_process {
    ## mega.nz
    for line in *.MEGAenc
    do
	if [ -f "${path_tmp}/${line}.tmp" ] &&
	       [ ! -f "${line}.st" ]
	then
	    key=$(head -n1 "$path_tmp"/"$line".tmp)
	    iv=$(tail -n1 "$path_tmp"/"$line".tmp)
	    openssl enc -d -aes-128-ctr -K $key -iv $iv -in "$line" -out "${line%.MEGAenc}" &&
		rm -f "${path_tmp}/${line}.tmp" "$line" &&
		print_c 1 "Il file $line è stato decrittato come ${line%.MEGAenc}"
	fi
    done

    ## *.M3U8
    if ls *__M3U8__* &>/dev/null
    then
	list_fname=$(ls -1 "$path_tmp"/filename_*__M3U8__* 2>/dev/null    |
			    sed -r "s|$path_tmp/filename_(.+).txt|\1|g")

	[ -z "$list_fname" ] &&
	    list_fname=$(ls -1 *__M3U8__*)

	list_fprefix=(
	    $(grep -oP '.+__M3U8__' <<< "$list_fname" |
		     awk '!($0 in a){a[$0]; print}')
	)

	for fprefix in "${list_fprefix[@]}"
	do
	    last_seg=$(grep "$fprefix" <<< "$list_fname" | wc -l)

	    while (( $i<=$last_seg ))
	    do
		unset segments
		for ((i=1; i<=$last_seg; i++))
		do
		    filename=$(grep -P "${fprefix}seg-[0-9]+-" <<< "$list_fname"     |
				      head -n1                                       |
				      sed -r "s|(${fprefix}seg-)[^-]+(-.+)|\1$i\2|g")

		    if [ ! -f "$filename" ] ||
		    	   [ ! -s "$filename" ]
		    then
		    	_log 22
		    	url_resume=$(grep -h "seg-${i}-" "$path_tmp"/filename_"${fprefix}"* 2>/dev/null)

			if url "$url_resume"
			then
		    	    wget -qO "$filename" "$url_resume" &&
		    		print_c 1 "Segmento $i recuperato" &&
		    		break
			else
			    _log 24
			    exit 1
			fi
		    else
	    	    	segments[i]="$filename"
		    fi
		done
	    done

	    echo
	    header_box "Creazione del file ${fprefix%__M3U8__}.mp4"

	    if cat "${segments[@]}" > "${fprefix%__M3U8__}.ts" 2>/dev/null
	    then
		unset ffmpeg
		command -v avconv &>/dev/null && ffmpeg="avconv"
		command -v ffmpeg &>/dev/null && ffmpeg="ffmpeg"

		if [ -z "$ffmpeg" ]
		then
		    dep=ffmpeg
		    _log 23
		    
		else
		    preset=superfast # -preset [ultrafast | superfast | fast | medium | slow | veryslow | placebo]
		    rm -f $ffmpeg-*.log

		    if [ -e /cygdrive ]
		    then
			$ffmpeg -i "${fprefix%__M3U8__}.ts"       \
				-report                           \
				-acodec libfaac                   \
				-ab 160k                          \
				-vcodec libx264                   \
				-crf 18                           \
				-preset $preset                   \
				-y                                \
				"${fprefix%__M3U8__}.mp4"   &&
			    rm -f "$fprefix"*
			
		    else
			( $ffmpeg -i "${fprefix%__M3U8__}.ts"       \
				  -report                           \
				  -acodec libfaac                   \
				  -ab 160k                          \
				  -vcodec libx264                   \
				  -crf 18                           \
				  -preset $preset                   \
				  -y                                \
				  "${fprefix%__M3U8__}.mp4" &>/dev/null &&
				rm -f "$fprefix"* ) &
			pid_ffmpeg=$!

			ffmpeg_stdout $ffmpeg $pid_ffmpeg
		    fi
		fi		
	    fi
	done
    fi

    ## --mp3/--flac: conversione formato
    if [ -n "$format" ]
    then
	[ -n "$(command -v avconv 2>/dev/null)" ] && convert2format="avconv"
	[ -n "$(command -v ffmpeg 2>/dev/null)" ] && convert2format="ffmpeg"
	echo
	header_box "Conversione in $format ($convert2format)"
	echo
	for line in $(cat $print_out)
	do
	    if [ -f "$line" ]
	    then
		mime="$(file --mime-type "$line")"
		mime="${mime##* }"
		
		if [[ "$mime" =~ (audio|video) ]]
		then
		    print_c 4 "Conversione del file: $line"
		    [ "$lite" == "true" ] && convert_params="-report -loglevel quiet"

		    if [ -e /cygdrive ]
		    then
			$convert2format $convert_params                   \
					-i "$line"                        \
					-aq 0                             \
					-y                                \
					"${line%.*}.$format"         &&
			    rm "$line"                               &&
			    print_c 1 "Conversione riuscita: ${line%.*}.$format" ||
				print_c 3 "Conversione NON riuscita: $line"
			
		    else
			( $convert2format                                   \
					  -i "$line"                        \
					  -report                           \
					  -aq 0                             \
					  -y                                \
					  "${line%.*}.$format" &>/dev/null     &&
				rm "$line"                                     &&
				print_c 1 "Conversione riuscita: ${line%.*}.$format" ||
				    print_c 3 "Conversione NON riuscita: $line" ) &
			pid_ffmpeg=$!

			ffmpeg_stdout $convert2format $pid_ffmpeg
		    fi
		    echo
		fi
	    fi
	done

	rm "$print_out"
    fi
}
