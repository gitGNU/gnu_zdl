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
## zdl-extension name: MultiUp (multi-link)

if [[ "$url_in" =~ multiup\.org ]]
then
    url_1="${url_in//en\/}"
    url_1="${url_1//download\/}"
    html=$(wget -qO- "${url_1}")

    url_2='https://multiup.org/en/mirror/'$(grep mirror <<< "$html" |tail -n1 |
						   sed -r 's|.+mirror\/([^"]+)\"[^"]+|\1|g')
    
    html=$(wget -qO- "${url_2}")

    for service in 'mega.nz\/\#' 'uptobox.com\/'
    do
	url_in_tmp=$(grep -P "$service" <<< "$html"|
			    sed -r 's|[^"]+\"([^"]+)\".*|\1|g')

	url "$url_in_tmp" && break	
    done
    
    replace_url_in "$url_in_tmp"

    [[ "$url_in" =~ multiup\.org ]] &&
	_log 2
fi
	    
