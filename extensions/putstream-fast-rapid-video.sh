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
## zdl-extension name: Fastvideo, Rapidvideo, Putstream


if [[ "$url_in" =~ (fastvideo.|rapidvideo.|putstream.) ]]
then
    if [[ ! "$url_in" =~ embed ]]
    then
	if [[ "$url_in" =~ (putstream.) ]]
	then
	    html=$(wget -q -O- --user-agent="Firefox" "$url_in")
	    file_in=$(grep '<Title>' <<< "$html" |sed -r 's|.*<Title>([^<>]+)<.+|\1|g')
	fi
	link_parser "$url_in"
	parser_path="${parser_path%%\/*}"
	url_packed="${parser_proto}${parser_domain}/embed-${parser_path%.html*}-607x360.html"
    else
	url_packed="$url_in"
    fi

    html_embed=$(wget "$url_packed" -O- -q --user-agent="Firefox")
    html_packed=$(grep 'p,a,c,k,e,d' <<< "$html_embed")
    html_sources=$(grep 'sources' <<< "$html_embed")

    if [ -n "$html_packed" ]
    then
	packed_args "$html_packed"
	packed_code=$(packed "$code_p" "$code_a" "$code_c" "$code_k")
	url_in_file=$(sed -r 's@.+file\:\"http([^"]+)mp4\".+@http\1mp4@' <<< "$packed_code")

	if [[ ! "$url_in" =~ (putstream.) ]]
	then
	#file_in=$(grep '<title>' < "$1" |tail -n1 |sed -r 's@.*>([^<>]+)<.*@\1@g')."${url_in_file##*.}"
	    file_in=$(sed -r 's@.+tv_file_name\=\"([^"]+)\".+@\1@' <<< "$packed_code")
	fi

    elif [ -n "$html_sources" ]
    then
	url_in_file=$(sed -r 's|.+file:\"([^"]+)\".+|\1|g' <<< "$html_sources")
	file_in="${file_in}.${url_in_file##*.}"
    fi

    [ -n "$file_in" ] && file_in="${file_in#Watch}".${url_in_file##*.}
    file_in="${file_in## }"
    
    if [ -z "$url_in_file" ]
    then
	break_loop=true
    else
	axel_parts=4
    fi
fi
