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

## ZDL add-on
## zdl-extension types: download
## zdl-extension name: Katfile


if [ "$url_in" != "${url_in//katfile\.}" ]
then
    html=$(wget -t1 -T$max_waiting                               \
		"$url_in"                                        \
		--user-agent="Firefox"                           \
		--keep-session-cookies                           \
		--save-cookies="$path_tmp/cookies.zdl"           \
		-qO-)
    
    [ -z "$html" ] &&
	command -v curl >/dev/null && 
	html=$(curl "$url_in") 

    if [[ "$html" =~ (File Not Found) ]]
    then
	_log 3

    else
	input_hidden "$html"
	post_data+="&method_free=Slow Download Speed"

	html=$(wget "$url_in"                       \
		    --post-data="$post_data"        \
		    --load-cookies="$path_tmp/cookies.zdl"   \
		    -qO-)

	if [[ "$html" =~ 'to download bigger files' ]]
	then
	    _log 4

	else
	    code=$(pseudo_captcha "$html")
	    if [[ "$code" =~ ^[0-9]+$ ]]
	    then
		print_c 1 "Pseudo-captcha: $code"
	    else
		print_c 3 "Pseudo-captcha: codice non trovato"
	    fi

	    unset post_data
	    input_hidden "$html"
	    post_data+="&code=$code"

	    html=$(wget "$url_in"                       \
			--post-data="$post_data"        \
			-qO-)

	    url_in_file=$(grep downloadbtn -B1 <<< "$html"  |
				 head -n1                   |
				 sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

	    aria2_connections=2
	fi
	
	end_extension
    fi
fi
