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
## zdl-extension name: Speedvideo


if [[ "$url_in" =~ (speedvideo.) ]]; then
    if [[ ! "$url_in" =~ embed ]]; then
	link_parser "$url_in"
	parser_path="${parser_path%%\/*}"
	url_link="http://speedvideo${parser_domain#*speedvideo}/embed-${parser_path%.html}-607x360.html"
    fi

    html=$(wget "$url_link" -O- -q)
    linkfile=$(grep linkfile <<< "$html" |head -n1 |sed -r 's|.+\"([^"]+)\".+|\1|g')
    var2=$(grep base64_decode <<< "$html" |sed -r 's|.+ ([^ ]+)\)\;$|\1|g')
    url_in_file=$(base64_decode $linkfile $(grep "$var2" <<< "$html" |head -n1 |sed -r 's|.+ ([^ ]+)\;$|\1|g') )
    file_in=$(wget -q -O- "$url_in" |grep 'itle>' |sed -r 's|.*itle>([^<>]+)<.+|\1|g').${url_in_file##*.}
    axel_parts=4
    link_parser "$url_in_file"
    if [ $? != 1 ] && [ "$file_in" == ".${url_in_file##*.}" ]; then
	loop_break=true
	_log 2
    fi
fi
 
