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

## zdl-extension types: download
## zdl-extension name: Uppit


if [ "$url_in" != "${url_in//uppit.}" ]
then
    html=$(wget -qO-                                \
	   "$url_in"                                \
	   --user-agent="$user_agent"               \
	   --save-cookies="$path_tmp"/cookies.zdl   \
	   --keep-session-cookies)
    input_hidden "$html"

    html=$(wget -qO-                               \
	 "$url_in"                                 \
	 --post-data="${post_data}&method_free= "  \
	 --load-cookies="$path_tmp"/cookies.txt)
    input_hidden "$html"

    url_in_file=$(grep Download <<< "$html" |
			 grep onClick       |
	       sed -r 's|[^"]+\"([^"]+)\".+|\1|' )

    unset post_data

    url_in_file=$(sanitize_url "$url_in_file")

    axel_parts=2
    
    end_extension
fi
