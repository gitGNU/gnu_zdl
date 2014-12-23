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
# Copyright (C) 2012
# Free Software Foundation, Inc.
# 
# For information or to collaborate on the project:
# https://savannah.nongnu.org/projects/zdl
# 
# Gianluca Zoni (project administrator and first inventor)
# http://inventati.org/zoninoz
# zoninoz@inventati.org
#

## ZDL add-on
## zdl-extension types: streaming
## zdl-extension name: Tvdigit.it

if [ "$url_in" != "${url_in//'tvdigit.it'}" ]; then

	wget "$url_in" -O "$path_tmp"/zdl.tmp -q
	url_in_file=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep ".flv")
	url_in_file="${url_in_file%%.flv*}.flv"
	url_in_file="http${url_in_file##*http}"
	url_in_file=$(urldecode "${url_in_file}")

	ext="flv"
	file_in=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "title>")
	file_in="${file_in#*'title>'}"
	file_in="${file_in%%'</title'*}"
	file_in="${file_in//\//-}.$ext"
	file_in=$(htmldecode "$file_in")
fi
