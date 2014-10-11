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

if [ "$url_in" != "${url_in//vk.com\/video_ext.php}" ]; then
    wget -t 1 --keep-session-cookies --save-cookies="$path_tmp"/cookies.zdl -O "$path_tmp/zdl.tmp" "$url_in" -q

    data_in_file=$(cat "$path_tmp/zdl.tmp" |grep cache | head -n 3 | tail -n 1)
    if [[ "$data_in_file" =~ http ]]; then
	url_in_file="${data_in_file##*cache}"
	url_in_file="${url_in_file#*\":\"}"
	url_in_file="${url_in_file%%\"*}"
	url_in_file="${url_in_file//'\'}"
    else
	data_in_file=$(cat "$path_tmp/zdl.tmp" |grep flashvars)
	url_in_file="${data_in_file##*url[0-9]}"
	url_in_file="${url_in_file#*\=}"
	url_in_file="${url_in_file%%\?*}"
    fi
    ext="${url_in_file##*'.'}"
    ext="${ext%'?'*}"
    data_in_file=$(cat "$path_tmp/zdl.tmp" | grep title)
    file_in="${data_in_file##*title\":\"}"
    file_in="${file_in%%\"*}"
    file_in="${file_in::240}.$ext"
elif [ "$url_in" != "${url_in//vk.com\/video}" ]; then
    wget -t 1 --keep-session-cookies --save-cookies="$path_tmp"/cookies.zdl -O "$path_tmp/zdl.tmp" "$url_in" -q

    data_in_file=$(cat "$path_tmp/zdl.tmp" | grep cache)
    url_in_file="${data_in_file##*cache}"
    url_in_file="${url_in_file#*'\":\"'}"
    url_in_file="${url_in_file%%'\"'*}"
    url_in_file="${url_in_file//'\\\'}"

    ext="${url_in_file##*'.'}"
    ext="${ext%'?'*}"
    data_in_file=$(cat "$path_tmp/zdl.tmp" | grep title)
    file_in="${data_in_file##*title\":\"}"
    file_in="${file_in%%\"*}"
    file_in="${file_in::240}.$ext"
fi

[ ! -z "$file_in" ] && file_in=$(urldecode "$file_in")
