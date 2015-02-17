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
## zdl-extension name: Vimeo (HD)

if [ "$url_in" != "${url_in//'vimeo.com/'[0-9]}" ]; then
	wget "$url_in" -O "$path_tmp"/zdl.tmp -q
	url_in_file=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "data-config-url")
	url_in_file="${url_in_file#*data-config-url=\"}"
	url_in_file="${url_in_file%%\"*}"
	url_in_file=$(htmldecode "${url_in_file}")
	url_in_file=$(wget "$url_in_file" -O- -q)
	url_in_file="${url_in_file#*\"url\":\"}"
	url_in_file="${url_in_file%%\"*}"

	ext="${url_in_file%'?'*}"
	ext="${ext##*'.'}"
	file_in=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "title>")
	file_in="${file_in#*'title>'}"
	file_in="${file_in%%'</title'*}"
	file_in="${file_in//\//-}.$ext"
	file_in=$(htmldecode "$file_in")
fi
