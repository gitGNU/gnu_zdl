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
# Copyright (C) 2012
# Free Software Foundation, Inc.
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (project administrator and first inventor)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

## zdl-extension types: streaming
## zdl-extension name: Fastvideo, Rapidvideo


if [[ "$url_in" =~ (fastvideo.|rapidvideo.) ]] && [[ ! "$url_in" =~ embed ]]; then
    link_parser "$url_in"
    links_loop - "$url_in"
    parser_path="${parser_path%%\/*}"
    url_in="${parser_proto}${parser_domain}/embed-${parser_path}-607x360.html"
    links_loop + "$url_in"
fi

if [[ "$url_in" =~ (fastvideo.|rapidvideo.) ]]; then
    html_packed=$(wget "$url_in" -O- -q |grep 'p,a,c,k,e,d')
    if [ ! -z "$html_packed" ]; then
	packed_args "$html_packed"
	packed_code=$(packed "$code_p" "$code_a" "$code_c" "$code_k")
	url_in_file=$(sed -r 's@.+file\:\"http([^"]+)mp4\".+@http\1mp4@' <<< "$packed_code")

	#file_in=$(grep '<title>' < "$1" |tail -n1 |sed -r 's@.*>([^<>]+)<.*@\1@g')."${url_in_file##*.}"
	file_in=$(sed -r 's@.+tv_file_name\=\"([^"]+)\".+@\1@' <<< "$packed_code")
	axel_parts=4
    else
	break_loop=true
    fi
fi
