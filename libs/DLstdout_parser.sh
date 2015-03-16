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

function data_stdout {
    shopt -s nullglob
    shopt -s dotglob
    check_tmps=( "$path_tmp"/?*_stdout.tmp )
    shopt -u nullglob
    shopt -u dotglob

    if (( ${#check_tmps[*]}>0 )); then
	awk_data=$(awk -f $path_usr/libs/common.awk -f $path_usr/libs/DLstdout_parser.awk "$path_tmp"/?*_stdout.tmp)
	eval "$awk_data"
	return 0
    else
	return 1
    fi
}

function data_alive {
    unset pid_alive pid_prog_alive file_alive downloader_alive alias_file_alive url_alive progress_alive length_alive alive
    if data_stdout
    then
	client=1
	tot=$(( ${#pid_out[*]}-1 ))
	j=0
	for i in `seq 0 $tot`; do
	    if check_pid ${pid_out[$i]}
	    then
		pid_alive[$j]="${pid_out[$i]}"
		pid_prog_alive[$j]="${pid_prog_out[$i]}"
		file_alive[$j]="${file_out[$i]}"
		downloader_alive[$j]="${downloader_out[$i]}"
		alias_file_alive[$j]="${alias_file_out[$i]}"
		url_alive[$j]="${url_out[$i]}"
		progress_alive[$j]="${progress_out[$i]}"
		length_alive[$j]=${length_out[$i]}
		alive=1
		(( j++ ))
	    fi
	done
	[ "$alive" == 1 ] && return 1
    fi
}

function check_download {
    if data_stdout
    then
	last_stdout=$(( ${#pid_out[*]}-1 ))
	for i in `seq 0 $last_stdout`; do
	    if [ "${file_in}" == "${file_out[$i]}" ] && [ ! -z "${length_saved[$i]}" ] && [ "$test_saved" != "${length_saved[$i]}" ]; then
		unset test_saved
		return 1
	    elif [ "${file_in}" == "${file_out[$i]}" ]; then
		test_saved="${length_saved[$i]}"
		break
	    fi
	done
    fi
}


function check_stdout {
    if data_stdout
    then
	last_stdout=$(( ${#pid_out[*]}-1 ))
	for ck in `seq 0 $last_stdout`; do
	    is_rtmp "${url_out[$ck]}"
	    if [ $? == 0 ]; then

		if check_pid ${pid_out[$ck]}
		then
		    if [ -f "${file_out[$ck]}" ] && [ -f "${alias_file_out[$ck]}" ]; then
			rm -f "${alias_file_out[$ck]}"
		    fi
		    
		    test_repeated="${repeated[${pid_out[$ck]}]}"
		    repeated[${pid_out[$ck]}]=`tail -n 100 "$path_tmp/${file_out[$ck]}_stdout.tmp"`
		    if [ "$test_repeated" ==  "${repeated[${pid_out[$ck]}]}" ] && [ -f "${file_out[$ck]}.st" ]; then
			kill ${pid_out[$ck]} &>/dev/null
		    fi
		    
		    if [ ! -f "${file_out[$ck]}" ] && [ ! -f "${alias_file_out[$ck]}" ]; then
			kill ${pid_out[$ck]}  &>/dev/null
		    fi
		fi

		if ! check_pid ${pid_out[$ck]}
		then
		    length_saved=0
		    [ -f "${file_out[$ck]}" ] && length_saved=`ls -l "./${file_out[$ck]}" | awk '{ print($5) }'`
		    
		    already_there=`cat "$path_tmp/${file_out[$ck]}_stdout.tmp" 2>/dev/null |grep 'already there; not retrieving.'`
		    if [ ! -z "$already_there" ]; then 
			unset already_there
			print_c 3 "Errore: "$path_tmp"/${file_out[$ck]}_stdout.tmp  --> \"already there; not retrieving.\": $PROG ha cercato di scaricare di nuovo un file già esistente nella directory di destinazione"
			read -p "ATTENZIONE!"
			rm -f "$path_tmp/${file_out[$ck]}_stdout.tmp"
		    else
			if [ "${length_out[$ck]}" == "0" ] || ( [ ! -z "${length_out[$ck]}" ] && (( ${length_out[$ck]} > 0 )) && (( $length_saved < ${length_out[$ck]} )) ); then
			    if [ ! -f "${file_out[$ck]}.st" ]; then
				rm -f "${file_out[$ck]}"
			    fi
			fi
			if ( [ ! -z "${length_out[$ck]}" ] && [ "${length_out[$ck]}" != "0" ] && (( "$length_saved" == "${length_out[$ck]}" )) && (( ${length_out[$ck]} > 0 )) ); then 
			    [ ! -f "${file_out[$ck]}.st" ] && links_loop - "${url_out[$ck]}"
			fi
		    fi
		fi
	    elif [ ${downloader_out[$ck]} == RTMPDump ]; then
		test_completed=$(grep 'Download complete' < "$path_tmp/${file_out[$ck]}_stdout.tmp")
		if ! check_pid "${pid_out[$ck]}"
		then
		    if [ -z "$test_completed" ]; then
			rm -f "${file_out[$ck]}"
		    else
			links_loop - "${url_out[$ck]}"
		    fi
		fi
	    fi
	done
	unset test_rtmp
	return 1
    fi
}

function check_alias {
	## if file_in is an alias...
    
    if [ -f "$file_in" ] && [ -f "$path_tmp/${file_in}_stdout.tmp" ] && [ "${file_in}" != "${file_in%.alias}" ]; then
	if data_stdout
	then
	    last_stdout=$(( ${#pid_out[*]}-1 ))
			#read -p ${#pid_out[*]}
	    for i in `seq 0 $last_stdout`; do
		if check_pid ${pid_out[$i]}
		then
		    if check_pid ${pid_in}
		    then
			unset real_file_in 
			real_file_in=`cat "$path_tmp"/${file_in}_stdout.tmp |grep filename`
			real_file_in="${real_file_in#*filename=\"}"
			real_file_in="${real_file_in%\"*}"
			
			file_in_alias="${file_in}"
			file_in="${real_file_in}"
			
			if [ "${pid_out[$i]}" != "$pid_in" ] && [ "$file_in" == "${file_out[$i]}" ]; then
			    kill $pid_in  &>/dev/null
			    rm -f  "${file_in_alias}"
			elif [ "${pid_out[$i]}" == "$pid_in" ] && [ "$file_in" == "${file_out[$i]}" ]; then
			    check_in_file    ## se file_in esiste, ne verifica la validità --> potrebbe cancellarlo
			    if [ ! -f "$file_in" ]; then
				mv "$file_in_alias" "$file_in"
				print_c 1 "$file_in_alias rinominato come $file_in"
			    else
				kill $pid_in  &>/dev/null
				rm -f  "${file_in_alias}"
			    fi
			fi
		    fi
		    
		    if ! check_pid ${pid_in} && [ "${pid_out[$i]}" != "$pid_in" ] && [ "$file_in" == "${file_out[$i]}" ]; then
			rm -f "${file_in}"
		    fi
		fi
	    done
	fi
    fi
}

function pipe_files {
    [ -z "$print_out" ] && [ -z "$pipe_out" ] && return
    for i in $(seq 0 ${#file_out[*]}); do
	if [ ! -z "${length_out[$i]}" ]; then
	    if [ "${downloader_out[$i]}" == "Axel" ]; then
		denum=$(( $axel_parts*100 ))
	    else
		denum=100
	    fi
	    [ -z "${num_percent[$i]}" ] && num_percent[$i]=0
	    length_down=$(( ${length_out[$i]}*${num_percent[$i]}/$denum ))
	    case ${type_speed[$i]} in
		KB/s) num_speed[$i]=$(( ${num_speed[$i]} * 1024 )) ;;
		MB/s) num_speed[$i]=$(( ${num_speed[$i]} * 1024 * 1024 )) ;;
	    esac
	    if [ -f "${file_out[$i]}" ] && ( ( (( "$length_down">5000000 )) && (( ${num_speed[$i]}>200000 )) ) || ( ((  "${length_saved[$i]}" == ${length_out[$i]} )) && [ ! -f "${file_out[$i]}.st" ] ) || [ -f "$print_out" ] ); then
		if [ -z $(cat "$path_tmp"/pipe_files.txt 2>/dev/null | grep "${file_out[$i]}") ]; then
		    echo "${file_out[$i]}" >> "$path_tmp"/pipe_files.txt
		fi
	    else
		listpipe=$(cat "$path_tmp"/pipe_files.txt 2>/dev/null)
		listpipe="${listpipe//${file_out[$i]}}"
		echo -e "$listpipe" > "$path_tmp"/pipe_files.txt
	    fi
	fi
    done
    _out
}


function _out {
    if [ -f "$path_tmp"/pipe_files.txt ]; then
	[ -f "$path_tmp"/pid_pipe ] && [ -z "$pid_pipe_out" ] && pid_pipe_out=$(cat "$path_tmp"/pid_pipe)
	if ! check_pid $pid_pipe_out && [ ! -z "$pipe_out" ]; then
	    outfiles=( $(cat "$path_tmp"/pipe_files.txt) )
	    if [ ! -z "${outfiles[*]}" ]; then
		nohup $pipe_out ${outfiles[*]} &>/dev/null &
		pid_pipe_out="$!"
		echo $pid_pipe_out > "$path_tmp"/pid_pipe
		pipe_done=1
	    fi
	elif [ ! -z "$print_out" ]; then
	    unset test_piped
	    while read line; do
		if [ -f "$print_out" ]; then
		    while read piped; do
			[ "$piped" == "$line" ] && test_piped=1 && break
		    done < "$print_out"
		fi
		[ ! -z "$line" ] && [ -z "$test_piped" ] && echo "$line" >> "$print_out"
		unset test_piped
	    done < "$path_tmp"/pipe_files.txt
	fi
    fi
}
