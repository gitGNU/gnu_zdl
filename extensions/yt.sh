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
## zdl-extension name: Youtube

shopt -u nullglob

if [ "$url_in" != "${url_in//'youtube.com/watch'}" ]; then
    links_loop - "$url_in"
    url_in=$(urldecode "$url_in")
    links_loop + "$url_in"
    videoType="mp4"
    ## html=$(wget -q "$url_in" -O -)
    html=$(wget -Ncq -e convert-links=off --keep-session-cookies --save-cookies="$path_tmp"/cookies.zdl --no-check-certificate "$url_in" -O - ) || _log 8 

    if [[ "$html" =~ \<title\>(.+)\<\/title\> ]]; then
	title="${BASH_REMATCH[1]}"
	title=$(echo $title | sed -r 's/([^0-9a-z])+/_/ig')
	title=$(echo $title | sed -r 's/_youtube//ig')
	title=$(echo $title | sed -r 's/^_//ig')
	title=$(echo $title | tr '[A-Z]' '[a-z]')
	title=$(echo $title | sed -r 's/_amp//ig')

	html=$(echo "$html" |grep 'url_encoded_fmt_stream_map')
	if [ ! -z "$html" ]; then 
	    html="${html#*url_encoded_fmt_stream_map}"
            ## quality: large -> medium -> small (il più alto disponibile è nella prima riga)
	    url_in_file=$(urldecode "$html" |sed -r 's|codecs|\ncodecs|g' | grep mp4 2>/dev/null | grep quality 2>/dev/null | head -n1 2>/dev/null |sed -r 's|.+url=([^,;\\]+)[,;\\]+.+|\1|g' 2>/dev/null)
	    url_in_file=$(urldecode "$url_in_file")
	    file_in="$title.$videoType"

	    unset break_loop
	    if [ -z "$url_in_file" ]; then
		_log 2
		break_loop=true
	    fi
	else
	    _log 2
	    break_loop=true
	fi
    else
	_log 9
	not_available=true
	break_loop=true
    fi
    axel_parts=4
fi

shopt -s nullglob
