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
## zdl-extension types: streaming download
## zdl-extension name: WStream (HD)

function add_wstream_definition {
    set_line_in_file + "$url_in $1" "$path_tmp"/wstream-definitions
}

function del_wstream_definition {
    set_line_in_file - "$url_in $1" "$path_tmp"/wstream-definitions
}

function get_wstream_definition {
    declare -n ref="$1"

    if test -f "$path_tmp"/wstream-definitions
    then
	ref=$(grep -P "^$url_in (o|n|l){1}$" "$path_tmp"/wstream-definitions |
		     cut -f2 -d' ')
    fi
}

if [[ "$url_in" =~ wstream ]] 
then
    unset html html2 movie_definition
    
    # if [ -z "$(grep -v wstream "$path_tmp/links_loop.txt" &>/dev/null)" ]
    # then
    # 	print_c 1 "Cookies cancellati"
    # 	rm -rf "$path_tmp/cookies.zdl"           
    # fi
    
    html=$(wget -t1 -T$max_waiting                               \
		"$url_in"                                        \
		--user-agent="Firefox"                           \
		--keep-session-cookies                           \
		--save-cookies="$path_tmp/cookies.zdl"           \
		-qO-)

    if [[ "$html" =~ (File Not Found|File doesn\'t exits) ]]
    then
	_log 3

    else
	# download_video=$(grep -P 'download_video.+Original' <<< "$html")

	# hash_wstream="${download_video%\'*}"
	# hash_wstream="${hash_wstream##*\'}"

	# id_wstream="${download_video#*\'}"
	# id_wstream="${id_wstream%%\'*}"

	# declare -A movie_definition
	# movie_definition=(
	#     ['o']="Original"
	#     ['n']="Normal"
	#     ['l']="Low"
	# )

	# for mode_stream in o n l
	# do
	#     get_wstream_definition mode_stream_test

	#     [ -n "$mode_stream_test" ] &&
	# 	mode_stream="$mode_stream_test"

	#     print_c 2 "Filmato con definizione ${movie_definition[$mode_stream]}..."
	    
	#     wstream_loops=0
	#     while ! url "$url_in_file" &&
	# 	    ((wstream_loops < 2))
	#     do
	# 	((wstream_loops++))
	# 	html2=$(wget -qO- -t1 -T$max_waiting           \
	# 		     "https://wstream.video/dl?op=download_orig&id=${id_wstream}&mode=${mode_stream}&hash=${hash_wstream}")
		
	# 	input_hidden "$html2"

	# 	url_in_file=$(wget -qO- -t1 -T$max_waiting     \
	# 			   "$url_in"                   \
	# 			   --post-data="$post_data" |
	# 			     grep 'Direct Download Link' |
	# 			     sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

	# 	((wstream_loops < 2)) && sleep 1
	#     done

	#     if ! url "$url_in_file" &&
	# 	    [[ "$html2" =~ 'have to wait '([0-9]+) ]]
	#     then
	# 	url_in_timer=$((${BASH_REMATCH[1]} * 60))
	# 	set_link_timer "$url_in" $url_in_timer
	# 	_log 33 $url_in_timer

	# 	add_wstream_definition $mode_stream
	# 	break

	#     else
	# 	if ! url "$url_in_file"
	# 	then
	# 	    url_in_file=$(grep 'Direct Download Link' <<< "$html2" |
	#      				 sed -r 's|.+\"([^"]+)\".+|\1|g')
	# 	fi
		
	# 	if url "$url_in_file"
	# 	then
	# 	    print_c 1 "Disponibile il filmato con definizione ${movie_definition[$mode_stream]}"
	# 	    set_wstream_definition $mode_stream
	# 	    break

	# 	else
	# 	    print_c 3 "Non è disponibile il filmato con definizione ${movie_definition[$mode_stream]}"
	# 	    del_wstream_definition $mode_stream
	# 	fi
	#     fi
	# done

	
	
	if url "$url_in_file"
	then
	    url_in_file="${url_in_file//https\:/http:}"
	    file_in="${url_in_file##*\/}"
	    
	else
	    unpacked=$(unpack "$html")
	    url_in_file="${unpacked%.mp4*}.mp4"
	    url_in_file="${url_in_file##*\"}"

	    file_in="${unpacked#*'title:'\"}"
	    file_in="${file_in%%\"*}"
	fi

	[ -z "$url_in_timer" ] &&
	    end_extension ||
		unset url_in_timer
    fi
fi
