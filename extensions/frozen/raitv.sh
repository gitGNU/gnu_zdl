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

## ZDL add-on
## zdl-extension types: streaming
## zdl-extension name: Rai.tv

if [ "$url_in" != "${url_in//'rai.tv'}" ]
then
    if [ "${url_in}" == "${url_in//dirette}" ]
    then 
	wget "$url_in" -O "$path_tmp"/zdl.tmp -q
	url_in_file=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "videoURL_MP4")
	url_in_file="${url_in_file#*\"}"
	url_in_file="${url_in_file%%\"*}"
	file_in=$(cat "$path_tmp"/zdl.tmp 2>/dev/null |grep "title>")
	file_in="${file_in#*'title>'}"
	file_in="${file_in%%'</title'*}"
	file_in="${file_in//\//-}.mp4"
    else
	_log 3
	print_c 3 "La diretta RAI usa un protocollo non supportato da $name_prog" | tee -a $file_log
    fi
fi
