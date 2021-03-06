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
## zdl-extension name: Exashare


if [ "$url_in" != "${url_in//exashare.}" ]
then
    html=$(wget -qO- -t 1 -T $max_waiting                \
		--user-agent="$user_agent"               \
		"$url_in")

    input_hidden "$html"

    countdown- $(grep 'countdown_str" style' <<< "$html" |
			sed -r 's|.+>([0-9]+)<.+|\1|g' )
    
    url_in_file=$(wget -qO-                                                              \
		       --user-agent="$user_agent"                                        \
		       --post-data="${post_data#op=search&}&imhuman=Proceed to video"    \
		       "$url_in"                             |
			 grep 'file: "'                      |
			 sed -r 's|[^"]+"([^"]+)"[^"]+|\1|g')

    file_in="${file_in}.${url_in_file##*.}"

    if ! url "$url_in_file" ||
	    [ -z "$file_in" ]
    then
	_log 2
    fi
fi
