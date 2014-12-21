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
# Copyright (C) 2012
# Free Software Foundation, Inc.
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (project administrator and first inventor)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#


function check_freespace {
    fsize=0
    if [ -f "$path_tmp"/${file_in}_stdout.tmp ]; then
	data_stdout "$path_tmp"/${file_in}_stdout.tmp
	if [ $? == 1 ] && [ ! -z ${length_out[0]} ]; then
	    fsize=$(( ${length_out[0]}/1024 ))
	fi
    else
	if [ ! -z "$lenght_in" ];then
	    fsize="$length_in"
	fi
    fi
    
    maxl=`df |wc -l`
    pattern=`pwd -P`
    for l in `seq 2 $maxl`; do
	dev=`df | awk '{ print($6) }' | sed -n "${l}p"`
	if [ "$dev" == "/" ]; then dev="$HOME" ; fi
	freespace=`df | awk '{ print($4) }' | sed -n "${l}p"`
	if [ "$pattern" != "${pattern//$dev}" ]; then
	    if (( $freespace<50000 )); then
		print_c 3 "Spazio insufficiente sul device. $PROG terminato."
		exit
	    elif [ ! -f "${file_in}.st" ] && [ $fsize != 0 ] && (( $freespace<$fsize )); then
		kill $pid_in 2>/dev/null
		_log 6
		return 1
	    fi
	fi
    done
    unset fsize
}


function download {
    export LANG="$prog_lang"
    export LANGUAGE="$prog_lang"
    unset headers
    rm -f "$path_tmp/${file_in}_stdout.tmp"
    if [ "$redirected" == "true" ]; then
	k=`date +"%s"`
	s=0
	while true; do
	    if [ $s == 0 ] || [ $s == $max_waiting ] || [ $s == $(( $max_waiting*2 )) ]; then 
		kill "$wpid" 2>/dev/null
		rm -f "$path_tmp/redirect"
		wget -t 1 -T $max_waiting --no-check-certificate --load-cookies=$path_tmp/cookies.zdl --post-data="${post_data}" "$url_in_file" -S -O /dev/null -o "$path_tmp/redirect" &
		wpid=$!
	    fi
	    [ -f "$path_tmp/redirect" ] && url_redirect=$(grep Location: < "$path_tmp/redirect" 2>/dev/null | head -n1 |sed -r 's|.*Location: ||g' |sed -r 's| |%20|g')
	    link_parser "$url_redirect"
	    test_link=$?
	    check_pid "$wpid"
	    if [[ $test_link == 1 ]] || [ $? != 1 ]; then 
		kill "$wpid" 2>/dev/null
		url_in_file="$url_redirect"
		break
	    elif (( $s>90 )); then
		kill "$wpid" 2>/dev/null
		return
	    else
		[ $s == 0 ] && print_c 2 "Redirezione (attendi massimo 90 secondi):"
		sleeping 1
		s=`date +"%s"`
		s=$(( $s-$k ))
		echo -e $s"\r\c"
	    fi
	done

	unset redirected url_redirect
	rm -f "$path_tmp/redirect"
    fi

    if [ "$downloader_in" == "Axel" ]; then
	[ "$file_in" != "" ] && argout="-o" && fileout="$file_in"
	if [ -f "$path_tmp"/cookies.zdl ]; then
	    export AXEL_COOKIES="$path_tmp/cookies.zdl"
	    sleeping 3
	    axel -n $axel_parts "${url_in_file}" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
	elif [ -f "$path_tmp"/flashgot_cookie.zdl ]; then
	    COOKIES=`cat "$path_tmp"/flashgot_cookie.zdl`
	    if [ ! -z "$COOKIES" ] ; then
		headers="-H \"Cookie:$COOKIES\""
		axel -n $axel_parts "$headers" "$url_in_file" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
	    else
		axel -n $axel_parts "$url_in_file" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
	    fi
	    
	else
	    sleeping 2
	    axel -n $axel_parts "$url_in_file" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
	fi
	pid_in=$!
	echo -e "${pid_in}\nlink_${prog}: $url_in\nAxel\n${pid_prog}\n$axel_parts\n$url_in_file" > "$path_tmp/${file_in}_stdout.tmp"
    elif [ "$downloader_in" == "Wget" ]; then
	if [ -f "$path_tmp"/cookies.zdl ]; then
	    COOKIES="$path_tmp/cookies.zdl"
	elif [ -f "$path_tmp"/flashgot_cfile.zdl ]; then
	    COOKIES="$path_tmp/flashgot_cfile.zdl"
	fi
	if [ ! -z "${post_data}" ]; then
	    method_post="--post-data=${post_data}"
	fi
	if [ "$file_in" != "" ]; then
	    argout="-O"
	    fileout="$file_in"
	else
	    argout="--trust-server-names"
	fi
	wget --no-check-certificate --retry-connrefused -c -nc --load-cookies=$COOKIES $method_post "$url_in_file" -S  $argout "$fileout" -a "$path_tmp/${file_in}_stdout.tmp" & 
#	wget -t 1 -T $max_waiting --no-check-certificate --retry-connrefused -c -nc --load-cookies=$COOKIES $method_post "$url_in_file" -S  $argout "$fileout" -a "$path_tmp/${file_in}_stdout.tmp" & 
	pid_in=$!
	echo -e "${pid_in}\nlink_${prog}: $url_in\nWget\n${pid_prog}\nlength_in=$length_in\n$url_in_file" > "$path_tmp/${file_in}_stdout.tmp"
    elif [ "$downloader_in" == "RTMPDump" ]; then
	rtmpdump -r "$streamer" --playpath="$playpath" -o "$file_in" &>>"$path_tmp/${file_in}_stdout.tmp" &
	pid_in=$!
	echo -e "${pid_in}\nlink_${prog}: $url_in\nRTMPDump\n${pid_prog}\n$file_in\n$streamer\n$playpath\n$(date +%s)" > "$path_tmp/${file_in}_stdout.tmp"
    elif [ "$downloader_in" == "cURL" ]; then
	( curl "$streamer playpath=$playpath" -o "$file_in" 2>>"$path_tmp/${file_in}_stdout.tmp"; links_loop - "$url_in" ) 2>/dev/null &
	pid_in=$!
	echo -e "${pid_in}\nlink_${prog}: $url_in\ncURL\n${pid_prog}\n$file_in\n$streamer\n$playpath" > "$path_tmp/${file_in}_stdout.tmp"
    fi
    
    if [ ! -z "$user" ] && [ ! -z "$host" ]; then
	accounts_alive[${#accounts_alive[*]}]="${user}@${host}:${pid_in}"
	unset user host
    fi
    unset post_data checked
    export LANG="$user_lang"
    export LANGUAGE="$user_language"
    rm -f "$path_tmp/._stdout.tmp" "$path_tmp/_stdout.tmp"
    sleeping 3
}


function check_in_url { 	## return --> no_download=1 
    if [ ! -z "$url_in" ]; then
	if [ -z "$file_in" ]; then
	    data_stdout
	    if [ $? == 1 ]; then 
		if [ "$multi" != true ] && (( $counter_downloading > 0 )) || ( [ ! -z "$num_multi" ] && (( $counter_downloading >= $num_multi )) ); then
		    return 1
		fi
		
		for ((i=0; i<${#pid_out[*]}; i++)); do
		    if [ "${url_out[$i]}" == "$url_in" ]; then
			check_pid ${pid_out[$i]}
			if [ $? == 1 ]; then
			    return 1
			fi

			file_in="${file_out[$i]}"
			length_saved=0
			[ -f "${file_out[$i]}" ] && length_saved=`ls -l "./${file_out[$i]}" | awk '{ print($5) }'`
			
			if [ -f "${file_out[$i]}" ] && [ ! -f "${file_out[$i]}.st" ] && [ "$length_saved" == "${length_out[$i]}" ] && [ "${num_percent[$i]}" == 100 ]; then
			    return 1
			fi
			unset length_saved
			check_freespace
			if [ $? == 1 ]; then return 1 ; fi
		    fi
		done
	    fi
	fi
    fi
}




function check_in_file { 	## return --> no_download=1 / download=5
    sanitize_file_in
    file_in_bis="${file_in}__BIS__${url_in//\//_}.${file_in##*.}"
    if [ ! -z "$exceeded" ]; then
	_log 4
	break_loop=true
	no_newip=true
	unset exceeded
	return 1
    elif [ ! -z "$not_available" ]; then
	[ ! -z "$url_in_file" ] && _log 3
	no_newip=true
	unset not_available
	return 1
    elif [ "$url_in_file" != "${url_in_file//{\"err\"/}" ]; then
	_log 2
	unset no_newip
	return 1
    elif [ -z "$url_in_file" ] || ( [ -z "${file_in}" ] && [ "$downloader_in" == "Axel" ] ); then
	_log 2
	unset no_newip
    fi

    if [ ! -z "${file_in}" ]; then
	length_saved=0
	length_alias_saved=0
		    
	no_newip=true
	data_stdout
	if [ $? == 1 ]; then
	    for ((i=0; i<${#pid_out[*]}; i++)); do
		if [ "${file_out[$i]}" == "$file_in" ] || [ "$file_in" == "${alias_file_out[$i]}" ]; then
		    check_pid ${pid_out[$i]}
		    if [ $? == 1 ]; then
			return 1
		    fi
		    length_saved=${length_saved[$i]} #`ls -l "./${file_in}" | awk '{ print($5) }'`
		    [ -f "${alias_file_out[$i]}" ] && length_alias_saved=`ls -l "./${alias_file_out[$i]}" | awk '{ print($5) }'` || length_alias_saved=0
		    if [[ "${length_out[$i]}" =~ ^[0-9]+$ ]] && ( (( ${length_out[$i]}>$length_saved )) && (( ${length_out[$i]}>$length_alias_saved )) ); then
			length_check="${length_out[$i]}"
		    else
			unset length_check
		    fi
		    if [ "${file_out[$i]}" == "$file_in" ] && [ "$url_in" == "${url_out[$i]}" ]; then
			no_bis=true
		    fi
		    break
		elif [ "$file_in" != "${file_out[$i]}" ] && [ "$url_in" == "${url_out[$i]}" ] && [ "$file_in_bis" != "${file_out[$i]}" ]; then
		    rm -f "$path_tmp/${file_out[$i]}_stdout.tmp" "${file_out[$i]}" "${file_out[$i]}.st" 
		fi
	    done
	fi

	if [ -f "${file_in}" ]; then
	    ## --bis abilitato di default
	    [ "$overwrite" != true ] && bis=true
	    if [ "$bis" == true ]; then
		homonymy_treating=( resume_dl rewrite_dl bis_dl )
	    else
		homonymy_treating=( resume_dl rewrite_dl )
	    fi
	    
	    for i in ${homonymy_treating[*]}; do
		if [ "$downloader_in" == Wget ]; then
		    case "$i" in
			resume_dl|rewrite_dl) 
			    if [ ! -z "$length_check" ] && (( $length_check>$length_saved )) && ( [ -z "$bis" ] || [ "$no_bis" == true ] ); then
				rm -f "$file_in" "${file_in}.st" 
	 			unset no_newip
	 			[ ! -z "$url_in_file" ] && return 5
			    fi
			    ;;
		    esac
		elif [ "$downloader_in" == RTMPDump ]; then
		    case "$i" in
			resume_dl|rewrite_dl) 
			    [ -f "$path_tmp/${file_out[$i]}_stdout.tmp" ] && test_completed=$(grep 'Download complete' < "$path_tmp/${file_out[$i]}_stdout.tmp")
			    if [ -f "${file_in}" ] && [ -z "$test_completed" ] && ( [ -z "$bis" ] || [ "$no_bis" == true ] ); then 
				unset no_newip
				[ ! -z "$url_in_file" ] && return 5
			    fi
			    ;;
		    esac
		elif [ "$downloader_in" == Axel ]; then
		    case "$i" in
			resume_dl) 
			    if [ -f "${file_in}.st" ] && ( [ -z "$bis" ] || [ "$no_bis" == true ] ); then 
				unset no_newip
				[ ! -z "$url_in_file" ] && return 5
			    fi
			    ;;
			rewrite_dl)
			    if ( [ -z "$bis" ] || [ "$no_bis" == true ] ) && [ ! -z "$length_check" ] && (( $length_check>$length_saved )); then
				rm -f "$file_in" "${file_in}.st" 
	 			unset no_newip
	 			[ ! -z "$url_in_file" ] && return 5
			    fi
			    ;;
		    esac
		fi
		## case bis_dl
	        if [ $i == bis_dl ] && [ -z "$no_bis" ]; then
		    file_in="${file_in_bis}"
		    if [ ! -f "${file_in_bis}" ]; then
			return 5
		    elif [ -f "${file_in_bis}" ] || ( [ ${downloader_out[$i]} == RTMPDump ] && [ ! -z "$test_completed" ] ); then
			links_loop - "$url_in"
		    fi
		fi
	    done
	    
	    ## ignore link
	    _log 1
	    no_newip=true
	elif [ ! -z "$url_in_file" ] || ( [ ! -z "$playpath" ] && [ ! -z "$streamer" ] ); then
	    return 5
	fi
    fi
    return 1
}


function check_instance_dl {	
    data_stdout
    if [ $? == 1 ]; then
	for ((i=0; i<${#pid_out[*]}; i++)); do
	    check_pid ${pid_prog_out[$i]}
	    if [ $? == 1 ]; then
		pss=`ps ax |grep "${pid_prog_out[$i]}"`
		max=`echo -e "$pss" |wc -l`
		for line in `seq 1 $max`; do
		    proc=`echo -e $pss"" |sed -n "${line}p"`
		    pid=`echo "$proc" | awk "{ print $ps_ax_pid }"`
		    tty=`echo "$proc" | awk "{ print $ps_ax_tty }"`
		    if [ "$pid" == "${pid_prog_out[$i]}" ] && [ "$pid" != "$pid_prog" ]; then
			return 1
		    fi
		done
	    fi
	done
    fi
}




function links_loop { 	## usage with op=+|- : links_loop $op $link
    op="$1"             ## operator
    url_loop="$2"       ## url
    if [ "$op" != "in" ]; then
	if [ -f "$path_tmp/rewriting" ];then
	    while [ -f "$path_tmp/rewriting" ]; do
		sleeping 0.1
	    done
	fi
	touch "$path_tmp/rewriting"
    fi

    if [ ! -z "$url_loop" ]; then
	case $op in
	    +)
		link_parser "$url_loop"
		if [ "$?" == 1 ]; then
		    links_loop "in" "$url_loop"
		    if [ "$?" != 1 ]; then
			echo "$url_loop" >> "$path_tmp"/links_loop.txt
			rm -f "$path_tmp/rewriting"
		    fi
		else
		    _log 12
		fi
		;;
	    -)
		if [ -f "$path_tmp/links_loop.txt" ]; then
		    for ((i=1; i<=$(wc -l < "$path_tmp/links_loop.txt"); i++)); do
			lnk=$(sed -n ${i}p < "$path_tmp/links_loop.txt" )
			[ "$lnk" != "$url_loop" ] && echo "$lnk" >> "$path_tmp"/links_loop2.txt
		    done
		    rm "$path_tmp"/links_loop.txt
		    [ -f "$path_tmp/links_loop2.txt" ] && mv "$path_tmp"/links_loop2.txt "$path_tmp"/links_loop.txt
		fi
		rm -f "$path_tmp/rewriting"
		;;
	    in) 
		if [ -f "$path_tmp"/links_loop.txt ]; then
		    for ((i=1; i<=$(wc -l < "$path_tmp"/links_loop.txt); i++)); do
			url_test=$(sed -n ${i}p < "$path_tmp"/links_loop.txt)
			if [ ! -z "${url_test}" ] && [ "${url_loop}" == "${url_test}" ]; then 
			    return 1
			fi
		    done
		fi
		return 5
		;;
	esac
    fi
}


function init_links_loop {
    if [ -f $file ]; then
	for ((i=1; i<=$(wc -l < "$file"); i++)); do
	    links_loop + "$(sed -n ${i}p < $file)"
	done
	data_stdout
	if [ $? == 1 ]; then
	    for ((i=0; i<${#pid_out[*]}; i++)); do 
		length_saved=0
		[ -f "${file_out[$i]}" ] && length_saved=`ls -l "./${file_out[$i]}" | awk '{ print($5) }'`
		if [ -f "${file_out[$i]}" ] && [ ! -f "${file_out[$i]}.st" ] && [ "$length_saved" == "${length_out[$i]}" ];then
		    links_loop - "${url_out[$i]}" 
		else
		    links_loop + "${url_out[$i]}"
		fi
		unset length_saved
	    done
	fi
    fi
}

function link_parser {
    local _domain userpass ext item param
    param="$1"
    # extract the protocol
    parser_proto=$(echo "$param" | grep '://' | sed -e's,^\(.*://\).*,\1,g' 2>/dev/null)

    # remove the protocol
    parser_url=$(echo "$param" | sed -e s,$parser_proto,,g 2>/dev/null)

    # extract domain
    _domain="${parser_url#*'@'}"
    _domain="${_domain%%\/*}"
    [ "${_domain}" != "${_domain#*:}" ] && parser_port="${_domain#*:}"
    _domain="${_domain%:*}"

    if [ ! -z "${_domain//[0-9.]}" ]; then
	ext="${_domain%'.'*}"
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
	    return 1
	fi
    fi
}

