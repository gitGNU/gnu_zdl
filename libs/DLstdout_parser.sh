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
    unset pid_alive

    if (( ${#check_tmps[*]}>0 ))
    then
	awk_data=$(awk                                \
	    -v url_in="$url_in"                       \
	    -v no_complete="$no_complete"             \
	    -f $path_usr/libs/common.awk              \
	    -f $path_usr/libs/DLstdout_parser.awk     \
	    "$path_tmp"/?*_stdout.tmp                 \
	    )
	eval "$awk_data"
	return 0
    else
	return 1
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
