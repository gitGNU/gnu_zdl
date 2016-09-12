
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

## zdl-extension types: shortlinks
## zdl-extension name: Shortlink


if [[ "$url_in" =~ (shortlink.) ]]
then
    shortcode="${url_in##*\/}"
    wget -q -O /dev/null                          \
	 --keep-session-cookies                   \
	 --save-cookies="$path_tmp/cookies.zdl"   \
	 --user-agent="$user_agent"               \
	 "$url_in"
    
    countdown- 10
    new_url=$(wget -qO-                                          \
		   http://www.shortlink.li/ajax/getLink          \
		   --post-data="short=$shortcode"                \
		   --user-agent="$user_agent"                    \
		   --load-cookies="$path_tmp/cookies.zdl"   |
		     sed -r 's|.+\"([^"]+)\"\}$|\1|g'       |
		     sed -r 's|\\||g')
    new_url="$(sanitize_url "$new_url")"
    
    if url "$new_url"
    then
	set_link - "$url_in"
	url_in="$new_url"
	set_link + "$url_in"	
    else
	break_loop=true
    fi
fi
