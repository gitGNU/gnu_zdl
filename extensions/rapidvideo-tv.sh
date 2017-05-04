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
## zdl-extension name: Rapidvideo.tv

if [[ "$url_in" =~ rapidvideo\. && ! "$url_in" =~ rapidvideo\.com ]]
then
    if [[ ! "$url_in" =~ embed ]]
    then
	link_parser "$url_in"
	parser_path="${parser_path%%\/*}"
	replace_url_in "${parser_proto}${parser_domain}/embed-${parser_path%.html*}-896x370.html"
    fi
    
    html=$(wget --keep-session-cookies \
		--save-cookies="$path_tmp"/cookies.zdl \
		--user-agent="$user_agent" \
		-qO- "$url_in")
    
    html_unpacked=$(unpack "$html")
    
    url_in_file="${html_unpacked#*file:\"}"
    url_in_file="${url_in_file%%\"*}"

    file_in="${html_unpacked#*file_name=\"}"
    file_in="${file_in%%\"*}".${url_in_file##*.}
    
    end_extension
fi
