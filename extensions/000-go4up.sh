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
## zdl-extension name: Go4Up (multi-link)

if [[ "$url_in" =~ 'go4up.com/dl/' ]]
then
    html=$(wget -qO- "$url_in")
    
    url_js=$(grep -A4 'function loadlinks' <<< "$html" |
		    grep 'url: '                       |
		    sed -r 's|[^"]+\"([^"]+)\".+|\1|g')
    url_js="http://go4up.com${url_js}"

    url_json=$(wget -qO- "$url_js" | tr -d '\')
    
    url_json="${url_json#*href=\"}"
    url_json="http://go4up.com${url_json%%\"*}"

    replace_url_in "$url_json" || _log 2
fi

if [[ "$url_in" =~ 'go4up.com/rd/' ]]
then
    html=$(wget -qO- "$url_in")

    if [[ "$html" =~ (Error link not available) ]]
    then
	_log 3

    else
	for line in $(sed -r 's|, |\n|g' < $path_usr/hosting.txt  |
			     tr '[A-Z]' '[a-z]'                   |
			     grep -Po '^[^ ]+')
	do
	    if [ "$line" != "go4up" ] &&
		   [[ "$html" =~ $line\. ]]
	    then
		url_html=$(grep -P "$line\." <<< "$html" |
				  sed -r 's|[^"]+\"([^"]+)\".+|\1|g')
		break
	    fi
	done

	replace_url_in "$url_html" || _log 2
    fi
fi
	    
