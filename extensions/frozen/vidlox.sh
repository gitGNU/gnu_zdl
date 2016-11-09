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
## zdl-extension name: Vidlox


if [[ "$url_in" =~ (vidlox.) ]]
then
    html=$(wget -qO- "$url_in")

    if [ -n "$html" ]
    then
	file_in=$(grep '<title>' -A1 <<<  "$html" |tail -n1)
	file_in="${file_in#Watch }"
	
	
	# url_link=$(grep 'sources:' <<< "$html" |
	# 		  sed -r 's|[^"]+\"([^"]+)\".+|\1|g')

	url_link=$(grep 'sources:' <<< "$html")
	url_link="${url_link##*file:\"}"
	url_link="${url_link%%\"*}"
	
	if [[ "$url_link" =~ \.m3u8$ ]]
	then
	    sanitize_file_in "$file_in"
	    file_in="$file_in".mp4
	    
	    url_in_file=$(wget -qO- "$url_link" | grep -vP '^\s*\#' | tail -n1)
	    ## downloader_in=FFMpeg
	    # stdbuf -oL -eL \
	    # 	   $ffmpeg -y -i "$url_in_file" -c copy -bsf:a aac_adtstoasc "$file_in" 2>&1 |
	    # 	tr '\r' '\n' 


	elif url "$url_link"
	then
	    url_in_file="$url_link"
	fi
    fi
    end_extension
fi
