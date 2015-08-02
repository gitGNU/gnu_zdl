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
## zdl-extension name: youtube-dl (script)


if [ -n "$(command -v youtube-dl 2>/dev/null)" ] &&
       [ -z "$url_in_file" ] &&
       [ -z "$break_loop" ]
then
    data=$(youtube-dl --get-url --get-filename "$url_in")

    items=( $(ls "$path_tmp"/filename_* 2>/dev/null) )
    for item in ${items[*]}
    do
	url=$(cat "$item" 2>/dev/null)
	if [ "${url%% }" == "$url_in" ]
	then
	    item="${item// /_}"
	    file_in="${item#*filename_}"
	    file_in="${file_in%.txt}"
	    break
	fi
    done

    if [ -z "$file_in" ]
    then
	file_in="$(tail -n1 <<< "$data")"
	file_in="${file_in% _ *}"
    fi
    
    url_in_file="$(tail -n2 <<< "$data" | head -n1)"

    if ! url "$url_in_file"
    then
	unset file_in url_in_file
    else
	unset break_loop
    fi
fi
