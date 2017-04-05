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
## zdl-extension name: VidABC

if [ "$url_in" != "${url_in//'vidabc.'}" ]
then
    html=$(wget -t1 -T$max_waiting                               \
		"$url_in"                                        \
		--user-agent="Firefox"                           \
		--keep-session-cookies                           \
		--save-cookies="$path_tmp/cookies.zdl"           \
		-qO-)

    input_hidden "$html"

    countdown- 6

    html=$(wget -qO-                                       \
		"${url_in#.html}"                          \
		--load-cookies="$path_tmp/cookies.zdl"     \
		--post-data="$post_data")

    if [[ "$html" =~ (File Not Found|File doesn\'t exits) ]]
    then
	_log 3

    else
	download_video=$(grep -P 'download_video.+High quality' <<< "$html")

	[ -z "$download_video" ] &&
	    download_video=$(grep -P 'download_video.+Normal quality' <<< "$html")

	mode_stream=$(grep -oP "'(h|n){1}'" <<< "$download_video" | tr -d "'")
	
	if [ -n "$mode_stream" ]
	then
	    hash_stream="$postdata_hash"
	    id_stream="$postdata_id"
	    
	    stream_loops=0
	    while ! url "$url_in_file" &&
		    ((stream_loops < 3))
	    do
		((stream_loops++))
		html2=$(wget -qO- "http://vidabc.com/dl?op=download_orig&id=${id_stream}&mode=${mode_stream}&hash=${hash_stream}")
		
		input_hidden "$html2"

		url_in_file=$(wget -qO- \
				   "$url_in" \
				   --post-data="$post_data" |
				     grep 'Direct Download Link' |
				     sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

		((stream_loops < 3)) && sleep 1
	    done
	fi
	
	if ! url "$url_in_file" &&
		[[ "$html2" =~ 'have to wait '([0-9]+) ]]
	then
	    url_in_timer=$((${BASH_REMATCH[1]} * 60))
	    set_link_timer "$url_in" $url_in_timer
	    _log 33 $url_in_timer

	else
	    if ! url "$url_in_file"
	    then
		url_in_file=$(grep 'Direct Download Link' <<< "$html2" |
	     			     sed -r 's|.+\"([^"]+)\".+|\1|g')
	    fi
	    
	    if url "$url_in_file"
	    then
		case $mode_stream in
		    h)			
			print_c 1 "Disponibile il filmato HD"			
			;;		    
		    n)
		 	print_c 1 "Verrà scaricato il filmato con definizione \"normale\""
			;;
		esac

		url_in_file="${url_in_file//https\:/http:}"
		file_in="${url_in_file##*\/}"
	    fi
	    
	    end_extension
	fi
    fi
fi
