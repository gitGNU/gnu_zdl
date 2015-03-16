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

function check_freespace {
    a=$a
}

function check_freespace_old {
    fsize=0
    if [ -f "$path_tmp"/${file_in}_stdout.tmp ]; then
	data_stdout "$path_tmp"/${file_in}_stdout.tmp
	if [ $? == 0 ] && [ ! -z "${length_out[0]}" ]; then
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
	    elif [ ! -f "${file_in}.st" ] && [ "$fsize" != 0 ] && (( $freespace<$fsize )); then
		kill -9 $pid_in &>/dev/null
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
	    if [ "$s" == 0 ] || [ "$s" == "$max_waiting" ] || [ "$s" == $(( $max_waiting*2 )) ]; then 
		kill -9 "$wpid" &>/dev/null
		rm -f "$path_tmp/redirect"
		wget -t 1 -T $max_waiting \
		    --user-agent="$user_agent" \
		    --no-check-certificate \
		    --load-cookies=$path_tmp/cookies.zdl \
		    --post-data="${post_data}" \
		    "$url_in_file" \
		    -S -O /dev/null -o "$path_tmp/redirect" &
		wpid=$!
	    fi
	    [ -f "$path_tmp/redirect" ] && url_redirect=$(grep Location: < "$path_tmp/redirect" 2>/dev/null | head -n1 |sed -r 's|.*Location: ||g' |sed -r 's| |%20|g')
	    link_parser "$url_redirect"
	    test_link=$?
	    check_pid "$wpid"
	    if [[ $test_link == 1 ]] || [ $? != 0 ]; then 
		kill -9 "$wpid" &>/dev/null
		url_in_file="$url_redirect"
		break
	    elif (( $s>90 )); then
		kill -9 "$wpid" &>/dev/null
		return
	    else
		[ "$s" == 0 ] && print_c 2 "Redirezione (attendi massimo 90 secondi):"
		sleeping 1
		s=`date +"%s"`
		s=$(( $s-$k ))
		print_c 0 "$s\r\c"
	    fi
	done

	unset redirected url_redirect
	rm -f "$path_tmp/redirect"
    fi

    if [ "$downloader_in" == "Axel" ]; then
	[ "$file_in" != "" ] && argout="-o" && fileout="$file_in"
	sleeping 2
	if [ -f "$path_tmp"/cookies.zdl ]; then
	    export AXEL_COOKIES="$path_tmp/cookies.zdl"
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
	    axel -n $axel_parts "$url_in_file" $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
	fi
	pid_in=$!
	echo -e "${pid_in}
$url_in
Axel
${pid_prog}
$file_in
$url_in_file
$axel_parts" > "$path_tmp/${file_in}_stdout.tmp"

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

##	wget -t 1 -T $max_waiting --no-check-certificate --retry-connrefused -c -nc --load-cookies=$COOKIES $method_post "$url_in_file" -S  $argout "$fileout" -a "$path_tmp/${file_in}_stdout.tmp" & 

	wget --user-agent="$user_agent" \
	    --no-check-certificate \
	    --retry-connrefused \
	    -c -nc -S \
	    --load-cookies=$COOKIES \
	    $method_post \
	    "$url_in_file" \
	    $argout \
	    "$fileout" \
	    -a "$path_tmp/${file_in}_stdout.tmp" &

	pid_in=$!

	echo -e "${pid_in}
$url_in
Wget
${pid_prog}
$file_in
$url_in_file" > "$path_tmp/${file_in}_stdout.tmp"

    elif [ "$downloader_in" == "RTMPDump" ] && [ ! -z "$downloader_cmd" ]; then
	eval $downloader_cmd -o "$file_in" &>>"$path_tmp/${file_in}_stdout.tmp" &
	pid_in=$!

        echo -e "${pid_in}
$url_in
RTMPDump
${pid_prog}
$file_in
$streamer
$playpath
$(date +%s)" > "$path_tmp/${file_in}_stdout.tmp"
	unset downloader_cmd

    elif [ "$downloader_in" == "RTMPDump" ]; then
	rtmpdump -r "$streamer" --playpath="$playpath" -o "$file_in" &>>"$path_tmp/${file_in}_stdout.tmp" &
	pid_in=$!

	echo -e "${pid_in}
$url_in
RTMPDump
${pid_prog}
$file_in
$streamer
$playpath
$(date +%s)" > "$path_tmp/${file_in}_stdout.tmp"

    elif [ "$downloader_in" == "cURL" ] && [ ! -z "$downloader_cmd" ]; then
	( eval $downloader_cmd -o "$file_in" &>>"$path_tmp/${file_in}_stdout.tmp"; links_loop - "$url_in" ) 2>/dev/null &
	pid_in=$!

	echo -e "${pid_in}
$url_in
cURL
${pid_prog}
$file_in
$streamer
$playpath" > "$path_tmp/${file_in}_stdout.tmp"
	unset downloader_cmd

    elif [ "$downloader_in" == "cURL" ]; then
	( curl "$streamer playpath=$playpath" -o "$file_in" 2>>"$path_tmp/${file_in}_stdout.tmp"; links_loop - "$url_in" ) 2>/dev/null &
	pid_in=$!

	echo -e "${pid_in}
$url_in
cURL
${pid_prog}
$file_in
$streamer
$playpath" > "$path_tmp/${file_in}_stdout.tmp"

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
	    if data_stdout
	    then 
		if [ "$multi" != true ] && (( $counter_downloading > 0 )) || ( [ ! -z "$num_multi" ] && (( $counter_downloading >= $num_multi )) ); then
		    return 1
		fi
		
		for ((i=0; i<${#pid_out[*]}; i++)); do
		    if [ "${url_out[$i]}" == "$url_in" ]; then
			if check_pid ${pid_out[$i]}
			then
			    return 1
			fi

			file_in="${file_out[$i]}"
			length_saved=0
			[ -f "${file_out[$i]}" ] && length_saved=$(size_file "${file_out[$i]}")
			
			if [ "$length_saved" != 0 ] && [ -f "${file_out[$i]}" ] && [ ! -f "${file_out[$i]}.st" ] && [ "$length_saved" == "${length_out[$i]}" ] && [ "${percent_out[$i]}" == 100 ]; then
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
    url_in_bis="${url_in::100}"
    file_in_bis="${file_in}__BIS__${url_in_bis//\//_}.${file_in##*.}"
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
	if data_stdout
	then
	    for ((i=0; i<${#pid_out[*]}; i++)); do
		if [ "${file_out[$i]}" == "$file_in" ] || [ "$file_in" == "${alias_file_out[$i]}" ]; then
		    if check_pid ${pid_out[$i]}
		    then
			return 1
		    fi
		    length_saved=${length_saved[$i]} 
		    [ -f "${alias_file_out[$i]}" ] && length_alias_saved=$(size_file "${alias_file_out[$i]}") || length_alias_saved=0
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
	    [ "$resume" != "enabled" ] && bis=true
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
			    [ -f "$path_tmp/${file_in}_stdout.tmp" ] && test_completed=$(grep 'Download complete' < "$path_tmp/${file_in}_stdout.tmp")
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
	        if [ "$i" == bis_dl ] && [ -z "$no_bis" ]; then
		    file_in="${file_in_bis}"
		    if [ ! -f "${file_in_bis}" ]; then
			return 5
		    elif [ -f "${file_in_bis}" ] || ( [ ${downloader_out[$i]} == RTMPDump ] && [ ! -z "$test_completed" ] ); then
			links_loop - "$url_in"
		    fi
		fi
	    done
	    
	    ## ignore link
	    if [[ "$length_saved" =~ ^[0-9]+$ ]] && (( "$length_saved" > 0 )); then
		_log 1
	    elif [[ "$length_saved" =~ ^[0-9]+$ ]] && (( "$length_saved" == 0 )); then
		rm -f "$file_in" "$file_in".st
	    fi
	    break_loop=true
	    no_newip=true
	elif [ ! -z "$url_in_file" ] || ( [ ! -z "$playpath" ] && [ ! -z "$streamer" ] ); then
	    return 5
	fi
    fi
    return 1
}


function check_instance_dl {	
    if data_stdout
    then
	for ((i=0; i<${#pid_out[*]}; i++)); do
	    if check_pid ${pid_prog_out[$i]}
	    then
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


function clean_file {
    unset items
    if [ -f "$path_tmp/rewriting" ];then
	while [ -f "$path_tmp/rewriting" ]; do
	    sleeping 0.1
	done
    fi
    touch "$path_tmp/rewriting"
    if [ ! -z "$1" ] && [ -f "$1" ]; then
	file_to_ck="$1"
	for ((i=1; i<=$(wc -l < "$file_to_ck"); i++)); do
	    it=$(sed -n "${i}p" < "$file_to_ck")
	    if [ "${items[*]}" == "${items[*]//$it}" ]; then
		items[${#items[*]}]="$it"
	    fi
	done
	
	rm "$file_to_ck"
	for ((i=0; i<${#items[*]}; i++)); do
	    [ ! -z "${items[$i]}" ] && echo "${items[$i]}" >> "$file_to_ck"
	done
    fi
    rm -f "$path_tmp/rewriting"
    unset items
}


function links_loop {
    local url_test="$2"
    link_parser "$url_test"
    if [ "$?" != 1 ] && [ "$1" == "+" ]; then
	_log 12 "$url_test"
	links_loop - "$url_test"
    else
	[ "$1" == "+" ] && url_test="${url_test%'#20\x'}"
	line_file "$1" "$url_test" "$path_tmp/links_loop.txt"
    fi
}

function init_links_loop {
    if [ -f "$file" ]; then
	for ((i=1; i<=$(wc -l < "$file"); i++)); do
	    links_loop + "$(sed -n ${i}p < $file)"
	done
	if data_stdout
	then
	    for ((i=0; i<${#pid_out[*]}; i++)); do 
		length_saved=0
		[ -f "${file_out[$i]}" ] && length_saved=$(size_file "${file_out[$i]}")
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

function kill_downloads {
    data_alive
    [ ! -z "${pid_alive[*]}" ] && kill -9 ${pid_alive[*]} &>/dev/null
}

