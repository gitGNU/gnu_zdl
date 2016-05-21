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

if [ "$url_in" != "${url_in//openload.}" ]
then
    URL_in="$(sed -r 's|\/F\/|/f/|g' <<< "$url_in")"

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
	
    else
	grep -P '\^o' <<< "$html"   |
	    head -n1                |
	    sed -r 's|[^>]+>(.+)</script.+|\1|g' >"$path_tmp/aaencoded.js"

	php_aadecode "$path_tmp/aaencoded.js" >"$path_tmp/aadecoded.js"
	sed -r 's|.+\"href\",\((.+)\)\)\;$|var a = \1;|g' -i "$path_tmp/aadecoded.js"

	url_in_file=$(nodejs_eval "$(cat "$path_tmp/aadecoded.js") a")
    fi

    if ! url "$url_in_file" ||
    	    [ "$url_in_file" == "$url_in" ] ||
    	    [ -z "$file_in" ]
    then
    	_log 2
    fi
fi   
