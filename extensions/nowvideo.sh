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
## zdl-extension name: Nowvideo

if [ "$url_in" != "${url_in//'nowvideo.'}" ]
then
    if [[ "$url_in" =~ 'http://nowvideo' ]]
    then
	replace_url_in "${url_in//nowvideo/www.nowvideo}"
    fi

    [[ "$url_in" =~ [0-9]+nowvideo ]] &&
	replace_url_in "${url_in//[0-9]nowvideo/nowvideo}"

    if [[ "$url_in" =~ nowvideo\.([^/]+)\/ ]]
    then
	ext=${BASH_REMATCH[1]}
	urlin=$(sed -r "s|nowvideo\.[^/]+|nowvideo.${ext:0:2}|g" <<< "$url_in")
	replace_url_in "$urlin"
	unset ext urlin
    fi

    html=$(wget -t 1 -T $max_waiting                     \
		"$url_in"                                \
		--user-agent="$user_agent"               \
		--keep-session-cookies                   \
		--save-cookies="$path_tmp"/cookies.zdl   \
		-qO-)

    if [ -n "$html" ]
    then
	test_exist=$(grep "This file no longer exists on our servers" <<< "$html")

	if [ -n "${test_exist}" ]
	then
	    echo sdhdshdfh
	    _log 3

	else
	    if [[ "$html" =~ (Continue to the video) ]]
	    then
		input_hidden "$html"
		
		html=$(wget -t 1 -T $max_waiting                     \
			    "$url_in"                                \
			    --user-agent="$user_agent"               \
			    --post-data="${post_data}&submit=submit" \
			    --keep-session-cookies                   \
			    --save-cookies="$path_tmp"/cookies.zdl   \
			    -qO-)
	    fi

	    if grep "yet ready" <<< "$html" &>/dev/null
	    then
		_log 3

	    else
		file_in=$(get_title "$html")
		file_in="${file_in#Watch}"
		file_in=$(trim "${file_in%'|'*}")

		url_in_file=$(grep "source" <<< "$html" |
				     head -n1 |
				     sed -r 's|.+\"([^"]+)\".+|\1|g')

		if ! url "$url_in_file"
		then
		    url_in_file="${url_in%'/video'*}"$(grep '/download.php?file=' <<< "$html" |
							      sed -r 's|[^"]+\"([^"]+).+|\1|g')
		fi
		
		if ! url "$url_in_file"
		then
		    flashvars_file=$(grep "flashvars.file=" <<< "$html")
		    flashvars_file="${flashvars_file#*'flashvars.file='\"}"
		    flashvars_file="${flashvars_file%\"*}"
		    
		    myip=$(wget -t 1 -T $max_waiting -qO- http://indirizzo-ip.com/ip.php)

		    flashvars_key=$(grep "$myip" <<< "$html")
		    flashvars_key="${flashvars_key#*\"}"
		    flashvars_key="${flashvars_key%\"*}"
		    flashvars_domain=$(grep "flashvars.domain=" <<< "$html")
		    flashvars_domain="${flashvars_domain#*'flashvars.domain='\"}"
		    flashvars_domain="${flashvars_domain%\"*}"

		    rm -f "$path_tmp"/zdl2.tmp
		    axel "${flashvars_domain}/api/player.api.php?user=undefined&cid=1&file=${flashvars_file}&pass=undefined&key=${flashvars_key}" -o "$path_tmp"/zdl2.tmp &>/dev/null

		    if [ ! -f "$path_tmp"/zdl2.tmp ]
		    then
	    		_log 5
			
		    elif [ -n "$(grep 'The video is being transfered' "$path_tmp"/zdl2.tmp)" ]
		    then
	    		_log 17
			
		    elif [ -z $(cat "$path_tmp"/zdl2.tmp 2>/dev/null |grep url ) ]
		    then
	    		not_available=true
	    		break_loop=true
		    else
	    		url_in_file=$(cat "$path_tmp"/zdl2.tmp)
	    		url_in_file="${url_in_file#*'url='}"
	    		url_in_file="${url_in_file%%'&'*}"

	    		file_in=$(grep "share" <<< "$html" |grep "title=")
	    		file_in="${file_in#*'title='}"
	    		file_in="${file_in%%\"*}"
		    fi
		fi

		if url "$url_in_file" &&
			[ -n "$file_in" ] &&
			[[ ! "$file_in" =~ (.mp4|.flv)$ ]]
		then
		    file_in="$file_in"."${url_in_file##*'.'}"
		fi
	    fi
	fi
    fi

    try_end=15
    end_extension
fi
