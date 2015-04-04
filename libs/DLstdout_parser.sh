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

    if (( ${#check_tmps[*]}>0 ))
    then
	awk_data=$(awk                                \
	    -v file_in="$file_in"                     \
	    -v url_in="$url_in"                       \
	    -v no_complete="$no_complete"             \
	    -v num_check="$num_check"                 \
	    -v no_check="$no_check"                   \
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

