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
## zdl-extension name: Movshare/Wholecloud

if [[ "$url_in" =~ (movshare\.|wholecloud\.) ]] &&
       [ "$url_in" != "${url_in//video}" ]
then
    replace_url_in "http://www.wholecloud.net/video/${url_in##*\/}"
    
    html=$(wget -t 1 -T $max_waiting \
		--keep-session-cookies \
		--save-cookies="$path_tmp"/cookies.zdl \
		"$url_in" -qO- )

    if [ -n "$html" ]
    then
	test_exist=$(grep "This file no longer exists on our servers" <<< "$html")
	if [ -n "$test_exist" ]
	then
	    _log 3

	else
	    if [[ "$html" =~ (Continue to the video) ]]
	    then
		input_hidden "$html"
		post_data+="&submit=submit"
		
		html=$(wget -t 1 -T $max_waiting                     \
			    "$url_in"                                \
			    --referer=wholecloud.net                 \
			    --user-agent="$user_agent"               \
			    --post-data="${post_data}"               \
			    --load-cookies="$path_tmp"/cookies.zdl \
			    -qO-)

	    fi

	    if grep "yet ready" <<< "$html" &>/dev/null
	    then
		_log 3

	    else

		file_in=$(grep "Title:" <<< "$html")
		file_in="${file_in%<*}"
		file_in=$(trim "${file_in##*>}")
		
		[ "$file_in" == Untitled ] &&
		    file_in=${file_in}-${url_in##*\/}
		
		url_in_file=$(grep "source" <<< "$html" |
				     head -n1 |
				     sed -r 's|.+\"([^"]+)\".+|\1|g')

		if ! url "$url_in_file"
		then
		    flashvars_file=$(grep "flashvars.file=" <<< "$html")
		    flashvars_file="${flashvars_file#*'flashvars.file='\"}"
		    flashvars_file="${flashvars_file%\"*}"

		    flashvars_key=$(grep "flashvars.filekey=" <<< "$html")
		    flashvars_key="${flashvars_key#*'flashvars.filekey='\"}"
		    flashvars_key="${flashvars_key%\"*}"
		    flashvars_domain=$(grep "flashvars.domain=" <<< "$html")
		    flashvars_domain="${flashvars_domain#*'flashvars.domain='\"}"
		    flashvars_domain="${flashvars_domain%\"*}"

		    rm -f "$path_tmp"/zdl2.tmp
		    axel "${flashvars_domain}/api/player.api.php?user=undefined&cid=1&file=${flashvars_file}&pass=undefined&key=${flashvars_key}" -o "$path_tmp"/zdl2.tmp &>/dev/null
		    
		    if [ ! -f "$path_tmp"/zdl2.tmp ]
		    then
			_log 5
			
		    elif ! grep url "$path_tmp"/zdl2.tmp &>/dev/null
		    then
			not_available=true
			break_loop=true

		    else
			url_in_file=$(cat "$path_tmp"/zdl2.tmp)
			url_in_file="${url_in_file#*'url='}"
			url_in_file="${url_in_file%%'&'*}"

			if [ -z "$file_in" ]
			then
			    file_in=$(grep "Title:" "$path_tmp"/zdl2.tmp)
			    file_in="${file_in%<*}"
			    file_in=$(trim "${file_in##*>}")

			    
			    [ "$file_in" == Untitled ] &&
				file_in=${file_in}-${url_in##*\/}
			fi
		    fi
		fi
	    fi
	fi	    
    fi
    try_end=15
    end_extension
    
fi
