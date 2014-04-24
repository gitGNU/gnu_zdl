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


if [ "$url_in" != "${url_in//'putlocker.com/file/'}" ]; then
    links_loop - "$url_in"
    url_in="${url_in//putlocker/firedrive}"
    links_loop + "$url_in"
fi

# if [ "$url_in" != "${url_in//'firedrive.com/file/'}" ]; then
#     url_in="${url_in%\#}"
#     wget -q -t 1 -T $max_waiting --retry-connrefused --keep-session-cookies --save-cookies="$path_tmp/cookies.zdl" -O "$path_tmp/zdl.tmp" $url_in &>/dev/null
#     echo -e "...\c"
#     test_putlocker=`cat "$path_tmp/zdl.tmp" | grep "File Does Not Exist"`
    
#     if [ -z "$test_putlocker" ]; then
# 	unset post_data
# 	tmp="$path_tmp/zdl.tmp"
# 	input_hidden
# 	post_data="${post_data}" 

# 	file_in=`cat "$path_tmp/zdl.tmp" |grep ' | Firedrive</title>'`
# 	file_in="${file_in#*'title>'}"
# 	file_in="${file_in%' | Firedrive</title>'*}"
# 	# wget -t 1 -T $max_waiting --load-cookies="$path_tmp/cookies.zdl" --save-cookies="$path_tmp/cookies.zdl" --post-data="$post_data" "${url_in}" -O "$path_tmp"/zdl.tmp &>/dev/null
# 	# input_hidden
# 	# post_data="${post_data}" 

# 	wget -p -t 1 -T $max_waiting --load-cookies="$path_tmp/cookies.zdl" --save-cookies="$path_tmp/cookies.zdl" --post-data="$post_data" "${url_in}" -O "$path_tmp"/zdl2.tmp &>/dev/null
# #exit
# 	url_in_file=`cat "$path_tmp"/zdl2.tmp | grep external_download`
# 	url_in_file="${url_in_file#*\"}"
# 	url_in_file="${url_in_file%%\"*}"
# 	if [ -z "$url_in_file" ]; then
# 	    links_loop - "$url_in"
# 	    print_c 3 "$url_in --> $name_prog non è riuscito ad estrarre l'URL del file $file_in" | tee -a $file_log
# 	    break_loop=true
# 	fi
#     else
# 	_log 3
# 	break_loop=true
#     fi
# fi

if [[ "${url_in}" =~ media.*firedrive\.com\/download ]]; then
    file_in="${url_in##*f=}"
    file_in="${file_in%%\&*}"
    url_in_file="$url_in"
fi
