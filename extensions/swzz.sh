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

## zdl-extension types: download streaming
## zdl-extension name: http://swzz.xyz

if [ "$url_in" != "${url_in//swzz.xyz}" ]
then
    html=$(wget -qO- "$url_in")
    if [ -z "$(grep 'var link =' <<< "$html")" ]
    then	
	packed_args "$(grep eval <<< "$html")"
	html=$( packed "$code_p" "$code_a" "$code_c" "$code_k" )
    fi
    
    url_in_new=$(grep -P 'var link\s*=' <<< "$html" |sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

    if url "$url_in_new"
    then
	links_loop - "$url_in"
	url_in="$url_in_new"
	links_loop + "$url_in"
    else
	_log 2
    fi
fi
