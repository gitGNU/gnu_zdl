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
## zdl-extension name: Dailymotion


if [ "$url_in" != "${url_in//dailymotion.com\/video}" ]; then
    echo -e ".dailymotion.com\tTRUE\t/\tFALSE\t0\tff\toff" > "$path_tmp"/cookies.zdl
    html="$(wget -t 1 -T $max_waiting --load-cookies="$path_tmp"/cookies.zdl -q "$url_in" -O-)"

    if [ ! -z "$html" ]
    then
	file_in=$(grep "title>" <<< "$html")
	file_in="${file_in#*'<title>'}"
	file_in="${file_in%'</title>'*}.mp4"

	url_in2="${url_in//'/video/'//embed/video/}"
	url_in2="${url_in2%%_*}"

	code=$(urldecode "$(wget -t 1 -T $max_waiting -q $url_in2 -O -)" | grep mp4\?auth)
	if [ ! -z "$code" ]
	then
	    auth="${code##*'mp4?auth='}"
	    auth="${auth%%\"*}"
	    url_in_file="${code%$auth*}$auth"
	    url_in_file="${url_in_file##*\"}"
	    url_in_file="${url_in_file//'\/'//}"
	else
	    _log 2
	fi
    else
	_log 2
    fi
fi
