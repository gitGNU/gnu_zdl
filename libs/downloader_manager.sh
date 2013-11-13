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
    if [ "$downloader_in" = "Axel" ]; then
	[ "$file_in" != "" ] && argout="-o" && fileout="$file_in"
	if [ -f "$path_tmp"/cookies.zdl ]; then
	    export AXEL_COOKIES="$path_tmp/cookies.zdl"
	    if [ "$redirected" == "true" ]; then
		k=`date +"%s"`
		s=0
		while true; do
		    if [ $s == 0 ] || [ $s == $max_waiting ] || [ $s == $(( $max_waiting*2 )) ]; then 
			kill "$wpid" 2>/dev/null
			rm -f "$path_tmp/redirect"
			wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl --post-data="${post_data}" "$url_in_file" -S -O /dev/null -o "$path_tmp/redirect" &
			wpid=$!
		    fi
		    url_redirect=$( cat "$path_tmp/redirect" 2>/dev/null |grep "Location:" | awk '{print $2}' )
		    check_pid "$wpid"
		    if [ ! -z "$url_redirect" ] || [ $? != 1 ] || (( $s>90 )); then 
			kill "$wpid" 2>/dev/null
			break
		    else
			[ $s == 0 ] && print_c 2 "Attendi massimo 90 secondi:"
			sleeping 1
			s=`date +"%s"`
			s=$(( $s-$k ))
			echo -e $s"\r\c"
		    fi
		done
		url_in_file="$url_redirect"
		unset redirected url_redirect
		rm -f "$path_tmp/redirect"
	    fi
	    sleeping 3
	    axel -n $axel_parts ${url_in_file} $argout "$fileout" >> "$path_tmp/${file_in}_stdout.tmp" &
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
	echo -e "${pid_in}\nlink_${prog}: $url_in\nAxel\n${pid_prog}\n$axel_parts" > "$path_tmp/${file_in}_stdout.tmp"
	
    elif [ "$downloader_in" = "Wget" ]; then
	if [ -f "$path_tmp"/cookies.zdl ]; then
	    COOKIES="$path_tmp/cookies.zdl"
	elif [ -f "$path_tmp"/flashgot_cfile.zdl ]; then
	    COOKIES="$path_tmp/flashgot_cfile.zdl"
	fi
	if [ ! -z "${post_data}" ]; then
	    method_post="--post-data=${post_data}"
	fi
	[ "$file_in" != "" ] && argout="-O" && fileout="$file_in"
	wget -t 1 -T $max_waiting --retry-connrefused -c -nc --load-cookies=$COOKIES "$method_post" "$url_in_file" -S  $argout "$fileout" -a "$path_tmp/${file_in}_stdout.tmp" & 
	pid_in=$!
	echo -e "${pid_in}\nlink_${prog}: $url_in\nWget\n${pid_prog}\nlength_in=$length_in" > "$path_tmp/${file_in}_stdout.tmp"
    fi
    
    if [ ! -z "$user" ] && [ ! -z "$host" ]; then
	accounts_alive[${#accounts_alive[*]}]="${user}@${host}:${pid_in}"
	unset user host
    fi
    unset post_data checked
    export LANG="$user_lang"
    export LANGUAGE="$user_language"
    rm -f "$path_tmp/._stdout.tmp" "$path_tmp/_stdout.tmp"
}


function clean_completed {
    data_stdout
    if [ $? == 1 ]; then
	last_out=$(( ${#pid_out[*]}-1 ))
	for j in `seq 0 $last_out`; do
	    length_saved=0
	    [ -f "${file_out[$j]}" ] && length_saved=`ls -l "./${file_out[$j]}" | awk '{ print($5) }'`
	    if [ -f "${file_out[$j]}" ] && [ ! -f "${file_out[$j]}.st" ] && [ "$length_saved" == "${length_out[$j]}" ];then
		rm  "$path_tmp"/"${file_out[$j]}_stdout.tmp"
	    fi
	done
    fi
}


function check_in_url { 	## return --> no_download=1 
    if [ ! -z "$url_in" ]; then
	if [ -z "$file_in" ]; then
	    data_stdout
	    if [ $? == 1 ]; then 
		last_out=$(( ${#pid_out[*]}-1 ))
		for i in `seq 0 $last_out`; do
		    if [ "${url_out[$i]}" == "$url_in" ]; then
			check_pid ${pid_out[$i]}
			if [ $? == 1 ]; then
			    return 1
			fi
			
			file_in="${file_out[$i]}"
			length_saved=0
			[ -f "${file_out[$i]}" ] && length_saved=`ls -l "./${file_out[$i]}" | awk '{ print($5) }'`
			
			if [ -f "${file_out[$i]}" ] && [ ! -f "${file_out[$i]}.st" ] && [ "$length_saved" == "${length_out[$i]}" ]; then
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


function check_in_file { 	## return --> no_download=1 --> download=5
    file_in="${file_in// /_}"
    file_in="${file_in//\'/_}"
    if [ ! -z "$exceeded" ]; then
	_log 4
	no_newip=true
	unset exceeded
    elif [ ! -z "$not_available" ]; then
	[ ! -z "$url_in_file" ] && _log 3
	no_newip=true
	unset not_available
	
    elif [ "$url_in_file" != "${url_in_file//{\"err\"/}" ]; then
	_log 2
	unset no_newip
    elif [ -z "$url_in_file" ] || [ -z "${file_in}" ]; then
	_log 2
	unset no_newip
    fi
    
    if [ ! -z "${file_in}" ]; then
	if ( [ ! -f "${file_in}.st" ] && [ -f "${file_in}" ] && [ "$downloader_in" = "Axel" ] ) || ( ( [ -f "${file_in}" ] || [ -f "${path_tmp}/${file_in}" ] ) && [ "$downloader_in" = "Wget" ] ); then
	    no_newip=true
	    data_stdout
	    if [ $? == 1 ]; then
		last_stdout=$(( ${#pid_out[*]}-1 ))
		for i in `seq 0 $last_stdout`; do
		    if [ "${file_out[$i]}" == "$file_in" ] || [ "$file_in" == "${alias_file_out[$i]}" ]; then
			check_pid ${pid_out[$i]}
			if [ $? == 1 ]; then
			    return 1
			else
			    if [ "$downloader_in" = "Wget" ]; then
				length_saved=0
				length_alias_saved=0
				length_saved=`ls -l "./${file_in}" | awk '{ print($5) }'`
				[ -f "${alias_file_out[$i]}" ] && length_alias_saved=`ls -l "./${alias_file_out[$i]}" | awk '{ print($5) }'`
				
				if [ "${length_out[$i]//[0-9]}" == "${length_out[$i]}" ] || [ "${length_out[$i]}" == "0" ] || [ "${length_out[$i]}" == "unspecified" ] || ( [ ! -z "${length_out[$i]}" ] && (( ${length_out[$i]}>$length_saved )) && (( ${length_out[$i]}>$length_alias_saved )) ); then
				    rm -f "$file_in" "${file_in}.st" 
				    unset no_newip

				    [ ! -z "$url_in_file" ] && return 5
				else

				    no_newip=true
				    
				fi
			    elif [ "$downloader_in" = "Axel" ]; then
				if [ -f "${file_in}.st" ]; then 
				    unset no_newip

				    [ ! -z "$url_in_file" ] && return 5
				else

				    no_newip=true
				fi
			    fi
			fi
		    fi
		done
		
	    else
		_log 1
		no_newip=true
	    fi
	    
	elif  [ ! -z "$url_in_file" ] && ( ( ( [ -f "${file_in}.st" ] || [ ! -f "${file_in}" ] ) && [ "$downloader_in" = "Axel" ] ) || ( ( [ ! -f "${file_in}" ] && [ ! -f "${path_tmp}/${file_in}" ] ) && [ "$downloader_in" = "Wget" ] ) ); then

	    return 5
	    unset no_newip
	fi
	
    fi
    return 1
}


function check_instance_dl {	
    data_stdout
    if [ $? == 1 ]; then
	last_stdout=$(( ${#pid_out[*]}-1 ))
	for i in `seq 0 $last_stdout`; do
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
		echo "$url_loop" >> "$path_tmp"/links_loop.txt
		rm -f "$path_tmp/rewriting"
		;;
	    -)
		if [ -f "$path_tmp/links_loop.txt" ]; then
		    lnx=`cat "$path_tmp"/links_loop.txt`
		    for lnk in $lnx; do
			[ "${url_loop//$lnk}" == "${url_loop}" ] && echo "$lnk" >> "$path_tmp"/links_loop2.txt
		    done
		    rm "$path_tmp"/links_loop.txt
		    [ -f "$path_tmp/links_loop2.txt" ] && mv "$path_tmp"/links_loop2.txt "$path_tmp"/links_loop.txt
		fi
		rm -f "$path_tmp/rewriting"
		;;
	    in) 
		lnx=`cat "$path_tmp"/links_loop.txt 2>/dev/null`
		if [ ! -z "$lnx" ];then
		    for lnk in $lnx; do
			if [ "${url_loop//$lnk}" != "${url_loop}" ]; then 
			    return 1
			fi
		    done
		    return 5
		else
		    return 5
		fi
		return
		;;
	esac
    fi
    if [ -f "$path_tmp/links_loop.txt" ]; then
	clean_file "$path_tmp"/links_loop.txt
    fi
}


function init_links_loop {
    if [ -f $file ]; then
	urls=`cat $file`
	for url in $urls; do
	    links_loop + $url
	done
	data_stdout
	if [ $? == 1 ]; then
	    last_stdout=$(( ${#pid_out[*]}-1 ))
	    for i in `seq 0 $last_stdout`; do
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

