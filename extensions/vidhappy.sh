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
## zdl-extension name: Vidhappy (RTMP)


if [[ "$url_in" =~ (vidhappy.) ]]; then
    if [[ ! "$url_in" =~ embed ]]; then
	link_parser "$url_in"
	parser_path="${parser_path%%\/*}"
	url_link="http://www.vidhappy${parser_domain#*vidhappy}/embed-${parser_path%.html}-607x360.html"
    fi
    html=$(wget -q "$url_link" -O -) 
    streamer=$(grep streamer <<< "$html" |sed -r 's|^.+\"([^"]+)\".+$|\1|')
    playpath=$(grep file:  <<< "$html" |head -n1|sed -r 's|^.+\"([^"]+)\".+$|\1|')
    input_hidden "$(wget --keep-session-cookies --save-cookies=$path_tmp/cookies.zdl -q -O- $url_in)"
    ext=${playpath%\?*}
    file_in="$postdata_fname".${ext##*.}
fi