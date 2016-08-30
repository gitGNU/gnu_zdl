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

## zdl-extension types: streaming download
## zdl-extension name: Openload

if [[ "$url_in" =~ (openload\.) ]]
then
    URL_in="$(sed -r 's|\/F\/|/f/|g' <<< "$url_in")"
    URL_in="$(sed -r 's|\/embed\/|/f/|g' <<< "$url_in")"

    html=$(wget -t 1 -T $max_waiting                      \
    		-qO-                                      \
    		--retry-connrefused                       \
    		--keep-session-cookies                    \
    		--save-cookies="$path_tmp"/cookies.zdl    \
    		--user-agent="$user_agent"                \
    		"${URL_in}")

    file_in=$(grep '<title>' <<< "$html" |sed -r 's/.+\<title>([^|]+)\ \|\ openload.+/\1/g')

    if [[ "$file_in" =~ ([fF]{1}ile [nN]{1}ot [fF]{1}ound) ]]
    then
	_log 3
	
    elif [ -n "$html" ]
    then
	chunk1=${url_in#*\/f\/}
	chunk1=${chunk1%%\/*}

	hiddenurl=$(grep hiddenurl <<< "$html" |
			   sed -r 's|.+hiddenurl\">(.+)<\/span>.*|\1|g')

	hiddenurl=$(htmldecode "$hiddenurl")
	hiddenurl="${hiddenurl//\\/\\\\}"
	hiddenurl="${hiddenurl//\'/\\\'}"
	hiddenurl="${hiddenurl//\"/\\\"}"
	hiddenurl="${hiddenurl//\`/\\\`}"
	hiddenurl="${hiddenurl//\$/\\\$}"
	
	countdown- 6
	
	chunk2=$($nodejs -e "var x = '$hiddenurl'; var s=[];for(var i=0;i<x.length;i++){var j=x.charCodeAt(i);if((j>=33)&&(j<=126)){s[i]=String.fromCharCode(33+((j+14)%94));}else{s[i]=String.fromCharCode(j);}}; var tmp=s.join(''); var str = tmp.substring(0, tmp.length - 1) + String.fromCharCode(tmp.slice(-1).charCodeAt(0) + 3); console.log(str)")

	if [ -n "$chunk2" ]
	then
	    url_in_file=$(wget -S --spider \
			       --referer="$URL_in" \
			       --keep-session-cookies                    \
    			       --load-cookies="$path_tmp"/cookies.zdl    \
    			       --user-agent="$user_agent"                \
			       "https://openload.co/stream/$chunk2" 2>&1 |
			      grep Location | head -n1 |
			      sed -r 's|.*Location: (.+)$|\1|g')

	    [ -z "$file_in" ] && file_in="${url_in_file##*\/}"
	fi
    fi
    end_extension
fi
