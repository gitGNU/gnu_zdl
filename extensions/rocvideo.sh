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
## zdl-extension name: Rocvideo


if [ "$url_in" != "${url_in//'rocvideo.'}" ]
then
    html=$(wget  -qO- -t 5 -T $max_waiting                \
		 --keep-session-cookies                   \
		 --save-cookies="$path_tmp/cookies.zdl"   \
		 --user-agent="$user_agent"               \
		 "$url_in")

    input_hidden "$html"

    html_packed=$(wget -qO-                                                   \
	 	       --user-agent="$user_agent"                             \
		       --load-cookies="$path_tmp/cookies.zdl"                 \
		       --post-data="${post_data}&method_free=Continue video"  \
		       "$url_in" |
			 grep 'p,a,c,k,e,d')

    packed_args "$html_packed"
    url_in_file=$(packed "$code_p" "$code_a" "$code_c" "$code_k" |
			 sed -r 's|.+file:\"([^"]+)\".+|\1|g')

    if ! url "$url_in_file" ||
	    [ -z "$file_in" ]
    then
	_log 2
    fi
fi
