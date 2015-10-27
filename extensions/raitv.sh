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
## zdl-extension types: streaming
## zdl-extension name: Rai.tv

if [ "$url_in" != "${url_in//'rai.tv'}" ]
then
    unset youtubedl_links
    
    html=$(wget -qO-                         \
		--user-agent="$user_agent"   \
		"$url_in")
    
    url_in_file='http:'$(grep 'videoURL_MP4 =' <<< "$html" | sed -r 's|[^"]+\"([^"]+)\".+|\1|g')
    file_in=$(youtube-dl --get-filename "$url_in" |tail -n1)

    user_agent="Firefox"

    if command -v youtube-dl &>/dev/null &&
	    [ -z "$url_in_file" ]
    then
    	url_in_file="$url_in"
	youtubedl_links+=( rai\.tv )
	
    elif [ -z "$url_in_file" ]
    then
    	_log 20
    fi
fi
