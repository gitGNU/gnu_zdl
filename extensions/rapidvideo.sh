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


if [ "$url_in" != "${url_in//rapidvideo}" ]; then
    # if [ "$url_in" != "${url_in%html}" ]; then
    # 	links_loop - "$url_in"
    # 	url_in="${url_in%\/*}"
    # 	links_loop + "$url_in"
    # fi
    wget --keep-session-cookies --save-cookies="$path_tmp"/cookies.zdl -O "$path_tmp/zdl.tmp" "$url_in" -q
    echo -e "...\c"
    URLaction=$(cat "$path_tmp/zdl.tmp"|grep POST)
    URLaction="${URLaction#*\'}"
    URLaction="${URLaction%\'*}"
    tmp="$path_tmp/zdl.tmp"
    input_hidden
    post_data="${post_data#*&}"
    wget --load-cookies="$path_tmp"/cookies.zdl --keep-session-cookies --save-cookies="$path_tmp"/cookies.zdl -O "$path_tmp/zdl2.tmp" --post-data="${post_data}" "$URLaction" -q

    url_in_file=$(cat "$path_tmp/zdl2.tmp" | grep "{file:'" )
    url_in_file="${url_in_file#*file:\'}"
    url_in_file="${url_in_file%%\'*}"
    ext="${url_in_file##*'.'}"
    file_in=$(cat "$path_tmp"/zdl.tmp 2>/dev/null | grep "Title>")
    file_in="${file_in#*'Title>'}"
    file_in="${file_in#Watch }"
    file_in="${file_in%'</Title'*}.$ext"
fi
