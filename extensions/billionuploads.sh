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

## zdl-extension types: download
## zdl-extension name: Billionuploads


if [ "$url_in" != "${url_in//billionuploads}" ]
then
    cookies="$path_tmp/cookies.zdl"

    if [ -z "$max_dl" ]
    then
	check_ip billionuploads
    fi

    html=$(wget -t 1 -T $max_waiting         \
	--retry-connrefused                  \
	--keep-session-cookies               \
	--save-cookies="$cookies"            \
	-qO-                                 \
	"$url_in" &>/dev/null)

    if [ -n "$html" ]
    then
	print_c 1 "...\c"
	
	unset post_data
	input_hidden "$html"
	post_data="${post_data%&cmt_type=*}"
	
	if [ -z "$file_in" ]
	then
	    file_in=$(grep "Filename" <<< "$html")
	    file_in="${file_in#*</b>}"
	    file_in="${file_in%<br>*}"
	fi
	
	print_c 2 "Attendi circa 30 secondi:"
	k=$(date +"%s")
	s=0
	unset url_in_file
	
	while true
	do
	    if (( $s>29 ))
	    then
		html=$(wget -t 1 -T $max_waiting                      \
			    --load-cookies=$path_tmp/cookies.zdl      \
			    --save-cookies="$cookies"                 \
			    --post-data="$post_data"                  \
			    "$url_in" -qO-)
		url_in_file=$(grep ">Download</a>" <<< "$html")
		url_in_file="${url_in_file#*product_download_url=}"
		url_in_file="${url_in_file%%\"*}"
	    fi
	    sleeping 1
	    s=$(date +"%s")
	    s=$(( $s-$k ))
	    
	    print_c 0 "$s\r\c"
	    if  ! check_pid $pid_prog      ||    
		    [ -n "$url_in_file" ]  ||    
		    (( $s > 60 ))
	    then
		break
	    fi
	    
	done
	if (( $axel_parts>8 ))
	then
	    axel_parts=8
	fi
    else
	_log 2
    fi
fi
