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
## zdl-extension name: swzz.xyz

if [ "$url_in" != "${url_in//swzz.xyz}" ]
then
    if wget -q --spider "$url_in"
    then
	html=$(wget -qO- "$url_in")

	if [[ ! "$html" =~ 'var link\s*=' ]]
	then
	    html=$(unpack "$html")
	fi
	
	url_in_new=$(grep -P 'var link\s*=' <<< "$html" |
			    sed -r 's|[^"]+\"([^"]+)\".+|\1|g')
	url_in_new=$(sanitize_url "${url_in_new}")
	
	replace_url_in "$url_in_new" ||
	    _log 2
	
    else
	_log 2
    fi
fi
