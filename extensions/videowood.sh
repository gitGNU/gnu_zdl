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
## zdl-extension name: Videowood


if [[ "$url_in" =~ (videowood.) ]]
then
    if [[ ! "$url_in" =~ embed ]]
    then
	url_packed="${url_in//'/video/'//embed/}"
    else
	url_packed="${url_in}"
    fi

    html_embed=$(wget -qO-                                   \
		      --user-agent="$user_agent"             \
		      "$url_packed")

    if [ -z "$html_embed" ] &&
	   command -v curl >/dev/null
    then
	html_embed=$(curl "$url_packed")
    fi
    
    if [[ "$html_embed" =~ "This video doesn't exist" ]]
    then
	_log 3

    else
	html_packed=$(grep 'p,a,c,k,e,d' <<< "$html_embed")

	if [ -n "$html_packed" ]
	then
	    packed_args "$html_packed"
	    packed_code=$(packed "$code_p" "$code_a" "$code_c" "$code_k")

	    url_in_file="${packed_code%%.mp4*}.mp4"
	    url_in_file="${url_in_file##*\"}"
	    url_in_file="${url_in_file//'\\'}"

	    file_in="$(grep '<span' <<< "$html_embed" |
			  head -n1                |
			  sed -r 's|[^>]+>([^<]+)<.+|\1|g' ).${url_in_file##*.}"
	fi

	if ! url "$url_in_file" &&
		[[ "$url_in_file" =~ ^(http://[^0-9]+) ]] ||
    		    [ -z "$file_in" ]
	then
    	    _log 2
	fi
    fi
fi
