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
## zdl-extension name: Videowood


if [ "$url_in" != "${url_in//'videowood.'}" ]
then
    test_ready=$(wget "$url_in" -qO- |grep 'video is not ready yet')
    if [ -n "$test_ready" ]
    then
	_log 17
	
    else
	html=$(wget -t 1 -T $max_waiting -qO- "${url_in//'/video/'//embed/}")
    
	if [ -n "$html" ] 
	then
	    url_in_file=$(grep file: <<< "$html" | grep http | head -n1)
	    url_in_file=${url_in_file#*\'}
	    url_in_file=${url_in_file#*\"}
	    url_in_file=${url_in_file%\'*}
	    url_in_file=${url_in_file%\"*}
	    
	    ext=${url_in_file##*.}
	    file_in=$(grep title: <<< "$html")
	    file_in="${file_in##*title\:}"
	    file_in="${file_in// /_}"
	    file_in="${file_in##_}"
	    file_in="${file_in%,*}"
	    file_in="${file_in%%_}".$ext
	    axel_parts=1
	else
	    _log 2
	fi
    fi
fi
