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
## zdl-extension name: Jheberg (multi-link)

if [[ "$url_in" =~ 'jheberg.net' ]]
then
    MIRRORS="${url_in//captcha/mirrors}"
    REDIRECT="${MIRRORS//mirrors/redirect}"
    GETLINK="http://www.jheberg.net/get/link/"

    slug="${url_in%%\/}"
    slug="${slug##*\/}"

    hosters=( "Mega" "UpToBox" )

    wget --keep-session-cookies                  \
	 --save-cookies="$path_tmp/cookies.zdl"  \
	 --user-agent="$user_agent"              \
	 --referer="$MIRRORS"                    \
	 "$REDIRECT" -qO /dev/null

    countdown- 5 

    for hoster in ${hosters[@]}
    do
	reurl=$(wget --keep-session-cookies                       \
		     --load-cookies="$path_tmp/cookies.zdl"       \
		     --user-agent="$user_agent"                   \
		     --referer="$REDIRECT"                        \
		     --header='X-Requested-With: XMLHttpRequest'  \
		     --post-data="slug=${slug}&hoster=${hoster}"  \
		     "$GETLINK" -qO-)
	reurl="${reurl%\"*}"
	reurl="${reurl##*\"}"

	url "$reurl" && break
    done

    url "$reurl" &&
	print_c 1 "$url_in sostituito con $reurl" &&
	replace_url_in "$reurl" ||
	    _log 2
fi
