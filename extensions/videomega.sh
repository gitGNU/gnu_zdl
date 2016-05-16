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
## zdl-extension name: Videomega


if [ "$url_in" != "${url_in//videomega.tv}" ]
then
    url_embed="${url_in//\?/cdn.php\?}"

    html=$(wget -t1 -T$max_waiting                      \
		--save-cookies="$path_tmp/cookies.zdl"  \
		--keep-session-cookies                  \
		"$url_embed"                            \
		--user-agent="$user_agent"              \
		-qO-)

    if [ -n "$html" ]
    then
	url_in_file=$(unpack "$html" |
			     sed -r 's|.+src\",\"([^"]+)\".+|\1|g')
	file_in=$(grep '<title>' <<< "$html" |
			 sed -r 's|[^>]+>([^<]+)<.+|\1|g')
	file_in="${file_in#Videomega.tv - }"
	
    else
	_log 2
    fi
fi
