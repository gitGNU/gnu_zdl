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
    rm -f "$path_tmp"/._stdout.tmp
    tmp_files=( "$path_tmp"/?*_stdout.tmp )
    shopt -u nullglob
    shopt -u dotglob
    unset pid_alive pid_out file_out url_out percent_out length_saved length_out no_check
    [ -z "$num_check" ] && num_check=0

    ## check_stdout, verifica inceppamento e ogni azione sui download: 
    ## disattivati se show_downloads_(lite|extended)
    if [ "$1" == "no_check" ]
    then
	no_check="true"
    else
	(( num_check++ ))
    fi

    
    if (( ${#tmp_files[*]}>0 ))
    then
	if [[ "$(head -n3 ${tmp_files[@]})" =~ (cURL|RTMPdump) ]]
	then
	    for ((i=0; i<${#tmp_files[*]}; i++))
	    do
		if [[ "$(sed -n 3p ${tmp_files[$i]})" =~ ^(cURL|RTMPdump)$ ]]
		then
		    tr "\r" "\n" < ${tmp_files[$i]} > ${tmp_files[i]}.newline
		    tmp_files[$i]=${tmp_files[$i]}.newline
		fi
	    done
	fi

	rm -f "$path_tmp/awk2bash_commands"
	
	awk_data=$(stdbuf -oL -eL                                   \
			  awk                                       \
			  -v file_in="$file_in"                     \
			  -v url_in="$url_in"                       \
			  -v no_complete="$no_complete"             \
			  -v num_check="$num_check"                 \
			  -v no_check="$no_check"                   \
			  -v wget_links_index="${#wget_links[*]}"   \
			  -f $path_usr/libs/common.awk              \
			  -f $path_usr/libs/DLstdout_parser.awk     \
			  ${tmp_files[@]}                           \
		)
	unset tmp_files

	if [[ "$socket_port" =~ ^[0-9]+$ ]]
	then
	    exec 3>/dev/tcp/localhost/$socket_port &&
		{
		    echo -e "$awk_data" >&3
		    exec 3>&-
		}
	fi

	eval "$awk_data"

	[ -f "$path_tmp/awk2bash_commands" ] &&
	    source "$path_tmp/awk2bash_commands"
	
	## per test da awk (codice da inserire): code = code "test=\"" test_awk "\"; "
	[ -n "$test" ] && echo -e "$test" 

	return 0
    else
	return 1
    fi
}

