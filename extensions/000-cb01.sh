#!/bin/bash
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
## zdl-extension name: cb01

if [ "$url_in" != "${url_in//cb01.}" ]
then
    cb01_redirect=$(wget -S --spider "${url_in//serietv\/}" 2>&1 | awk '/Location:/{print $2}' | head -n1)

    if url "$cb01_redirect"
    then
	replace_url_in "$cb01_redirect"

    else
	_log 2
    fi
fi

if [ "$url_in" != "${url_in//k4pp4.}" ]
then
    html=$(wget -qO- "$url_in" |
		  grep 'Clicca per proseguire')

    html="${html#*\"}"
    
    replace_url_in "${html%%\"*}"
fi

