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

if [ "$url_in" != "${url_in//cineblog01}" ]; then
    if [ ! -z "$(command -v curl 2>/dev/null)" ]; then
	new_url=$(curl "$url_in" -s |grep window.location.href | sed -r 's|^.+\"([^"]+)\".+$|\1|')
	[ -z "$new_url" ] && new_url=$(wget "$url_in" -q -O- |grep 'Clicca per proseguire' |sed -r 's|[^"]+\"([^"]+)\".+|\1|g')
	if link_parser "$new_url"
	then
	    links_loop - "$url_in"
	    url_in="$new_url"
	    links_loop + "$url_in"
	else
	    break_loop=true
	    _log 2
	fi

    fi
fi


