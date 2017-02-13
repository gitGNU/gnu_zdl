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

## zdl-extension types: streaming download
## zdl-extension name: TubeOffLine.com

if ! url "$url_in_file" ||
	test -z "$file_in"
then
    host="${url_in#*\/\/}"
    host="${host#www.}"
    host="${host%%\/*}"
    host=$(grep -oP '[^.]+\.[^.]+$' <<< "$host")
    host="${host%%.*}"

    print_c 2 "tubeoffline -> host: $host"
    
    html=$(wget -qO- "$url_in")

    file_in=$(get_title "$html")

    html=$(wget -qO- "http://www.tubeoffline.com/downloadFrom.php?host=${host}&video=${url_in}")
    
    url_in_file=$(grep -P 'Best.+http' <<< "$html")
    ! url "${url_in_file}" &&
	url_in_file=$(grep -P 'http.+DOWNLOAD' <<< "$html" |head -n1)
    
    url_in_file="http${url_in_file#*http}"
    url_in_file="${url_in_file%%\"*}"

    if ! url "$url_in_file"
    then
	unset file_in url_in_file
    else
	print_c 1 "TubeOffLine: $url_in_file"
	unset break_loop
    fi
fi