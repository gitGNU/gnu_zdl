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
## zdl-extension name: Streamin


# if [ "$url_in" != "${url_in//'streamin.to'}" ]
# then
#     html=$(wget	-qO- "$url_in")

#     if [[ "$html" =~ (File Deleted|file was deleted) ]]
#     then
# 	_log 3

#     elif [ -n "$html" ]
#     then
# 	input_hidden "$html"
# 	file_in="$postdata_fname"
# 	countdown- 6
# 	html=$(wget -qO-                      \
# 		    --post-data="$post_data"  \
# 		    "$url_in")
	
# 	streamer=$(grep streamer <<< "$html"                |
# 			  sed -r 's|^.+\"([^"]+)\".+$|\1|')
	
# 	playpath=$(grep file:  <<< "$html"                  |
# 			  head -n2                          |
# 			  tail -n1                          |
# 			  sed -r 's|^.+\"([^"]+)\".+$|\1|')
#     else
# 	_log 2
#     fi
# fi


if [ "$url_in" != "${url_in//'streamin.to'}" ]
then    
    if [[ ! "$url_in" =~ embed ]]
    then
	id_url="${url_in##*\/}"
	url_embed="http://streamin.to/embed-${id_url}-640x360.html"
	replace_url_in "$url_embed"
    fi
    
    url_title="${url_in//embed-}"
    url_title="${url_title//-640x360.html}"
    
    html=$(wget -qO- "$url_title")
    input_hidden "$html"
    
    html=$(wget -qO- "$url_in")
    unpacked=$(unpack "$html")
    
    url_in_file="${unpacked#*file\:\"}"
    url_in_file="${url_in_file%%\"*}"

    file_in="${file_in}.${url_in_file##*.}"

    end_extension
fi
