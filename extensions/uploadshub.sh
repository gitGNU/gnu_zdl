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
## zdl-extension name: Uploadshub


if [ "$url_in" != "${url_in//'uploadshub.com'}" ]
then
    html=$(wget -qO-                                      \
		--retry-connrefused                       \
		--keep-session-cookies                    \
		--save-cookies="$path_tmp"/cookies.zdl    \
		--user-agent="$user_agent"                \
		"$url_in")

    if [[ "$html" =~ (File Not Found) ]]
    then
	_log 3

    else
	input_hidden "$html"


	html2=$(wget -qO- --user-agent="$user_agent" --post-data="${post_data}" "$url_in")

	url_in_file=$(grep -P '<a href.+uploadshub.com.+<!--' <<< "$html2" |
			     sed -r 's|[^"]+\"([^"]+)\".+|\1|')

	file_in=$(grep '<title>' <<< "$html" |
			 sed -r 's|\ *<title>([^<]+)<.+|\1|')
	file_in="${file_in#Download }"

	end_extension
    fi
fi
