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

shopt -u nullglob

if [ "$url_in" != "${url_in//'youtube.com/watch'}" ]; then
    videoType="mp4"
    html=$(wget -q "$url_in" -O -)

    if [[ "$html" =~ \<title\>(.+)\<\/title\> ]]; then
	title="${BASH_REMATCH[1]}"
	title=$(echo $title | sed -r 's/([^0-9a-z])+/_/ig')
	title=$(echo $title | sed -r 's/_youtube//ig')
	title=$(echo $title | sed -r 's/^_//ig')
	title=$(echo $title | tr '[A-Z]' '[a-z]')
	title=$(echo $title | sed -r 's/_amp//ig')
    else
	_log 9 
    fi

    html=$(echo "$html" |grep 'url_encoded_fmt_stream_map')

    if [ -z "$html" ]; then 
    	echo "\nURL non trovato\n"
    fi

    html="${html#*url_encoded_fmt_stream_map}"
    html=$(urldecode "$html")
    html="${html%%${videoType}*}$videoType"
    html="${html##*url=}"
    url_in_file="${html%%\,*}"
    file_in="$title.$videoType"
fi

shopt -s nullglob
