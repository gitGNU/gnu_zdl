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


if [ "$url_in" != "${url_in//vk.com\/video_ext}" ]; then
    wget --keep-session-cookies --save-cookies="$path_tmp"/cookies.zdl -O "$path_tmp/zdl.tmp" "$url_in" -q
    echo -e "...\c"
    data_in_file=$(cat "$path_tmp/zdl.tmp" | grep flashvars |head -n 1)
 
    url_in_file="${data_in_file%'&amp;jpg='*}"
    url_in_file="${url_in_file##*'='}"

    ext="${url_in_file##*'.'}"
    echo "${url_in_file}"

    referer="${data_in_file#*referrer=}"
    referer=$(urldecode "${referer%%'&amp;'*}" )
    if [ ! -z "$referer" ]; then
	wget "$referer" -O "$path_tmp"/zdl2.tmp -q 
	file_in=$(cat "$path_tmp"/zdl2.tmp 2>/dev/null | grep "title>")
	file_in="${file_in#*'title>'}"
	file_in="${file_in%'</title'*}.$ext"
    else
	file_in="${url_in_file##*\/}"
    fi
fi
