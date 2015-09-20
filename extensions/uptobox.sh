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

## zdl-extension types: download
## zdl-extension name: Uptobox

if [ "$url_in" != "${url_in//uptobox.}" ]
then
    html=$(wget -t 2 -T $max_waiting                      \
		-qO-                                      \
		--retry-connrefused                       \
		--keep-session-cookies                    \
		--save-cookies=$path_tmp/cookies.zdl      \
		--user-agent="$user_agent"                \
		"$url_in")
    unset post_data
    input_hidden "$html" #### $file_in == POST[fname]
    sleep 2    
    html2=$(wget -t 2 -T $max_waiting                        \
		 -qO-                                        \
		 --load-cookies=$path_tmp/cookies.zdl        \
		 --save-cookies=$path_tmp/cookies2.zdl       \
		 --post-data="$post_data"                    \
		 --user-agent="$user_agent"                  \
		 "$url_in")
    
    url_in_file=$(grep "Click here to start your download" -B2 <<< "$html2" | head -n1 | sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

    unset post_data

    url_in_file=$(sanitize_url "$url_in_file")

    if ! url "$url_in_file" ||
	    [ "$url_in_file" == "$url_in" ]
    then
	if [[ "$html" =~ (File not found) ]]
	then
    	    _log 3
	else
    	    _log 2
	fi
    else
	axel_parts=2
    fi

fi   
