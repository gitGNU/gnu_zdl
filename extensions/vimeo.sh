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

if [[ "$url_in" =~ vimeo\.com\/([0-9]+) ]]
then
    html=$(wget https://player.vimeo.com/video/${BASH_REMATCH[1]} -qO-)
    html2="$html"

    ## meglio scaricare con aria2 il file mp4
    #
    # if command -v youtube-dl &>/dev/null
    # then
    # 	url_in_file=$(youtube-dl --dump-json "$url_in")
    # 	url_in_file="${url_in_file%.m3u8*}.m3u8"
    # 	url_in_file="${url_in_file##*\"}"

    # else
	if [ -z "$html" ]
	then
	    html2=$(wget -qO- "$url_in")
	    url_embed=$(grep GET <<< "$html2" |
			       sed -r 's|.+GET\",\"([^"]+)\".+|\1|g')
	    html=$(wget -qO- "$url_embed")
	fi

	url_in_file=$(grep -P 'token=' <<< "$(echo -e "${html//http/\\nhttp}")")
	url_in_file="${url_in_file%%\"*}"

	## M3U8: alternativa valida ma incompleta
	#
	# m3u8_url=$(echo -e "${html//http/\\nhttp}"  |
	# 		      grep m3u8                   |
	# 		      tail -n1                    |
	# 		      sed -r 's|([^"]+)\".+|\1|g')
	#
	# url_in_file=${m3u8_url%%video*}$(wget -qO- "$m3u8_url" | tail -n1 | sed -r "s|\.\.\/\.\.\/(.+)|\1|g")
#    fi
    
    ext="${url_in_file%'?'*}"
    ext="${ext##*'.'}"
    file_in=$(get_title "$html2").$ext

    end_extension
fi
