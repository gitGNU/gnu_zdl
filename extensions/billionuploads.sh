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


if [ "$url_in" != "${url_in//billionuploads}" ]; then
    cookies="$path_tmp/cookies.zdl"
    if [ ! -z "$multi" ];then
	check_ip billionuploads
    fi
    wget -q -t 1 -T $max_waiting --retry-connrefused --keep-session-cookies --save-cookies="$cookies" -O "$path_tmp/zdl.tmp" $url_in &>/dev/null
    echo -e "...\c"
    
    unset post_data
    input_hidden "$path_tmp/zdl.tmp"
    post_data="${post_data%&cmt_type=*}"
    
    if [ -z "$file_in" ]; then
	file_in=`cat "$path_tmp/zdl.tmp"|grep "Filename"`
	file_in="${file_in#*</b>}"
	file_in="${file_in%<br>*}"
    fi
    
    print_c 2 "Attendi circa 30 secondi:"
    k=`date +"%s"`
    s=0
    unset url_in_file
    while true; do
	
	if (( $s>29 )); then
	    wget -t 1 -T $max_waiting --load-cookies=$path_tmp/cookies.zdl --save-cookies="$cookies" --post-data="$post_data" $url_in -O "$path_tmp"/zdl2.tmp &>/dev/null
	    url_in_file=`cat "$path_tmp"/zdl2.tmp | grep ">Download</a>"`
	    url_in_file="${url_in_file#*product_download_url=}"
	    url_in_file="${url_in_file%%\"*}"
	fi
	sleeping 1
	s=`date +"%s"`
	s=$(( $s-$k ))
	
	echo -e $s"\r\c"
	if [ ! -z "$url_in_file" ] || (( $s > 60 )); then
	    break
	fi
    done
    if (( $axel_parts>8 )); then
	axel_parts=8
    fi
fi
