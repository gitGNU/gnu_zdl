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

## zdl-extension types: streaming
## zdl-extension name: VK (HD)


if [ "$url_in" != "${url_in//vk.com\/video_ext.php}" ]
then
    html="$(wget -t 1 -T $max_waiting --keep-session-cookies --save-cookies="$path_tmp"/cookies.zdl "$url_in" -q -O-)"

    if [ ! -z "$html" ]
    then
	if [[ $(grep prohibited <<< "$html") ]]
	then
	    _log 11
	else
	    data_in_file=$(grep cache <<< "$html" 2>/dev/null | head -n 3 | tail -n 1)
	    if [[ "$data_in_file" =~ http ]]
	    then
		url_in_file="${data_in_file##*cache}"
		url_in_file="${url_in_file#*\":\"}"
		url_in_file="${url_in_file%%\"*}"
		url_in_file="${url_in_file//'\'}"
	    else
		data_in_file=$(grep flashvars <<< "$html" 2>/dev/null)
		url_in_file="${data_in_file##*url[0-9]}"
		url_in_file="${url_in_file#*\=}"
		url_in_file="${url_in_file%%\?*}"
	    fi
	    ext="${url_in_file##*'.'}"
	    ext="${ext%'?'*}"
	    data_in_file=$(grep title <<< "$html" 2>/dev/null)
	    file_in="${data_in_file##*title\":\"}"
	    file_in="${file_in%%\"*}"
	    file_in="${file_in::240}"
	fi
    else
	_log
    fi
    
elif [ "$url_in" != "${url_in//vk.com\/video}" ]
then
    html=$(wget -t 1 -T $max_waiting                     \
		--keep-session-cookies                   \
		--save-cookies="$path_tmp"/cookies.zdl   \
		"$url_in" -qO-)

    if [ -n "$html" ]
    then
	if grep prohibited <<< "$html" >/dev/null
	then
	    _log 11
	    
	else
	    data_in_file=$(grep cache <<< "$html" 2>/dev/null)
	    url_in_file="${data_in_file##*cache}"
	    url_in_file="${url_in_file#*'\":\"'}"
	    url_in_file="${url_in_file%%'\"'*}"
	    url_in_file="${url_in_file//'\\\'}"

	    ext="${url_in_file##*'.'}"
	    ext="${ext%'?'*}"
	    data_in_file=$(grep title <<< "$html" 2>/dev/null)
	    file_in="${data_in_file##*title\":\"}"
	    file_in="${file_in%%\"*}"
	    file_in="${file_in::240}"
	fi
    else
	_log 2
    fi
fi

if [ "$url_in" != "${url_in//vk.com}" ]
then
    if [ -n "$file_in" ]
    then
	file_in=$(urldecode "$file_in" |sed -r 's|/||g' 2>/dev/null).$ext
    else
	file_in=$(sed -r 's|.+\/([^/?]+).*$|\1|' <<< "$url_in_file" 2>/dev/null)
    fi
fi

